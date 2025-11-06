#!/bin/bash

# 현재 시간 가져오기
current_time=$(date '+%Y-%m-%d %H:%M:%S')

# 프로젝트명 가져오기 (Git repository 명)
project_name=$(git remote get-url origin 2>/dev/null | sed 's/.*\///' | sed 's/\.git$//' || basename "$(pwd)")

# 현재 Git 브랜치 가져오기
git_branch=$(git branch --show-current 2>/dev/null || echo "No git repository")

# 알림 메시지 구성
message="⚠️  Claude Code - 명령을 수행하기 전에 확인이 필요합니다.

시간: $current_time
프로젝트명: $project_name
git branch: $git_branch"

# macOS 모달 팝업 표시
osascript -e "display dialog \"$message\" with title \"Claude AI - 확인 요청\" buttons {\"확인\"} default button \"확인\" with icon 2"
