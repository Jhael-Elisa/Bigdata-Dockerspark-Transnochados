from docx import Document
from docx.table import Table
from docx.oxml import OxmlElement
from docx.shared import Inches
from copy import deepcopy
from pathlib import Path
src=Path(r'C:\Users\johnn\Downloads\LI19 - Practica con Apache Hive (4).docx')
d=Document(src); template=deepcopy(d.tables[2]._tbl)
questions=[r.cells[1].text for r in d.tables[1].rows[1:]]
sql=[r.cells[2].text for r in d.tables[1].rows[1:]]
desc=[r.cells[3].text for r in d.tables[1].rows[1:]]
# Original question -> matching SQL row, KPI row, screenshot.
maps=[(8,20,16),(13,21,20),(1,6,21),(4,15,22),(24,14,23),(6,3,24),(9,9,25),(3,13,26),(21,4,27),(22,5,28),(14,22,29),(15,17,18),(20,12,30),(25,10,31),(12,23,10),(23,1,11),(5,24,12),(17,2,13),(7,11,15),(19,16,32),(10,19,33),(11,7,34),(2,25,35),(16,18,17),(18,8,14)]
answers=[
'Encontré más registros de tipo Ip, con 929.684, seguidos por User, con 831.162. Son las entidades que más se repiten en mi resultado.',
'Obtuve 985 combinaciones de categoría y técnica MITRE. Vi que una categoría puede estar vinculada con varias técnicas, por eso la consulta devuelve tantas filas.',
'Encontré 70 técnicas asociadas a LateralMovement. Al separarlas pude contar cada técnica por su cuenta, aunque vinieran juntas en una celda.',
'El incidente 93 quedó primero en mi resultado: reúne 3.224 alertas distintas y 10.000 registros de eventos.',
'Vi que las 15:00 tienen la mayor cantidad de registros sospechosos, con 38.572. Tomé la hora tal como aparece en el archivo, sin convertirla a la hora local.',
'En los 50 registros mostrados obtuve un puntaje de 100. Ese valor sale de la regla de la consulta; por sí solo no demuestra que todos sean ataques confirmados.',
'Obtuve 99.159 combinaciones de dispositivo e incidente con más de una alerta distinta. No las interpreté como 99.159 dispositivos únicos, porque un equipo puede aparecer en varios incidentes.',
'El identificador 360606 aparece primero, con 3.219.634 registros. En este archivo el campo de IP contiene códigos, así que no puedo identificar una dirección real a partir de ese número.',
'La combinación de cuenta 453297 y UPN 673934 reunió 579.880 registros con evidencia impactada. Esto me permite ubicar el grupo con más registros afectados, aunque los nombres están codificados.',
'La combinación 453297 y 673934 quedó primera, con 2.641.848 registros. La frecuencia me sirve para priorizar su revisión, pero no basta para afirmar que sea una cuenta comprometida.',
'Obtuve 57 combinaciones de categoría y grado del incidente. También apareció la combinación Category e IncidentGrade una vez, lo que indica que hay una fila de encabezados dentro de los datos.',
'CommandAndControl quedó primero, con 269.971 registros sospechosos. Para este conteo incluí los que tenían Suspicious en el nivel de sospecha o en el veredicto.',
'La alerta 0 reunió 11.292 registros de evidencia y quedó primera. Conté las filas asociadas a cada alerta, no alertas diferentes.',
'La hora 16 tuvo el mayor conteo, con 211.093 registros. Comparé las 24 horas usando la hora registrada en el archivo.',
'Obtuve 4.147.993 registros. Vi que el total incluye una fila con nombres de columnas; por eso hay un registro más que los 4.147.992 del ejemplo.',
'Agrupé los registros por día y pude ver cómo cambia la cantidad entre fechas. Mi captura muestra solo las primeras 20 fechas del resultado.',
'Obtuve 1.752.940 BenignPositive, 1.492.354 TruePositive y 902.698 FalsePositive. También apareció IncidentGrade una vez, correspondiente a una fila de encabezados.',
'Encontré 3.498.157 registros sin nivel de sospecha, 649.454 Suspicious y 381 Incriminated. Además apareció SuspicionLevel una vez como dato de encabezado.',
'Conté 2.288.528 registros Related y 1.859.464 Impacted. Predominan las evidencias relacionadas; también encontré una fila con el texto EvidenceRole.',
'El título codificado como 0 apareció en 606.471 registros y fue el más repetido. Este resultado cuenta registros por título, no alertas únicas.',
'La combinación de dispositivo 98799 y nombre 153085 quedó primera. Como son identificadores codificados, el resultado no me permite saber qué equipo físico representa.',
'El detector 0 quedó primero, con 606.471 registros. Usé este conteo para comparar el volumen por detector; no representa necesariamente esa cantidad de alertas distintas.',
'Obtuve 401 valores al separar y contar las técnicas MITRE. En el resultado también apareció MitreTechniques, así que ese encabezado debe excluirse antes de interpretar el conteo como técnicas válidas.',
'InitialAccess fue la categoría más frecuente, con 1.952.969 registros. En mi resultado concentra más eventos que las demás categorías.',
'Encontré 3.155.260 registros sin veredicto, 633.484 Suspicious, 187.095 Malicious y 172.101 NoThreatsFound. También vi otros valores que necesitan revisión, incluido el encabezado LastVerdict.'
]
# Preserve all existing material before the teacher answer example.
body=d.element.body;old=d.tables[2]._tbl;idx=list(body).index(old)
for e in list(body)[idx:]:
 if not e.tag.endswith('sectPr'):body.remove(e)
def fill(cell,text):
 p=cell.paragraphs[0];rp=deepcopy(p.runs[0]._r.rPr) if p.runs and p.runs[0]._r.rPr is not None else None
 for e in list(cell._tc):
  if e.tag.endswith('p') or e.tag.endswith('tbl'):cell._tc.remove(e)
 p=cell.add_paragraph();r=p.add_run(text)
 if rp is not None:r._r.insert(0,rp)
 return p
for n,(s,k,img) in enumerate(maps,1):
 el=deepcopy(template);body.insert(len(body)-1,el);t=Table(el,d._body)
 for cell,text in zip(t.rows[1].cells,[str(n),questions[n-1],sql[s-1].replace('siem_event_logs','db4_john.data4_john'),desc[k-1]]):fill(cell,text)
 p=fill(t.rows[2].cells[0],'');p.add_run().add_picture(f'li19_revision/image{img}.png',width=Inches(6.3))
 p=fill(t.rows[3].cells[0],'');r=p.add_run('Respuesta a la pregunta (en sus palabras): ');r.bold=True;p.add_run(answers[n-1])
 # Keep the image and its answer together, preserving the template's typography.
 for row in t.rows:
  pr=row._tr.get_or_add_trPr();pr.append(OxmlElement('w:cantSplit'))
 for row in t.rows[:3]:
  for cell in row.cells:
   for p in cell.paragraphs:p.paragraph_format.keep_with_next=True
 spacer=OxmlElement('w:p');el.addnext(spacer)
out=Path(r'C:\Users\johnn\Downloads\LI19_Johnny_Suarez_Abasto_Resuelto.docx');d.save(out)
print(out)
print('sections',[(s.page_width,s.page_height,s.orientation) for s in d.sections])
