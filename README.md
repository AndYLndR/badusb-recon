BadUSB post-exploitation recon lab — Flipper Zero + PowerShell + IOC analysis (educational)
# BadUSB Recon Lab

> Simulacion de ataque BadUSB con Flipper Zero contra Windows en entorno controlado.
> Proyecto educativo de seguridad ofensiva y analisis de deteccion.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-Windows-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-blue)

---

## Disclaimer

**Este repositorio contiene herramientas de doble uso (dual-use).**
Su uso esta destinado **exclusivamente** a investigacion, educacion y
pruebas en entornos propios y autorizados.

El autor no se hace responsable del uso indebido. Ver [DISCLAIMER.md](DISCLAIMER.md).

**Usar estas tecnicas contra sistemas sin autorizacion por escrito es ILEGAL**
en la mayoria de jurisdicciones, incluyendo Espana (art. 197 y 197 bis del Codigo Penal).

---

## Que es esto?

Un laboratorio personal para entender como funcionan los **BadUSB / HID injection**
usando un **Flipper Zero**, desarrollando un payload de reconocimiento
post-explotacion en PowerShell, y documentando:

- Como se construye y ejecuta el ataque.
- Que **huellas (IOCs)** deja en el sistema.
- Como **detectarlo** desde el lado defensivo.
- Como **mitigarlo**.

El objetivo no es solo demostrar la parte ofensiva, sino tambien
**entender el ciclo completo**: ataque -> deteccion -> respuesta.

---

## Objetivos del proyecto

- [x] Payload de reconocimiento en PowerShell (identidad, sistema, red, defensas).
- [x] Encoding UTF-16LE + Base64 para `-EncodedCommand`.
- [x] Generador de Ducky Script a partir del payload.
- [ ] Documentacion de IOCs generados con capturas.
- [ ] Guia de deteccion y mitigacion.
- [ ] Comparativa de metodos de entrega (inline vs download vs ofuscado).
- [ ] Subida de archivos a webhook (PS 7+ con `-Form`).

---

## Entorno

