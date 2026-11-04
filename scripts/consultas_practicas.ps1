$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
Set-Location $Root
function Invoke-Docker([string[]]$A){& docker @A;if($LASTEXITCODE -ne 0){throw "Error Docker: $($A -join ' ')"}}
function Hive([string]$Db,[string]$Sql){
 $full=@('SET hive.execution.engine=mr;','SET mapreduce.framework.name=yarn;','SET hive.exec.mode.local.auto=false;',$Sql)-join [Environment]::NewLine
 $a=@('compose','exec','-T','hive-server','beeline','-u',"jdbc:hive2://localhost:10000/$Db",'--silent=true','--showHeader=true','--outputformat=table','-e',$full)
 & docker @a;if($LASTEXITCODE -ne 0){throw "Error en Beeline para $Db"}
}
function Catalog([string]$Text){
 $items=@()
 foreach($b in ($Text.Trim() -split '(?m)^@@\s*$')){
  $l=@($b.Trim() -split '\r?\n');if($l.Count -lt 2){continue}
  $head=$l[0] -split '\|',2
  $items += [pscustomobject]@{Number=$head[0];Name=$head[1];Sql=($l[1..($l.Count-1)] -join [Environment]::NewLine)}
 }
 return ,$items
}
function Test-HdfsTableData([string]$Location){
 $listing=& docker compose exec -T yarn-resourcemanager hdfs dfs -ls -C $Location 2>$null
 return ($LASTEXITCODE -eq 0 -and @($listing|Where-Object { "$_".Trim() }).Count -gt 0)
}
function Wait-HiveServer([int]$Attempts=60,[int]$DelaySeconds=2){
 Write-Host 'Esperando a que HiveServer2 acepte conexiones...' -ForegroundColor Cyan
 for($i=1;$i -le $Attempts;$i++){
  $client=$null
  try{
   $client=[System.Net.Sockets.TcpClient]::new()
   $connect=$client.BeginConnect('127.0.0.1',10000,$null,$null)
   if($connect.AsyncWaitHandle.WaitOne(1000) -and $client.Connected){
    $client.EndConnect($connect);$client.Close()
    Write-Host 'HiveServer2 esta listo.' -ForegroundColor Green
    return
   }
  }catch{}finally{if($client){$client.Close()}}
  Start-Sleep -Seconds $DelaySeconds
 }
 throw 'HiveServer2 no respondio en el puerto 10000 despues de 120 segundos. Revisa docker compose logs hive-server.'
}
$Q16=Catalog @'
1|Total de usuarios
SELECT COUNT(*) AS total_usuarios FROM fb_jhaelguevara;
@@
2|Usuarios mayores de 25 anios
SELECT COUNT(*) AS usuarios_mayores_25 FROM fb_jhaelguevara WHERE age>25;
@@
3|Promedio de amigos por genero
SELECT gender,ROUND(AVG(friends),2) AS promedio_amigos FROM fb_jhaelguevara WHERE gender IS NOT NULL GROUP BY gender ORDER BY promedio_amigos DESC;
@@
4|Me gusta recibidos: jovenes vs mayores de 35
SELECT grupo_edad,SUM(likes_recd) AS me_gusta_recibidos FROM (SELECT CASE WHEN age BETWEEN 13 AND 25 THEN '13-25 anos' WHEN age>35 THEN 'Mayores de 35 anos' END AS grupo_edad,likes_recd FROM fb_jhaelguevara WHERE age BETWEEN 13 AND 25 OR age>35) t GROUP BY grupo_edad;
@@
5|Usuarios por mes de cumpleanios
SELECT month AS mes_cumpleanos,COUNT(*) AS usuarios FROM fb_jhaelguevara GROUP BY month ORDER BY month;
@@
6|Jovenes: celular vs computadora
SELECT SUM(mlikes) AS me_gusta_celular,SUM(wlikes) AS me_gusta_web FROM fb_jhaelguevara WHERE age BETWEEN 13 AND 25;
@@
7|Adultos: celular vs computadora
SELECT SUM(mlikes) AS me_gusta_celular,SUM(wlikes) AS me_gusta_web FROM fb_jhaelguevara WHERE age>25;
'@
$Q17=Catalog @'
1|Ingreso total de ventas validas
SELECT CAST(ROUND(SUM(Quantity*UnitPrice),2) AS DECIMAL(18,2)) ingreso_total FROM tec_jhaelguevara WHERE Quantity>0 AND UnitPrice>0 AND CustomerID IS NOT NULL;
@@
2|Diez productos mas vendidos por cantidad
SELECT Description,SUM(CAST(Quantity AS INT)) unidades_vendidas,COUNT(DISTINCT InvoiceNo) pedidos_con_producto FROM tec_jhaelguevara WHERE CAST(Quantity AS INT)>0 GROUP BY Description ORDER BY unidades_vendidas DESC LIMIT 10;
@@
3|Clientes unicos y porcentaje por pais
WITH p AS (SELECT Country,COUNT(DISTINCT CustomerID) clientes FROM tec_jhaelguevara WHERE CustomerID IS NOT NULL GROUP BY Country) SELECT Country,clientes,ROUND(clientes*100.0/SUM(clientes) OVER(),2) porcentaje FROM p ORDER BY clientes DESC;
@@
4|Ticket promedio por orden
SELECT CAST(ROUND(AVG(total_orden),2) AS DECIMAL(18,2)) ticket_promedio FROM (SELECT InvoiceNo,SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))) total_orden FROM tec_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY InvoiceNo) t;
@@
5|Mediana del ticket
WITH t AS (SELECT InvoiceNo,SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))) total_orden FROM tec_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY InvoiceNo), r AS (SELECT total_orden,ROW_NUMBER() OVER(ORDER BY total_orden) rn,COUNT(*) OVER() n FROM t) SELECT CAST(ROUND(AVG(total_orden),2) AS DECIMAL(18,2)) mediana_ticket FROM r WHERE rn IN (CAST(FLOOR((n+1)/2.0) AS BIGINT),CAST(FLOOR((n+2)/2.0) AS BIGINT));
@@
6|Evolucion mensual de ventas
WITH f AS (SELECT InvoiceDate fecha,InvoiceNo,Quantity q,UnitPrice p FROM tec_jhaelguevara WHERE Quantity>0 AND UnitPrice>0) SELECT YEAR(fecha) anio,MONTH(fecha) mes,COUNT(DISTINCT InvoiceNo) pedidos,CAST(ROUND(SUM(q*p),2) AS DECIMAL(18,2)) ingresos FROM f GROUP BY YEAR(fecha),MONTH(fecha) ORDER BY anio,mes;
@@
7|Tasa de devolucion por producto
SELECT Description,SUM(CASE WHEN Quantity<0 OR InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END) devoluciones,SUM(CASE WHEN Quantity>0 THEN 1 ELSE 0 END) ventas_validas,ROUND(100.0*SUM(CASE WHEN Quantity<0 OR InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END)/COUNT(*),2) tasa_devolucion_pct FROM tec_jhaelguevara WHERE CustomerID IS NOT NULL GROUP BY Description HAVING COUNT(*)>=10 ORDER BY tasa_devolucion_pct DESC LIMIT 15;
@@
8|Pedidos, ingresos y ticket por hora
WITH f AS (SELECT InvoiceDate fecha,InvoiceNo,Quantity q,UnitPrice p FROM tec_jhaelguevara WHERE Quantity>0 AND UnitPrice>0) SELECT HOUR(fecha) hora,COUNT(DISTINCT InvoiceNo) pedidos,CAST(ROUND(SUM(q*p),2) AS DECIMAL(18,2)) ingresos,CAST(ROUND(AVG(q*p),2) AS DECIMAL(18,2)) ticket_promedio FROM f GROUP BY HOUR(fecha) ORDER BY hora;
@@
9|Estacionalidad de productos
WITH m AS (SELECT Description,MONTH(InvoiceDate) mes,SUM(Quantity) unidades_mes FROM tec_jhaelguevara WHERE Quantity>0 GROUP BY Description,MONTH(InvoiceDate) HAVING SUM(Quantity)>50) SELECT Description,mes,unidades_mes,ROUND(100.0*unidades_mes/SUM(unidades_mes) OVER(PARTITION BY Description),2) distribucion_pct FROM m ORDER BY Description,mes LIMIT 30;
@@
10|Score de margen implicito por producto
SELECT Description,CAST(ROUND(AVG(CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) precio_promedio,COUNT(DISTINCT InvoiceNo) pedidos_con_producto,CAST(ROUND(AVG(CAST(UnitPrice AS DECIMAL(12,2)))*COUNT(DISTINCT InvoiceNo),2) AS DECIMAL(18,2)) score_margen_proxy FROM tec_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY Description HAVING COUNT(DISTINCT InvoiceNo)>=5 ORDER BY score_margen_proxy DESC LIMIT 20;
@@
11|Clientes registrados vs anonimos
SELECT CASE WHEN CustomerID IS NULL THEN 'Anonimo' ELSE 'Registrado' END tipo_cliente,COUNT(DISTINCT InvoiceNo) pedidos,CAST(ROUND(AVG(Quantity*UnitPrice),2) AS DECIMAL(18,2)) ticket_promedio,CAST(ROUND(SUM(Quantity*UnitPrice),2) AS DECIMAL(18,2)) revenue_total FROM tec_jhaelguevara WHERE Quantity>0 AND UnitPrice>0 GROUP BY CASE WHEN CustomerID IS NULL THEN 'Anonimo' ELSE 'Registrado' END;
@@
12|Tasa de cancelacion por pais
SELECT Country,SUM(CASE WHEN CAST(Quantity AS INT)<0 OR InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END) cancelaciones,SUM(CASE WHEN CAST(Quantity AS INT)>0 THEN 1 ELSE 0 END) ventas_validas,ROUND(100.0*SUM(CASE WHEN CAST(Quantity AS INT)<0 OR InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END)/COUNT(*),2) tasa_cancelacion_pct FROM tec_jhaelguevara GROUP BY Country HAVING COUNT(*)>=50 ORDER BY tasa_cancelacion_pct DESC;
'@
$Q18=Catalog @'
1|Total de registros
SELECT COUNT(*) total_registros FROM data3_jhaelguevara;
@@
2|Facturas unicas
SELECT COUNT(DISTINCT InvoiceNo) total_facturas FROM data3_jhaelguevara;
@@
3|Clientes unicos
SELECT COUNT(DISTINCT CustomerID) total_clientes FROM data3_jhaelguevara WHERE CustomerID IS NOT NULL AND CustomerID<>'';
@@
4|Ingreso total de ventas validas
SELECT CAST(ROUND(SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) ingreso_total FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0;
@@
5|Ventas totales por pais
SELECT Country,CAST(ROUND(SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) ventas_totales FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY Country ORDER BY ventas_totales DESC;
@@
6|Diez paises con mas facturas
SELECT Country,COUNT(DISTINCT InvoiceNo) total_facturas FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY Country ORDER BY total_facturas DESC LIMIT 10;
@@
7|Diez productos mas vendidos por cantidad
SELECT StockCode,Description,SUM(CAST(Quantity AS INT)) cantidad_vendida FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY StockCode,Description ORDER BY cantidad_vendida DESC LIMIT 10;
@@
8|Diez productos con mas ingresos
SELECT StockCode,Description,CAST(ROUND(SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) ingreso_producto FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY StockCode,Description ORDER BY ingreso_producto DESC LIMIT 10;
@@
9|Clientes que mas compraron por valor
SELECT CustomerID,CAST(ROUND(SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) total_comprado FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 AND CustomerID IS NOT NULL AND CustomerID<>'' GROUP BY CustomerID ORDER BY total_comprado DESC LIMIT 10;
@@
10|Ticket promedio por factura
SELECT CAST(ROUND(AVG(total_factura),2) AS DECIMAL(18,2)) ticket_promedio FROM (SELECT InvoiceNo,SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))) total_factura FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY InvoiceNo) t;
@@
11|Diez facturas con mayor monto
SELECT InvoiceNo,CAST(ROUND(SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) total_factura FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY InvoiceNo ORDER BY total_factura DESC LIMIT 10;
@@
12|Promedio de unidades por factura
SELECT CAST(ROUND(AVG(total_productos),2) AS DECIMAL(18,2)) promedio_productos_por_factura FROM (SELECT InvoiceNo,SUM(CAST(Quantity AS INT)) total_productos FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY InvoiceNo) t;
@@
13|Diez productos con precio maximo mas alto
SELECT StockCode,Description,MAX(CAST(UnitPrice AS DECIMAL(12,2))) precio_maximo FROM data3_jhaelguevara WHERE CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY StockCode,Description ORDER BY precio_maximo DESC LIMIT 10;
@@
14|Diez productos con mayor precio promedio
SELECT StockCode,Description,CAST(ROUND(AVG(CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) precio_promedio FROM data3_jhaelguevara WHERE CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY StockCode,Description ORDER BY precio_promedio DESC LIMIT 10;
@@
15|Facturas por mes
WITH f AS (SELECT InvoiceNo,CAST(Quantity AS INT) q,CAST(UnitPrice AS DECIMAL(12,2)) p,MONTH(FROM_UNIXTIME(UNIX_TIMESTAMP(InvoiceDate,'dd/MM/yyyy H:mm'))) mes FROM data3_jhaelguevara) SELECT mes,COUNT(DISTINCT InvoiceNo) total_facturas FROM f WHERE q>0 AND p>0 GROUP BY mes ORDER BY mes;
@@
16|Ingreso total por mes
WITH f AS (SELECT CAST(Quantity AS INT) q,CAST(UnitPrice AS DECIMAL(12,2)) p,MONTH(FROM_UNIXTIME(UNIX_TIMESTAMP(InvoiceDate,'dd/MM/yyyy H:mm'))) mes FROM data3_jhaelguevara) SELECT mes,CAST(ROUND(SUM(q*p),2) AS DECIMAL(18,2)) ingreso_mensual FROM f WHERE q>0 AND p>0 GROUP BY mes ORDER BY mes;
@@
17|Ingreso por ano y mes
WITH f AS (SELECT CAST(Quantity AS INT) q,CAST(UnitPrice AS DECIMAL(12,2)) p,YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(InvoiceDate,'dd/MM/yyyy H:mm'))) anio,MONTH(FROM_UNIXTIME(UNIX_TIMESTAMP(InvoiceDate,'dd/MM/yyyy H:mm'))) mes FROM data3_jhaelguevara) SELECT anio,mes,CAST(ROUND(SUM(q*p),2) AS DECIMAL(18,2)) ingreso_total FROM f WHERE q>0 AND p>0 GROUP BY anio,mes ORDER BY anio,mes;
@@
18|Diez dias con mayores ventas
WITH f AS (SELECT TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(InvoiceDate,'dd/MM/yyyy H:mm'))) fecha,CAST(Quantity AS INT) q,CAST(UnitPrice AS DECIMAL(12,2)) p FROM data3_jhaelguevara) SELECT fecha,CAST(ROUND(SUM(q*p),2) AS DECIMAL(18,2)) ventas_dia FROM f WHERE q>0 AND p>0 GROUP BY fecha ORDER BY ventas_dia DESC LIMIT 10;
@@
19|Facturas por hora
WITH f AS (SELECT HOUR(FROM_UNIXTIME(UNIX_TIMESTAMP(InvoiceDate,'dd/MM/yyyy H:mm'))) hora,InvoiceNo,CAST(Quantity AS INT) q,CAST(UnitPrice AS DECIMAL(12,2)) p FROM data3_jhaelguevara) SELECT hora,COUNT(DISTINCT InvoiceNo) total_facturas FROM f WHERE q>0 AND p>0 GROUP BY hora ORDER BY total_facturas DESC;
@@
20|Cantidad de devoluciones o cancelaciones
SELECT COUNT(*) total_devoluciones FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)<0 OR InvoiceNo LIKE 'C%';
@@
21|Valor total de devoluciones o cancelaciones
SELECT CAST(ROUND(SUM(ABS(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2)))),2) AS DECIMAL(18,2)) valor_total_devoluciones FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)<0 OR InvoiceNo LIKE 'C%';
@@
22|Diez productos con mas unidades devueltas
SELECT StockCode,Description,SUM(ABS(CAST(Quantity AS INT))) cantidad_devuelta FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)<0 OR InvoiceNo LIKE 'C%' GROUP BY StockCode,Description ORDER BY cantidad_devuelta DESC LIMIT 10;
@@
23|Clientes con mas valor de devoluciones
SELECT CustomerID,COUNT(*) total_registros_devolucion,CAST(ROUND(SUM(ABS(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2)))),2) AS DECIMAL(18,2)) valor_devoluciones FROM data3_jhaelguevara WHERE (CAST(Quantity AS INT)<0 OR InvoiceNo LIKE 'C%') AND CustomerID IS NOT NULL AND CustomerID<>'' GROUP BY CustomerID ORDER BY valor_devoluciones DESC LIMIT 10;
@@
24|Paises con mas valor de devoluciones
SELECT Country,CAST(ROUND(SUM(ABS(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2)))),2) AS DECIMAL(18,2)) valor_devoluciones FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)<0 OR InvoiceNo LIKE 'C%' GROUP BY Country ORDER BY valor_devoluciones DESC LIMIT 10;
@@
25|Ingreso neto por pais
SELECT Country,CAST(ROUND(SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) ingreso_neto FROM data3_jhaelguevara WHERE CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY Country ORDER BY ingreso_neto DESC;
@@
26|Clientes con mas frecuencia de compra
SELECT CustomerID,COUNT(DISTINCT InvoiceNo) total_compras FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 AND CustomerID IS NOT NULL AND CustomerID<>'' GROUP BY CustomerID ORDER BY total_compras DESC LIMIT 10;
@@
27|Gasto promedio por cliente
SELECT CAST(ROUND(AVG(total_cliente),2) AS DECIMAL(18,2)) gasto_promedio_cliente FROM (SELECT CustomerID,SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))) total_cliente FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 AND CustomerID IS NOT NULL AND CustomerID<>'' GROUP BY CustomerID) t;
@@
28|Clientes con alta frecuencia y alto valor
SELECT CustomerID,COUNT(DISTINCT InvoiceNo) frecuencia_compra,CAST(ROUND(SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) monto_total FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 AND CustomerID IS NOT NULL AND CustomerID<>'' GROUP BY CustomerID HAVING COUNT(DISTINCT InvoiceNo)>=5 AND SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2)))>=1000 ORDER BY monto_total DESC;
@@
29|Productos de alto volumen y bajo precio
SELECT StockCode,Description,SUM(CAST(Quantity AS INT)) cantidad_vendida,CAST(ROUND(AVG(CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) precio_promedio,CAST(ROUND(SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) ingreso_total FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY StockCode,Description HAVING SUM(CAST(Quantity AS INT))>=1000 AND AVG(CAST(UnitPrice AS DECIMAL(12,2)))<2 ORDER BY cantidad_vendida DESC LIMIT 20;
@@
30|Productos de bajo volumen y alto ingreso
SELECT StockCode,Description,SUM(CAST(Quantity AS INT)) cantidad_vendida,CAST(ROUND(SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) ingreso_total FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY StockCode,Description HAVING SUM(CAST(Quantity AS INT))<100 AND SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2)))>1000 ORDER BY ingreso_total DESC;
@@
31|Clientes por pais ordenados por monto
SELECT Country,CustomerID,CAST(ROUND(SUM(CAST(Quantity AS INT)*CAST(UnitPrice AS DECIMAL(12,2))),2) AS DECIMAL(18,2)) monto_total FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 AND CustomerID IS NOT NULL AND CustomerID<>'' GROUP BY Country,CustomerID ORDER BY Country,monto_total DESC;
@@
32|Clientes unicos por pais
SELECT Country,COUNT(DISTINCT CustomerID) clientes_unicos FROM data3_jhaelguevara WHERE CustomerID IS NOT NULL AND CustomerID<>'' GROUP BY Country ORDER BY clientes_unicos DESC;
@@
33|Promedio de unidades vendidas por producto
SELECT CAST(ROUND(AVG(cantidad_total),2) AS DECIMAL(18,2)) promedio_unidades_por_producto FROM (SELECT StockCode,SUM(CAST(Quantity AS INT)) cantidad_total FROM data3_jhaelguevara WHERE CAST(Quantity AS INT)>0 AND CAST(UnitPrice AS DECIMAL(12,2))>0 GROUP BY StockCode) t;
@@
34|Productos sin descripcion
SELECT StockCode,COUNT(*) registros_sin_descripcion FROM data3_jhaelguevara WHERE Description IS NULL OR Description='' GROUP BY StockCode ORDER BY registros_sin_descripcion DESC;
@@
35|Registros con precio unitario cero
SELECT InvoiceNo,StockCode,Description,Quantity,UnitPrice,CustomerID,Country FROM data3_jhaelguevara WHERE CAST(UnitPrice AS DECIMAL(12,2))=0 LIMIT 50;
'@

$ddl16=@'
CREATE DATABASE IF NOT EXISTS db_jhaelguevara;
CREATE TABLE IF NOT EXISTS db_jhaelguevara.fb_jhaelguevara(id INT,age INT,day INT,year INT,month INT,gender STRING,tenure INT,friends INT,friends_init INT,likes INT,likes_recd INT,mlikes INT,mlikes_rcd INT,wlikes INT,wlikes_rcd INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE;
'@
$ddl17=@'
CREATE DATABASE IF NOT EXISTS dbec_jhaelguevara;
CREATE TABLE IF NOT EXISTS dbec_jhaelguevara.tec_jhaelguevara(InvoiceNo STRING,StockCode STRING,Description STRING,Quantity INT,InvoiceDate TIMESTAMP,UnitPrice DOUBLE,CustomerID INT,Country STRING) STORED AS ORC;
'@
$stage17=@'
CREATE TABLE IF NOT EXISTS dbec_jhaelguevara.tec_jhaelguevara_stage(InvoiceNo STRING,StockCode STRING,Description STRING,Quantity STRING,InvoiceDate STRING,UnitPrice STRING,CustomerID STRING,Country STRING) ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES ("separatorChar"=",","quoteChar"="\"","escapeChar"="\\") STORED AS TEXTFILE TBLPROPERTIES ("skip.header.line.count"="1");
'@
$ddl18=@'
CREATE DATABASE IF NOT EXISTS db3_jhaelguevara;
CREATE TABLE IF NOT EXISTS db3_jhaelguevara.data3_jhaelguevara(InvoiceNo STRING,StockCode STRING,Description STRING,Quantity INT,InvoiceDate STRING,UnitPrice DECIMAL(10,2),CustomerID STRING,Country STRING) STORED AS ORC;
'@
$stage18=@'
CREATE TABLE IF NOT EXISTS db3_jhaelguevara.data3_jhaelguevara_stage(InvoiceNo STRING,StockCode STRING,Description STRING,Quantity STRING,InvoiceDate STRING,UnitPrice STRING,CustomerID STRING,Country STRING) ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES ("separatorChar"=";","quoteChar"="\"","escapeChar"="\\") STORED AS TEXTFILE TBLPROPERTIES ("skip.header.line.count"="1");
'@
$defs=@{
'16'=@{Db='db_jhaelguevara';Table='fb_jhaelguevara';Location='/user/hive/warehouse/db_jhaelguevara.db/fb_jhaelguevara';Source='CSV\pseudo_facebook_JhaelGuevara.csv';File='pseudo_facebook_JhaelGuevara.csv';Hdfs='/user/hive/warehouse/pseudo_facebook_JhaelGuevara.csv';Ddl=$ddl16}
'17'=@{Db='dbec_jhaelguevara';Table='tec_jhaelguevara';Location='/user/hive/warehouse/dbec_jhaelguevara.db/tec_jhaelguevara';Source='CSV\data_JhaelGuevara.csv';File='data_JhaelGuevara.csv';Hdfs='/user/hive/warehouse/data_JhaelGuevara.csv';Ddl=$ddl17;Stage=$stage17}
'18'=@{Db='db3_jhaelguevara';Table='data3_jhaelguevara';Location='/user/hive/warehouse/db3_jhaelguevara.db/data3_jhaelguevara';Source='CSV\data3_JhaelGuevara_hive.csv';File='data3_JhaelGuevara_hive.csv';Ddl=$ddl18;Stage=$stage18}
}
$queries=@{'16'=$Q16;'17'=$Q17;'18'=$Q18}

Write-Host 'Iniciando Hive/YARN...' -ForegroundColor Cyan
Invoke-Docker (@('compose','up','-d')+@('hive-server','yarn-nodemanager','datanode1','datanode2','datanode3'))
Wait-HiveServer
while($true){
 Clear-Host
 Write-Host 'CONSULTAS APACHE HIVE' -ForegroundColor Cyan
 Write-Host '1. LI16 - Facebook';Write-Host '2. LI17 - Online Retail';Write-Host '3. LI18 - Online Retail (;)' ;Write-Host 'Q. Salir'
 $pick=(Read-Host 'Elige practica').Trim().ToUpperInvariant()
 if($pick -eq 'Q'){break}
 if($pick -eq '1'){$k='16'}elseif($pick -eq '2'){$k='17'}elseif($pick -eq '3'){$k='18'}else{Write-Host 'Opcion no valida' -ForegroundColor Yellow;Start-Sleep 1;continue}
 $d=$defs[$k];$src=Join-Path $Root $d.Source
 try{
  if(-not(Test-Path $src)){throw "Falta el CSV $src"}
  Hive $d.Db $d.Ddl
  if(-not(Test-HdfsTableData $d.Location)){
   if($k -eq '18'){
    Hive $d.Db "DROP TABLE IF EXISTS $($d.Db).$($d.Table)_stage; $($d.Stage)"
    Invoke-Docker @('compose','cp',$src,"hive-server:/tmp/$($d.File)")
    Hive $d.Db "LOAD DATA LOCAL INPATH '/tmp/$($d.File)' INTO TABLE $($d.Db).$($d.Table)_stage; INSERT OVERWRITE TABLE $($d.Db).$($d.Table) SELECT InvoiceNo,StockCode,Description,CAST(Quantity AS INT),InvoiceDate,CAST(UnitPrice AS DECIMAL(10,2)),NULLIF(CustomerID,''),Country FROM $($d.Db).$($d.Table)_stage; DROP TABLE $($d.Db).$($d.Table)_stage;"
   }elseif($k -eq '17'){
    Hive $d.Db "DROP TABLE IF EXISTS $($d.Db).$($d.Table)_stage; $($d.Stage)"
    Invoke-Docker @('compose','cp',$src,"yarn-resourcemanager:/tmp/$($d.File)")
    Invoke-Docker @('compose','exec','-T','yarn-resourcemanager','hdfs','dfs','-mkdir','-p','/user/hive/warehouse')
    Invoke-Docker @('compose','exec','-T','yarn-resourcemanager','hdfs','dfs','-put','-f',"/tmp/$($d.File)",'/user/hive/warehouse/')
    Hive $d.Db "LOAD DATA INPATH '$($d.Hdfs)' INTO TABLE $($d.Db).$($d.Table)_stage; INSERT OVERWRITE TABLE $($d.Db).$($d.Table) SELECT InvoiceNo,StockCode,Description,CAST(Quantity AS INT),CAST(FROM_UNIXTIME(UNIX_TIMESTAMP(InvoiceDate,'M/d/yyyy H:mm')) AS TIMESTAMP),CAST(UnitPrice AS DOUBLE),CAST(NULLIF(CustomerID,'') AS INT),Country FROM $($d.Db).$($d.Table)_stage; DROP TABLE $($d.Db).$($d.Table)_stage;"
   }else{
    Invoke-Docker @('compose','cp',$src,"yarn-resourcemanager:/tmp/$($d.File)")
    Invoke-Docker @('compose','exec','-T','yarn-resourcemanager','hdfs','dfs','-mkdir','-p','/user/hive/warehouse')
    Invoke-Docker @('compose','exec','-T','yarn-resourcemanager','hdfs','dfs','-put','-f',"/tmp/$($d.File)",'/user/hive/warehouse/')
    Hive $d.Db "LOAD DATA INPATH '$($d.Hdfs)' INTO TABLE $($d.Db).$($d.Table);"
   }
   Write-Host 'CSV cargado.' -ForegroundColor Green
  }else{Write-Host 'La tabla ya contiene archivos; se conserva sin volver a cargar.' -ForegroundColor Green}
 }catch{Write-Host $_ -ForegroundColor Red;Read-Host 'Enter para volver'|Out-Null;continue}
 while($true){
  Clear-Host
  Write-Host "LI$k | $($d.Db)" -ForegroundColor Cyan
  foreach($q in $queries[$k]){Write-Host ("{0,2}. {1}" -f $q.Number,$q.Name)}
  Write-Host 'P. Ejecutar consulta propia'
  Write-Host 'B. Volver al menu'
  $sel=(Read-Host 'Escribe el numero o parte del nombre').Trim()
  if($sel.ToUpperInvariant() -eq 'B'){break}
  if($sel.ToUpperInvariant() -eq 'P'){
   Write-Host 'Escribe tu SQL. Termina la ultima linea con punto y coma (;).'
   $sqlLines=@()
   do{$line=Read-Host 'SQL';if($line){$sqlLines+= $line}}while(-not ($line.TrimEnd().EndsWith(';')))
   $customSql=$sqlLines -join [Environment]::NewLine
   Clear-Host
   Write-Host "LI$k | Consulta propia" -ForegroundColor Cyan
   Write-Host '';Write-Host 'SQL:' -ForegroundColor Yellow;Write-Host $customSql
   Write-Host '';Write-Host 'SALIDA DE HIVE:' -ForegroundColor Yellow
   try{Hive $d.Db $customSql}catch{Write-Host $_ -ForegroundColor Red}
   Write-Host '';Read-Host 'Enter para elegir otra consulta'|Out-Null
   continue
  }
  $found=@($queries[$k]|Where-Object{"$($_.Number)" -eq $sel -or $_.Name.IndexOf($sel,[StringComparison]::OrdinalIgnoreCase)-ge 0})
  if($found.Count -ne 1){Write-Host 'No es una opcion unica; prueba con el numero exacto.' -ForegroundColor Yellow;Read-Host 'Enter'|Out-Null;continue}
  $q=$found[0]
  Clear-Host
  Write-Host ("LI{0} | Consulta {1}: {2}" -f $k,$q.Number,$q.Name) -ForegroundColor Cyan
  Write-Host '';Write-Host 'SQL:' -ForegroundColor Yellow;Write-Host $q.Sql
  Write-Host '';Write-Host 'SALIDA DE HIVE:' -ForegroundColor Yellow
  try{Hive $d.Db $q.Sql}catch{Write-Host $_ -ForegroundColor Red}
  Write-Host '';Read-Host 'Enter para elegir otra consulta'|Out-Null
 }
}
Write-Host 'Menu cerrado.'

