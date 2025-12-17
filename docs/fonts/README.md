Coloca aquí tus archivos de fuentes .woff2 con los nombres siguientes para que el proyecto pueda cargarlas localmente:

- OpenSans-Regular.woff2
- OpenSans-700.woff2
- CinzelDecorative-Regular.woff2
- GreatVibes-Regular.woff2

Nota: este proyecto incluye los archivos .woff2 en la carpeta `fonts/`.

- Uso offline: las reglas `@font-face` especificadas en `INDEX.HTML` cargan las fuentes desde `fonts/`.
- Fallback remoto: si el navegador no puede cargar las fuentes locales, el proyecto también incluye una carga remota por defecto desde Google Fonts para mayor compatibilidad.

Cómo probar localmente:
1. Sirve el proyecto desde la raíz del repo con un servidor local (recomendado):

```powershell
cd "c:\Users\romin\OneDrive\Escritorio\WEB DIANA"
python -m http.server 8000  # (o npx http-server -c-1 . si tienes npm)
```
2. Abre http://localhost:8000/INDEX.HTML y espera a que la página cargue.
3. En DevTools → Console verás logs de comprobación sobre si las fuentes se cargaron desde local o desde el fallback remoto.

Si quieres que elimine la carga remota y deje solo las fuentes locales, dime y lo cambio.

Cómo obtenerlos: 
1. Ve a Google Fonts, selecciona las familias y pesos que necesites.
2. Descarga los archivos y convierte a .woff2 si es necesario (puedes usar herramientas como fonttools o servicios en línea confiables).
3. Renombra los archivos siguiendo los nombres de arriba y colócalos en la carpeta `fonts/`.

> Automatización: puedes ejecutar el script PowerShell `scripts/download-fonts.ps1` desde la raíz del proyecto para descargar y renombrar automáticamente las versiones .woff2.

Si prefieres automatizar la descarga desde la máquina local (requiere PowerShell o curl):

PowerShell (ejemplo, puede necesitar ajustes):

```powershell
# Descarga la hoja de estilos de Google Fonts para "Open Sans" y extrae urls (requiere procesamiento manual)
Invoke-WebRequest -Uri "https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;700&display=swap" -OutFile "open-sans.css"
# Revisa open-sans.css para copiar los enlaces a los archivos woff2 y descarga cada uno con Invoke-WebRequest
```

Nota: Algunas descargas desde fonts.gstatic.com pueden estar sujetas a política de uso. Usa siempre fuentes con licencia adecuada para tu proyecto.
