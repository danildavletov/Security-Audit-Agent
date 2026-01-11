#!/bin/bash
# Security Checkup Script for Linux Servers
# Usage: ssh server "bash -s" < security_checkup.sh

set -e

echo "=== SYSTEM INFO ==="
echo "Hostname: $(hostname)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo ""

echo "=== SSH CONFIGURATION ==="
grep -E '^(Port|PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|PermitEmptyPasswords|X11Forwarding|AllowUsers|AllowGroups|MaxAuthTries|LoginGraceTime|ChallengeResponseAuthentication|UsePAM)' /etc/ssh/sshd_config 2>/dev/null || echo "Cannot read sshd_config"
echo ""

echo "=== SSH CONFIG DUPLICATES ==="
for param in PermitRootLogin PasswordAuthentication PubkeyAuthentication PermitEmptyPasswords X11Forwarding; do
    count=$(grep -c "^$param" /etc/ssh/sshd_config 2>/dev/null || echo 0)
    if [ "$count" -gt 1 ]; then
        echo "DUPLICATE: $param appears $count times:"
        grep -n "^$param" /etc/ssh/sshd_config
    fi
done
echo ""

echo "=== OPEN PORTS ==="
ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null || echo "Cannot check ports"
echo ""

echo "=== FIREWALL STATUS ==="
if command -v ufw &>/dev/null; then
    echo "UFW:"
    ufw status verbose 2>/dev/null || echo "Cannot check UFW"
elif command -v firewall-cmd &>/dev/null; then
    echo "Firewalld:"
    firewall-cmd --list-all 2>/dev/null || echo "Cannot check firewalld"
else
    echo "iptables INPUT policy:"
    iptables -L INPUT -n --line-numbers 2>/dev/null | head -20 || echo "Cannot check iptables"
fi
echo ""

echo "=== FAIL2BAN STATUS ==="
if command -v fail2ban-client &>/dev/null; then
    fail2ban-client status 2>/dev/null || echo "fail2ban not running"
    for jail in $(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | tr ',' ' '); do
        echo "--- Jail: $jail ---"
        fail2ban-client status "$jail" 2>/dev/null
    done
else
    echo "fail2ban not installed"
fi
echo ""

echo "=== USERS WITH LOGIN SHELL ==="
grep -E '/bin/(bash|sh|zsh|fish)$' /etc/passwd
echo ""

echo "=== SUDO CONFIGURATION ==="
echo "sudo group members:"
getent group sudo 2>/dev/null || getent group wheel 2>/dev/null || echo "No sudo/wheel group"
echo ""
echo "sudoers.d files:"
ls -la /etc/sudoers.d/ 2>/dev/null || echo "No sudoers.d"
cat /etc/sudoers.d/* 2>/dev/null | grep -v '^#' | grep -v '^$' || true
echo ""

echo "=== ROOT SSH KEYS ==="
if [ -f /root/.ssh/authorized_keys ]; then
    echo "Keys count: $(wc -l < /root/.ssh/authorized_keys)"
    cat /root/.ssh/authorized_keys
else
    echo "No authorized_keys for root"
fi
echo ""

echo "=== PENDING SECURITY UPDATES ==="
if command -v apt &>/dev/null; then
    apt list --upgradable 2>/dev/null | grep -i secur || apt list --upgradable 2>/dev/null | head -10
elif command -v yum &>/dev/null; then
    yum check-update --security 2>/dev/null | head -20 || true
fi
echo ""

echo "=== AUTOMATIC UPDATES ==="
if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
    cat /etc/apt/apt.conf.d/20auto-upgrades
elif dpkg -l | grep -q unattended-upgrades; then
    echo "unattended-upgrades installed"
else
    echo "No automatic updates configured"
fi
echo ""

echo "=== LISTENING SERVICES ==="
ss -tlnp 2>/dev/null | awk 'NR>1 {print $4, $6}' | sort -u
echo ""

echo "=== WORLD-WRITABLE FILES IN /etc ==="
find /etc -type f -perm -002 2>/dev/null | head -10 || echo "None found"
echo ""

echo "=== SUID/SGID BINARIES (non-standard) ==="
find /usr/local -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null || echo "None in /usr/local"
echo ""

echo "=== DOCKER CONTAINERS ==="
if command -v docker &>/dev/null; then
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Cannot access docker"
else
    echo "Docker not installed"
fi
echo ""

echo "=== RECENT AUTH FAILURES ==="
if [ -f /var/log/auth.log ]; then
    grep -i "failed\|invalid\|error" /var/log/auth.log 2>/dev/null | tail -10
elif command -v journalctl &>/dev/null; then
    journalctl -u ssh --no-pager -n 50 2>/dev/null | grep -i "failed\|invalid" | tail -10
fi
echo ""

echo "=== END OF SECURITY CHECKUP ==="
