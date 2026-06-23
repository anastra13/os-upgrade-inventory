#!/bin/bash

echo "=================================================="
echo " PRE-UPGRADE INVENTORY - $(hostname) - $(date +'%Y-%m-%d')"
echo "=================================================="

check_version() {
    local app_name=$1
    local cmd=$2
    if command -v "$cmd" &> /dev/null; then
        echo -n -e "[✓] $app_name : "
        eval "$3"
    else
        echo "[ ] $app_name : Not installed"
    fi
}

echo "--- 1. WEB, PROXY & VHOSTS ---"
check_version "Nginx" "nginx" "nginx -v 2>&1 | cut -d'/' -f2"
# Extract active Nginx vhosts (handling servers configured without an explicit server_name)
if command -v nginx &> /dev/null; then
    echo "    --- Active Nginx Vhosts ---"
    nginx -T 2>/dev/null | grep -E "server_name |listen " | grep -v "#" | awk '
        /listen/ {
            port=$0; 
            gsub(/^[ \t]+|;/, "", port); 
            gsub(/listen /, "", port); 
            current_port=port;
        }
        /server_name/ {
            name=$0; 
            gsub(/^[ \t]+|;/, "", name); 
            gsub(/server_name /, "", name); 
            print "    - " name " (listen " current_port ")"; 
            current_port="";
        }
        /listen/ {
            if (current_port != "") {
                print "    - [default_server] (listen " current_port ")";
            }
        }
    ' | sort -u
fi

echo ""
check_version "Apache" "apache2" "apache2 -v | grep 'Server version' | cut -d'/' -f2"
# Extract active Apache vhosts via apachectl
if command -v apachectl &> /dev/null; then
    echo "    --- Active Apache Vhosts ---"
    apachectl -S 2>/dev/null | grep -E "(\.conf:[0-9]+|^[[:space:]]*port)" | awk '{
        gsub(/^\s+/, ""); 
        print "    - " $1 " " $2
    }'
fi

echo ""
check_version "ProxySQL" "proxysql" "proxysql --version | awk '{print \$3}'"

# HAProxy Block
check_version "HAProxy" "haproxy" "haproxy -v | head -n1 | awk '{print \$3}'"
if command -v haproxy &> /dev/null; then
    # Process runtime validation
    if pgrep -x "haproxy" &>/dev/null; then echo "    - Status: Active (Running)"; else echo "    - Status: Stopped"; fi

    # Configuration syntax validation before upgrade
    if [ -f "/etc/haproxy/haproxy.cfg" ]; then
        if haproxy -c -f /etc/haproxy/haproxy.cfg &>/dev/null; then
            echo "    - Configuration (/etc/haproxy/haproxy.cfg): Valid [✓]"
        else
            echo "    - Configuration (/etc/haproxy/haproxy.cfg): ERROR / INVALID [⚠️]"
        fi
    fi
fi

echo ""
check_version "Mercure" "mercure" "mercure top --version 2>/dev/null || mercure version 2>/dev/null || echo 'Active'"

echo -e "\n--- 2. DATABASES, QUEUES & CACHE ---"
check_version "MariaDB" "mariadb" "mariadb -V | awk '{print \$5}' | cut -d',' -f1"
if [ ! -x "$(command -v mariadb)" ] && pgrep mariadbd &>/dev/null; then
    echo "[✓] MariaDB (standalone binary): $(mariadbd -V 2>&1 | awk '{print $3}')"
fi
if [ ! -x "$(command -v mysqld)" ] && pgrep mysqld &>/dev/null; then
    echo "[✓] MySQL Server (standalone binary): $(mysqld -V 2>&1 | awk '{print $3}')"
fi

# PostgreSQL Block
if command -v pg_lsclusters &> /dev/null; then
    echo "[✓] PostgreSQL (Active Clusters):"
    pg_lsclusters --no-header | awk '{print "    - Version " $1 " (Cluster: " $2 ", Port: " $3 ", Status: " $4 ")"}'
elif command -v psql &> /dev/null; then
    echo "[✓] PostgreSQL (Client Only): $(psql --version | awk '$3')"
fi

check_version "Redis" "redis-server" "redis-server -v | awk '{print \$3}' | cut -d'=' -f2"

