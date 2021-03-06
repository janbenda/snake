function createdbs {

  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "drop table if exists UI_KRAJ_1960"
  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "drop table if exists UI_VUSC"
  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "drop table if exists UI_OKRES"
  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "drop table if exists ui_kraj_1960"
  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "drop table if exists ui_vusc"
  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "drop table if exists ui_okres"
  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "drop table if exists zv_pcobc"

  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "create table UI_OKRES ( \
     KOD int primary key, \
     NAZEV varchar(50), \
     VUSC_KOD int, \
     KRAJ_1960_KOD int, \
     NUTS_LAU varchar(50), \
     PLATI_OD varchar(50), \
     PLATI_DO varchar(50), \
     DATUM_VZNIKU varchar(50) \
  )"

  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "create table UI_VUSC ( \
     KOD int primary key, \
     NAZEV varchar(50), \
     REGSOUDR_KOD varchar(50), \
     NUTS_LAU varchar(50), \
     PLATI_OD varchar(50), \
     PLATI_DO varchar(50), \
     DATUM_VZNIKU varchar(50) \
  )"

  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "create table UI_KRAJ_1960 ( \
     KOD int primary key, \
     NAZEV varchar(50), \
     STAT_KOD varchar(10), \
     PLATI_OD varchar(50), \
     PLATI_DO varchar(50), \
     DATUM_VZNIKU varchar(50) \
  )"

  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "create table zv_pcobc ( \
     NAZCOBCE varchar(50), \
     PSC varchar(5) primary key, \
     NAZPOST varchar(50), \
     KODOKRESU int, \
     NAZOKRESU varchar(50), \
     NAZOBCE varchar(50)
  )"
}

FIRMA=${1:-"zepter"}
ZIPFILES="UI_VUSC.zip UI_OKRES.zip UI_KRAJ_1960.zip"

case "$FIRMA" in
"zepter")
  DB=zakaznik
  SERVER=192.168.2.4
  USER=jan
  PASS=1qw
  SQLCHARSET=cp1250
  ;;
"wic")
  DB=snake
  SERVER=192.168.1.10
  USER=root
  PASS=Honda621
  SQLCHARSET=latin2
  ;;
"gar")
  DB=snake
  SERVER=172.25.15.32
  USER=root
  PASS=Honda621
  SQLCHARSET=latin2
  ;;
esac

createdbs

for ZIPF in $ZIPFILES
do 
  rm -f ${ZIPF}
  curl -o $ZIPF "https://www.cuzk.cz/CUZK/media/CiselnikyISUI/${ZIPF%%.*}/${ZIPF}?ext=.zip"  
  rm -f ${ZIPF%%.*}.csv
  unzip $ZIPF  
  rm -f $ZIPF
  iconv -f WINDOWS-1250 -t ${SQLCHARSET} ${ZIPF%%.*}.csv > ${ZIPF%%.*}.csv.conv
  mv ${ZIPF%%.*}.csv.conv ${ZIPF%%.*}.csv
  mysqlimport --ignore-lines=1 --fields-terminated-by=\; -h$SERVER -u$USER -p$PASS ${DB} --local ${ZIPF%%.*}.csv
  TABLE=${ZIPF%%.*}
  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "rename table ${TABLE} to ${TABLE,,}"
done

ZIPF=xls_pcobc.zip
FEXT=zv_pcobc.xls
rm -f ${ZIPF} ${FEXT} ${FEXT%%.*}.csv
curl -o ${ZIPF} https://www.ceskaposta.cz/documents/10180/3738087/${ZIPF}
unzip $ZIPF  
#po instalaci gnumeric, kde neni gnome to nejde, ale libreoffice to umi taky
libreoffice --infilter=CSV:44,34,76,1 --headless --convert-to csv $FEXT
sleep 1
#ssconvert $FEXT ${FEXT%%.*}.csv
iconv -f utf8 -t ${SQLCHARSET} ${FEXT%%.*}.csv > ${FEXT%%.*}.csv.conv
mv ${FEXT%%.*}.csv.conv ${FEXT%%.*}.csv
rm -f $ZIPF

mysqlimport --fields-optionally-enclosed-by=\" --ignore-lines=1 --fields-terminated-by=, -h$SERVER -u$USER -p$PASS ${DB} --local ${FEXT%%.*}.csv


#okres
#KOD;NAZEV;VUSC_KOD;KRAJ_1960_KOD;NUTS_LAU;PLATI_OD;PLATI_DO;DATUM_VZNIKU
#3201;Bene\232ov;27;32;CZ0201;23.11.2017 00:00:00;;11.04.1960 00:00:00

#ui_vusc
#KOD;NAZEV;REGSOUDR_KOD;NUTS_LAU;PLATI_OD;PLATI_DO;DATUM_VZNIKU
#19;Hlavn\355 m\354sto Praha;19;CZ010;23.11.2016 00:00:00;;01.01.2000 00:00:00

#psc
#NAZCOBCE,PSC,NAZPOST,KODOKRESU,NAZOKRESU,NAZOBCE
#Abertamy,36235,Abertamy,3403,"Karlovy Vary",Abertamy

#a takhle dostanu kraj a okres 
#select psc.psc,okres.nazev okres,vusc.nazev kraj
#from zv_pcobc psc 
#left join UI_OKRES okres on okres.kod=psc.kodokresu
#left join UI_VUSC vusc on vusc.kod=okres.vusc_kod
#where psc = '56301'
