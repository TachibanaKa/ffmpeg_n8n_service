#!/bin/bash
# FFmpeg 全功能处理脚本
# 参数：
# $1 = 输入文件
# $2 = 输出文件
INPUT_FILE=$1
OUTPUT_FILE=$2

echo "Processing $INPUT_FILE -> $OUTPUT_FILE ..."

# 基本转码：720p MP4 H.264
ffmpeg -i "$INPUT_FILE" -vf "scale=1280:720" -c:v libx264 -crf 23 -preset fast "$OUTPUT_FILE"

# 可拓展：
# - 音量调整：-af "volume=1.5"
# - 水印：-i watermark.png -filter_complex "overlay=10:10"
# - 拼接多视频
# - 色彩滤镜：-vf "hue=s=0"
