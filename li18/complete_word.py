from pathlib import Path
from copy import deepcopy
import json
from docx import Document
from docx.text.paragraph import Paragraph
from docx.shared import Inches,Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH,WD_COLOR_INDEX
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

root=Path(__file__).parent
src=Path(r'C:\Users\johnn\Downloads\LI18 - Practica con Apache Hive (3).docx')
d=Document(src);orig=list(d.paragraphs);sections=[s._sectPr.xml for s in d.sections]
queries=json.loads((root/'consultas.json').read_text(encoding='utf-8'))
def font(p):
    for r in p.runs:r.font.name='Arial';r.font.size=Pt(11)
def after(anchor,text='',bold=False):
    el=OxmlElement('w:p');anchor._p.addnext(el);p=Paragraph(el,anchor._parent)
    p.style=d.styles['Normal'];p.paragraph_format.space_after=Pt(6)
    p.add_run(text).bold=bold;font(p);return p
def fig(anchor,key,caption):
    p=after(anchor);p.alignment=WD_ALIGN_PARAGRAPH.CENTER;p.paragraph_format.keep_with_next=True
    p.add_run().add_picture(str(root/'evidencias'/f'{key}.jpg'),width=Inches(6.0))
    p=after(p,caption);p.alignment=WD_ALIGN_PARAGRAPH.CENTER;return p
def answer(anchor,text,images=()):
    p=after(anchor,text)
    for key,caption in images:p=fig(p,key,caption)
    return p

a=orig[2]
for text in ['Materia: Big Data','Estudiante: Johnny Suarez Abasto','Grupo: 02','Fecha: 27 de octubre de 2026']:
    a=after(a,text);a.alignment=WD_ALIGN_PARAGRAPH.CENTER
answer(orig[6],'Se descargó online+retail.zip desde el repositorio UCI y se extrajo Online Retail.xlsx. El archivo contiene 541.909 registros y ocho columnas. Se conservó el Excel original.', [('00_fuente','Evidencia de los archivos originales y del CSV convertido en la terminal de VS Code.')])
answer(orig[8],'Se convirtió la hoja de Excel a data3_john.csv en UTF-8 y sin fila de encabezados. Las fechas se expresaron como M/d/yyyy H:mm para mantener compatibilidad con las consultas propuestas. Se conservaron las comillas de las descripciones, los precios cero y las cantidades negativas. Los identificadores de cliente vacíos se transformaron a NULL en la tabla final. El resultado se verificó con el conteo de 541.909 filas en Hive.')
answer(orig[10],'Se utilizó el entorno del Grupo 02, Bigdata-Dockerspark-Transnochados, con Docker Desktop. El servicio hive-server ejecuta HiveServer2 y yarn-resourcemanager aloja el NameNode. Las consultas se ejecutaron realmente desde PowerShell en la terminal integrada de VS Code, mediante Beeline y JDBC. Las capturas muestran el comando SQL, Get-Date del sistema anfitrión y la salida de Hive; Select-Object limita únicamente la cantidad de líneas visibles en las consultas extensas.')
answer(orig[12],'Se creó la base db3_john y se verificó su existencia mediante SHOW DATABASES. Esta base organiza las tablas de entrada y análisis del laboratorio.', [('00_base','Creación y verificación de db3_john desde la terminal integrada.')])

