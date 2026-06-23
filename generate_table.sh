#!/bin/bash

REPORT_DIR="$HOME/rapports"

# Markdown Table Headers
echo "| Hostname | HAProxy | MariaDB | PHP-FPM | Redis | RabbitMQ |"
echo "|--- |--- |--- |--- |--- |--- |"

# Enable case-insensitive match for file extensions
shopt -s nocaseglob

for logfile in "$REPORT_DIR"/*.TXT; do
    shopt -u nocaseglob # Disable case-insensitive match for downstream execution
    
    if [ -f "$logfile" ]; then
        # 1. Parse Hostname
        hostname=$(grep "PRE-UPGRADE INVENTORY" "$logfile" | awk '{print $5}')
        [ -z "$hostname" ] && hostname=$(basename "$logfile" | sed -E 's/\.[tT][xX][tT]$//')

        # 2. Parse HAProxy
        haproxy=$(grep "HAProxy :" "$logfile" | cut -d':' -f2 | xargs)
        if [ "$haproxy" = "Not installed" ] || [ -z "$haproxy" ]; then haproxy="-"; fi

        # 3. Parse MariaDB
        if grep -q "MariaDB (standalone binary)" "$logfile"; then
            mariadb=$(grep "MariaDB (standalone binary)" "$logfile" | cut -d':' -f2 | xargs)
        else
            mariadb=$(grep "MariaDB :" "$logfile" | cut -d':' -f2 | xargs)
        fi
        { [ -z "$mariadb" ] || [ "$mariadb" = "Not installed" ]; } && mariadb="-"

        # 4. Parse PHP-FPM Engine
        php=$(grep "PHP-FPM :" "$logfile" | awk -F'->' '{print $2}' | xargs | tr ' ' ',')
        [ -z "$php" ] && php="-"

        # 5. Parse Redis
        redis=$(grep "Redis :" "$logfile" | cut -d':' -f2 | xargs)
        if [ "$redis" = "Not installed" ] || [ -z "$redis" ]; then redis="-"; fi

        # 6. Parse RabbitMQ Server
        if grep -q "RabbitMQ Server" "$logfile"; then
            rabbitmq=$(grep "RabbitMQ Server" "$logfile" | cut -d':' -f2 | xargs | sed 's/Version //g')
        else
            rabbitmq="-"
        fi
        if [ "$rabbitmq" = "Not installed" ] || [ -z "$rabbitmq" ]; then rabbitmq="-"; fi

        # Output parsed line
        echo "| $hostname | $haproxy | $mariadb | $php | $redis | $rabbitmq |"
    fi
done
