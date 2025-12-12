# Script para descargar fuentes de Google Fonts como .woff2 y colocarlas en la carpeta fonts\
# Uso: Ejecutar en PowerShell desde la raíz del proyecto (donde está INDEX.HTML)
# Requiere conexión a internet y permisos de escritura en la carpeta fonts\

$headers = @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'; 'Accept' = 'text/css,*/*;q=0.1' }
$fontsDir = "../fonts"  # Esto asume que el script está en /scripts
if(-not (Test-Path $fontsDir)) { New-Item -ItemType Directory -Path $fontsDir | Out-Null }

# Familias con pesos y nombres de salida:
$families = @(
    @{ name = 'Open Sans'; css = 'https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;700&display=swap'; map = @{ '400'='OpenSans-Regular.woff2'; '700'='OpenSans-700.woff2' } },
    @{ name = 'Cinzel Decorative'; css = 'https://fonts.googleapis.com/css2?family=Cinzel+Decorative:wght@400&display=swap'; map = @{ '400'='CinzelDecorative-Regular.woff2' } },
    @{ name = 'Great Vibes'; css = 'https://fonts.googleapis.com/css2?family=Great+Vibes&display=swap'; map = @{ '400'='GreatVibes-Regular.woff2' } }
)

foreach ($f in $families) {
    Write-Host "Procesando: $($f.name)"
    $tmpCss = Invoke-WebRequest -Uri $f.css -Headers $headers -UseBasicParsing -ErrorAction Stop
    $cssText = $tmpCss.Content

    # Extraer bloques @font-face con weight y url(woff2)
    $regex = [regex]"@font-face\s*\{[^}]*font-weight:\s*(\d+)[^}]*src:\s*url\((https?://[^)]+\.(?:woff2|ttf))"
    $matches = $regex.Matches($cssText)
    if ($matches.Count -eq 0) {
        Write-Host "  No se encontraron URLs woff2 para $($f.name)"
        continue
    }

    foreach ($m in $matches) {
        $weight = $m.Groups[1].Value
        $url = $m.Groups[2].Value
        if ($f.map.ContainsKey($weight)) {
            $filename = $f.map[$weight]
            $outPath = Join-Path $fontsDir $filename
            Write-Host "  Descargando peso $weight -> $filename"
            try {
                Invoke-WebRequest -Uri $url -OutFile $outPath -Headers $headers -UseBasicParsing -ErrorAction Stop
                Write-Host "   OK: $outPath"
            } catch {
                Write-Host ("   Error al descargar {0} - {1}" -f $url, $_)
            }
        } else {
            Write-Host "  Peso $weight no mapeado, omitiendo: $url"
        }
    }
}

Write-Host "Descarga completada. Revisa la carpeta fonts y ejecuta el servidor local para probar."