| Componente | Detalle |
|---|---|
| Dispositivo | Flipper Zero (BadUSB) |
| Victima | Windows 11 Pro |
| PowerShell | 5.1 / 7+ |
| Exfiltracion | Webhook de Discord (configurable) |
| Autor | 14ND3R ([@AndYLndR](https://github.com/AndYLndR)) |
| Contacto | 14nd3r@proton.me |

---

## Estructura del repositorio

badusb-recon-lab/
  README.md
  LICENSE
  SECURITY.md
  DISCLAIMER.md
  .gitignore
  config.example.ps1
  payloads/
    payload.ps1
    encode_base64.ps1
    payload_ducky.example.txt
  docs/
    01-entorno.md
    02-ejecucion.md
    03-iocs.md
    04-deteccion.md
    05-mitigacion.md
  screenshots/
  tools/
    extract_iocs.ps1

> `config.local.ps1` y los archivos generados (`payload.b64.txt`,
> `payload_ducky.txt`) estan en `.gitignore` y **no se suben al repositorio**.

---

## Uso

> Solo en entornos **propios o con autorizacion por escrito**.

### 1. Clonar el repositorio

git clone https://github.com/AndYLndR/badusb-recon-lab.git
cd badusb-recon-lab

### 2. Configurar el webhook

Copia el archivo de ejemplo y editalo con tu webhook real:

Copy-Item .\config.example.ps1 .\config.local.ps1
notepad .\config.local.ps1

Dentro veras:

$Config = @{
    Webhook = "https://discord.com/api/webhooks/REPLACE_WITH_YOUR_WEBHOOK"
    SendZip = $false
    ZipPath = "$env:TEMP\prueba.zip"
    MaxLen  = 1900
    DelayMs = 700
}

Sustituye la URL por tu webhook real.

> `config.local.ps1` esta en `.gitignore`. **Nunca se sube al repositorio.**

### 3. Generar el Base64 para el Ducky

Antes de ejecutar cualquier `.ps1`, si PowerShell te da error de
Execution Policy:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Despues, genera el payload codificado:

.\payloads\encode_base64.ps1

Eso genera:

- `payloads/payload.b64.txt` -> el Base64 UTF-16LE
- `payloads/payload_ducky.txt` -> el Ducky Script listo para pegar en el Flipper

### 4. Ejecutar desde el Flipper

Carga `payload_ducky.txt` en tu Flipper Zero (app BadUSB) o en tu Ducky
y ejecutalo contra un sistema propio. El payload:

1. Recolecta informacion del sistema (usuario, host, SO, IP, privilegios).
2. La envia troceada a un webhook de Discord.
3. Genera un log local en `%TEMP%` para analisis de IOCs.

---

## Deteccion e IOCs

*Documentacion en progreso. Se anadira en proximas versiones.*

Se cubriran, entre otros:

| Huella | Fuente | Evento / Ruta |
|---|---|---|
| Ejecucion PowerShell | Windows PowerShell Log | Event ID 4104 (Script Block) |
| Proceso creado | Security Log | Event ID 4688 |
| Linea de comandos | Sysmon | Event 1 |
| Conexion saliente | Sysmon | Event 3 |
| Resolucion DNS | Sysmon | Event 22 |
| Prefetch | Disco | `C:\Windows\Prefetch\POWERSHELL.EXE-*.pf` |
| Historial PS | Disco | `ConsoleHost_history.txt` |
| USB insertado | System Log | Events 2003 / 2100 |
| Defender | Windows Defender | `Get-MpThreatDetection` |

Cada IOC se documentara con captura del Event Viewer y su consulta
en PowerShell / KQL.

---

## Mitigacion

*Documentacion en progreso.*

- **PowerShell Constrained Language Mode** (WDAC / AppLocker).
- **ASR rules** de Microsoft Defender:
  - Block Office apps from creating child processes
  - Block executable content from email and webmail
  - Block credential stealing from lsass.exe
- **Bloqueo de USB masivo** via GPO.
- **Restricciones de red saliente** (proxy + firewall).
- **Sysmon** desplegado con config de SwiftOnSecurity o Olaf Hartong.
- **Auditoria de procesos** con linea de comandos habilitada.

---

## Roadmap

- [x] Payload base funcional (recon + envio a webhook).
- [x] Encoding UTF-16LE + Base64.
- [x] Generador automatico de Ducky Script.
- [ ] Documentacion de IOCs con capturas.
- [ ] Guia de deteccion (queries + Event Viewer).
- [ ] Guia de mitigacion (GPO + ASR + WDAC).
- [ ] Metodo de entrega via download (`IEX + iwr`) - *proximamente*.
- [ ] Version ofuscada (gzip+Base64) + analisis de deofuscacion - *proximamente*.
- [ ] Subida de archivos a webhook (PS 7+ con `-Form`) - *proximamente*.

---

## Pruebas realizadas

- [x] Ejecucion manual del payload en Windows 11 Pro (host propio).
- [x] Envio correcto de bloques a webhook de Discord.
- [x] Generacion y verificacion del Base64 UTF-16LE.
- [ ] Prueba desde Flipper Zero fisico (pendiente).
- [ ] Captura de IOCs post-ejecucion (pendiente).

---

## Licencia

MIT - ver [LICENSE](LICENSE).

---

## Contacto

- GitHub: [@AndYLndR](https://github.com/AndYLndR)
- Email: 14nd3r@proton.me

---

## Agradecimientos

- A la comunidad de seguridad ofensiva por la documentacion publica sobre BadUSB.
- A los mantenedores de Flipper Zero por el hardware.
- A los proyectos de blue team (Sysmon, SwiftOnSecurity, Olaf Hartong) por las
  configuraciones de deteccion que hacen posible la parte defensiva de este lab.