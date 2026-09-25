#!/bin/bash

printf "%-10s %-10s %-10s %s\n" "PID" "PPID" "STATUS" "COMMAND"

for pid_dir in /proc/[0-9]*/; do
    
    pid=$(basename "$pid_dir")
    
    if [ -f "${pid_dir}stat" ]; then

        stat_line=$(cat "${pid_dir}stat")

        stat_after_name="${stat_line##*)}"
        stat_fields=( $stat_after_name )

        status="${stat_fields[0]}"
        ppid="${stat_fields[1]}"

        command=""
        
            if [ -f "${pid_dir}cmdline" ]; then
                command=$(xargs -0 < "${pid_dir}cmdline" 2>/dev/null)
            fi
        
            if [ -z "$command" ]; then
                command="[$(cat "${pid_dir}comm" 2>/dev/null)]"
            fi

        printf "%-10s %-10s %-10s %s\n" "$pid" "$ppid" "$status" "$command"
    fi
done
