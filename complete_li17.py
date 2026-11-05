from pathlib import Path
from copy import deepcopy
from docx import Document
from docx.text.paragraph import Paragraph
from docx.shared import Inches,Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH,WD_COLOR_INDEX
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

root=Path(__file__).parent
src=Path(r'C:\Users\johnn\Downloads\LI17 - Practica con Apache Hive (2).docx')
pics=Path(r'C:\Users\johnn\Pictures\Screenshots\Caprturas Lab17')
d=Document(src); originals=list(d.paragraphs)
section_xml=[s._sectPr.xml for s in d.sections]
def add(anchor,text='',bold=False):
    el=OxmlElement('w:p');anchor._p.addnext(el);p=Paragraph(el,anchor._parent)
    p.style=d.styles['Normal'];p.paragraph_format.space_after=Pt(6)
    p.paragraph_format.keep_with_next=False
    r=p.add_run(text);r.font.name='Arial';r.font.size=Pt(11);r.bold=bold
    return p
def picture(anchor,prefix,caption):
    path=next(pics.glob(prefix+'*.png'))
    p=add(anchor);p.alignment=WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.keep_with_next=True
    p.runs[0].add_picture(str(path),width=Inches(6.05))
    p=add(p,caption);p.alignment=WD_ALIGN_PARAGRAPH.CENTER
    return p
def response(anchor,text,images):
    a=add(anchor,text)
    if images:a.paragraph_format.keep_with_next=True
    for prefix,caption in images:a=picture(a,prefix,caption)
    return a

# Conservar la portada y completar la identificacion sin cambiar sus estilos.
a=originals[2]
for text in ['Materia: Big Data','Estudiante: Johnny Suarez Abasto','Grupo: 02','Fecha de realización: 21 de octubre de 2026']:
    a=add(a,text);a.alignment=WD_ALIGN_PARAGRAPH.CENTER
response(originals[6], 'Resultado obtenido: se utilizó el dataset de comercio electrónico data.csv y se conservó el original. Se preparó data_john.csv en UTF-8, sin encabezado, con 541.909 registros y ocho campos. La revisión detectó descripciones con comas entre comillas, números de factura con prefijo C y clientes sin identificación.', [('LI17_02_', 'Evidencia 2. Archivo personalizado y primeras filas.')])
response(originals[8], 'Resultado obtenido: se reutilizó el repositorio Bigdata-Dockerspark-Transnochados del Grupo 02, distinto de big-data-europe, con Docker Desktop y Docker Compose. Se verificaron nueve contenedores activos. El servicio yarn-resourcemanager ejecuta el NameNode y hive-server proporciona HiveServer2.', [('LI17_01_', 'Evidencia 1. Entorno del laboratorio en ejecución.')])
response(originals[9], 'Resultado obtenido: se accedió a HiveServer2 desde el servicio hive-server mediante Beeline, con la conexión JDBC jdbc:hive2://localhost:10000 y el usuario root.', [])
response(originals[11], 'Resultado obtenido: se creó dbec_john con CREATE DATABASE IF NOT EXISTS dbec_john y se seleccionó mediante USE dbec_john. La consulta current_database() confirmó la base activa.', [('LI17_04_', 'Evidencia 4. Creación y selección de dbec_john.')])

types=[('InvoiceNo','STRING'),('StockCode','STRING'),('Description','STRING'),('Quantity','INT'),('InvoiceDate','TIMESTAMP'),('UnitPrice','DECIMAL(18,4)'),('CustomerID','INT'),('Country','STRING')]
t=d.tables[0];template=deepcopy(t.rows[-1]._tr)
while len(t.rows)>1:t._tbl.remove(t.rows[-1]._tr)
for name,typ in types:
    t._tbl.append(deepcopy(template))
    for c,v in zip(t.rows[-1].cells,(name,typ)):
        c.text=v
        for p in c.paragraphs:
            for r in p.runs:r.font.name='Arial';r.font.size=Pt(11)
