# Security Audit via Claude (Windows PowerShell)
# Usage: .\security_audit.ps1 <ssh_host>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$TargetHost
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CheckupScript = Join-Path $ScriptDir "security_checkup.sh"
$Date = Get-Date -Format "yyyy-MM-dd"

Write-Host "Collecting security data from $TargetHost..." -ForegroundColor Cyan
$Output = & cmd /c "ssh $TargetHost `"bash -s`" < `"$CheckupScript`" 2>&1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "SSH connection failed" -ForegroundColor Red
    exit 1
}

Write-Host "Analyzing with Claude..." -ForegroundColor Cyan

$Prompt = @"
You are a Linux security auditor. Analyze server output and generate report.

## Report Format

### Server Security Report: {hostname}
**Date:** $Date

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
``````bash
{exact commands}
``````

#### Positive Findings
List what is properly configured.

## Rules
- PasswordAuthentication yes → CRITICAL
- PermitRootLogin yes → MEDIUM
- Duplicate SSH params → HIGH (last wins)
- No firewall → CRITICAL
- No fail2ban → HIGH
- Pending security updates → HIGH

--- SERVER: $TargetHost ---
$Output
--- END ---

Generate the security report.
"@

claude -p $Prompt --print
