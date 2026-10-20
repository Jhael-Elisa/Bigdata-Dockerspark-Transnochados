# Guion de exposición LG15 — Persona 2

## Tu responsabilidad

Explicar cómo se realizó la prueba de falla con el dataset de 1 GB: registrar el estado inicial, detener el DataNode 2, observar la detección y comprobar que el archivo sigue disponible.

Duración aproximada: 5 a 7 minutos.

## Preparación en VS Code

Abre estos archivos en este orden:

1. scripts/lg15/03_estado.sh
2. grupo02/resultados/1GB_antes_fsck.txt
3. scripts/lg15/04_fallo.sh
4. grupo02/resultados/1GB_falla_datanode2_monitoreo.txt
5. grupo02/resultados/1GB_durante_fsck.txt
6. scripts/lg15/05_leer.sh
7. grupo02/resultados/1GB_lectura_durante_falla.txt

En VS Code, Ctrl + G permite ir a una línea. Los números indicados corresponden a los archivos revisados; si se editan, busca el texto señalado.

Las evidencias guardadas corresponden al experimento anterior. Los comandos que ejecutes en la terminal muestran el estado actual y sus resultados pueden ser diferentes.

## 1. Introducción al procedimiento

### Qué mostrar

La carpeta scripts/lg15/ en el explorador de VS Code.

### Qué decir

“Después de configurar el clúster, realizamos el experimento en tres momentos: antes, durante y después de la falla.

Primero cargamos el dataset de 1 GB dentro de /grupo02/. Registramos dónde estaban sus bloques y cuántas réplicas tenían. Luego apagamos el DataNode 2, observamos cómo HDFS detectaba la caída y verificamos si el archivo seguía siendo legible.

Voy a mostrar los comandos utilizados y las evidencias guardadas de esa prueba.”

### Secuencia del trabajo

1. 01_preparar.sh: crear las carpetas del grupo.
2. 02_cargar.sh: generar y cargar el dataset, y guardar su MD5 original.
3. 03_estado.sh: registrar nodos, bloques y réplicas.
4. 04_fallo.sh: detener un DataNode y monitorear la recuperación.
5. 05_leer.sh: leer el archivo completo y comparar su MD5.
6. 06_restaurar.sh: volver a encender el nodo.
7. 07_guardar_resultados.sh: guardar los resultados en HDFS.

## 2. Cómo registramos el estado inicial

### Archivo y líneas

Abre scripts/lg15/03_estado.sh y señala las líneas 13 a 15.

```bash
hdfs_cmd dfsadmin -report 2> /dev/null | tee "$REPORTE"
hdfs_cmd fsck "${RUTA}" -files -blocks -locations 2> /dev/null | tee "$FSCK"
distribucion_bloques "$FSCK" | tee "${DIR_RESULTADOS}/${ETIQUETA}_${FASE}_distribucion.txt"
```

### Qué decir

“Este script registra el estado del sistema. El primer comando consulta los DataNodes y su capacidad. El segundo revisa el archivo y muestra sus bloques, réplicas y ubicaciones. El tercero resume cómo están distribuidas las copias entre los nodos.

Utilizamos tee para mostrar la salida en pantalla y, al mismo tiempo, guardarla como evidencia.”

### Qué significan los comandos

- dfsadmin -report: informa sobre los DataNodes y el almacenamiento.
- fsck: revisa el estado del archivo y sus bloques.
- -files: muestra los archivos revisados.
- -blocks: muestra información de los bloques.
- -locations: muestra dónde están las réplicas.
- tee: muestra y guarda la salida.
- 2> /dev/null: descarta la salida de errores en esa llamada.

## 3. Estado del archivo antes de la falla

### Archivo y primera parte que debes señalar

Abre grupo02/resultados/1GB_antes_fsck.txt. Ve a la línea 5:

```text
1073741824 bytes, replicated: replication=2, 8 block(s): OK
```

### Qué decir

“Aquí comprobamos que el archivo tenía 1.073.741.824 bytes, estaba configurado con replicación dos y tenía ocho bloques. Cada bloque es de 128 MiB. En el trabajo llamamos a este dataset de 1 GB; su tamaño exacto equivale a 1 GiB.”

### Ejemplo de un bloque: línea 8

Busca el bloque blk_1073742101. Señala Live_repl=2 y sus dos ubicaciones:

