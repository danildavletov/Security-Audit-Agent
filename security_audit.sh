#!/bin/bash
# Security Audit via Claude
# Usage: ./security_audit.sh <ssh_host>

set -e

HOST="$1"
if [ -z "$HOST" ]; then
    echo "Usage: $0 <ssh_host>"
    echo "Example: $0 servername"
    echo "         $0 user@192.168.1.1"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Collecting security data from $HOST..." >&2
OUTPUT=$(ssh "$HOST" "bash -s" < "$SCRIPT_DIR/security_checkup.sh" 2>&1)

echo "Analyzing with Claude..." >&2
claude -p "You are a Linux security auditor. Analyze server output and generate report.

## Report Format

### Server Security Report: {hostname}
**Date:** $(date +%Y-%m-%d)

#### Summary
| Category | Status |
|----------|--------|
| SSH Hardening | GOOD/WARN/CRITICAL |
| Firewall | GOOD/WARN/CRITICAL |
| Fail2ban | GOOD/WARN/CRITICAL |
| User Management | GOOD/WARN/CRITICAL |
| Updates | GOOD/WARN/CRITICAL |

#### Issues Found
For each issue:
**{CRITICAL/HIGH/MEDIUM/LOW}: {Title}**
- Problem: {description}
- Risk: {what could happen}
- Fix:
\`\`\`bash
{exact commands}
\`\`\`

#### Positive Findings
List what is properly configured.

## Rules
- PasswordAuthentication yes → CRITICAL
- PermitRootLogin yes → MEDIUM
- Duplicate SSH params → HIGH (last wins)
- No firewall → CRITICAL
- No fail2ban → HIGH
- Pending security updates → HIGH

--- SERVER: $HOST ---
$OUTPUT
--- END ---

Generate the security report." --print
