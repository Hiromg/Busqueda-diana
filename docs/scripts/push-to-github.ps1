<#
PowerShell script para inicializar un repo git local (si es necesario), crear
un repositorio en GitHub usando la API y hacer push del contenido.

Uso:
1. Crea un token personal (PAT) en GitHub con permisos `repo` (y `public_repo` si es público).
2. Ejecuta desde la raíz del proyecto (donde está INDEX.HTML):
   powershell -ExecutionPolicy Bypass -File .\scripts\push-to-github.ps1

El script pedirá tu usuario de GitHub, el nombre del repositorio y el PAT.
#>

param()

function Abort($msg) {
    Write-Host "ERROR: $msg" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Abort "Git no está instalado. Instala Git (https://git-scm.com/) y vuelve a ejecutar." 
}

Write-Host "Se verificó que Git esté instalado." -ForegroundColor Green

$cwd = Get-Location
Write-Host "Proyecto actual: $cwd"

$owner = Read-Host "Tu usuario de GitHub (o la organización)"
$repoName = Read-Host "Nombre deseado para el repositorio (ej: web-diana)"
$isPrivate = Read-Host "Repositorio privado? (s/n)" 
$isPrivate = ($isPrivate -match '^[sS]')
$pat = Read-Host "Personal Access Token (PAT) (se requiere scope 'repo')" -AsSecureString
$patPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pat))

if ([string]::IsNullOrWhiteSpace($owner) -or [string]::IsNullOrWhiteSpace($repoName) -or [string]::IsNullOrWhiteSpace($patPlain)) {
    Abort "Usuario, nombre de repo y token son obligatorios."
}

# Inicializar git si no es repo
if (-not (Test-Path "$cwd\.git")) {
    Write-Host "Inicializando repositorio Git local..."
    git init
    Write-Host "Agregando archivos..."
    git add .
    git commit -m "Initial commit"
}

# Crear el repo en GitHub
Write-Host "Creando repositorio en GitHub (puede fallar si ya existe)..."

$body = @{ name = $repoName; private = $isPrivate }
$json = $body | ConvertTo-Json

$headers = @{ 'Authorization' = "token $patPlain"; 'User-Agent' = 'RepoUploaderScript' }

try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $json -ContentType 'application/json' -ErrorAction Stop
    Write-Host "Repositorio creado: $($response.full_name)" -ForegroundColor Green
} catch {
    $msg = $_.Exception.Message
    Write-Host "No se pudo crear el repositorio: $msg" -ForegroundColor Yellow
    Write-Host "Si el repositorio ya existe, continuamos usando el remoto existente..."
}

git branch -M main

$remoteUrl = "https://github.com/$owner/$repoName.git"

if (git remote get-url origin 2>$null) {
    Write-Host "Remote 'origin' ya existe. Actualizando a: $remoteUrl"
    git remote set-url origin $remoteUrl
} else {
    git remote add origin $remoteUrl
}

Write-Host "Realizando push a GitHub..." 
# Para evitar prompts de credenciales, podemos usar la URL con token (menos seguro). Preguntar al usuario.
$useTokenUrl = Read-Host "¿Usar URL con token para push automático? (ej: https://username:token@github.com/...) (s/n)"
if ($useTokenUrl -match '^[sS]') {
    # Usar $() para delimitar correctamente las variables dentro de la cadena
    $pushUrl = "https://$($owner):$($patPlain)@github.com/$($owner)/$($repoName).git"
    git remote set-url origin $pushUrl
}

try {
    git push -u origin main --force
    Write-Host "Push realizado correctamente a $remoteUrl" -ForegroundColor Green
} catch {
    Write-Host "Push falló: $_" -ForegroundColor Red
}

Write-Host "Proceso terminado. Considera revisar el repo en https://github.com/$owner/$repoName" -ForegroundColor Cyan
