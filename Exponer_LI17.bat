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
17
'@
    db = @'
dbec_john
'@
    table = @'
dbec_john.tec_john
'@
    prep = @'
Conservamos el original y preparamos data_john.csv sin encabezado. 541909 filas, 8 columnas. UTF-8. OpenCSVSerde respeta comas dentro de comillas. Fechas M/d/yyyy H:mm convertidas a TIMESTAMP. Clientes vacios a NULL.
'@
    copy = @'
PASO REALIZADO (no se repite la carga):
docker compose cp "C:\Users\johnn\Downloads\data_john.csv" yarn-resourcemanager:/tmp/
docker compose exec yarn-resourcemanager hdfs dfs -put /tmp/data_john.csv /user/hive/warehouse/li17_john/
Ahora se listan los archivos de la base ya cargada; LOAD DATA pudo mover el CSV a la tabla.
'@
    schema = @'
Entrada: tec_john_csv con OpenCSVSerde y columnas STRING. Final: tec_john en ORC; Quantity INT, UnitPrice DECIMAL(18,4), InvoiceDate TIMESTAMP, CustomerID INT; otros campos STRING.
'@
    load = @'
PASO REALIZADO: LOAD DATA INPATH 'hdfs://yarn-resourcemanager:9000/user/hive/warehouse/li17_john/data_john.csv' INTO TABLE dbec_john.tec_john_csv;
Luego convertimos los tipos y generamos tec_john en ORC.
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
    Write-Host 'C1  Ingreso total'
    Write-Host 'C2  Productos por unidades'
    Write-Host 'C3  Clientes por pais'
    Write-Host 'C4  Ticket y mediana'
    Write-Host 'C5  Ingresos mensuales'
    Write-Host 'C6  Devoluciones por descripcion'
    Write-Host 'C7  Actividad por hora'
    Write-Host 'C8  Concentracion mensual'
    Write-Host 'C9  Score de precio y frecuencia'
    Write-Host 'C10  Registrados y anonimos'
    Write-Host 'C11  Actividad por dia'
    Write-Host 'C12  Cancelaciones por pais'
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

            # C1: Ingreso total
            'C1' {
                Write-Host 'Ventas positivas con cliente identificado; no es utilidad.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    ROUND(SUM(Quantity * UnitPrice), 2) as ingreso_total
FROM dbec_john.tec_john
WHERE Quantity > 0 
  AND UnitPrice > 0 
  AND CustomerID IS NOT NULL;
'@
                Run-Sql $sql
            }

            # C2: Productos por unidades
            'C2' {
                Write-Host 'Volumen positivo, no neto; hay descripciones vacias y valores extremos.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    Description,
    SUM(Quantity) as unidades_vendidas,
    COUNT(DISTINCT InvoiceNo) as pedidos_con_producto
FROM dbec_john.tec_john
WHERE Quantity > 0
GROUP BY Description
ORDER BY unidades_vendidas DESC
LIMIT 10;
'@
                Run-Sql $sql
            }

            # C3: Clientes por pais
            'C3' {
                Write-Host 'El denominador suma clientes distintos por pais.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    Country,
    COUNT(DISTINCT CustomerID) as clientes_unicos,
    ROUND(COUNT(DISTINCT CustomerID) * 100.0 / 
        SUM(COUNT(DISTINCT CustomerID)) OVER (), 2) as porcentaje
FROM dbec_john.tec_john
WHERE CustomerID IS NOT NULL
GROUP BY Country
ORDER BY clientes_unicos DESC;
'@
                Run-Sql $sql
            }

            # C4: Ticket y mediana
            'C4' {
                Write-Host 'Primero sumamos por factura; luego calculamos media y mediana aproximada.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    ROUND(AVG(order_total), 2) as ticket_promedio,
    PERCENTILE_APPROX(order_total, 0.5) as mediana_ticket
FROM (
    SELECT 
        InvoiceNo,
        CAST(SUM(Quantity * UnitPrice) AS DOUBLE) as order_total
    FROM dbec_john.tec_john
    WHERE Quantity > 0 AND UnitPrice > 0
    GROUP BY InvoiceNo
) orders;
'@
                Run-Sql $sql
            }

            # C5: Ingresos mensuales
            'C5' {
                Write-Host 'Diciembre de 2011 solo llega al dia 9.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    YEAR(InvoiceDate) as anio,
    MONTH(InvoiceDate) as mes,
    COUNT(DISTINCT InvoiceNo) as pedidos,
    ROUND(SUM(Quantity * UnitPrice), 2) as ingresos
FROM dbec_john.tec_john
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY anio, mes;
'@
                Run-Sql $sql
            }

            # C6: Devoluciones por descripcion
            'C6' {
                Write-Host 'Tasa por linea; incluye conceptos de ajustes y descuentos.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    Description,
    COUNT(CASE WHEN Quantity < 0 OR InvoiceNo LIKE 'C%' THEN 1 END) as devoluciones,
    COUNT(CASE WHEN Quantity > 0 THEN 1 END) as ventas_validas,
    ROUND(
        COUNT(CASE WHEN Quantity < 0 OR InvoiceNo LIKE 'C%' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(*), 0), 2
    ) as tasa_devolucion_pct
FROM dbec_john.tec_john
WHERE CustomerID IS NOT NULL
GROUP BY Description
HAVING COUNT(*) >= 10
ORDER BY tasa_devolucion_pct DESC
LIMIT 15;
'@
                Run-Sql $sql
            }

            # C7: Actividad por hora
            'C7' {
                Write-Host 'El alias ticket_promedio del SQL original es promedio por linea, no por factura.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    HOUR(InvoiceDate) as hora,
    COUNT(DISTINCT InvoiceNo) as pedidos,
    ROUND(SUM(Quantity * UnitPrice), 2) as ingresos,
    ROUND(AVG(Quantity * UnitPrice), 2) as ticket_promedio
FROM dbec_john.tec_john
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY HOUR(InvoiceDate)
ORDER BY hora;
'@
                Run-Sql $sql
            }

            # C8: Concentracion mensual
            'C8' {
                Write-Host 'Consulta original completa: puede producir muchas filas. HAVING excluye meses antes del porcentaje; no prueba estacionalidad recurrente.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    Description,
    MONTH(InvoiceDate) as mes,
    SUM(Quantity) as unidades_mes,
    ROUND(SUM(Quantity) * 100.0 / SUM(SUM(Quantity)) OVER (PARTITION BY Description), 2) as distribucion_pct
FROM dbec_john.tec_john
WHERE Quantity > 0
GROUP BY Description, MONTH(InvoiceDate)
HAVING SUM(Quantity) > 50
ORDER BY Description, mes;
'@
                Run-Sql $sql
            }

            # C9: Score de precio y frecuencia
            'C9' {
                Write-Host 'No es margen real: faltan costos.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    Description,
    ROUND(AVG(UnitPrice), 2) as precio_promedio,
    COUNT(DISTINCT InvoiceNo) as pedidos_con_producto,
    ROUND(AVG(UnitPrice) * COUNT(DISTINCT InvoiceNo), 2) as score_margen_proxy
FROM dbec_john.tec_john
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY Description
HAVING COUNT(DISTINCT InvoiceNo) >= 5
ORDER BY score_margen_proxy DESC
LIMIT 20;
'@
                Run-Sql $sql
            }

            # C10: Registrados y anonimos
            'C10' {
                Write-Host 'El alias ticket_promedio es promedio por linea. Cliente ausente no significa venta invalida.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    CASE WHEN CustomerID IS NULL THEN 'Anónimo' ELSE 'Registrado' END as tipo_cliente,
    COUNT(DISTINCT InvoiceNo) as pedidos,
    ROUND(AVG(Quantity * UnitPrice), 2) as ticket_promedio,
    ROUND(SUM(Quantity * UnitPrice), 2) as revenue_total
FROM dbec_john.tec_john
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY CASE WHEN CustomerID IS NULL THEN 'Anónimo' ELSE 'Registrado' END;
'@
                Run-Sql $sql
            }

            # C11: Actividad por dia
            'C11' {
                Write-Host 'Mide actividad, no conversion: faltan visitas.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    DAYOFWEEK(InvoiceDate) as dia_semana,  -- 1=Domingo, 7=Sábado
    CASE DAYOFWEEK(InvoiceDate)
        WHEN 1 THEN 'Domingo' WHEN 2 THEN 'Lunes' WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miércoles' WHEN 5 THEN 'Jueves' WHEN 6 THEN 'Viernes'
        ELSE 'Sábado' END as dia_nombre,
    COUNT(DISTINCT InvoiceNo) as pedidos,
    ROUND(SUM(Quantity * UnitPrice), 2) as ingresos
FROM dbec_john.tec_john
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY DAYOFWEEK(InvoiceDate)
ORDER BY dia_semana;
'@
                Run-Sql $sql
            }

            # C12: Cancelaciones por pais
            'C12' {
                Write-Host 'Tasa por linea, no por factura completa.'
                # SQL literal: se conserva completo y se envia a Run-Sql.
                $sql = @'
SELECT 
    Country,
    COUNT(CASE WHEN Quantity < 0 OR InvoiceNo LIKE 'C%' THEN 1 END) as cancelaciones,
    COUNT(CASE WHEN Quantity > 0 THEN 1 END) as ventas_validas,
    ROUND(
        COUNT(CASE WHEN Quantity < 0 OR InvoiceNo LIKE 'C%' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(*), 0), 2
    ) as tasa_cancelacion_pct
FROM dbec_john.tec_john
GROUP BY Country
HAVING COUNT(*) >= 50
ORDER BY tasa_cancelacion_pct DESC;
'@
                Run-Sql $sql
            }
                default { Write-Host 'Opcion no valida. Use 1 a 8, C1... o 0.' }
        }
    } catch { Write-Host ('ERROR: '+$_.Exception.Message) -ForegroundColor Red }
    Write-Host ''
    [void](Read-Host 'Enter para volver al menu')
}
