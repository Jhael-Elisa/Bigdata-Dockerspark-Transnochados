from pathlib import Path
import openpyxl,csv,datetime,json,hashlib
p=Path(__file__).parent
x=next((p/'fuente').glob('*.xlsx'))
w=openpyxl.load_workbook(x,read_only=True,data_only=True)
it=iter(w.active.values);head=next(it);count=0;nulls=0;changed=0
with (p/'data3_john.csv').open('w',encoding='utf-8',newline='') as f:
    out=csv.writer(f,lineterminator='\n')
    for row in it:
        vals=[]
        for v in row:
            if isinstance(v,datetime.datetime):v=f'{v.month}/{v.day}/{v.year} {v.hour}:{v.minute:02d}'
            elif v is None:v=''
            elif isinstance(v,float) and v.is_integer():v=str(int(v))
            else:v=str(v)
            if '\n' in v or '\r' in v: changed+=1;v=v.replace('\r',' ').replace('\n',' ')
            vals.append(v)
        out.writerow(vals);count+=1;nulls+=not vals[6]
meta={'archivo_excel':x.name,'fuente':'https://archive.ics.uci.edu/static/public/352/online+retail.zip','columnas':head,'registros':count,'clientes_sin_id':nulls,'campos_con_salto_normalizado':changed,'sha256_excel':hashlib.sha256(x.read_bytes()).hexdigest()}
(p/'preparacion.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(meta,ensure_ascii=False,indent=2))