response(originals[14], 'InvoiceNo se definió como texto porque las cancelaciones contienen el prefijo C. StockCode admite códigos alfanuméricos. El precio se representó con precisión decimal y la fecha se convirtió desde el patrón M/d/yyyy H:mm. Los identificadores de cliente vacíos se transformaron a NULL.', [])
response(originals[20], 'Resultado obtenido: se creó primero tec_john_csv con ocho columnas STRING y OpenCSVSerde para respetar las comillas y las comas dentro de las descripciones. Luego se creó dbec_john.tec_john mediante conversión de tipos y almacenamiento ORC. La validación confirmó 541.909 registros, cero fechas, cantidades y precios nulos y 135.080 registros sin CustomerID.', [('LI17_05_', 'Evidencia 5. Esquema de la tabla de entrada CSV.'),('LI17_07_', 'Evidencia 7. Tipos de la tabla final tec_john.'),('LI17_08_', 'Evidencia 8. Validación de registros y conversiones.')])
response(originals[23], 'Resultado obtenido: DESCRIBE FORMATTED confirmó que la tabla final es administrada y que su Location corresponde a hdfs://yarn-resourcemanager:9000/user/hive/warehouse/dbec_john.db/tec_john. La ubicación relaciona la definición de Hive con los archivos ORC almacenados en HDFS.', [('LI17_09_', 'Evidencia 9. Ubicación y propiedades de la tabla final.')])
response(originals[25], "Resultado obtenido: el archivo se copió a /tmp/ del contenedor y se subió a /user/hive/warehouse/li17_john/ en HDFS. Se cargó en tec_john_csv mediante LOAD DATA INPATH con la URI completa de HDFS y posteriormente se generó la tabla final tipada. Esta separación evita interpretar incorrectamente las descripciones y fechas del CSV.", [('LI17_03_', 'Evidencia 3. Copia del archivo y carga en HDFS.'),('LI17_06_', 'Evidencia 6. Lectura inicial de la tabla de entrada.')])
response(originals[26], 'Resultado obtenido: SELECT * FROM dbec_john.tec_john LIMIT 10 recuperó diez registros. Se utilizó salida CSV para visualizar las ocho columnas, con fechas timestamp, cantidades enteras y precios decimales.', [('LI17_10_', 'Evidencia 10. Diez registros de la tabla final.')])

