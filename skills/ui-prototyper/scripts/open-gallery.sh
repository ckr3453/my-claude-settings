#!/bin/bash
# 특정 feature의 gallery.html 브라우저에서 열기
set -e

FEATURE="${1}"
PORT="${PORT:-8765}"

if [ -z "$FEATURE" ]; then
  echo "Usage: $0 <feature-name>"
  exit 1
fi

URL="http://localhost:$PORT/$FEATURE/gallery.html"

# OS별 브라우저 열기
if [[ "$OSTYPE" == "darwin"* ]]; then
  open "$URL"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  xdg-open "$URL"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
  start "$URL"
else
  echo "브라우저 자동 오픈 실패. 수동으로 접속하세요: $URL"
fi
