#!/bin/bash
# Se ejecuta DENTRO del contenedor del NameNode.
# Escribe por la salida estándar un CSV sintético de ventas de exactamente N bytes.
BYTES="$1"
BLOQUE=/tmp/bloque_ventas.csv

awk 'BEGIN {
    srand(2);
    split("La Paz,Cochabamba,Santa Cruz,Oruro,Potosi,Sucre,Tarija,Trinidad,Cobija", ciudad, ",");
    split("laptop,celular,tablet,monitor,teclado,mouse,impresora,router", producto, ",");
    for (i = 1; i <= 250000; i++)
        printf "%d,2026-%02d-%02d,%s,%s,%d,%.2f\n", i, int(rand() * 12) + 1, int(rand() * 28) + 1,
            ciudad[int(rand() * 9) + 1], producto[int(rand() * 8) + 1], int(rand() * 20) + 1, rand() * 5000;
}' > "$BLOQUE"

# Se repite el bloque hasta completar el tamaño pedido.
{
    echo "id_venta,fecha,ciudad,producto,cantidad,precio"
    while cat "$BLOQUE"; do :; done
} 2> /dev/null | head -c "$BYTES"
