#!/bin/bash

LOG_FILE="/home/user/logs/access.log"
EMAIL="your_email@example.com"

check_file() {
    if [ ! -f "$LOG_FILE" ]; then
        echo "Лог-файл не найден!" | mail -s "Возникла проблема!" "$EMAIL"
        exit 1
    fi
}

set_time() {
    TARGET_DATE=$(LC_ALL=C date -d "1 hour ago" +"%d/%b/%Y:%H")
    TIME_START=$(LC_ALL=C date -d "1 hour ago" +"%d.%m.%Y %H:00:00")
    TIME_END=$(LC_ALL=C date -d "1 hour ago" +"%d.%m.%Y %H:59:59")
}

generate_report() {
    echo "Отчет о работе веб-сервера"
    echo "Период обработки: $TIME_START - $TIME_END"
    echo ""
    echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
    echo ""

    echo "1. Топ-10 IP-адресов по количеству запросов:"
    echo ""
    awk '{print $1}' "$TMP_LOG" | sort | uniq -c | sort -rn | head -n 10
    echo ""

    echo "2. Топ-10 запрашиваемых URL:"
    echo ""
    awk -F'"' '{print $2}' "$TMP_LOG" | awk '{print $2}' | sort | uniq -c | sort -rn | head -n 10
    echo ""

    echo "3. HTTP-коды ответов сервера:"
    echo ""
    awk -F'"' '{print $3}' "$TMP_LOG" | awk '{print $1}' | sort | uniq -c | sort -rn
    echo ""

    echo "4. Ошибки веб-сервера (HTTP 4xx и 5xx):"
    echo ""
    awk -F'"' '{ 
        split($3, status, " "); 
        if (status[1] ~ /^[45]/) { 
            print "Код: " status[1] " | IP: " $1 " | URL: " $2 
        } 
    }' "$TMP_LOG" | sort | uniq -c | sort -rn | head -n 20
} 

check_file
set_time

TMP_LOG=$(mktemp)
REPORT_FILE=$(mktemp)
trap 'rm -f "$TMP_LOG" "$REPORT_FILE"' EXIT

grep -F "[$TARGET_DATE:" "$LOG_FILE" > "$TMP_LOG"

if [ ! -s "$TMP_LOG" ]; then
    (
    echo "Отчет о работе веб-сервера"
    echo "Период: $TIME_START — $TIME_END"
    echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
    echo "За указанный период запросов не обнаружено."
    ) | mail -s "Веб-сервер: Отчет за $TIME_START" "$EMAIL"
    exit 0
fi

generate_report > "$REPORT_FILE"

mail -s "Веб-сервер: Отчет за $TIME_START" "$EMAIL" < "$REPORT_FILE"