results=[
('Resultado obtenido: el ingreso total fue de 8.911.407,90. La consulta suma Quantity × UnitPrice en líneas con cantidad y precio positivos y CustomerID no nulo. Responde al ingreso de ventas que cumplen esos filtros; no mide utilidad ni ingreso neto después de devoluciones, y excluye las ventas sin identificación del cliente.', [('LI17_11_','Evidencia 11. Ingreso total de ventas válidas.')]),
('Resultado obtenido: PAPER CRAFT, LITTLE BIRDIE encabezó el listado con 80.995 unidades en una factura; le siguieron MEDIUM CERAMIC TOP STORAGE JAR con 78.033 unidades en 247 pedidos y WORLD WAR 2 GLIDERS ASSTD DESIGNS con 55.047 unidades en 535 pedidos. La captura presenta los diez primeros. Se agrupa por Description, se suman cantidades positivas y se cuentan facturas distintas. Responde al volumen bruto positivo por descripción, pero no descuenta devoluciones ni filtra precios cero. Una descripción vacía también aparece entre los resultados y requiere depuración antes de tomar decisiones de inventario.', [('LI17_12_','Evidencia 12. Diez descripciones con mayor cantidad positiva.')]),
('Resultado obtenido: United Kingdom concentró 3.950 clientes únicos y el 90,18 % del conteo acumulado por país; Germany presentó 95 y 2,17 %, y France 87 y 1,99 %. La consulta excluye CustomerID nulos y calcula el porcentaje sobre la suma de clientes distintos de cada país. Responde a la distribución geográfica, aunque un cliente asociado a más de un país puede contribuir a varios grupos; el denominador no es necesariamente el total global de clientes únicos.', [('LI17_13_','Evidencia 13. Distribución de clientes identificados por país.')]),
('Resultado obtenido: el ticket promedio fue de 534,40 y la mediana aproximada de 303,80. Primero se suma el importe positivo de cada InvoiceNo y después se obtiene su media y percentil 0,5. La consulta responde al importe por orden y la media superior a la mediana indica influencia de órdenes elevadas. Se convirtió el total a DOUBLE para PERCENTILE_APPROX. No se descuentan devoluciones ni se exige CustomerID. Para ejecutar correctamente se desactivó la ejecución vectorizada de Hive.', [('LI17_14_','Evidencia 14. Ticket promedio y mediana aproximada.')]),
('Resultado obtenido: noviembre de 2011 presentó el mayor ingreso mensual, 1.509.496,33, con 2.769 pedidos; octubre registró 1.154.979,30 y septiembre 1.058.590,17. La consulta agrupa por año y mes y suma importes con cantidades y precios positivos. Responde a la evolución de ingresos brutos positivos y pedidos. Diciembre de 2011 contiene datos hasta el día 9, por lo que sus 638.792,68 no deben interpretarse como una caída de un mes completo.', [('LI17_15_','Evidencia 15. Pedidos e ingresos mensuales.')]),
('Resultado obtenido: CRUK Commission y Discount alcanzaron 100,00 % de líneas clasificadas como devolución, con 16 y 77 registros respectivamente y ninguna línea con cantidad positiva. La consulta clasifica cantidades negativas o facturas C, agrupa por descripción y exige al menos diez registros con cliente identificado. Calcula frecuencia por línea, no por unidad ni por factura completa. Los conceptos de comisión y descuento no representan necesariamente productos físicos; por ello, el indicador requiere revisar la naturaleza de cada concepto antes de atribuir desperdicio logístico.', [('LI17_16_','Evidencia 16. Tasa de líneas de devolución por descripción.')]),
('Resultado obtenido: las 12:00 reunieron la mayor cantidad de pedidos, 3.220; las 10:00 concentraron el mayor ingreso, 1.446.742,70. El SQL sugerido presenta su mayor promedio por línea a las 07:00, con 81,95. La consulta complementaria que suma cada factura y hora mostró también a las 07:00 el mayor ticket por orden, 1.071,01 en 29 pedidos. Se responde por separado a volumen, ingreso y ticket. AVG(Quantity × UnitPrice) del SQL original es un promedio por línea y no por pedido; la agrupación adicional corrige esa interpretación.', [('LI17_17A_','Evidencia 17A. Indicadores horarios del SQL sugerido.'),('LI17_17B_','Evidencia 17B. Ticket promedio calculado por factura y hora.')]),
('Resultado obtenido: en la consulta complementaria PAPER CRAFT, LITTLE BIRDIE concentró 80.995 unidades en diciembre, equivalentes al 100,00 % de su volumen positivo. Otras descripciones también mostraron concentraciones del 100 %, incluidas anotaciones de ajustes como came coded as 20713. La consulta sugerida agrupa por descripción y mes, pero HAVING elimina meses con 50 unidades o menos antes del porcentaje. La variante complementaria conserva todos los meses en el denominador y filtra después las concentraciones superiores al 40 %. Esto identifica concentraciones, no prueba una estacionalidad recurrente: el conjunto abarca poco más de un año, mezcla meses de distintos años y contiene ajustes y descripciones no comerciales.', [('LI17_18A_','Evidencia 18A. Distribución mensual sugerida.'),('LI17_18B_','Evidencia 18B. Concentraciones mensuales superiores al 40 %.')]),
('Resultado obtenido: DOTCOM POSTAGE obtuvo el mayor score, 206.248,77, con precio promedio de 292,14 y presencia en 706 pedidos. Manual alcanzó 66.743,93 y POSTAGE 34.992,23. La consulta multiplica el precio promedio sin redondear por las facturas distintas y exige al menos cinco pedidos. Produce el indicador aproximado propuesto, pero no un margen de ganancia: no hay costos y los primeros conceptos incluyen cargos o ajustes. Un score elevado no demuestra rentabilidad ni equivale al ingreso total del producto.', [('LI17_19_','Evidencia 19. Indicador de precio por frecuencia de pedidos.')]),
('Resultado obtenido: los registrados acumularon 18.532 pedidos e ingresos de 8.911.407,90, frente a 1.428 pedidos y 1.755.276,64 en operaciones anónimas. El promedio por línea fue 22,40 y 13,28, respectivamente. La consulta clasifica según CustomerID y compara cantidades positivas con precio positivo. Permite describir diferencias, pero su columna ticket_promedio corresponde al importe por línea y no por orden. Tampoco demuestra que el registro cause mayor gasto ni garantiza que los grupos de facturas sean disjuntos si una factura combina identificadores presentes y ausentes.', [('LI17_20_','Evidencia 20. Clientes con y sin identificación.')]),
('Resultado obtenido: el jueves tuvo el mayor ingreso, 2.203.161,24, y la mayor cantidad de pedidos, 4.246. El martes registró 2.178.632,61 en 3.554 pedidos. No se obtuvieron filas de sábado porque no hay ventas que cumplan los filtros para ese día. La consulta agrupa las ventas positivas por día de semana y responde a pedidos e ingresos, pero no a conversión: faltan visitas o sesiones para calcular compras respecto de oportunidades. El resultado orienta la revisión de actividad comercial sin demostrar causas de esa distribución.', [('LI17_21_','Evidencia 21. Pedidos e ingresos por día de la semana.')]),
('Resultado obtenido: USA encabezó la tasa de cancelación con 38,49 %, formada por 112 líneas de cancelación y 179 de cantidad positiva; Malta siguió con 11,81 % y Japan con 10,34 %. La consulta utiliza cantidad negativa o prefijo C, agrupa por país y considera países con al menos 50 registros. Responde a una proporción de líneas, no a una tasa de facturas canceladas. La columna ventas_validas solo exige cantidad positiva y no precio positivo. Las diferencias identifican países a revisar, pero no establecen causas logísticas o culturales.', [('LI17_22_','Evidencia 22. Tasa de líneas de cancelación por país.')])
]
kpis=[]
for table in d.tables[1:]:
    for p in table.rows[1].cells[0].paragraphs:
        if p.text.strip().startswith('KPI:'):kpis.append(p)