field_rows=[
('InvoiceNo','STRING','Contiene números de factura y cancelaciones con prefijo C. INT perdería estas últimas.'),
('StockCode','STRING','Los códigos pueden incluir letras; existen conceptos especiales como DOT, M y AMAZONFEE.'),
('Description','STRING','Puede estar vacía, contener comas entre comillas o registrar ajustes de inventario. Se utiliza OpenCSVSerde.'),
('Quantity','INT','Admite valores positivos y negativos. Los negativos se conservan para estudiar devoluciones y ajustes.'),
('InvoiceDate','STRING','Se conserva el patrón M/d/yyyy H:mm requerido por los SQL. Se convierte con unix_timestamp en los análisis temporales; agrupar solo por mes mezcla años.'),
('UnitPrice','DECIMAL(18,4)','Representa importes monetarios con precisión decimal. Se conservan precios cero y negativos; cada consulta establece sus filtros.'),
('CustomerID','STRING','Identificador sin operaciones aritméticas. Hay 135.080 filas sin ID, convertidas a NULL. El texto mantiene compatibilidad con la comprobación de cadena vacía.'),
('Country','STRING','Permite agrupar por país. Algunas categorías representan territorios o denominaciones comerciales; no se normalizaron para conservar el dataset.')]
t=d.tables[0];template=deepcopy(t.rows[-1]._tr)
while len(t.rows)>1:t._tbl.remove(t.rows[-1]._tr)
for name,typ,comment in field_rows:
    t._tbl.append(deepcopy(template))
    for c,value in zip(t.rows[-1].cells,[name,typ,comment,'Reservado para revisión del docente.']):
        c.text=value
        for p in c.paragraphs:font(p)
answer(orig[18],'Se creó data3_john_csv con ocho columnas de texto y OpenCSVSerde para leer correctamente el CSV. A partir de ella se generó db3_john.data3_john en formato ORC, convirtiendo Quantity a INT y UnitPrice a DECIMAL(18,4). InvoiceNo y StockCode se conservaron como texto, y CustomerID vacío se convirtió a NULL. El esquema final respeta las particularidades identificadas.', [('02_tipos','Descripción de las tablas de entrada y análisis en Hive.'),('03_esquema','Tipos de las ocho columnas de db3_john.data3_john.')])
answer(orig[20],'DESCRIBE FORMATTED confirmó la ubicación hdfs://yarn-resourcemanager:9000/user/hive/warehouse/db3_john.db/data3_john. La tabla es MANAGED_TABLE y utiliza OrcSerde: Hive mantiene sus metadatos y administra los archivos ORC en HDFS.', [('04_location','Propiedades de ubicación y almacenamiento consultadas directamente en Hive.')])
answer(orig[22],'Se copió data3_john.csv a /tmp/ del contenedor y se subió a /user/hive/warehouse/li18_john/. LOAD DATA INPATH trasladó el archivo a la tabla de entrada. La evidencia repite la carga con OVERWRITE para mostrar su ejecución en pantalla sin duplicar registros. El conteo de la tabla de entrada se mantuvo en 541.909; la tabla final contiene la conversión tipada del mismo dataset.', [('01_hdfs','Copia al contenedor y carga del CSV en HDFS.'),('01_carga','LOAD DATA y verificación de 541.909 registros en la tabla de entrada.')])
answer(orig[24],'SELECT * FROM db3_john.data3_john LIMIT 10 recuperó diez registros. La salida CSV permitió visualizar las ocho columnas sin perder el contenido por el ancho de la terminal. Esta muestra valida la lectura inicial; el conteo general completa la comprobación de carga.', [('05_muestra','Diez registros reales consultados desde la terminal de VS Code.')])

