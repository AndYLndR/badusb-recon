# ============================================================
# BadUSB Recon - Build Script
# ------------------------------------------------------------
# Genera el Ducky Script listo para cargar en el Flipper.
#
# Uso:
#   .\build.ps1
#   .\build.ps1 -Webhook "https://discord.com/api/webhooks/..."
#   .\build.ps1 -OutputPath "C:\ruta\custom\ducky.txt"
# ============================================================

param(
    [string]$Webhook,
    [string]$OutputPath
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$genScript = Join-Path $scriptDir "payloads\generate_ducky.ps1"

if (-not (Test-Path $genScript)) {
    Write-Host "[-] No se encuentra $genScript" -ForegroundColor Red
    exit 1
}

$args = @()
if ($Webhook)    { $args += "-Webhook";    $args += $Webhook }
if ($OutputPath) { $args += "-OutputPath"; $args += $OutputPath }

& $genScript @args

Write-Host ""
Write-Host "=== SIGUIENTE PASO ===" -ForegroundColor Cyan
Write-Host "  1. Copia payload_ducky.txt a la SD del Flipper (carpeta badusb/)"
Write-Host "  2. Desconecta el Flipper del PC"
Write-Host "  3. Ejecuta el payload contra el sistema objetivo"
Write-Host ""