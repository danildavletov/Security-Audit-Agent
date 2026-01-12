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

TEMP_OUTPUT=$(mktemp)
trap "rm -f $TEMP_OUTPUT" EXIT

echo "Collecting security data from $HOST..." >&2
scp -q "$SCRIPT_DIR/security_checkup.sh" "$HOST":/tmp/security_checkup.sh

# Run with TTY, save output on remote, then fetch
ssh -t "$HOST" "sudo bash /tmp/security_checkup.sh > /tmp/audit_output.txt 2>&1; rm /tmp/security_checkup.sh"
scp -q "$HOST":/tmp/audit_output.txt "$TEMP_OUTPUT"
ssh "$HOST" "rm /tmp/audit_output.txt" 2>/dev/null

OUTPUT=$(cat "$TEMP_OUTPUT" | tr -d '\r')

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

Generate the security report." --print | tee "$SCRIPT_DIR/output.md"
