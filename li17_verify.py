from pathlib import Path
from docx import Document
import subprocess,json,csv,io
d=Document(r'C:\Users\johnn\Downloads\LI17 - Practica con Apache Hive (2).docx')
queries=[]
for t in d.tables[1:]:
    collecting=False;lines=[]
    for p in t.rows[1].cells[0].paragraphs:
        text=p.text
        if text.strip().upper().startswith('SELECT') and not collecting:collecting=True
        if collecting:
            lines.append(text)
            if ';' in text:
                sql='\n'.join(lines).replace('ecommerce.retail','dbec_john.tec_john')
                sql=sql.replace('SUM(Quantity * UnitPrice) as order_total','CAST(SUM(Quantity * UnitPrice) AS DOUBLE) as order_total')
                queries.append(sql);collecting=False;lines=[]
out=[]
for i,q in enumerate(queries):
    sql='SET mapreduce.task.io.sort.mb=10; SET hive.vectorized.execution.enabled=false; SET hive.vectorized.execution.reduce.enabled=false; '+q
    r=subprocess.run(['docker','compose','exec','-T','hive-server','beeline','-u','jdbc:hive2://localhost:10000','-n','root','--silent=true','--outputformat=csv2','-e',sql],capture_output=True,text=True,encoding='utf-8',errors='replace')
    rows=list(csv.reader(io.StringIO(r.stdout)))
    out.append({'sql':q,'rows':rows,'error':r.stderr if r.returncode else ''})
    Path('li17_results.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
    print(i+1,rows[:3],flush=True)