answers=[
'Se obtuvieron 541.909 registros. COUNT(*) cuenta todas las filas, incluidas devoluciones y operaciones sin cliente identificado. La descripción corresponde al resultado y el conteo coincide con los registros convertidos desde Excel.',
'Se identificaron 25.900 valores distintos de InvoiceNo. La consulta cuenta facturas y documentos con prefijo C, no solo compras positivas. Es correcta como inventario de identificadores de factura, pero el resultado no equivale a 25.900 ventas válidas.',
'Se obtuvieron 4.372 clientes identificados distintos. El SQL excluye identificadores nulos o vacíos, pero no exige cantidades ni precios positivos. Por ello responde al número de clientes presentes en el dataset, incluidos quienes figuran en devoluciones, y no estrictamente a clientes con compras válidas.',
'El ingreso total de las líneas con Quantity > 0 y UnitPrice > 0 fue de 10.666.684,54. Se sumó cantidad por precio unitario. La consulta incluye clientes anónimos y corresponde a ventas brutas positivas; no representa utilidad ni ingreso neto después de devoluciones.',
'United Kingdom encabezó las ventas positivas con 9.025.222,08, seguido de Netherlands con 285.446,34 y EIRE con 283.453,96. Se obtuvieron 38 categorías de país. El agrupamiento responde al importe por mercado, no a unidades vendidas, y no descuenta devoluciones.',
'United Kingdom registró 18.019 facturas con líneas de cantidad y precio positivos; Germany, 457; y France, 392. Se mostraron los diez primeros países. La consulta compara frecuencia mediante documentos distintos por país y no cantidad de filas o productos.',
'El código 23843, PAPER CRAFT, LITTLE BIRDIE, fue primero con 80.995 unidades; el 23166, MEDIUM CERAMIC TOP STORAGE JAR, registró 78.033; y el 84077, WORLD WAR 2 GLIDERS ASSTD DESIGNS, 55.047. El SQL suma cantidades positivas por código y descripción. Responde al volumen bruto vendido, sin descontar devoluciones; el mismo código con descripciones distintas se separa.',
'DOT, DOTCOM POSTAGE, generó 206.248,77; 22423, REGENCY CAKESTAND 3 TIER, 174.484,74; y 23843, PAPER CRAFT, LITTLE BIRDIE, 168.469,60. El SQL ordena el importe positivo por código y descripción. La descripción del indicador es adecuada, pero DOTCOM POSTAGE es un concepto de envío y no necesariamente un producto físico.',
'El cliente 14646 lideró con 280.206,02; le siguieron 18102 con 259.657,30 y 17450 con 194.550,79. Se sumaron ventas positivas de clientes identificados. La consulta responde al mayor valor bruto comprado, no a rentabilidad ni gasto neto después de devoluciones.',
'El ticket promedio por factura fue de 534,40. La subconsulta suma las líneas positivas de cada InvoiceNo y la consulta exterior promedia esos totales. Corresponde al importe medio por pedido, no al promedio de líneas ni al gasto total de cada cliente.',
'La factura 581483 fue la de mayor importe, con 168.469,60, seguida de 541431 con 77.183,60 y 574941 con 52.940,94. La suma por documento permite identificar órdenes grandes. Sus importes se calculan con líneas positivas y no garantizan que las compras no hayan sido canceladas posteriormente.',
'El promedio fue de 279,98 unidades por factura. Se sumó Quantity por documento y se promediaron esos totales. La consulta responde a unidades, no a cantidad de productos diferentes ni a número de líneas: un mismo artículo puede aportar muchas unidades.',
'El mayor precio registrado fue 38.970,0000 para M, Manual; AMAZONFEE alcanzó 17.836,4600 y B, Adjust bad debt, 11.062,0600. El SQL busca el máximo precio positivo por código y descripción sin filtrar cantidades negativas. Identifica valores altos y atípicos, pero varios son cargos o ajustes, por lo que no corresponde tratarlos automáticamente como productos premium.',
'B, Adjust bad debt, tuvo el mayor precio promedio: 11.062,06. AMAZONFEE promedió 7.324,78 y 22502, PICNIC BASKET WICKER 60 PIECES, 649,50. AVG calcula un promedio simple de precios por línea y no uno ponderado por unidades. Se incluyen devoluciones si el precio es positivo; el resultado requiere distinguir artículos de cargos y ajustes.',
'Noviembre concentró 2.769 facturas positivas y diciembre 2.378; enero tuvo 1.086. La conversión de fecha permitió agrupar por número de mes. La consulta responde al conteo mensual, pero combina diciembre de 2010 y diciembre de 2011 y no prueba por sí sola una estacionalidad recurrente.',
'Noviembre presentó el mayor ingreso agrupado por mes, 1.509.496,33; diciembre sumó 1.462.538,82 y octubre 1.154.979,30. El SQL suma importes positivos y mezcla el mismo mes de años diferentes. Por ello describe la distribución por mes del año, no una serie cronológica completa.',
'Al separar año y mes, noviembre de 2011 fue el período de mayor ingreso con 1.509.496,33. Diciembre de 2010 registró 823.746,14 y diciembre de 2011, 638.792,68. Esta consulta responde mejor a la evolución temporal. El último mes es incompleto, porque el dataset llega hasta el 9 de diciembre de 2011.',
'El día de mayor ingreso positivo fue el 9 de diciembre de 2011, con 200.920,60. Le siguieron el 14 de noviembre con 114.419,89 y el 20 de septiembre con 109.612,03. Se agrupa por fecha y se ordena la suma de ventas; el resultado permite localizar picos, pero no demuestra que fueran causados por campañas.',
'Las 12:00 reunieron la mayor cantidad de facturas positivas, 3.220; las 13:00 registraron 2.753 y las 14:00, 2.457. El SQL cuenta documentos distintos por hora y responde a frecuencia de compras, no al mayor ingreso o ticket. Las horas corresponden a las fechas registradas en el dataset, sin una conversión de zona horaria.',
'Se contaron 10.624 registros con cantidad negativa o InvoiceNo que comienza por C. La consulta responde a líneas asociadas a devoluciones o cancelaciones; no cuenta documentos distintos ni unidades. También puede incluir ajustes de inventario con cantidad negativa.',
'El valor absoluto de las líneas clasificadas como devolución fue de 896.812,49. ABS convierte el importe de cada línea a positivo antes de sumarlo. Es una medida de magnitud de devoluciones y ajustes, no una pérdida contable comprobada ni un cálculo de costos.',
'PAPER CRAFT, LITTLE BIRDIE, código 23843, encabezó las unidades devueltas con 80.995; MEDIUM CERAMIC TOP STORAGE JAR, código 23166, registró 74.494. La descripción printing smudges/thrown away acumuló 19.200 y muestra que también existen anotaciones de ajuste. El SQL suma unidades absolutas por código y descripción; no permite atribuir automáticamente el resultado a problemas de calidad.',
'El cliente 16446 presentó el mayor valor de devolución, 168.469,60 en una línea; 12346 registró 77.183,60 en una línea y 15098, 39.267,00 en dos. La consulta ordena por valor monetario, no por cantidad de devoluciones, aunque la pregunta utiliza la expresión más devoluciones. Ambas métricas aparecen separadas en el resultado.',
'United Kingdom concentró 815.291,60 de valor absoluto de devoluciones, seguido de EIRE con 20.177,14 y France con 12.311,21. El SQL responde al monto por país, no a una tasa relativa. Un país con más ventas puede acumular un importe mayor sin tener peor proporción de devoluciones.',
'United Kingdom obtuvo 8.209.930,48 de ingreso neto bajo el filtro de precio positivo; Netherlands, 284.661,54; y EIRE, 263.276,82. La suma conserva cantidades negativas, que reducen los importes. Responde al saldo de ventas y ajustes incluidos, pero no equivale a utilidad neta ni contempla costos, impuestos o precios no positivos.',
'El cliente 12748 tuvo 209 compras distintas; 14911, 201; y 17841, 124. Se cuentan facturas positivas por cliente identificado. La consulta responde a frecuencia durante el período, independientemente del importe; no mide antigüedad ni periodicidad entre compras.',
'El gasto promedio acumulado por cliente con compras válidas fue de 2.054,27. Primero se suman las ventas positivas de cada cliente y después se promedian esos totales. Es el gasto por cliente durante el período completo, no ticket por factura ni promedio mensual.',
'Se identificaron 1.028 clientes con al menos cinco facturas positivas y un importe acumulado mínimo de 1.000. El cliente 14646 tuvo 73 compras y 280.206,02; 18102, 60 y 259.657,30; y 17450, 46 y 194.550,79. La consulta responde a los umbrales establecidos de frecuencia y valor; la etiqueta VIP depende de esos criterios, no es una categoría preexistente del dataset.',
'El código 23166, MEDIUM CERAMIC TOP STORAGE JAR, lideró con 78.033 unidades, precio promedio de 1,47 e ingreso de 81.700,92. WORLD WAR 2 GLIDERS ASSTD DESIGNS registró 55.047 unidades, precio medio de 0,32 e ingreso de 13.841,85. El filtro identifica grupos con al menos 1.000 unidades y precio promedio inferior a 2. La media de precios es simple por línea y no ponderada.',
'PICNIC BASKET WICKER 60 PIECES, código 22502, generó 39.619,50 con 61 unidades. AMAZONFEE registró 13.761,09 con dos unidades y Adjust bad debt, 11.062,06 con una. Se obtuvieron 22 grupos que cumplen menos de 100 unidades y más de 1.000 de ingreso. El SQL responde al contraste de volumen e importe, pero no demuestra un alto margen porque faltan costos y varios conceptos son cargos.',
'La consulta produjo 4.346 combinaciones de país y cliente con ventas positivas, ordenadas por país y monto descendente. En Australia, 12415 lideró con 124.914,53, seguido de 12431 con 5.514,67 y 12388 con 2.780,66. Responde a un orden comercial dentro de cada país; no genera una columna numérica de ranking y no debe interpretarse como un orden global de todos los clientes.',
'United Kingdom presentó 3.950 clientes identificados distintos, Germany 95 y France 87. Se obtuvieron 37 categorías de país. El SQL responde a la base de clientes presentes en los registros, pero no exige ventas positivas: incluye clientes que solo pudieran figurar en devoluciones.',
'El promedio de unidades positivas vendidas por código de producto fue de 1.424,88. La subconsulta suma Quantity por StockCode y la consulta exterior promedia esos totales. Responde al promedio por código, no a una media por línea ni por factura; tampoco descuenta devoluciones.',
'Se detectaron 960 códigos con al menos una línea sin descripción. Los códigos 35965 y 23084 tuvieron diez registros cada uno y 22084, nueve. La consulta cuenta filas vacías por código. No implica que esos códigos carezcan siempre de descripción: pueden tener otras líneas completas.',
'Se mostraron 50 registros con UnitPrice igual a cero mediante LIMIT 50. Entre ellos figura la factura 536414, código 22139, con 56 unidades, sin descripción ni CustomerID y país United Kingdom. La consulta identifica ejemplos para revisión; no calcula el total de registros con precio cero ni permite decidir por sí sola si corresponden a promociones o errores.'
]
assert len(answers)==35
table=d.tables[1];source_rows=list(table.rows[1:])
def merged_row_after(anchor):
    row=table.add_row();anchor._tr.addnext(row._tr)
    c=row.cells[0].merge(row.cells[-1]);c.text=''
    pr=row._tr.get_or_add_trPr();pr.append(OxmlElement('w:cantSplit'))
    return row,c
