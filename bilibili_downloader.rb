#!/usr/bin/env ruby
'''
这是前期版本
使用线程工作，但是多线程会造成死锁问题
排队序列不会自动补充，效率一般。推荐下面的 plus 版本
----
下载哔哩哔哩合集 Hack机器人
source_url 要是合集url保留p参数
https://www.bilibili.com/video/BV1Wu411B72F?p=
参数说明：
  source_url: 合集地址，要保留p参数，例如 https://www.bilibili.com/video/BV1Wu411B72F?p=
  format_type: 格式 720/1080/default， 具体参考 show_info 返回
  thread_sleep: 5 一组线程之后休眠时间 秒
  thread_num: 2, 一次进行的线程数
  begin: 5, # >=1 开始索引 从1开始
  total: 1, # >= 1 要下载多少，从1开始
------
依赖:
1. 请提前安装Python3+
`pip install you-get`
下载任务依赖 python you-get
2.脚本起到多线程协调任务
'''

class Downloader
  def initialize(opt)
    @source_url = opt[:source_url]
    @thread_num = opt[:thread_num]
    @format_type = opt[:format_type] || 'test'
    @thread_sleep = opt[:thread_sleep] || 1

    @begin = opt[:begin] || 1 # >= 1
    @total = opt[:total] || 1 # >= 1

    @start_index = @begin - 1
    @end_index = @start_index + @total
  end

  def download_worker(task_id)
    puts "[Thread @#{task_id} is running]"
    uri = "#{@source_url}#{task_id}"
    puts "Download Worker@#{task_id},@#{@format_type}"

    __send__("download_#{@format_type}", uri)
  end

  def download_1080(url)
    system("you-get --format=dash-flv "+url)
  end

  def download_720(url)
    system("you-get --format=dash-flv720 "+url)
  end

  def download_480(url)
    system("you-get --format=dash-flv480 "+url)
  end

  def download_360(url)
    system("you-get --format=dash-flv360 "+url)
  end

  def download_default(url)
    system("you-get "+url)
  end

  def download_test(arg)
    puts "hello world"
  end

  def showinfo
    system("you-get -i "+@source_url)
  end

  def download
    grouping_ids_arr = self.grouping
    # p grouping_ids_arr
    self.thread_work(grouping_ids_arr, lambda { |task_id| self.download_worker(task_id) })
  end

  def thread_work(order_group, handler)
    while order_group
      current_task_ids = order_group.shift
      if !current_task_ids
        break
      end

      threads_group = []
      current_task_ids.each do |payload|
        threads_group << Thread.new do
          handler.call(payload)
        end
      end

      # puts "start task: #{current_task_ids.join(',')}"
      threads_group.each { |thr| thr.join }
      # threads_group.map do |thr|
      #   thr.value
      # end
      if @thread_sleep > 0
        sleep @thread_sleep
      end
    end
  end

  def grouping
    """
    @task_pice_group = [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12], [13, 14, 15]]
    """
    grouping_result = []
    group_count = @total / @thread_num

    for group_index in (0..group_count-1)
      group_pices = []
      for sub_index in (0..@thread_num-1)
        pice_id = @start_index - 1 + group_index * @thread_num + sub_index + 1
        # printf("#{pice_id} \t")
        group_pices.push(pice_id + 1)
      end
      # puts ""
      grouping_result.push(group_pices)
    end

    if(group_count*@thread_num < @total)
      group_pices = []
      for rest_sub_index in ((@start_index + group_count*@thread_num).. @end_index-1)
        pice_id = rest_sub_index
        # printf("#{pice_id} \t")
        group_pices.push(pice_id + 1)
      end
      # puts ""
      grouping_result.push(group_pices)
    end

    return grouping_result
  end
end


# 剧集总数
total = 8
# 当前第几集开始
current = 1

hacker = Downloader.new(
  source_url:'https://www.bilibili.com/video/BV1vs41117JH?p=',
  format_type: 480,
  thread_sleep: 0,

  thread_num: 3,
  begin: current, # >=1 
  total: total - current + 1, # >= 1
)
# hacker.showinfo
hacker.download