@echo off
setlocal
set "SELF=%~f0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:SELF); $m='###PS###'; & ([scriptblock]::Create($s.Substring($s.LastIndexOf($m)+$m.Length)))"
exit /b
###PS###
$ErrorActionPreference='Stop'
Set-Location (Split-Path -Parent $env:SELF)
$settings='SET mapreduce.task.io.sort.mb=10; SET hive.vectorized.execution.enabled=false; SET hive.vectorized.execution.reduce.enabled=false; '
$md=Join-Path $env:USERPROFILE 'Downloads\LI19 - Practica con Apache Hive (4).md'
$rows=Get-Content -LiteralPath $md | Where-Object { $_ -match '^\|\s*\d+\s*\|' } | Select-Object -First 25
while($true){
 Clear-Host; Write-Host 'LI19 - Menu de exposicion' -ForegroundColor Cyan
 Write-Host '1 Iniciar servicios    2 Ver contenedores    0 Salir'
 foreach($line in $rows){$c=$line.Trim('|').Split('|'); $n=[int]$c[0].Trim(); $q=$c[1].Trim() -replace '\*\*','' -replace '\\',''; Write-Host ("C{0} {1}" -f $n,$q)}
 $op=(Read-Host 'Opcion').Trim().ToUpper(); if($op -eq '0'){break}
 if($op -eq '1'){docker compose up -d; docker compose ps; [void](Read-Host 'Enter para menu'); continue}
 if($op -eq '2'){docker compose ps; [void](Read-Host 'Enter para menu'); continue}
 if($op -match '^C(\d+)$'){
  $n=[int]$Matches[1]; if($n -lt 1 -or $n -gt $rows.Count){Write-Host 'Opcion no valida';[void](Read-Host);continue}
  $c=$rows[$n-1].Trim('|').Split('|'); $question=$c[1].Trim() -replace '\*\*','' -replace '\\',''; $sql=$c[2].Trim() -replace '\\([_*`<>+=])','$1'; $sql=$sql -replace 'siem_event_logs','db4_john.data4_john'
  $sql=$sql -replace 'Timestamp','`timestamp`' -replace 'MitreTechniques','mitretechniques' -replace 'Category','category' -replace 'IncidentId','incidentid' -replace 'AlertId','alertid' -replace 'IncidentGrade','incidentgrade' -replace 'SuspicionLevel','suspicionlevel' -replace 'LastVerdict','lastverdict' -replace 'EntityType','entitytype' -replace 'EvidenceRole','evidencerole' -replace 'DeviceId','deviceid' -replace 'DeviceName','devicename' -replace 'IpAddress','ipaddress' -replace 'DetectorId','detectorid' -replace 'AlertTitle','alerttitle' -replace 'AccountName','accountname' -replace 'AccountUpn','accountupn'
  $sql=$sql -replace 'to_date\(from_unixtime\(unix_timestamp\(`timestamp`, "yyyy-MM-dd''T''HH:mm:ss.SSS''Z''"\)\)\)','substr(`timestamp`,1,10)'
  $sql=$sql -replace 'hour\(from_unixtime\(unix_timestamp\(`timestamp`, "yyyy-MM-dd''T''HH:mm:ss.SSS''Z''"\)\)\)','CAST(substr(`timestamp`,12,2) AS INT)'
  Write-Host $question -ForegroundColor Yellow; Write-Host "`nSQL:`n$sql" -ForegroundColor Cyan; [void](Read-Host 'Enter para ejecutar la consulta')
  docker compose exec -T hive-server beeline -u jdbc:hive2://localhost:10000 -n root --silent=true --outputformat=table -e ($settings+$sql)
 } else {Write-Host 'Opcion invalida'}
 [void](Read-Host 'Enter para volver al menu')
}
