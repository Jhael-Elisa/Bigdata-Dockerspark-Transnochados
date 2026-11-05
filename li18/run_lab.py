from pathlib import Path
from docx import Document
import subprocess,json,datetime,textwrap,sys
sys.stdout.reconfigure(encoding='utf-8')
root=Path(__file__).parent; (root/'resultados').mkdir(exist_ok=True);(root/'evidencias').mkdir(exist_ok=True)
settings='SET mapreduce.task.io.sort.mb=10; SET hive.vectorized.execution.enabled=false; SET hive.vectorized.execution.reduce.enabled=false; '
def execute(sql):
    r=subprocess.run(['docker','compose','exec','-T','hive-server','beeline','-u','jdbc:hive2://localhost:10000','-n','root','--silent=true','--outputformat=tsv2','-e',settings+sql],capture_output=True,text=True,encoding='utf-8',errors='replace')
    if r.returncode or 'Error:' in r.stderr:raise RuntimeError(r.stderr[-3500:])
    return r.stdout.strip(),r.stderr
def save(name,question,sql,out):
    now=datetime.datetime.now().astimezone().isoformat(timespec='seconds')
    (root/'resultados'/f'{name}.tsv').write_text(out+'\n',encoding='utf-8')
    lines=out.splitlines(); shown=lines[:23]
    text=f'LI18 | Johnny Suarez Abasto | {question}\nFecha y hora del sistema: {now}\nMotor: Apache Hive 3.1.3 / Beeline / MapReduce local\n\nSQL EJECUTADO\n'+ '\n'.join(textwrap.wrap(sql,110,replace_whitespace=False))+'\n\nRESULTADO REAL DE HIVE\n'+'\n'.join(shown)
    if len(lines)>23:text+=f'\n\nVista inicial: 22 de {len(lines)-1} filas. Salida completa: {name}.tsv'
    text+='\n\nEstado: consulta finalizada sin errores.\n'
    (root/'resultados'/f'{name}.txt').write_text(text,encoding='utf-8')
    return now
setup="""CREATE DATABASE IF NOT EXISTS db3_john;
CREATE TABLE IF NOT EXISTS db3_john.data3_john_csv (
InvoiceNo STRING,StockCode STRING,Description STRING,Quantity STRING,
InvoiceDate STRING,UnitPrice STRING,CustomerID STRING,Country STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar'=',','quoteChar'='"','escapeChar'='\\\\')
STORED AS TEXTFILE;"""
out,_=execute(setup);save('00_base','Base de datos y tabla CSV',setup,out)
load="LOAD DATA INPATH 'hdfs://yarn-resourcemanager:9000/user/hive/warehouse/li18_john/data3_john.csv' INTO TABLE db3_john.data3_john_csv;"
out,_=execute(load);save('01_carga','Carga del CSV en HDFS y Hive',load,out or 'Carga completada.')
typed="""CREATE TABLE db3_john.data3_john STORED AS ORC AS
SELECT InvoiceNo, StockCode, Description, CAST(Quantity AS INT) AS Quantity,
InvoiceDate, CAST(UnitPrice AS DECIMAL(18,4)) AS UnitPrice,
CASE WHEN TRIM(CustomerID)='' THEN NULL ELSE TRIM(CustomerID) END AS CustomerID,
Country FROM db3_john.data3_john_csv;"""
out,_=execute(typed);save('02_tipos','Esquema tipado de analisis',typed,out or 'Tabla ORC creada.')
for name,q in [('03_esquema','DESCRIBE db3_john.data3_john;'),('04_location','DESCRIBE FORMATTED db3_john.data3_john;'),('05_muestra','SELECT * FROM db3_john.data3_john LIMIT 10;')]:
    out,_=execute(q)
    save(name,name,q,out)
doc=Document(r'C:\Users\johnn\Downloads\LI18 - Practica con Apache Hive (3).docx')
queries=[]
for row in doc.tables[1].rows[1:]:
    n=int(row.cells[0].text.strip());question=row.cells[1].text;sql=row.cells[2].text.replace('online_retail','db3_john.data3_john')
    out,_=execute(sql);stamp=save(f'Q{n:02}',question,sql,out)
    queries.append({'n':n,'pregunta':question,'sql':sql,'salida':out,'fecha':stamp})
    (root/'consultas.json').write_text(json.dumps(queries,ensure_ascii=False,indent=2),encoding='utf-8')
    print(n,question,out.splitlines()[1:3],flush=True)
