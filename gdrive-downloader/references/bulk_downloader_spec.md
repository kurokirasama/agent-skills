# Especificación de Skill: `gdrive-bulk-downloader`

> **Objetivo:** descargar el contenido completo de una **carpeta de Google Drive (URL)** o de un **archivo/video individual (URL)** a un directorio local, **preservando la estructura de carpetas**, incluso cuando el owner deshabilitó la descarga y el copiado (*view-only*). Opcionalmente, generar **transcripciones de video con Whisper**.
>
> Basada y validada en la sesión 2026-10-08 (carpeta "Japones_compartido": 25 videos restringidos + 40 archivos mixtos, descargados y transcritos con éxito).

---

## 1. Metadatos sugeridos

- **name:** `gdrive-bulk-downloader`
- **description (EN):** Download all files from a Google Drive folder URL or a single file URL (including view-only, download-disabled videos) preserving folder structure; optional Whisper transcription of videos. Use when the user asks to download a Drive folder, multiple Drive videos, or a restricted/view-only Drive video.
- **Triggers:** "descarga/baja esta carpeta de drive", "descargar videos de drive", "download drive folder", cualquier URL `drive.google.com`.
- **Inputs:**
  - `url` (obligatorio): carpeta o archivo.
  - `dest_dir` (default: `<cwd>/temp/`, preguntar si hay duda).
  - `transcribe` (bool, default `false`): generar transcripciones.
  - `lang` (default `es`): idioma para Whisper.
  - `parallel` (default `3`): descargas simultáneas.

## 2. Parseo de URL → ID

| Forma | Patrón | ID |
|---|---|---|
| Carpeta | `drive.google.com/drive/(u/N/)?folders/<ID>` | `<ID>` |
| Archivo/video | `drive.google.com/file/d/<ID>/view?t=...` | `<ID>` (el `?t=` se ignora) |

`FOLDER_ID`/`FILE_ID` = `[A-Za-z0-9_-]{20,}`.

**Shortcuts:** una carpeta compartida puede contener solo *accesos directos*. Resolver el target antes de descargar:
- rclone: `rclone lsjson --drive-root-folder-id <ID> <remote>:` — los shortcuts aparecen como carpeta con campo `ID: "<targetId>\t<shortcutId>"`.
- MCP: `drive_search` con `name contains '<nombre>' and mimeType = 'application/vnd.google-apps.folder'`.
- Descargar cada target explícitamente (no confiar en el seguimiento implícito).

## 3. Precondiciones (verificar ANTES)

1. **rclone** con un remote Google válido: `rclone lsd <remote>:`. Si da `invalid_grant`, reconectar: `rclone config reconnect <remote>:` (interactivo, requiere al usuario). Última cuenta validada: `gdrive` (verificar vigencia).
2. **yt-dlp** (`~/.local/bin/yt-dlp`) con cookies del navegador. El config global ya las tiene (`~/.config/yt-dlp/config` → `--cookies-from-browser chrome+GNOMEKEYRING`); si no, pasar el flag explícito.
3. **Whisper** (solo si `transcribe`): usar el binario **pipx** `~/.local/bin/whisper` (venv con torch cu126 y **CUDA funcionando**). ⚠️ NO usar el python global de pyenv (torch cu130 incompatible con driver 575). Modelo `large-v3-turbo` ya cacheado en `~/.cache/whisper/`.
4. Espacio en disco: `df -h <dest_dir>` ≥ tamaño total (obtener con `rclone size --json`).

## 4. Inventario y planificación

```bash
rclone size --json --drive-root-folder-id <ID> <remote>:          # total bytes + count
rclone lsjson -R --files-only --drive-root-folder-id <ID> <remote>: > inv.json
jq -r '.[] | [.ID, .Path, .Size, .MimeType] | @tsv' inv.json      # ID, ruta, tamaño, tipo
```

**Matriz de decisión por archivo:**

| Situación | Método |
|---|---|
| Archivo normal (pptx/pdf/imagen/zip/…) | `rclone copy` (preserva estructura, archivo original) |
| Video | `rclone copy` primero; si falla 403 → **yt-dlp** (ver §5) |
| Video ya *view-only* conocido | yt-dlp directo |
| Archivo no-video restringido (403 `cannotDownloadFile`) | **Sin vía por API.** Reportar; sugerir pedir al owner que habilite "descarga, impresión y copia" o rol Editor/Downloader. |

## 5. Descarga de videos restringidos (yt-dlp) — método clave

Cuando el owner deshabilitó descarga/copiado (`403 cannotDownloadFile` / `cannotCopyFile`), el **streaming del reproductor sí funciona** autenticado con las cookies del navegador. yt-dlp lo explota transparentemente.

