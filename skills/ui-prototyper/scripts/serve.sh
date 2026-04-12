#!/bin/bash
# .prototypes 폴더에서 로컬 서버 실행
set -e

PORT=${PORT:-8765}
PROTOTYPES_DIR="${1:-.prototypes}"

if [ ! -d "$PROTOTYPES_DIR" ]; then
  echo "Error: $PROTOTYPES_DIR 폴더가 없습니다."
  exit 1
fi

# 기존 서버 종료
if [ -f "$PROTOTYPES_DIR/.server.pid" ]; then
  OLD_PID=$(cat "$PROTOTYPES_DIR/.server.pid")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "기존 서버 종료 중... (PID: $OLD_PID)"
    kill "$OLD_PID"
    sleep 1
  fi
  rm -f "$PROTOTYPES_DIR/.server.pid"
fi

# 새 서버 시작
cd "$PROTOTYPES_DIR"
python3 -m http.server "$PORT" &
SERVER_PID=$!
echo $SERVER_PID > .server.pid
cd - > /dev/null

sleep 1

if kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "서버 시작됨"
  echo "  PID: $SERVER_PID"
  echo "  URL: http://localhost:$PORT/"
  echo ""
  echo "종료: kill $SERVER_PID  (또는 kill \$(cat $PROTOTYPES_DIR/.server.pid))"
else
  echo "Error: 서버 시작 실패"
  exit 1
fi