```text
172.20.0.7:9866
172.20.0.8:9866
```

### Qué decir

“Tomemos este bloque como ejemplo. Tiene dos réplicas vivas: una en el DataNode 1 y otra en el DataNode 2. Esto será importante porque vamos a apagar el nodo 2 y revisar qué pasa con este mismo bloque.”

Las IP corresponden al experimento guardado. Pueden cambiar al recrear los contenedores.

### Resumen del estado: líneas 25 a 33

Señala:

```text
Total blocks (validated): 8
Under-replicated blocks: 0
Average block replication: 2.0
Missing blocks: 0
Corrupt blocks: 0
```

### Qué decir

“Antes de la falla, los ocho bloques estaban disponibles, cada uno tenía sus dos copias y no había bloques perdidos ni corruptos. Había dieciséis copias de bloques en total: ocho por dos.”

## 4. Cómo simulamos la falla

### Archivo y líneas

Abre scripts/lg15/04_fallo.sh. Señala las líneas 28 a 31, especialmente:

```bash
docker compose stop "${DN}"
```

### Qué decir

“Para simular la falla detuvimos únicamente el servicio del DataNode 2. No apagamos todo el clúster. El comando ejecutado para este experimento fue docker compose stop datanode2.”

### Comando de la prueba

```powershell
docker compose stop datanode2
```

Mostrar el código no requiere ejecutar nuevamente la falla. Más abajo está la secuencia para una demostración en vivo.

## 5. Comprobación de acceso inmediatamente después

### Archivo y líneas

En scripts/lg15/04_fallo.sh señala las líneas 34 a 36:

```bash
nn hdfs dfs -head "${RUTA}" 2> /dev/null | head -3
```

### Qué decir

“Inmediatamente después intentamos leer las primeras líneas del archivo. Esto nos permitió comprobar que seguía siendo accesible, porque HDFS podía utilizar las réplicas de los nodos que continuaban activos.

Esta lectura inicial solo revisa una parte del contenido. Más adelante verificamos el archivo completo.”

### Concepto que debes recordar

- Leer con -head muestra el comienzo del archivo.
- Leer con -cat y calcular el MD5 permite comparar el contenido completo con el original.

## 6. Cuándo detectó HDFS la caída

### Archivo

Abre grupo02/resultados/1GB_falla_datanode2_monitoreo.txt. Muéstralo completo.

### Encabezados

```text
TIEMPO    VIVOS    MUERTOS    SUBREPLICADOS_DATASET
```

### Qué decir

“Este registro muestra el tiempo desde la detención, la cantidad de nodos vivos, los muertos y los bloques subreplicados del dataset.”

### Primero señala +84s y +90s: líneas 9 a 11

```text
+84s      3       0         0
+90s      2       1         0
El NameNode declaró MUERTO a datanode2 (+90s)
```

### Qué decir

“Aunque el contenedor ya estaba apagado, hasta los 84 segundos el NameNode todavía reportaba tres nodos vivos. Esto ocurre porque espera un tiempo sin recibir heartbeats antes de declarar muerto a un nodo.

A los 90 segundos el reporte cambió a dos vivos y uno muerto.”

### Después señala +113s y +116s: líneas 14 a 16

```text
+113s     2       1         4
+116s     2       1         0
Todos los bloques del dataset vuelven a tener sus réplicas (+116s)
```

### Qué decir

“A los 113 segundos registramos cuatro bloques subreplicados. A los 116 segundos volvieron a cero, porque HDFS había reconstruido las copias faltantes.”

### Si preguntan por qué a los 90 segundos hay cero subreplicados

“El script consulta sucesivamente distintas métricas, y sus actualizaciones y lecturas no son una fotografía simultánea. El monitoreo registró primero al nodo muerto y después los cuatro bloques subreplicados.”

### Qué es un heartbeat

Una señal periódica que el DataNode envía al NameNode para indicar que sigue activo. En esta configuración se envía cada tres segundos; el tiempo para declarar muerto al nodo fue aproximadamente 90 segundos.

## 7. Qué ocurrió con los bloques durante la falla

### Archivo y primeras líneas

Abre grupo02/resultados/1GB_durante_fsck.txt. Señala las líneas 3 a 6:

