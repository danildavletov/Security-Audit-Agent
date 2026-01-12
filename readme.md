# Security Audit for Linux Servers

Automated security audit for Linux servers via SSH + Claude AI.

## Files

```
security_checkup.sh   — Data collection script (runs on remote server)
security_audit.ps1    — Windows PowerShell launcher
security_audit.bat    — Windows CMD wrapper
security_audit.sh     — Linux/macOS launcher
prompt.md             — Full prompt reference
output.md             — Generated report
```

## Usage

### Windows (CMD or PowerShell)

```cmd
.\security_audit.bat servername
```

Or directly:

```powershell
.\security_audit.ps1 servername
```

You will be prompted for the sudo password securely.

### Linux/macOS

```bash
./security_audit.sh servername
```

You will be prompted for sudo password via SSH TTY.

## What It Does

1. Copies `security_checkup.sh` to the target server
2. Runs it with sudo to collect security data
3. Sends output to Claude for analysis
4. Generates a report with findings and fix commands
5. Saves report to `output.md`

## Data Collected

- SSH configuration (hardening settings, duplicates)
- Firewall status (UFW/firewalld/iptables)
- Fail2ban status and banned IPs
- Users with login shells
- Sudo configuration
- Open ports and listening services
- Pending security updates
- World-writable files in /etc
- SUID/SGID binaries
- Docker containers
- Recent auth failures

## Requirements

- SSH access to target server
- `claude` CLI installed and in PATH
- Target server: sudo access for the SSH user

## Example Output

```
### Server Security Report: servername
**Date:** 2026-01-12

#### Summary
| Category | Status |
|----------|--------|
| SSH Hardening | CRITICAL |
| Firewall | GOOD |
| Fail2ban | GOOD |
| User Management | GOOD |
| Updates | WARN |

#### Issues Found

**CRITICAL: Password Authentication Enabled**
- Problem: PasswordAuthentication set to yes
- Risk: Brute force attacks possible
- Fix:
```bash
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
```

#### Positive Findings
- UFW firewall active with default deny
- fail2ban protecting sshd
- Public key authentication enabled
```

## Customization

Add checks to `security_checkup.sh`:

```bash
echo "=== MY CUSTOM CHECK ==="
# your commands here
echo ""
```

## Integration

```python
import subprocess

def security_audit(host: str) -> str:
    result = subprocess.run(
        ["powershell", "-File", "security_audit.ps1", host],
        capture_output=True,
        text=True,
        input="your_sudo_password"  # or prompt user
    )
    return result.stdout
```
