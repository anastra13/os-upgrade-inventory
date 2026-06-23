# os-upgrade-inventory
> Automated pre‑flight check and system inventory tool for Linux OS upgrades

`os-upgrade-inventory` is a lightweight automation toolkit designed to audit a fleet of Linux servers **before performing a major OS upgrade** (for example: Debian 11 → Debian 12).  
It maps active services, runtimes, virtual hosts, message brokers, and security agents to help identify upgrade risks and prevent post‑migration regressions.

---

## ✨ Features

- **SSH-based automated inventory** across multiple remote servers  
- **Comprehensive scan**, including:
  - Active services and systemd units
  - Installed runtimes (PHP, Python, Java, etc.)
  - Web server virtual hosts (Apache / Nginx)
  - Message brokers and queues (Redis, RabbitMQ, etc.)
  - Security daemons and agents (Fail2ban, AV, EDR)
- **Per-server plain-text reports** generated automatically
- **Minimal dependencies** — Bash + SSH only
- **Designed for pre-upgrade risk assessment**

---

## 🛠️ Requirements

### Master machine
- `bash`
- Network reachability to target servers
- SSH access with public key authentication

### Target machines
- Public SSH key installed for the `root` user (or equivalent privileged account)
- Linux distribution supported (Debian, Ubuntu, Rocky, Alma, etc.)

---


---

## 🚀 Quick start

### 1. Populate the server list

Edit `serveurs_client.txt` and add one server per line:

```text
server1.example.com
server2.example.com
192.168.10.25


chmod +x run_inventory.sh check_versions.sh

./run_inventory.sh



