#!/usr/bin/env bash
# Claude Code status line script

input=$(cat)

# Model ID
model=$(echo "$input" | jq -r '.model.id // "unknown"')

# Project directory and git branch
# workspace.project_dir is the session root; fall back to current_dir/cwd.
proj_dir=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // empty')
project=""
branch=""
if [ -n "$proj_dir" ]; then
  project=$(basename "$proj_dir")
  # --abbrev-ref gives "HEAD" on a detached checkout; show the short SHA instead.
  branch=$(git -C "$proj_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ "$branch" = "HEAD" ]; then
    branch=$(git -C "$proj_dir" rev-parse --short HEAD 2>/dev/null)
  fi
fi

# Context window: used tokens (input + output from current_usage) vs total size
# Format as e.g. "12k/200k"
# NB: current_usage.input_tokens is only the *uncached* delta for the last request
# (often single digits). The whole prompt also lives in cache_creation/cache_read.
# total_input_tokens is the rollup of all three, so use that.
ctx_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
ctx_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

ctx_used=$(( ctx_input + ctx_output ))

format_k() {
  local n=$1
  if [ "$n" -ge 1000 ]; then
    printf "%dk" $(( n / 1000 ))
  else
    printf "%d" "$n"
  fi
}

ctx_used_fmt=$(format_k "$ctx_used")
ctx_size_fmt=$(format_k "$ctx_size")
if [ "$ctx_used" -ge 100000 ]; then
  ctx_str="🚨 ${ctx_used_fmt}/${ctx_size_fmt}"
else
  ctx_str="${ctx_used_fmt}/${ctx_size_fmt}"
fi

# Rate limits with reset times
format_reset() {
  local ts=$1
  if [ -z "$ts" ] || [ "$ts" = "null" ]; then
    echo ""
    return
  fi
  local now
  now=$(date +%s)
  local diff=$(( ts - now ))
  if [ "$diff" -le 0 ]; then
    echo "(now)"
  elif [ "$diff" -lt 3600 ]; then
    printf "(%dm)" $(( diff / 60 ))
  else
    printf "(%dh%dm)" $(( diff / 3600 )) $(( (diff % 3600) / 60 ))
  fi
}

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Session cost
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

parts=()
if [ -n "$project" ]; then
  if [ -n "$branch" ]; then
    parts+=("$project ⎇ $branch")
  else
    parts+=("$project")
  fi
fi
parts+=("$model")
parts+=("$ctx_str")

if [ -n "$cost_usd" ]; then
  cost_str=$(printf '$%.2f' "$cost_usd")
  parts+=("$cost_str")
fi

if [ -n "$five_pct" ] || [ -n "$seven_pct" ]; then
  rate_str=""
  if [ -n "$five_pct" ]; then
    five_reset_fmt=$(format_reset "$five_reset")
    rate_str="5h:$(printf '%.0f' "$five_pct")% ${five_reset_fmt}"
  fi
  if [ -n "$seven_pct" ]; then
    seven_reset_fmt=$(format_reset "$seven_reset")
    [ -n "$rate_str" ] && rate_str="$rate_str | "
    rate_str="${rate_str}7d:$(printf '%.0f' "$seven_pct")% ${seven_reset_fmt}"
  fi
  parts+=("$rate_str")
fi

# Join parts with " | "
output=""
for part in "${parts[@]}"; do
  if [ -n "$output" ]; then
    output="$output | $part"
  else
    output="$part"
  fi
done

echo "$output"
