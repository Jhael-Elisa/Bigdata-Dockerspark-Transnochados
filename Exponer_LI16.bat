@echo off
REM Lanzador BAT: ejecuta el bloque PowerShell incluido en este mismo archivo.
REM El menu usa switch y las consultas estan escritas en SQL literal.
setlocal
set "LAB_MENU_FILE=%~f0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:LAB_MENU_FILE); $m='###POWERSHELL###'; & ([scriptblock]::Create($s.Substring($s.LastIndexOf($m)+$m.Length)))"
exit /b %errorlevel%
###POWERSHELL###

$ErrorActionPreference='Stop'
$root=Split-Path -Parent $env:LAB_MENU_FILE
Set-Location -LiteralPath $root
[Console]::OutputEncoding=[System.Text.Encoding]::UTF8
# Datos del laboratorio en texto visible.
$data = @{
    lab = @'
16
'@
    db = @'
db_john
'@
    table = @'
db_john.fb_john
'@
    prep = @'
Conservamos el original y preparamos pseudo_facebook_john.csv sin encabezado. 99003 filas, 15 columnas. Genero STRING y los demas campos INT.
'@
    copy = @'
PASO REALIZADO (no se repite la carga):
docker compose cp "C:\Users\johnn\Downloads\pseudo_facebook_john.csv" yarn-resourcemanager:/tmp/
docker compose exec yarn-resourcemanager hdfs dfs -put /tmp/pseudo_facebook_john.csv /user/hive/warehouse/
Ahora se listan los archivos de la base ya cargada; LOAD DATA pudo mover el CSV a la tabla.
'@
    schema = @'
Tabla TEXTFILE delimitada por comas, 15 columnas.
'@
    load = @'
PASO REALIZADO: LOAD DATA INPATH 'hdfs://yarn-resourcemanager:9000/user/hive/warehouse/pseudo_facebook_john.csv' INTO TABLE db_john.fb_john;
Durante la exposicion solo verificamos la tabla; no duplicamos datos.
'@
}

