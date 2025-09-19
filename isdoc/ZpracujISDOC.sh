#parametry
#vstupni isdoc soubor
#vystupni dbf (koncovka dbf se pridava)
ISDOCFILE=$1
OUTPFILE=$2

sed   's/\r$//' ${ISDOCFILE} | \
sed -e :a -e '$!N; s/\n/ /; ta' >${ISDOCFILE}.crlf.oneline
vd --encoding cp1250 -o ${ISDOCFILE}.csv -f xml -b ${ISDOCFILE}.crlf.oneline
iconv -f UTF8 -t iso8859-2 -o ${ISDOCFILE}.csv.isowin  ${ISDOCFILE}.csv  

./createisdoc ${ISDOCFILE}.csv.isowin ${OUTPFILE}

rm -f ${ISDOCFILE}.crlf.oneline
rm -f ${ISDOCFILE}.csv
rm -f ${ISDOCFILE}.csv.isowin