```bash
# Ver formatos disponibles (suele haber: 140 audio-only, 134/136 video-only, 22 merged)
yt-dlp -F "https://drive.google.com/file/d/<FILE_ID>/view"

# Descarga (720p máx. expuesto por Drive + audio, merge ffmpeg)
yt-dlp -f "bestvideo*+bestaudio/best" --merge-output-format mp4 \
  --no-warnings --no-progress --retries 2 \
  -o "<dest>/<subcarpeta>/%(title)s.%(ext)s" \
  "https://drive.google.com/file/d/<FILE_ID>/view"
```

Notas:
- El warning "Only the owner and editors can download this file" **no impide** la descarga del stream.
- Calidad máxima = la que Drive expone para streaming (típicamente **720p**), aunque el archivo fuente sea mayor.
- Nombres: yt-dlp sanea `/` → `⧸` (rclone usa `／`). Aceptable; documentarlo.
- Paralelizar con pool de **3** workers (`&` + `wait -n` mientras `jobs -rp` ≥ 3). ~2.5 MB/s por stream.
- Log con marcadores `OK <id>` / `FAIL <id>` y guardar `.part` para reanudar.
- **rclone y `&&`:** un fallo parcial retorna exit 7 y corta la cadena. Ejecutar cada carpeta/etapa independiente.

## 6. Transcripciones (opcional, opt-in)

```bash
whisper "<video.mp4>" --model large-v3-turbo --language es \
  --output_format txt --output_dir "<dest>/transcripciones/<misma-relativa>" --verbose False
```

- Estructura espejo: `transcripciones/<ruta relativa del video>/<nombre>.txt`.
- Saltar si el `.txt` ya existe (reanudable).
- GPU RTX A4000 ≈ **20x realtime** (46 min → ~2.3 min). Solo txt (agregar `srt`/`vtt` si se pide).
- Correr secuencial (1 proceso GPU a la vez); batch en background tras terminar descargas.

## 7. Estructura de salida

```
<dest_dir>/<NombreCarpetaDrive>/
  ├── <subcarpetas originales...>/        # videos + documentos mezclados
  └── ...
<dest_dir>/<NombreCarpetaDrive>/transcripciones/<espejo>/*.txt   # solo si transcribe
<dest_dir>/.rclone_download.log / .ytdlp_download.log / .whisper_batch.log
```

## 8. Verificación y reporte

1. Comparar inventario: `rclone lsf -R --files-only --drive-root-folder-id <ID> <remote>:` (o `inv.json`) vs. archivos locales (`find -type f`). Lista exacta de faltantes.
2. Validar videos: `ffprobe -v error -show_entries format=duration,size -of default=nw=1 <archivo>`.
3. Reportar: totales OK/FAIL por motivo (403 → remedio: pedir permiso al owner), tamaño, rutas.
4. Nota de uso: contenido para uso personal; el owner había restringido la descarga.

## 9. Gotchas (aprendidos en la sesión real)

1. `rclone reconnect` es interactivo → avisar al usuario (notificación Discord + ask).
2. **pkill self-match:** `pkill -f "script.sh"` mata también el shell que lo invoca. Usar truco de corchetes: `pkill -f "[t]ranscribe_videos.sh"`.
3. Un proceso hijo de un script matado puede quedar huérfano → verificar con `pgrep -af "[p]atrón"` y matar el hijo explícitamente.
4. No usar torch del python global (cu130) para Whisper; usar el venv pipx (cu126).
5. Shortcuts de Drive no son archivos: resolver target ID.
6. Nombres con `/` en Drive rompen el FS local → dejar que las herramientas saneen.
7. Antes de jobs largos: `nohup … &`, logs con marcadores (`DONE`), y verificación por conteos.

## 10. Flujo del agente (pasos que la skill debe encodear)

1. Parsear URL (carpeta vs archivo) → IDs; resolver shortcuts.
2. Verificar precondiciones (§3); si el remote rclone no tiene token válido y no se puede reconectar, usar MCP google-workspace como respaldo para inventario y archivos permitidos (los videos seguirán requiriendo yt-dlp).
3. Inventario + tamaño (§4); elegir `dest_dir` (default `temp/`).
4. Descargar: rclone (bulk) → recopilar fallos 403 → enrutar videos a yt-dlp (§5).
5. (Opcional) Whisper batch (§6), después de que `DONE` de descargas.
6. Verificar (§8) y reportar resumen con faltantes y remedios.

## 11. Criterios de aceptación (tests de la skill futura)

- [ ] URL de carpeta con contenido mixto (docs + videos normales + videos view-only) → todo descargado con estructura, 0 intervención manual.
- [ ] URL de un video view-only individual → descargado.
- [ ] Re-ejecución idempotente: salta archivos existentes y solo retoma pendientes/`.part`.
- [ ] `transcribe=false` por defecto; con `true` genera txt por video en estructura espejo (GPU).
- [ ] Reporte final incluye: conteos OK/FAIL, motivos (403), y remedio sugerido (pedir habilitar descarga al owner).
