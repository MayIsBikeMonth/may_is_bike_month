#!/bin/sh
set -eu

sh backup.sh

# On the 1st of each month, copy the latest backup to monthly/ (retained for 1 year)
if [ "$(date +%d)" = "01" ]; then
  . ./env.sh
  LATEST=$(aws $aws_args s3 ls "s3://$S3_BUCKET/$S3_PREFIX/" | sort | tail -n 1 | awk '{print $NF}')
  if [ -n "$LATEST" ]; then
    aws $aws_args s3 cp "s3://$S3_BUCKET/$S3_PREFIX/$LATEST" "s3://$S3_BUCKET/monthly/$LATEST"
  fi
  # Remove monthly backups older than 365 days
  CUTOFF=$(date -d "@$(($(date +%s) - 31536000))" +%Y-%m-%d)
  aws $aws_args s3 ls "s3://$S3_BUCKET/monthly/" | while IFS= read -r line; do
    FILE_DATE=$(echo "$line" | awk '{print $1}')
    FILE_NAME=$(echo "$line" | awk '{print $NF}')
    if [ -n "$FILE_NAME" ] && [ "$FILE_DATE" \< "$CUTOFF" ]; then
      aws $aws_args s3 rm "s3://$S3_BUCKET/monthly/$FILE_NAME"
    fi
  done
fi

if [ -n "${HONEYBADGER_CHECKIN_URL:-}" ]; then
  wget -qO- "$HONEYBADGER_CHECKIN_URL" > /dev/null 2>&1
fi