```text
Target Replicas is 2 but found 1 live replica(s)
```

### Qué decir

“Aquí HDFS indica que esperaba dos copias, pero encontró solamente una copia viva en cada uno de estos cuatro bloques. Eso significa que estaban subreplicados.”

### Compara el mismo bloque: línea 9

Busca blk_1073742101. Ahora muestra:

```text
Live_repl=1
```

Su única ubicación disponible es 172.20.0.7.

### Qué decir

“Este es el mismo bloque que antes tenía una copia en los nodos 1 y 2. Después de la caída, conserva una copia disponible en el nodo 1. Por eso todavía puede leerse.”

### Resumen: líneas 29 a 34

```text
Under-replicated blocks: 4
Average block replication: 1.5
Missing blocks: 0
Corrupt blocks: 0
```

### Qué decir

“Cuatro bloques quedaron con una copia y los otros cuatro conservaron dos. Por eso teníamos doce copias disponibles entre ocho bloques: doce dividido entre ocho da una replicación promedio de 1,5.

No había bloques perdidos ni corruptos. El archivo seguía disponible, aunque tenía menos protección frente a otra falla.”

### Cálculo para explicar si te preguntan

```text
4 bloques × 1 copia = 4 copias
4 bloques × 2 copias = 8 copias
Total = 12 copias disponibles
Promedio = 12 / 8 = 1,5
```

### Por qué aparece HEALTHY

El archivo conserva al menos una copia disponible de cada bloque. Estar subreplicado no significa que el archivo esté perdido o corrupto.

## 8. Cómo verificamos el archivo completo

### Archivo y líneas

Abre scripts/lg15/05_leer.sh. Señala las líneas 14 a 18. El comando central es:

```bash
hdfs dfs -cat RUTA_DEL_ARCHIVO | md5sum
```

### Qué decir

“Para verificar todo el contenido, leímos el archivo completo con hdfs dfs -cat y calculamos el MD5 de lo leído. Luego lo comparamos con el MD5 calculado antes de cargar el archivo.”

### Evidencia que debes abrir

grupo02/resultados/1GB_lectura_durante_falla.txt

```text
MD5 original (al cargar): 4531aba60b6563905faaf534e7146250
MD5 leído desde HDFS:     4531aba60b6563905faaf534e7146250
Tiempo de lectura:        4 s
RESULTADO: el archivo se leyó COMPLETO y sin corrupción
```

### Qué decir

“Los valores coincidieron y la lectura completa tardó cuatro segundos. Esta evidencia corresponde a una lectura con el DataNode 2 todavía detenido.”

## 9. Cierre y paso a la persona 3

### Qué decir

“Con esto comprobamos que el archivo seguía disponible durante la falla. Mi compañero explicará ahora la recuperación de las réplicas y la comparación con el dataset de 10 GB.”

## 10. Comandos para mostrar el estado actual en vivo

Ejecuta estos comandos en la terminal PowerShell de VS Code, dentro de la carpeta del proyecto. Ejecútalos de uno en uno.

### Ver los contenedores

```powershell
docker compose ps
```

Qué decir: “Este comando muestra cuáles contenedores están ejecutándose actualmente.”

### Consultar el estado de HDFS

```powershell
docker compose exec -T yarn-resourcemanager hdfs dfsadmin -report
```

Qué decir: “Aquí verificamos cuántos DataNodes están activos y el estado del almacenamiento.”

### Confirmar que el dataset existe

```powershell
docker compose exec -T yarn-resourcemanager hdfs dfs -ls /grupo02/dataset_1GB
```

Si la ruta no existe, continúa mostrando las evidencias guardadas. Levantar los contenedores no carga automáticamente los datasets de LG15.

Qué decir en ese caso: “Estos archivos muestran la prueba que realizamos anteriormente; los comandos de la terminal muestran el estado actual del entorno.”

### Revisar los bloques del dataset, si existe

```powershell
docker compose exec -T yarn-resourcemanager hdfs fsck /grupo02/dataset_1GB/dataset_grupo02_1GB -files -blocks -locations
```

Busca el número de bloques, Live_repl, Under-replicated blocks y Missing blocks.

### Mostrar las primeras líneas del dataset

```powershell
docker compose exec -T yarn-resourcemanager hdfs dfs -head /grupo02/dataset_1GB/dataset_grupo02_1GB
```

