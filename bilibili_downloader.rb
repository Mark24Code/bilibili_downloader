#!/usr/bin/env ruby

"" "
Bilibili Ruby多线程下载器
@Author: mark.zhangyoung@qq.com
@Date: 2022.05.31
@License: MIT
工作要求:
1.系统安装Python3
2.安装you-get （pip3 install you-get)
原理:
  you-get仅仅只能单线程工作，本脚本使用Ruby3的Ractor技术制造一个多线程无锁队列
  真正的并行执行you-get任务
配置说明:
robot = Robot.new(
  source_url:'https://www.bilibili.com/video/BV13F411376G?p=1', # 具体目录清淡的一个地址，p=几无所谓
  format_type: 480, # 格式 480、360、720、default 要根据网页确定
  workers: 3, # 工作线程数
  total: 54 # 要下载的资源总数，默认1开始
)
使用说名:
robot.run
" ""

class DownloadCmd
  def initialize(url, format_type)
    @url = url
    @format_type = format_type || "default"
  end

  def format_default
    "#{@url}"
  end

  def format_1080
    "--format=dash-flv #{@url}"
  end

  def format_720
    "--format=dash-flv720 #{@url}"
  end

  def format_480
    "--format=dash-flv480 #{@url}"
  end

  def format_360
    "--format=dash-flv360 #{@url}"
  end

  def download_full_cmd
    args = __send__("format_#{@format_type}")
    "you-get #{args}"
  end
end

class Robot
  def initialize(opt)
    @source_url = self.split_source_url(opt[:source_url])
    @format_type = opt[:format_type] || "480"

    @queue = Ractor.new do
      loop do
        Ractor.yield(Ractor.receive)
      end
    end

    @worker_count = opt[:workers] || 3
    @total = opt[:total]
  end

  def split_source_url(source_url)
    pattern = /^(https:\/\/www.bilibili.com\/.*?\?p=)(.*?)/
    result = pattern.match(source_url)
    if result && result[0]
      result
    else
      throw "URL must be `https://www.bilibili.com/video/<videoId>?p=<orderId>` format."
    end
  end

  def hack
    cmd = DownloadCmd.new(@source_url, @format_type).download_full_cmd

    workers_ractors = (1..@worker_count).map do |worker_id|
      Ractor.new(@queue, cmd, name: "worker@#{worker_id}") do |queue, cmd|
        while job_id = queue.take
          full_cmd = "#{cmd}#{job_id}"

          puts full_cmd
          system(full_cmd)

          Ractor.yield "Download #{job_id} success"
        end
      end
    end

    job_tasks = (1..@total).to_a

    job_tasks.each do |job_id|
      @queue.send job_id
    end

    job_tasks.each {
      puts Ractor.select(*workers_ractors)
    }
  end
end

robot = Robot.new(
  source_url: "https://www.bilibili.com/video/BV13F411376G?p=1",
  format_type: 480,
  workers: 3,
  total: 54,
)

robot.hack