for n,(row,result) in enumerate(zip(source_rows,answers),1):
    row._tr.get_or_add_trPr().append(OxmlElement('w:cantSplit'))
    for cell in row.cells:
        for p in cell.paragraphs:p.paragraph_format.keep_with_next=True
    # Adaptacion de la tabla ejecutada, manteniendo el esquema y formato de la guia.
    for p in row.cells[2].paragraphs:
        for r in p.runs:r.text=r.text.replace('online_retail','db3_john.data3_john')
    for p in row.cells[1].paragraphs:
        for r in p.runs:r.font.highlight_color=WD_COLOR_INDEX.YELLOW
    imgrow,c=merged_row_after(row);p=c.paragraphs[0];p.alignment=WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.keep_with_next=True
    p.add_run().add_picture(str(root/'evidencias'/f'Q{n:02}.jpg'),width=Inches(5.95))
    p=c.add_paragraph(f'Evidencia {n}. SQL y resultado en la terminal integrada de VS Code.');p.alignment=WD_ALIGN_PARAGRAPH.CENTER;p.paragraph_format.keep_with_next=True;font(p)
    ansrow,c=merged_row_after(imgrow);p=c.paragraphs[0];p.add_run('Respuesta y revisión de la descripción: ').bold=True;p.add_run(result);font(p)

