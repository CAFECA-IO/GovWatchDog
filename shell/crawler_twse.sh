#!/bin/bash

# 自臺灣證券交易所下載每日收盤行情

record_file=".last_downloaded"
data_folder="twse_data"
mkdir -p "$data_folder"

# 預設起始與結束日期
default_start="20040211"
end_date="20250802"

# 讀取下載記錄決定下載起始點（macOS）
if [ -f "$record_file" ]; then
    last_download=$(cat "$record_file")
    start_date=$(date -j -f "%Y%m%d" "$last_download" -v+1d "+%Y%m%d")
    echo "從上次下載的下一天繼續：$start_date"
else
    start_date=$default_start
    echo "無下載紀錄，從預設日期開始：$start_date"
fi

# 將日期轉成 yyyymmdd → 秒數（macOS）
to_seconds() {
    date -j -f "%Y%m%d" "$1" "+%s"
}

# 初始化時間
start_sec=$(to_seconds "$start_date")
end_sec=$(to_seconds "$end_date")

# 主迴圈
current_sec=$start_sec
while [ "$current_sec" -le "$end_sec" ]; do
    date_str=$(date -j -f "%s" "$current_sec" "+%Y%m%d")
    url="https://www.twse.com.tw/rwd/zh/afterTrading/MI_INDEX?date=${date_str}&type=ALL&response=csv"
    output_file="${data_folder}/${date_str}.csv"

    echo "正在下載 $date_str..."

    curl -s -o "$output_file" "$url"

    if grep -q '[0-9]' "$output_file"; then
        echo "$date_str" > "$record_file"
        echo "下載成功，已更新紀錄為 $date_str"
    else
        echo "略過 $date_str 無資料或非交易日"
        rm -f "$output_file"
    fi

    sleep_time=$((1 + RANDOM % 60))
    echo "等待 $sleep_time 秒..."
    sleep "$sleep_time"

    # 前進一天
    current_sec=$((current_sec + 86400))
done

echo "任務完成"
