# Security Audit for Linux Servers

Автоматический аудит безопасности Linux-серверов через SSH + Claude.

## Файлы

```
security_checkup.sh  — Сбор данных с сервера
security_audit.sh    — Linux/macOS версия
security_audit.ps1   — Windows PowerShell версия
security_audit.bat   — Windows CMD версия
prompt.md            — Полные инструкции (для справки)
```

## Использование

**Linux/macOS:**
```bash
./security_audit.sh servername
```

**Windows PowerShell:**
```powershell
.\security_audit.ps1 servername
```

**Windows CMD:**
```cmd
security_audit.bat servername
```

## Что делает

1. Подключается к серверу по SSH
2. Запускает `security_checkup.sh` для сбора данных
3. Отправляет вывод в Claude для анализа
4. Выдаёт отчёт с командами для исправления

## Требования

- SSH-доступ к серверу (лучше по ключу)
- `claude` CLI в PATH
- bash

## Пример вывода

```
### Server Security Report: servername
**Date:** 2026-01-11

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
- Risk: Brute force attacks
- Fix:
```bash
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
```

#### Positive Findings
- SSH on non-standard port
- UFW firewall active with DROP policy
- fail2ban protecting sshd
- Public key authentication enabled
```

## Интеграция с агентской системой

```python
import subprocess

def security_audit(host: str) -> str:
    result = subprocess.run(
        ["./security_audit.sh", host],
        capture_output=True,
        text=True
    )
    return result.stdout
```

## Кастомизация

Добавить проверки в `security_checkup.sh`:
```bash
echo "=== MY CHECK ==="
# commands
echo ""
```