assert len(kpis)==len(results)==12
for anchor,(text,images) in zip(kpis,results):response(anchor,text,images)

# Mantener SQL original y anotar su adaptacion al esquema ejecutado.
response(originals[36], 'Las doce consultas propuestas se probaron sobre dbec_john.tec_john en lugar de ecommerce.retail. Las sentencias originales se conservan en la guía; los resultados y capturas siguientes corresponden al esquema personalizado. Las consultas complementarias distinguen ticket por línea de ticket por orden y corrigen el denominador de la concentración mensual.', [])
for p in originals:
    for r in p.runs:
        for a,b in [('dbec_tunombre','dbec_john'),('tec_tunombre','tec_john'),('data_tunombre.csv','data_john.csv')]:r.text=r.text.replace(a,b)
    if p.text.strip().startswith(('Descargue','Crear una base','Identifique','Crear una tabla','Revisa que','Cargar los','Mostrar los')):
        for r in p.runs:r.font.highlight_color=WD_COLOR_INDEX.YELLOW
for idx,text in {
16:'CREATE TABLE dbec_john.tec_john_csv (',
17:'InvoiceNo STRING, StockCode STRING, Description STRING, Quantity STRING, InvoiceDate STRING, UnitPrice STRING, CustomerID STRING, Country STRING)',
18:"ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'",
19:'WITH SERDEPROPERTIES ("separatorChar"=",", "quoteChar"="\\\"", "escapeChar"="\\\\")',
20:'STORED AS TEXTFILE;'
}.items():
    p=originals[idx]
    if p.runs:
        p.runs[0].text=text
        for r in p.runs[1:]:r.text=''
    else:p.add_run(text)
for table in d.tables[1:]:
    for p in table.rows[1].cells[0].paragraphs:
        if p.text.strip().startswith('¿'):
            for r in p.runs:r.font.highlight_color=WD_COLOR_INDEX.YELLOW

# Permitir que las filas narrativas se repartan en paginas sin cambiar anchos o bordes.
for table in d.tables:
    for row in table.rows:
        for el in list(row._tr.xpath('./w:trPr/w:cantSplit')):el.getparent().remove(el)
        # Altura heredada de una fila vacia: permitir su expansion natural al llenarla.
        for el in list(row._tr.xpath('./w:trPr/w:trHeight')):el.getparent().remove(el)

a=add(originals[-1],'Conclusiones',True)
a.paragraph_format.page_break_before=True
for text in [
'Se completó el flujo desde el CSV local hasta la tabla ORC tipada en Hive. El uso de OpenCSVSerde permitió tratar los campos entre comillas, la conversión de fechas habilitó los análisis temporales y la transformación de identificadores vacíos a NULL permitió comparar operaciones con y sin cliente registrado.',
'El análisis obtuvo ingresos positivos de clientes identificados por 8.911.407,90; un ticket medio por orden de 534,40; y el mayor ingreso mensual en noviembre de 2011. La comparación por hora y por día mostró que la mayor cantidad de pedidos no siempre coincide con el mayor ingreso ni con el mayor ticket.',
'La revisión de los KPI permitió distinguir medidas calculadas de sus interpretaciones: no se obtuvo margen real sin costos, conversión sin visitas, ni estacionalidad recurrente a partir de concentraciones aisladas. Los porcentajes de devolución y cancelación del SQL se calcularon por línea. Estas precisiones evitan convertir resultados descriptivos en conclusiones que los datos no respaldan.',
'Las consultas se ejecutaron con MapReduce local. Se aplicó SET mapreduce.task.io.sort.mb=10 para limitar el búfer y se desactivó la ejecución vectorizada al resolver un error en los datos intermedios de PERCENTILE_APPROX. Estos ajustes de sesión permitieron completar el análisis sin modificar los registros del dataset.'
]:a=add(a,text)
d.core_properties.author='Johnny Suarez Abasto'
out=root/'LI17_Johnny_Suarez_Abasto_Completo.docx';d.save(out)
assert [s._sectPr.xml for s in d.sections]==section_xml
print(out)
