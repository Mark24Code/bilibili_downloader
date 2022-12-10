#!/usr/bin/env ruby

AUTHOR = "Mark24"
EMAIL = "mark.zhangyoung@gmail.com"
EMAIL_CN = "mark.zhangyoung@qq.com"
VERSION = "4.2.3"
SCRIPT_FILE_NAME = "bilibili_downloader.rb"
REPO = "https://github.com/Mark24Code/bilibili_downloader"
README =  "https://github.com/Mark24Code/bilibili_downloader/blob/main/README.md"
EXAMPLE_URL = "https://www.bilibili.com/video/BV1Xx41117tr"
SCRIPT_STATIC_FILE_URL = "https://raw.githubusercontent.com/Mark24Code/bilibili_downloader/main/#{SCRIPT_FILE_NAME}"

require 'optparse'
require 'uri'
require 'thread'

module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
   (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.linux?
    (/linux/ =~ RUBY_PLATFORM) != nil
  end
end


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
    @url = opt.fetch(:url, nil)
    @format_type = opt.fetch(:format_type, 'default')
  end

  def start
    self.download_dispatcher
  end

  def download_dispatcher
    __send__("download_#{@format_type}")
  end

  def download_1080
    system("you-get --format=dash-flv " + @url)
  end

  def download_720
    system("you-get --format=dash-flv720 " + @url)
  end

  def download_480
    system("you-get --format=dash-flv480 " + @url)
  end

  def download_360
    system("you-get --format=dash-flv360 " + @url)
  end

  def download_default
    system("you-get " + @url)
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
    @url = nil
    self.preprocess
  end

  def start
    self.add_job_to_queue
  end

  def preprocess
    @thread_count = @thread_count > @range.size ? @range.size : @thread_count
    self.get_clean_url
  end

  def add_job_to_queue
    ws = Workshop.new(@thread_count, @mode)
    finished = []

    @range.map do | p_id |
      ws << lambda { 
        sleep @sleep if @sleep
        target = @url.clone
        target.query = "p=#{p_id}"
        d = Downloader.new(url: "#{target}", format_type: @format_type)
        d.start
        finished << p_id
      }
    end
    ws << :done
    ws.join
    
    self.tail_job
    puts "====== #{SCRIPT_FILE_NAME} Report ======"
    puts "Expected: #{@range.size}"
    puts "Finished: #{finished.length}"
  end

  def get_clean_url
    u = URI(@raw_url)
    u.query = nil
    @url = u
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


options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{SCRIPT_FILE_NAME} [options]"

  opts.on("-u URL", "--url URL", "Video source url. Just full video web url which pasted from web browser.") do |t|
    options[:url] = t
  end
  opts.on("-f FORMAT_TYPE", "--format_type FORMAT_TYPE", "Video format type.  e.g. 480/720/1080/default 取决于视频支持，见播放器") do |t|
    options[:format_type] = t || 'default'
  end

  opts.on("-t SLEEP", "--time SLEEP", "Sleep seconds between each thread job.") do |t|
    options[:sleep] = t.to_i || 0
  end

  opts.on("-c THREAD_COUNT", "--thread_count THREAD_COUNT ", "Thread count to download. Recommand your computer cpu core numbers.") do |t|
    options[:thread] = t.to_i
  end

  opts.on("-r RANGE", "--range RANGE ", "Download video range. e.g 1..4 means from 1 to 40, use Ruby `Range` syntax") do |t|
    options[:range] = instance_eval("(#{t})")
  end

  opts.on("--example", "Give me a example") do |t|
    puts "1. Run by local file: "
    puts "./#{SCRIPT_FILE_NAME} <CLI options>"
    puts ""
    puts "e.g. :"
    puts "./#{SCRIPT_FILE_NAME} -u #{EXAMPLE_URL} -c 4 -r 1..40"
    puts ""
    puts "2. Ruby from Internet by curl:"
    puts "ruby -e \"$(curl -fsSL #{SCRIPT_STATIC_FILE_URL})\" -- <CLI options>"
    puts ""
    puts "e.g. :"
    puts "ruby -e \"$(curl -fsSL #{SCRIPT_STATIC_FILE_URL})\" -- -u #{EXAMPLE_URL} -c 4 -r 1..40"
    return
  end

  opts.on("--doc", "Document, wiki") do |t|
    puts README
    return 
  end

  opts.on("--preinstall", "Install dependencies library.") do |t|
    if OS.mac?
      puts "==== bilibili downloader ===="
      puts "[install library 1/2] install python3"
      system("brew install python3")
      puts "[install library 2/2] install you-get"
      system("pip3 install you-get")
    elsif OS.linux?
      result = `uname -a`
      if (/debian/ =~ result) != nil
        puts "==== bilibili downloader ===="
        puts "[install library 1/2] install python3"
        system("sudo apt install python3")
        puts "[install library 2/2] install you-get"
        system("pip3 install you-get")
      else
        puts "Just support Debian Linux auto install. You must install by yourself."
      end
    else
      puts "Not Support Windows. You must install by yourself."
    end
  end

  opts.on("-v", "--version", "version") do
    puts "Bilibili Downloader v#{VERSION}"
    puts "Repo: #{REPO}"
    puts ""
    puts "Author: #{AUTHOR}"
    puts "Email: #{EMAIL}"
    puts "Email(in China): #{EMAIL_CN}"
    
    exit 0
  end
end.parse!


if options.keys.length == 0
  puts "bilibili_downloader: Opps..."
  puts ""
  puts "You give nothing arguments. `./#{SCRIPT_FILE_NAME} --help` may help you."
  puts "More Details & Wiki:  #{REPO}/blob/main/README.md"
  return
end


hacker = BiliBiliDownloadHacker.new(options)
hacker.start