$settings='SET mapreduce.task.io.sort.mb=10; SET hive.vectorized.execution.enabled=false; SET hive.vectorized.execution.reduce.enabled=false; '
# Funcion compartida: muestra el SQL, espera Enter y ejecuta Beeline.
function Run-Sql([string]$sql) {
    Write-Host "`nCONSULTA PREPARADA:" -ForegroundColor Cyan
    Write-Host $sql
    Write-Host ('docker compose exec -T hive-server beeline -u jdbc:hive2://localhost:10000 -n root --silent=true --outputformat=table -e "'+$settings+$sql+'"') -ForegroundColor DarkCyan
    [void](Read-Host 'Comando listo. Pulsa Enter para ejecutarlo')
    Write-Host "`nRESULTADO REAL DE HIVE - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
    & docker compose exec -T hive-server beeline -u jdbc:hive2://localhost:10000 -n root --silent=true --outputformat=table -e ($settings+$sql)
    if ($LASTEXITCODE -ne 0) { Write-Host 'No se completo la consulta. Revise el error anterior y la opcion 1. No se muestran resultados guardados.' -ForegroundColor Red }
}
function Start-Lab {
    Write-Host 'COMANDO PREPARADO: docker compose up -d; docker compose ps' -ForegroundColor Cyan
    [void](Read-Host 'Enter para iniciar Docker si hace falta y ejecutar')
    & cmd.exe /d /c "docker info >nul 2>&1"
    if ($LASTEXITCODE -ne 0) {
        $desktop=Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
        if (!(Test-Path -LiteralPath $desktop)) { throw 'Abra Docker Desktop manualmente y vuelva a elegir 1.' }
        Start-Process -FilePath $desktop -WindowStyle Hidden
        Write-Host 'Esperando Docker Desktop (hasta 120 segundos)...'
        $ready=$false
        for ($i=0;$i -lt 24;$i++) {
            Start-Sleep -Seconds 5
            & cmd.exe /d /c "docker info >nul 2>&1"
            if ($LASTEXITCODE -eq 0) { $ready=$true; break }
        }
        if (!$ready) { throw 'Docker aun no responde. Termine su inicio y vuelva a elegir 1.' }
    }
    Write-Host 'COMANDO: docker compose up -d'
    & docker compose up -d
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron iniciar los servicios.' }
    & docker compose ps
    Write-Host 'Hive puede tardar en estar listo. Si falla una conexion, espere y repita la consulta.'
}
while ($true) {
    Clear-Host
    Write-Host ('LABORATORIO '+$data.lab+' - Johnny Suarez Abasto') -ForegroundColor Cyan
    Write-Host 'Pasos del laboratorio en orden. Las consultas se ejecutan en vivo.'
    Write-Host '1  Iniciar Docker Desktop y levantar servicios'
    Write-Host '2  Ver contenedores del proyecto'
    Write-Host '3  Preparacion del CSV: explicacion y comandos utilizados'
    Write-Host '4  Copia a HDFS: comandos utilizados y verificar archivos actuales'
    Write-Host '5  Base de datos: explicar creacion y verificar existencia'
    Write-Host '6  Tabla: esquema y tipos'
    Write-Host '7  Carga: explicar procedimiento y verificar Location'
    Write-Host '8  Mostrar diez registros actuales'
    Write-Host '----- Consultas de analisis -----'
    Write-Host 'C1  Total de usuarios'
    Write-Host 'C2  Usuarios mayores de 25'
    Write-Host 'C3  Amigos por genero'
    Write-Host 'C4  Likes recibidos por edad'
    Write-Host 'C5  Cumpleanos por mes'
    Write-Host 'C6  Movil y web: jovenes'
    Write-Host 'C7  Movil y web: adultos'
    Write-Host '0  Salir (los contenedores siguen funcionando)'
    $option=(Read-Host 'Opcion').Trim().ToUpperInvariant()
    if ($option -eq '0') { break }
    try {
        # switch compara la opcion ingresada con cada caso.
        switch ($option) {
                '1' { Start-Lab }
                '2' { Write-Host 'COMANDO PREPARADO: docker compose ps'; [void](Read-Host 'Enter para ejecutar'); & docker compose ps }
                '3' { Write-Host $data.prep }
                '4' { Write-Host $data.copy; Write-Host ('COMANDO PREPARADO: docker compose exec -T yarn-resourcemanager hdfs dfs -ls -R /user/hive/warehouse/'+$data.db+'.db'); [void](Read-Host 'Enter para ejecutar'); & docker compose exec -T yarn-resourcemanager hdfs dfs -ls -R ('/user/hive/warehouse/'+$data.db+'.db') }
                '5' { Write-Host ('Paso realizado: CREATE DATABASE IF NOT EXISTS '+$data.db+'; USE '+$data.db+';'); Run-Sql ('SHOW DATABASES; USE '+$data.db+'; SELECT current_database();') }
                '6' { Write-Host $data.schema; Run-Sql ('DESCRIBE '+$data.table+';') }
                '7' { Write-Host $data.load; Run-Sql ('DESCRIBE FORMATTED '+$data.table+';') }
                '8' { Run-Sql ('SELECT * FROM '+$data.table+' LIMIT 10;') }

            # C1: Total de usuarios
            'C1' {
                Write-Host 'Cada fila representa un usuario.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT COUNT(*) AS total_usuarios FROM db_john.fb_john;
'@
                Run-Sql $sql
            }

            # C2: Usuarios mayores de 25
            'C2' {
                Write-Host 'No incluye a quienes tienen exactamente 25.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT COUNT(*) AS usuarios_mayores_de_25 FROM db_john.fb_john WHERE age > 25;
'@
                Run-Sql $sql
            }

            # C3: Amigos por genero
            'C3' {
                Write-Host 'Comparamos promedios. Se excluyen generos ausentes de esta consulta.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT gender AS genero, COUNT(*) AS usuarios, ROUND(AVG(friend_count),2) AS promedio_amigos FROM db_john.fb_john WHERE gender IN ('male','female') GROUP BY gender ORDER BY promedio_amigos DESC;
'@
                Run-Sql $sql
            }

            # C4: Likes recibidos por edad
            'C4' {
                Write-Host 'Se excluyen edades de 26 a 35.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT CASE WHEN age BETWEEN 13 AND 25 THEN 'Jovenes 13-25' ELSE 'Mayores de 35' END AS grupo, COUNT(*) AS usuarios, SUM(likes_received) AS total_likes, ROUND(AVG(likes_received),2) AS promedio FROM db_john.fb_john WHERE age BETWEEN 13 AND 25 OR age > 35 GROUP BY CASE WHEN age BETWEEN 13 AND 25 THEN 'Jovenes 13-25' ELSE 'Mayores de 35' END;
'@
                Run-Sql $sql
            }

            # C5: Cumpleanos por mes
            'C5' {
                Write-Host 'Agrupacion por mes de nacimiento.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT dob_month AS mes, COUNT(*) AS usuarios FROM db_john.fb_john GROUP BY dob_month ORDER BY dob_month;
'@
                Run-Sql $sql
            }

            # C6: Movil y web: jovenes
            'C6' {
                Write-Host 'Mide likes dados, no tiempo de uso.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT COUNT(*) AS usuarios, SUM(mobile_likes) AS likes_movil, SUM(www_likes) AS likes_web FROM db_john.fb_john WHERE age BETWEEN 13 AND 25;
'@
                Run-Sql $sql
            }

            # C7: Movil y web: adultos
            'C7' {
                Write-Host 'Web no equivale necesariamente a computadora.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT COUNT(*) AS usuarios, SUM(mobile_likes) AS likes_movil, SUM(www_likes) AS likes_web FROM db_john.fb_john WHERE age > 25;
'@
                Run-Sql $sql
            }
                default { Write-Host 'Opcion no valida. Use 1 a 8, C1... o 0.' }
        }
    } catch { Write-Host ('ERROR: '+$_.Exception.Message) -ForegroundColor Red }
    Write-Host ''
    [void](Read-Host 'Enter para volver al menu')
}
