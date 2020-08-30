#!/bin/sh

GC_HEAD="G21\nG90\nG94\nG40\nG64\nF100.0\nS1.0"
DWELL_DOWN=$2
DWELL_UP=$3

GC_DOWN="M03\nG4 P${DWELL_DOWN}"
GC_UP="M05\nG4 P${DWELL_UP}"

INFILE=$1

cp "${INFILE}" "${INFILE}.bak"

echo ${GC_HEAD} > ${INFILE}

sed -r -e '/^($|G21|G90|G94|M03|M05)/d' \
       -e '0,/G00 Z/d' \
       -e '/G01 Z0/d' \
       -e 's/^G01 Z-.*/'"${GC_DOWN}"'/g' \
       -e 's/^G00 Z.*/'"${GC_UP}"'/g' \
    "${INFILE}.bak" >> ${INFILE}

echo "M02\n" >> ${INFILE}
