function createdbs {

  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "drop table if exists UI_VUSC"
  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "drop table if exists UI_OKRES"
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

  mysql -h$SERVER -u$USER -p$PASS ${DB} -e "create table zv_pcobc ( \
     NAZCOBCE varchar(50), \
     PSC varchar(5) primary key, \
     NAZPOST varchar(50), \
     KODOKRESU int, \
     NAZOKRESU varchar(50), \
     NAZOBCE varchar(50)
  )"
}



ZIPFILES="UI_VUSC.zip UI_OKRES.zip"

DB=temptables
SERVER=192.168.2.4
USER=jan
PASS=1qw

createdbs

for ZIPF in $ZIPFILES
do 
  rm -f ${ZIPF}
  curl -o $ZIPF "https://www.cuzk.cz/CUZK/media/CiselnikyISUI/${ZIPF%%.*}/${ZIPF}?ext=.zip"  
  rm -f ${ZIPF%%.*}.csv
  unzip $ZIPF  
  rm -f $ZIPF
  mysqlimport --ignore-lines=1 --fields-terminated-by=\; -h$SERVER -u$USER -p$PASS ${DB} --local ${ZIPF%%.*}.csv
done




ZIPF=xls_pcobc.zip
rm -f ${ZIPF}
curl -o ${ZIPF} https://www.ceskaposta.cz/documents/10180/3738087/${ZIPF}
FEXT=zv_pcobc.xls
rm -f ${FEXT}
unzip $ZIPF  
rm -f ${FEXT%%.*}.csv
#po instalaci gnumeric
ssconvert $FEXT ${FEXT%%.*}.csv
iconv -f utf8 -t cp1250 ${FEXT%%.*}.csv > ${FEXT%%.*}.csv.cp1250
mv ${FEXT%%.*}.csv.cp1250 ${FEXT%%.*}.csv
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
