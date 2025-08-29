#!/bin/bash
set -e  # 脚本遇到错误立即退出

# 默认值：根目录 test.mp4 → 根目录 output.mp4
INPUT_FILE=${1:-test.mp4}
OUTPUT_FILE=${2:-output.mp4}

# 确保输入文件存在
if [ ! -f "$INPUT_FILE" ]; then
  echo "❌ Input file $INPUT_FILE does not exist"
  exit 1
fi

# 确保输出目录存在
mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "🚀 Processing $INPUT_FILE -> $OUTPUT_FILE ..."
ffmpeg -i "$INPUT_FILE" -vf "scale=1280:720" -c:v libx264 -crf 23 -preset fast "$OUTPUT_FILE"

echo "✅ Done! Output saved to $OUTPUT_FILE"