# Completar el ejemplo de formato de la guia para no dejar marcadores pendientes.
sample=d.tables[2]
values=['1','Validación de la cantidad de registros','SELECT COUNT(*) FROM db3_john.data3_john;','La carga contiene 541.909 registros.']
for c,v in zip(sample.rows[1].cells,values):
    c.text=v
    for p in c.paragraphs:font(p)
c=sample.rows[2].cells[0];c.text='';p=c.paragraphs[0];p.alignment=WD_ALIGN_PARAGRAPH.CENTER;p.add_run().add_picture(str(root/'evidencias'/'Q01.jpg'),width=Inches(5.95))
c=sample.rows[3].cells[0];c.text='Respuesta a la pregunta: el dataset contiene 541.909 filas. El conteo de Hive coincide con los registros convertidos desde el Excel y respalda la validación de la carga.'
for p in c.paragraphs:font(p)
for p in orig:
    for r in p.runs:
        for old,new in [('data3_tunombre','data3_john'),('db3_tunombre','db3_john')]:r.text=r.text.replace(old,new)

a=after(orig[-1],'Conclusiones',True)
a.paragraph_format.page_break_before=True
for text in [
'Se completaron la descarga del Excel, su conversión a CSV, la carga en HDFS y Hive y la ejecución de las 35 consultas. Las evidencias incluidas son capturas reales de la terminal integrada de VS Code con los comandos, la hora del sistema y la salida de Hive.',
'El dataset contiene 541.909 registros, 25.900 identificadores de factura y 4.372 clientes identificados en el conjunto completo. Las ventas positivas sumaron 10.666.684,54, el ticket medio por factura fue de 534,40 y el promedio de unidades por factura, 279,98. Estos indicadores utilizan poblaciones y filtros diferentes y se interpretaron de acuerdo con cada SQL.',
'Se contaron 10.624 líneas de devolución o ajuste y un valor absoluto asociado de 896.812,49. Su análisis permite contrastar ventas brutas y saldos netos, pero no equivale a pérdidas contables. La presencia de portes, comisiones y ajustes entre los códigos exige revisar la naturaleza de los conceptos antes de calificarlos como productos premium o de alto margen.',
'La práctica permitió diferenciar filas, facturas, unidades y clientes, así como ingresos, precios y utilidad. También mostró que agrupar por mes sin año mezcla períodos, que una consulta ordenada por monto no responde necesariamente a frecuencia y que los datos incompletos requieren revisión antes de tomar decisiones comerciales.',
'Para ejecutar las consultas se utilizó MapReduce local con mapreduce.task.io.sort.mb=10 y la ejecución vectorizada desactivada. Las vistas extensas se limitaron en la terminal mediante Select-Object, sin alterar los filtros ni las agregaciones de los SQL. Los comentarios del profesor se reservaron para su evaluación.'
]:a=after(a,text)
d.core_properties.author='Johnny Suarez Abasto';d.core_properties.title='LI18 Tercera práctica con Apache Hive'
assert [s._sectPr.xml for s in d.sections]==sections
out=root.parent/'LI18_Johnny_Suarez_Abasto_Completo.docx';d.save(out);print(out)