Esto demuestra acceso al comienzo del archivo. No sustituye la verificación completa con MD5.

## 11. Si deciden repetir la falla en vivo

### Comprobar las condiciones iniciales

Antes de detener el nodo, confirma:

- El dataset existe.
- Los tres DataNodes están activos.
- Cada bloque del dataset tiene dos réplicas disponibles.

Muestra primero el reporte y el fsck usando los comandos de la sección anterior.

### Detener solamente el DataNode 2

```powershell
docker compose stop datanode2
```

### Mostrar que el contenedor está detenido

```powershell
docker compose ps -a
```

### Intentar leer el comienzo del archivo

```powershell
docker compose exec -T yarn-resourcemanager hdfs dfs -head /grupo02/dataset_1GB/dataset_grupo02_1GB
```

La lectura puede tardar si el cliente intenta contactar primero al nodo detenido.

### Consultar la detección y los bloques

```powershell
docker compose exec -T yarn-resourcemanager hdfs dfsadmin -report
```

```powershell
docker compose exec -T yarn-resourcemanager hdfs fsck /grupo02/dataset_1GB/dataset_grupo02_1GB -files -blocks -locations
```

Consulta durante la demostración. La subreplicación puede durar poco y no aparecer justo cuando ejecutas fsck; las evidencias guardadas muestran el estado capturado en el experimento anterior.

### Lectura completa y cálculo del MD5

```powershell
docker compose exec -T yarn-resourcemanager bash -c 'set -o pipefail; hdfs dfs -cat /grupo02/dataset_1GB/dataset_grupo02_1GB | md5sum'
```

Compara el resultado con el MD5 original del dataset que esté cargado actualmente. El MD5 histórico solo sirve como referencia si es exactamente el mismo archivo.

### Restaurar el nodo al finalizar

```powershell
docker compose start datanode2
```

Después comprueba nuevamente que los tres DataNodes estén activos con dfsadmin -report.

Los tiempos, las IP y la cantidad de bloques afectados pueden cambiar en una nueva ejecución. No presentes los resultados históricos como resultados de la demostración actual.

## 12. Preguntas que debes poder responder

### ¿Cómo simularon la falla?

“Detuvimos únicamente el DataNode 2 con docker compose stop datanode2.”

### ¿Por qué no se detectó inmediatamente?

“El NameNode espera un tiempo sin recibir heartbeats para declarar muerto al nodo. En nuestra configuración fue aproximadamente 90 segundos.”

### ¿Qué significa subreplicado?

“El bloque tiene menos copias disponibles que las configuradas. Debía tener dos y temporalmente tenía una.”

### ¿Por qué el archivo seguía disponible?

“Porque cada bloque conservaba al menos una réplica en un DataNode activo.”

### ¿Por qué la replicación promedio fue 1,5?

“Había doce copias disponibles para ocho bloques. Doce dividido entre ocho es 1,5.”

### ¿Cómo comprobaron el contenido completo?

“Leímos el archivo con -cat, calculamos el MD5 y lo comparamos con el original. Los valores coincidieron.”

### ¿Quién ordena recuperar las copias?

“El NameNode identifica los bloques subreplicados y ordena la reconstrucción. Los DataNodes transfieren los bloques entre ellos.”

### ¿Qué demuestra detener un contenedor?

“Simula la falla de un DataNode. Como todos los contenedores están en una computadora, no demuestra tolerancia a la caída de esa computadora completa.”

## 13. Recordatorio rápido para tener al lado

1. Introducción: antes, durante y después.
2. 03_estado.sh: report y fsck, líneas 13 a 15.
3. Antes: ocho bloques, dos réplicas, cero perdidos.
4. Ejemplo: blk_1073742101 tenía copias en DN1 y DN2.
5. 04_fallo.sh: detener DN2, líneas 28 a 31.
6. Lectura inicial: -head, líneas 34 a 36.
7. Monitoreo: detección a los 90 s; cuatro subreplicados registrados a los 113 s; recuperación a los 116 s.
8. Durante: el mismo bloque tiene Live_repl=1 en DN1.
9. Archivo disponible: cero bloques perdidos y corruptos.
10. 05_leer.sh y evidencia: lectura completa y MD5 coincidente.
11. Dar la palabra a la persona 3.