# RabbitMQ Server Block
if dpkg -l | grep -q "^ii.*rabbitmq-server"; then
    echo "[✓] RabbitMQ Server: $(dpkg -l rabbitmq-server | grep "^ii" | awk '{print $3}')"
else
    echo "[ ] RabbitMQ Server: Not installed"
fi

# Mosquitto MQTT Block
check_version "Mosquitto MQTT" "mosquitto" "mosquitto -h | head -n1 | awk '{print \$3}'"
if [ ! -x "$(command -v mosquitto)" ] && pgrep -x mosquitto &>/dev/null; then
    echo "[✓] Mosquitto MQTT: Active (Process detected outside standard PATH)"
fi

echo -e "\n--- 3. HIGH AVAILABILITY, BACKUP & SYSTEM ---"
# Keepalived Block
if dpkg -l | grep -q "^ii.*keepalived"; then
    kp_ver=$(dpkg -l keepalived | grep "^ii" | awk '{print $3}')
    echo -n "[✓] Keepalived: Version $kp_ver"
    if pgrep keepalived &>/dev/null; then echo " (Active)"; else echo " (Stopped)"; fi
else
    echo "[ ] Keepalived: Not installed"
fi

# Veeam Agent Block
if dpkg -l | grep -q "^ii.*veeam"; then
    ve_ver=$(dpkg -l veeam | grep "^ii" | awk '{print $3}')
    echo -n "[✓] Veeam Agent for Linux: Version $ve_ver"
    if pgrep veeamservice &>/dev/null; then echo " (Service Active)"; else echo " (Service Stopped)"; fi
else
    echo "[ ] Veeam Agent for Linux: Not installed"
fi

check_version "Fail2Ban" "fail2ban-server" "fail2ban-client version"
check_version "Supervisor" "supervisorctl" "supervisorctl version 2>/dev/null || echo 'Installed'"

echo -e "\n--- 4. RUNTIMES & ATLASSIAN APPLICATIONS ---"
if ls /usr/sbin/php-fpm* &> /dev/null; then
    for fpm in /usr/sbin/php-fpm*; do
        echo -n "[✓] PHP-FPM: $(basename $fpm) -> "
        $fpm -v | head -n 1 | awk '{print $2}'
    done
fi
check_version "Java Global" "java" "java -version 2>&1 | head -n 1 | cut -d'\"' -f2"

# Confluence & Jira Application Path Engine
if [ -d "/opt/atlassian/confluence" ]; then
    conf_properties="/opt/atlassian/confluence/confluence/WEB-INF/classes/com/atlassian/confluence/util/build.properties"
    echo -n "[✓] Confluence Application: "
    if [ -f "$conf_properties" ]; then
        echo "Version $(grep "build.version" "$conf_properties" | cut -d'=' -f2 | tr -d '\r' | tr -d ' ')"
    else echo "Detected (Custom Path Layout)"
    fi
fi
if [ -d "/opt/atlassian/jira" ]; then
    jira_properties="/opt/atlassian/jira/atlassian-jira/WEB-INF/classes/jira-application.properties"
    echo -n "[✓] Jira Application: "
    if [ -f "$jira_properties" ]; then
        echo "Version $(grep "jira.version" "$jira_properties" | cut -d'=' -f2 | tr -d '\r' | tr -d ' ')"
    else echo "Detected (Custom Path Layout)"
    fi
fi

echo -e "\n--- 5. SECURITY & AGENTS ---"
if dpkg -l | grep -q "^ii.*falcon-sensor"; then
    echo "[✓] CrowdStrike Falcon: Version $(dpkg -l falcon-sensor | grep "^ii" | awk '{print $3}')"
fi
if [ -x "/opt/ds_agent/ds_agent" ] || [ -x "/opt/ds_agent/ds_am" ]; then
    echo "[✓] Trend Micro Deep Security Agent: Installed"
else
    echo "[ ] Trend Micro Deep Security Agent: Not installed"
fi

echo -e "\n--- 6. DOCKER & CONTAINERS ---"
if command -v docker &> /dev/null; then
    echo "[✓] Docker Engine: $(docker --version | awk '{print $3}' | tr -d ',')"
    echo "    --- Running Containers ---"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | sed 's/^/    /'
fi

echo "=================================================="
