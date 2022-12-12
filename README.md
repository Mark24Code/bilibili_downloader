# bilibili_downloader


## 1. Before use:

### 1.1 Make sure you have `ruby3`

MacOS:

`brew install ruby`

Debian Linux:

`sudo apt install ruby`

### 1.2 Make sure you have `ffmpeg`

[ffmpeg homepage](https://ffmpeg.org/download.html)

MacOS:

`brew install ffmpeg`

Debian

`sudo apt install ffmpeg`

## 1.2 Other Dependency

### 1.2.1 Auto install 

Just support  MacOS、Debian Linux

`./bilibili_downloader --preinstall`

### 1.2.2 Install by yourself


1. Make sure you have `python3` 

MacOS:

`brew install python3`

Debian

`sudo apt install python3`

2. Make sure you have `you-get` 

MacOS:

`pip install you-get`

Debian:

`sudo pip install you-get`

# 2. Run hack script

## 2.1 local script file run：

`./bilibili_downloader.rb --help`


```text
Usage: bilibili_downloader.rb [options]
    -u, --url URL                    Video source url. Just full video web url which pasted from web browser.
    -f, --format_type FORMAT_TYPE    Video format type.  e.g. 480/720/1080/default 取决于视频支持，见播放器
    -t, --time SLEEP                 Sleep seconds between each thread job.
    -c, --thread_count THREAD_COUNT  Thread count to download. Recommand your computer cpu core numbers.
    -r, --range RANGE                Download video range. e.g 1..4 means from 1 to 40, use Ruby `Range` syntax
        --example                    Give me a example
        --doc                        Document, wiki
        --preinstall                 Install dependencies library.
    -v, --version                    version
```


## 2.2 Run script from network

curl support:

```shell
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Mark24Code/bilibili_downloader/main/bilibili_downloader.rb)" -- <CLI options>
```

e.g.

```shell
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Mark24Code/bilibili_downloader/main/bilibili_downloader.rb)" --  -u https://www.bilibili.com/video/BV1Xx41117tr -c 4 -r 1..40
```
