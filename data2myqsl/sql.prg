REQUEST HB_CODEPAGE_CSISO

FUNCTION sql_opendb( cHostName,  cDBUser,  cDBPass )

   LOCAL conn
   local _cpsql:='latin2'
   hb_default( @cHostName, "80.82.152.87" ) 
   hb_default( @cDBUser, "import" )
   hb_default( @cDBPass, "Honda621" )
/* tohle se mi zatim nepodarilo rozchodit asi mam spatne poradi parametru ted delam hlaseni mavela, tak specham necham to na proiste neslo to kvuli db, musi byt neco zadano mozna i nil? 
   conn = rddInfo( RDDI_CONNECT, { "MYSQL", cHostName,  cDBUser,  cDBPass,"zeptersoft" }, "SQLMIX" )
   IF Empty( conn ) .or. conn == 0
      ? "Unable connect to server", rddInfo( RDDI_ERRORNO ), rddInfo( RDDI_ERROR )
      RETURN NIL
   ENDIF
   rddInfo( RDDI_EXECUTE, "set character_set_client = '" + _cpsql + "'", "SQLMIX" )
   rddInfo( RDDI_EXECUTE, "set character_set_results = '" + _cpsql + "'", "SQLMIX" )
   rddInfo( RDDI_EXECUTE, "set character_set_connection = '" + _cpsql + "'", "SQLMIX" )
*/

   conn := mysql_real_connect( cHostName,  cDBUser,  cDBPass )
   IF  Empty( conn ) .OR. !( mysql_error( conn ) == "" )
      RETURN NIL
   ENDIF
   mysql_query( conn, "set character_set_client = '" + _cpsql + "'" )
   mysql_query( conn, "set character_set_results = '" + _cpsql + "'" )
   mysql_query( conn, "set character_set_connection = '" + _cpsql + "'" )

   RETURN conn

FUNCTION sql_query( conn, sSQL )

/* tohle se mi zatim nepodarilo rozchodit asi mam spatne poradi parametru ted delam hlaseni mavela, tak specham necham to na proiste 
   rddInfo( RDDI_EXECUTE, sSQL, "SQLMIX" )
   dbUseArea( .T., , sSQL, "country" )  //taky nejaky posledni parametr potrebuj espojeni, protoze obcas mam vice spojeni a nechi pouzit default aby nebylo out of sync
*/

   mysql_query( conn, sSQL )
   IF  !( mysql_error( conn ) == "" )
      RETURN .F.
   ENDIF

   RETURN .T.

