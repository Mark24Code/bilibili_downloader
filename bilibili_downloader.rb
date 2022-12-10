#!/usr/bin/env ruby
'''
----
下载哔哩哔哩合集 Hack机器人 3.0
改进说明:
1.独立性的多线程
2.均匀的分发任务模型（cycle mode）
3.友好的参数，url、range 非常自然易用
参数说明：
  url: 合集地址特征是存在 p=1 数字具有递增性，贴完整地址即可
  format_type: 格式 720/1080/default， 具体参考 show_info 返回
  sleep: 1 一组线程之后休眠时间 秒
  thread: 2, 一次进行的线程数
  range: (1..40) 1到40集；可以是一个range序列或者数组（会用来生成p序列）
------
依赖:
1. 请提前安装Python3+
`pip install you-get`
下载任务依赖 python you-get
2.脚本起到多线程协调任务
'''

require 'uri'
require 'thread'

class Worker
  attr :name, :group
  def initialize(name)
    @name = "worker@#{name}"
    @queue = Queue.new
    @thr = Thread.new { perfom }
  end

  def <<(job)
    @queue.push(job)
  end

  def join
    @thr.join
  end

  def perfom
    while (job = @queue.deq)
      break if job == :done
      puts "worker@#{name}: job:#{job}"
      job.call
    end
  end

  def size
    @queue.size
  end
end


class NormalMode
  def initialize(workers)
    @workers = workers
  end

  def assign(job)
    @workers.sort{|a,b| a.size <=> b.size}.first << job
  end
end

class CycleMode
  def initialize(workers)
    @current_worker = workers.cycle # 迭代器
  end

  def assign(job)
    @current_worker.next << job
  end
end

class GroupMode
  GROUPS = [:group1, :group2, :group3]

  def initialize(workers)
    @workers = {}
    workers_per_group = workers.length / GROUPS.size
    workers.each_slice(workers_per_group).each_with_index do |slice, index|
      group_id = GROUPS[index]
      @workers[group_id] = slice
    end
  end

  def assign(job)
    worker = @workers[job.group].sort_by(&:size).first
    worker << job
  end
end

Mode = {
  normal: NormalMode,
  cycle: CycleMode,
  group: GroupMode
}

class Workshop
  def initialize(count, master_name)
    @worker_count = count
    @workers = @worker_count.times.map do |i|
      Worker.new(i)
    end
    @master = Mode[master_name].new(@workers)
  end

  def <<(job)
    if job == :done
      @workers.map {|m| m << job}
    else
      @master.assign(job)
    end
  end

  def join
    @workers.map {|m| m.join}
  end
end

class Downloader
  def initialize(opt)
    @uri = opt.fetch(:uri, nil)
    @format_type = opt.fetch(:format_type, 'default')
  end

  def start
    self.download_dispatcher
  end

  def download_dispatcher
    __send__("download_#{@format_type}")
  end

  def download_1080
    system("you-get --format=dash-flv " + @uri)
  end

  def download_720
    system("you-get --format=dash-flv720 " + @uri)
  end

  def download_480
    system("you-get --format=dash-flv480 " + @uri)
  end

  def download_360
    system("you-get --format=dash-flv360 " + @uri)
  end

  def download_default
    system("you-get " + @uri)
  end
end



class BiliBiliDownloadHacker
  def initialize(opt = {})
    @raw_url = opt.fetch(:url, nil)
    @format_type = opt.fetch(:format_type, 480)
    @sleep = opt.fetch(:sleep, 0)
    @thread_count = opt.fetch(:thread, 3)
    @range = opt.fetch(:range, nil)
    @mode = opt.fetch(:mode, :cycle) # normal,cycle

    self.check_opts
    @uri = nil
    self.preprocess
    

  end

  def start
    self.add_job_to_queue
  end

  def preprocess
    @thread_count = @thread_count > @range.size ? @range.size : @thread_count
    self.get_clean_uri
  end

  def add_job_to_queue
    ws = Workshop.new(@thread_count, @mode)
    finished = []

    @range.map do | p_id |
      ws << lambda { 
        sleep @sleep if @sleep
        target = @uri.clone
        target.query = "p=#{p_id}"
        d = Downloader.new(uri: "#{target}", format_type: @format_type)
        d.start
        finished << p_id
      }
    end
    ws << :done
    ws.join
    
    self.tail_job
    puts "--- Report -------"
    puts "finished: #{finished.length}"
  end

  def get_clean_uri
    u = URI(@raw_url)
    u.query = nil
    @uri = u
  end


  def check_opts
    if !@raw_url
      raise Error('error: `url` must not be nil')
    end

    if !@range
      raise Error('error: `range` must not be nil')
    end
  end

  def tail_job
    system("mkdir xml")
    system("mv *.xml ./xml/")
  end
end

hacker = BiliBiliDownloadHacker.new(
  url: "https://www.bilibili.com/video/BV1Xx41117tr/?spm_id_from=333.337.search-card.all.click&vd_source=b426269b70cf7c5ee688ab3b6b3983e7",
  format_type: 480,
  range: (1..40),
  thread: 10,
  sleep: 1,
)

hacker.start