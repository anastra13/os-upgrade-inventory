# os-upgrade-inventory

> **Automated pre-flight check and system inventory tool for Linux OS upgrades.**

This repository provides a lightweight automation toolset designed to audit a fleet of remote Linux servers via SSH before undertaking a major operating system upgrade (such as upgrading from Debian 11 Bullseye to Debian 12 Bookworm). It maps active services, virtual hosts, runtimes, messaging queues, and security daemons to prevent post-migration breaking changes.

## 🛠️ Prerequisites

- Master Machine: Needs `bash` and SSH access to targets.
- Target Machines: Public SSH key deployed for `root` user access.

## 🚀 Usage

1. Populate `serveurs_client.txt` with your target server IPs or FQDNs (one per line).
2. Make both scripts executable:
   ```bash
   chmod +x check_versions.sh run_inventory.sh
