#tohle je prevod z serveru nevim jaky
#FROM_SERVER="10.3.21.99"
#FROM_DB="gar"
#FROM_USER="root"
#FROM_PASS="Honda621"

#tohle je prevod z serveru zaloha gar do prace db snake
FROM_SERVER="172.25.15.32"
FROM_DB="snake"
FROM_USER="root"
FROM_PASS="Honda621"
TO_SERVER="192.168.2.4"
TO_USER="jan"
TO_PASS="1qw"
TO_DB="snake"
for TABLE in $(mysql -h$FROM_SERVER -u$FROM_USER -p$FROM_PASS $FROM_DB -se "show tables like 'vm2'")
do
  echo $TABLE
  mysqldump --add-drop-table -C -u$FROM_USER -p$FROM_PASS -h$FROM_SERVER $FROM_DB $TABLE|mysql -C -u$TO_USER -p$TO_PASS -h$TO_SERVER $TO_DB
done
