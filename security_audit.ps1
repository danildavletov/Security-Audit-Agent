# Security Audit - handles SSH with sudo properly
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$TargetHost
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CheckupScript = Join-Path $ScriptDir "security_checkup.sh"
$TempOutput = "$env:TEMP\audit_output.txt"
$OutputFile = Join-Path $ScriptDir "output.md"
$Date = Get-Date -Format "yyyy-MM-dd"

Write-Host "Collecting security data from $TargetHost..." -ForegroundColor Cyan

# Copy script to remote
& scp -q $CheckupScript "${TargetHost}:/tmp/security_checkup.sh"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to copy script" -ForegroundColor Red
    exit 1
}

# Prompt for sudo password securely
$SecurePassword = Read-Host -Prompt "Enter sudo password for $TargetHost" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

# Run script with sudo -S (reads password from stdin)
$Output = $Password | & ssh $TargetHost "sudo -S bash /tmp/security_checkup.sh 2>/dev/null; rm /tmp/security_checkup.sh" 2>&1

# Clear password from memory
$Password = $null
[GC]::Collect()

if (-not $Output) {
    Write-Host "Failed to collect data" -ForegroundColor Red
    exit 1
}

# Save raw output
$Output | Out-File -FilePath $TempOutput -Encoding UTF8

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
- PasswordAuthentication yes -> CRITICAL
- PermitRootLogin yes -> MEDIUM
- Duplicate SSH params -> HIGH (last wins)
- No firewall -> CRITICAL
- No fail2ban -> HIGH
- Pending security updates -> HIGH

--- SERVER: $TargetHost ---
$Output
--- END ---

Generate the security report.
"@

$Result = & claude -p $Prompt --print
$Result
[System.IO.File]::WriteAllText($OutputFile, ($Result -join "`n"), [System.Text.Encoding]::UTF8)
