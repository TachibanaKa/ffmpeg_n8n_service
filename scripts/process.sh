#!/bin/bash
set -e

# JSON 输入通过环境变量传入
INPUT_JSON=${INPUT_JSON:-input.json}   # n8n 传入环境变量 INPUT_JSON
OUTPUT_FILE=${OUTPUT_FILE:-output.mp4} # 输出文件

TEMP_DIR="temp_ffmpeg"
mkdir -p "$TEMP_DIR"

echo "📄 Using JSON: $INPUT_JSON"
echo "💾 Output file: $OUTPUT_FILE"

# 检查 jq 是否安装
if ! command -v jq &> /dev/null; then
    echo "❌ jq is required. Install it first."
    exit 1
fi

# 清空临时目录
rm -rf "$TEMP_DIR/*"

# 解析 JSON，按 index 排序
indexes=$(echo "$INPUT_JSON" | jq -c 'sort_by(.index)[]')

# 用于存储每个片段文件
SEGMENTS=()
i=0
for obj in $indexes; do
    i=$((i+1))
    echo "🎬 Processing segment #$i"

    # 解析图片和音频
    img_urls=$(echo "$obj" | jq -r '.img_urls' | tr ',' ' ')
    audios=$(echo "$obj" | jq -r '.audios' | tr ',' ' ')

    # 创建临时目录
    SEG_TEMP="$TEMP_DIR/segment_$i.mp4"
    mkdir -p "$TEMP_DIR/segment_$i"
    cd "$TEMP_DIR/segment_$i"

    img_list=()
    for url in $img_urls; do
        fname=$(basename "$url")
        wget -q "$url" -O "$fname"
        img_list+=("$fname")
    done

    audio_list=()
    for url in $audios; do
        fname=$(basename "$url")
        wget -q "$url" -O "$fname"
        audio_list+=("$fname")
    done

    # 每个图片显示时长 = 音频总长度 / 图片数
    total_audio_duration=$(ffmpeg -i "${audio_list[0]}" 2>&1 | grep "Duration" | awk '{print $2}' | tr -d ,)
    h=$(echo $total_audio_duration | cut -d: -f1)
    m=$(echo $total_audio_duration | cut -d: -f2)
    s=$(echo $total_audio_duration | cut -d: -f3)
    total_sec=$(echo "$h*3600 + $m*60 + $s" | bc)
    per_img=$(echo "$total_sec / ${#img_list[@]}" | bc -l)

    # 生成视频片段（图片轮播）
    ffmpeg_cmd="ffmpeg -y -loop 1 -framerate 1 -t $per_img -i ${img_list[0]}"
    for j in $(seq 1 $((${#img_list[@]}-1))); do
        ffmpeg_cmd="$ffmpeg_cmd -loop 1 -framerate 1 -t $per_img -i ${img_list[$j]}"
    done

    # 直接用 ffmpeg 拼接图片轮播 + 配音
    ffmpeg -y -framerate 1 -pattern_type glob -i "*.jpg" -i "${audio_list[0]}" \
        -c:v libx264 -r 25 -pix_fmt yuv420p -c:a aac -shortest "$SEG_TEMP"

    cd ../..
    SEGMENTS+=("$SEG_TEMP")
done

# 拼接所有片段
concat_file="$TEMP_DIR/concat_list.txt"
> "$concat_file"
for f in "${SEGMENTS[@]}"; do
    echo "file '$PWD/$f'" >> "$concat_file"
done

ffmpeg -y -f concat -safe 0 -i "$concat_file" -c copy "$OUTPUT_FILE"

echo "✅ All done! Output: $OUTPUT_FILE"
