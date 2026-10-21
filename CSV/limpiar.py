import csv
from datetime import datetime

entrada = open('data.csv', encoding='latin-1', newline='')
salida = open('data_jhaelguevara.csv', 'w', encoding='utf-8', newline='')

lector = csv.reader(entrada)
next(lector)  # quita el encabezado

total = 0
for fila in lector:
    # quitar comas internas para no romper el delimitador
    fila = [c.replace(',', ' ').strip() for c in fila]
    # convertir fecha 12/1/2010 8:26 -> 2010-12-01 08:26:00
    fecha = datetime.strptime(fila[4], '%m/%d/%Y %H:%M')
    fila[4] = fecha.strftime('%Y-%m-%d %H:%M:%S')
    salida.write(','.join(fila) + '\n')
    total = total + 1

entrada.close()
salida.close()

print('Filas escritas:', total)