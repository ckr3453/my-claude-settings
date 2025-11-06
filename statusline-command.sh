#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r ".workspace.current_dir")
project_dir=$(echo "$input" | jq -r ".workspace.project_dir")
model_name=$(echo "$input" | jq -r ".model.display_name")
model_id=$(echo "$input" | jq -r ".model.id")
version=$(echo "$input" | jq -r ".version")
output_style=$(echo "$input" | jq -r ".output_style.name // \"default\"")

# Get project name from project directory
project_name=$(basename "$project_dir")
absolute_dir="$cwd"

# Get git branch
branch=""
if [ -d "$project_dir/.git" ]; then
    branch=$(cd "$project_dir" && git --no-optional-locks branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
        branch=$(cd "$project_dir" && git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    fi
fi
branch="${branch:-no-branch}"

# Get current time in yyyy-mm-dd HH:MM:SS format
current_time=$(date +"%Y-%m-%d %H:%M:%S")

# Get token usage with ccusage
token_usage=""
usage_percent=""
usage_percent_color=""
reset_time=""
if command -v ccusage &> /dev/null; then
    usage_output=$(ccusage --today 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$usage_output" ]; then
        # Debug: Save output for troubleshooting
        # echo "$usage_output" > /tmp/ccusage-debug.txt

        # Extract Total row from ccusage output
        total_row=$(echo "$usage_output" | grep "│ Total")

        if [ -n "$total_row" ]; then
            # Clean ANSI color codes first
            total_clean=$(echo "$total_row" | sed 's/\x1b\[[0-9;]*m//g')

            # Try multiple parsing strategies
            # Strategy 1: Parse as pipe-delimited table (most ccusage versions)
            current_usage=$(echo "$total_clean" | awk -F '│' '{print $7}' | tr -d ' ,' | grep -oE '[0-9]+')

            # Strategy 2: If strategy 1 fails, try finding "Total Tokens:" label
            if [ -z "$current_usage" ]; then
                current_usage=$(echo "$usage_output" | grep -i "total tokens" | grep -oE '[0-9,]+' | tr -d ',' | head -n1)
            fi

            # Strategy 3: If still empty, try JSON output
            if [ -z "$current_usage" ]; then
                json_output=$(ccusage --today --json 2>/dev/null)
                if [ $? -eq 0 ] && [ -n "$json_output" ]; then
                    current_usage=$(echo "$json_output" | jq -r '.total.total_tokens // empty' 2>/dev/null)
                fi
            fi

            # Get max limit - Claude Pro has 200k tokens limit
            max_limit=200000

            if [ -n "$current_usage" ] && [ "$current_usage" -gt 0 ]; then
                # Calculate percentage
                usage_percent=$(echo "scale=0; ($current_usage * 100) / $max_limit" | bc)
                if [ "$usage_percent" -gt 100 ]; then
                    usage_percent=100
                fi

                # Determine color based on percentage
                if [ "$usage_percent" -lt 70 ]; then
                    usage_percent_color="\033[32m"  # Green
                elif [ "$usage_percent" -lt 85 ]; then
                    usage_percent_color="\033[33m"  # Yellow
                else
                    usage_percent_color="\033[31m"  # Red
                fi

                # Format current usage in k/M
                if [ "$current_usage" -ge 1000000 ]; then
                    usage_formatted=$(echo "scale=1; $current_usage / 1000000" | bc)M
                elif [ "$current_usage" -ge 1000 ]; then
                    usage_formatted=$(echo "scale=0; $current_usage / 1000" | bc)k
                else
                    usage_formatted="$current_usage"
                fi

                # Format max limit (200k)
                limit_formatted="200k"

                token_usage="$usage_formatted / $limit_formatted"

                # Calculate reset time - next day at midnight UTC
                # Get current UTC time and calculate hours/minutes until next midnight
                current_utc_hour=$(date -u +"%H")
                current_utc_minute=$(date -u +"%M")
                hours_until_reset=$((23 - current_utc_hour))
                minutes_until_reset=$((60 - current_utc_minute))

                if [ "$minutes_until_reset" -eq 60 ]; then
                    minutes_until_reset=0
                    hours_until_reset=$((hours_until_reset + 1))
                fi

                reset_time=$(printf "%dh %dm" "$hours_until_reset" "$minutes_until_reset")
            else
                token_usage="0k / 200k"
                usage_percent="0"
                usage_percent_color="\033[32m"  # Green

                # Calculate reset time
                current_utc_hour=$(date -u +"%H")
                current_utc_minute=$(date -u +"%M")
                hours_until_reset=$((23 - current_utc_hour))
                minutes_until_reset=$((60 - current_utc_minute))

                if [ "$minutes_until_reset" -eq 60 ]; then
                    minutes_until_reset=0
                    hours_until_reset=$((hours_until_reset + 1))
                fi

                reset_time=$(printf "%dh %dm" "$hours_until_reset" "$minutes_until_reset")
            fi
        else
            token_usage="N/A"
            usage_percent="N/A"
            usage_percent_color="\033[37m"
            reset_time="N/A"
        fi
    else
        token_usage="N/A"
        usage_percent="N/A"
        usage_percent_color="\033[37m"
        reset_time="N/A"
    fi
else
    token_usage="not installed"
    usage_percent="N/A"
    usage_percent_color="\033[37m"
    reset_time="N/A"
fi

# ANSI color codes
CYAN="\033[36m"
MAGENTA="\033[35m"
GREEN="\033[32m"
BLUE="\033[34m"
PURPLE="\033[95m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# Determine output style emoji
output_style_emoji="📋"
case "$output_style" in
    "json"|"JSON")
        output_style_emoji="🔧"
        ;;
    "markdown"|"Markdown")
        output_style_emoji="📝"
        ;;
    "code"|"Code")
        output_style_emoji="💻"
        ;;
    "learning"|"Learning")
        output_style_emoji="🎓"
        ;;
    "explanatory"|"Explanatory")
        output_style_emoji="💡"
        ;;
    "default"|"Default")
        output_style_emoji="📋"
        ;;
    *)
        output_style_emoji="📄"
        ;;
esac

# Print 3-line status
printf "${CYAN}📁 %s${RESET}  ${MAGENTA}📦 %s${RESET}  ${GREEN}🌿 %s${RESET}\n" \
    "$absolute_dir" "$project_name" "$branch"

printf "${BLUE}🤖 %s${RESET}  ${PURPLE}%s %s${RESET}  ${PURPLE}🔌 %s${RESET} ${usage_percent_color}(%s%%)${RESET}  ${PURPLE}🔄 %s${RESET}\n" \
    "$model_id" "$output_style_emoji" "$output_style" "$token_usage" "$usage_percent" "$reset_time"

printf "${YELLOW}⏰ %s${RESET}  ${RED}📌 v%s${RESET}" \
    " $current_time" "$version"
