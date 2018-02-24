REQUEST HB_CODEPAGE_CS852
REQUEST HB_CODEPAGE_CSWIN
REQUEST HB_CODEPAGE_CS852C    // clipper kompatibilni tabulka


#require "hbmysql"

#include "inkey.ch"

STATIC cdp_dbf, cdp_sql
STATIC sRootDir // := hb_DirSepDel( hb_DirBase() )
STATIC aFileMask // := { { "plan/steel.dbf", {} }, { "normy/buprod*dbf", {} }, { "normy/bunv*.dbf", {} }, { "normy/bunk*.dbf", {} }, { "normy/burez*.dbf", {} }, { "normy/bumezc*.dbf", {} }, { 'normy/mezc*.dbf', {} }, { "normy/butar*.dbf", {} }, { 'dta/vm1.dbf', { 'kdnr' } }, { "dta/buvm2*dbf", {} }, { "dta/vm21.dbf", { "v_typ,lager,c_rok1,c_mes1,artnr" } }, { "dta/fi3.dbf", {} }, { "dta/fi9.dbf", {}  }, { "dta/vm15.dbf", {}  } }
STATIC cHostName // := "172.25.15.32" // "10.10.222.15" // "80.82.152.87"
STATIC cUser // := "root"
STATIC cPassword // := "Honda621"
STATIC cDatabase // := "snake"
STATIC cBatchSQL // nazev souboru s SQL prikazy k vykonani po importu presun mezc do jedne tabulky apod

#include "directry.ch"

FUNCTION main

   LOCAL cExt, cPath, cFile, sFileMask

   readcfg()
   SetMode( 25, 80 )

   FOR EACH sFileMask in aFileMask
      hb_FNameSplit( sFileMask[ 1 ], @cPath, @cFile, @cExt )
      // AEval( hb_DirScan( sRootDir+"/"+cPath, cFile+cExt ), {| x | ImportFile( sRootDir+"/"+cPath + x[ F_NAME ] ) } )
      AEval( Directory( sRootDir + "/" + cPath + "/" + cFile + cExt ), {| x | ImportFile( sRootDir + "/" + cPath + x[ F_NAME ], sFileMask[ 2 ] ) } )
   NEXT sFileMask
// vykonani batch SQL
   RunBatchSQL( cBatchSQL )

   RETURN .T.

FUNCTION ImportFile ( sFile, aIndexy )

   LOCAL cExt, cPath, cFile

   hb_FNameSplit( sFile, @cPath, @cFile, @cExt )
   dbf2mysq( sFile, aIndexy )

   RETURN .T.


PROCEDURE dbf2mysq( cFile, aIndexy )

   STATIC nNumFields, aFieldStruct
   LOCAL i
   LOCAL lCreateTable := .T.
   LOCAL oServer, oTable, cTable
   LOCAL tStart := Secs( Time() )
   LOCAL cInsertQuery
   LOCAL j, MaxRecords := 50, Conn, SQLrow, SQLres
   LOCAL cExt, cPath
   LOCAL _ret, iKey

   SET DELE ON
   Set( _SET_DATEFORMAT, "yyyy-mm-dd" )
   SetMode( 40, 120 )
   hb_cdpSelect ( cdp_sql )
   Set( _SET_DBCODEPAGE, cdp_dbf )
   cdp_sql = hb_cdpSelect()
   cdp_dbf = Set( _SET_DBCODEPAGE )
   hb_SetTermCP ( 'CSISO' )
   QOut( cFile )


   hb_FNameSplit( cFile, @cPath, @cTable, @cExt )

   USE ( cFile ) SHARED READONLY
   _vet := RecCount()
   nNumFields := FCount()
   aFieldStruct = dbStruct()

   newStruct := AClone( aFieldStruct )
   FOR i = 1 TO nNumFields
      IF newStruct[ i, F_NAME ] == 'OR'
         newStruct[ i, F_NAME ] := newStruct[ i, F_NAME ] + "_"
      ENDIF
   NEXT i
   aFieldStruct := AClone( newStruct )
   newStruct = nil

   oServer := TMySQLServer():New( cHostName, cUser, cPassword )
   IF oServer:NetErr()
      ? oServer:Error()
      RETURN
   ENDIF

   oServer:SelectDB( cDatabase )
   IF oServer:NetErr()
      ? oServer:Error()
      RETURN
   ENDIF

   IF lCreateTable
      IF hb_AScan( oServer:ListTables(), cTable,,, .T. ) > 0
         oServer:DeleteTable( cTable )
         IF oServer:NetErr()
            ? oServer:Error()
            RETURN
         ENDIF
      ENDIF
      oServer:CreateTable( cTable, aFieldStruct )
      IF oServer:NetErr()
         ? oServer:Error()
         RETURN
      ENDIF
   ENDIF

   // Initialize MySQL table
   oTable := oServer:Query( "SELECT * FROM " + cTable + " LIMIT 1" )
   IF oTable:NetErr()
      ? oTable:Error()
      RETURN
   ENDIF

   IF ( conn := sql_opendb( cHostName,  cUser,  cPassword ) ) == nil
      ? "Connection error:", mysql_error( conn )
      RETURN
   ENDIF



   DO WHILE ! Eof() .AND. hb_keyStd( Inkey() ) != K_ESC


      // field names

      cInsertQuery := "INSERT INTO " + cDatabase + "." + cTable + " ("
      FOR i := 1 TO nNumFields
         cInsertQuery += aFieldStruct[ i ][ 1 ] + ","
      NEXT
      // remove last comma from list
      cInsertQuery := hb_StrShrink( cInsertQuery ) + ") VALUES ("
      j = 1
      DO WHILE ! Eof() .AND. j <= MaxRecords
         // field values
         FOR i := 1 TO nNumFields
            cInsertQuery += HarbValueToSQL( FieldGet( i ) ) + ","
         NEXT

         cInsertQuery := hb_StrShrink( cInsertQuery ) + "),("
         j = j + 1
         IF RecNo() % 1000 == 0
            DevPos( Row(), 50 )
            DevOut( hb_ntos( _vet ) + " " + hb_ntos( RecNo() ) )
            // DevOut( "imported recs:", hb_ntos( RecNo() ) )
         ENDIF
         dbSkip()
      ENDDO
      cInsertQuery := hb_StrShrink( cInsertQuery, 2 )
      // ?cInsertQuery
      IF !sql_query( conn, cInsertQuery )
         ? "sql " + cInsertQuery + hb_eol() + " error:", mysql_error( conn )
         EXIT
      ENDIF
   ENDDO
   cInsertQuery = "select count(*) as importovano from " + cDatabase + "." + cTable
   IF sql_query( conn, cInsertQuery  )
      SQLres = mysql_store_result( conn )
      SQLrow := mysql_fetch_row( SQLres )
   ELSE
      ?"Import neuspesny!"
      ? "sql " + cInsertQuery + hb_eol() + " error:", mysql_error( conn )
   ENDIF
   dbCloseArea()

   oTable:Destroy()
   oServer:Destroy()
   FOR EACH iKey in aIndexy
      cInsertQuery = "alter table " + cDatabase + "." + cTable + " add index " + StrTran( StrTran( ikey, ' ', '' ), ',', '_' ) + "( " + iKey + " )"
      IF sql_query( conn, cInsertQuery  )
      ELSE
         ? "sql " + cInsertQuery + hb_eol() + " error:", mysql_error( conn )
      ENDIF
   NEXT keys

   RETURN

STATIC FUNCTION HarbValueToSQL( Value )

   SWITCH ValType( Value )
   CASE "N" ; RETURN hb_ntos( Value )
   CASE "D" ; RETURN iif( Empty( Value ), "null", "'" + hb_DToC( Value, "yyyy-mm-dd" ) + "'" )
   CASE "T" ; RETURN iif( Empty( Value ), "null", "'" + hb_TToC( Value, "yyyy-mm-dd", "hh:mm:ss" ) + "'" )
      // CASE "C" ; RETURN iif( Empty( Value ), "''", "'" + mysql_escape_string(hb_translate( Value, cdp_dbf, cdp_sql  )) + "'" )
   CASE "C" ; RETURN iif( Empty( Value ), "null", "'" + mysql_escape_string( Value ) + "'" )
   CASE "M"
   CASE "W" ; RETURN iif( Empty( Value ), "''", "'" + mysql_escape_string( value ) + "'" )
   CASE "L" ; RETURN iif( Value, "1", "0" )
   CASE "U" ; RETURN "NULL"
   ENDSWITCH

   RETURN "''"  // NOTE: Here we lose values we cannot convert


STATIC FUNCTION readcfg()

   IF Empty( hIni := hb_iniRead( ExeName() + ".ini" ) )
      ? ExeName() + ".ini"  + " is Not a valid .ini file!"
      QUIT
   ELSE
      cSection = 'DBF'
      sRootDir = hIni[ cSection ][ 'RootDir' ]
      aFileMask = &( hIni[ cSection ][ 'FileMask' ] )
      cdp_dbf = hIni[ cSection ][ 'cdp_dbf' ]

      cSection = 'SQL'
      cdp_sql = hIni[ cSection ][ 'cdp_sql' ]
      cHostName = hIni[ cSection ][ 'HostName' ]
      cUser := hIni[ cSection ][ 'User' ]
      cPassword := hIni[ cSection ][ 'Password' ]
      cDatabase := hIni[ cSection ][ 'Database' ]
      cBatchSQL := hIni[ cSection ][ 'BatchSQL' ]
   ENDIF

   RETURN .T.

FUNCTION RunBatchSQL( cBatchSQL )

   LOCAL oServer, oFile, Conn, cStartTime

   IF ! hb_FNameExists( cBatchSQL )
      RETURN .F.
   ENDIF

   IF ( conn := sql_opendb( cHostName,  cUser,  cPassword ) ) == nil
      ? "Connection error:", mysql_error( conn )
      RETURN
   ENDIF
   cQuery = "use " + cDatabase
   IF sql_query( conn, cQuery )
      ? "sql " + cQuery + hb_eol() + " OK"
   ELSE
      ? "sql " + cQuery + hb_eol() + " error:", mysql_error( conn )
   ENDIF

   oFile := TFileRead():New( cBatchSQL )
   oFile:Open()
   IF oFile:Error()
      ? oFile:ErrorMsg( "FileRead: " )
      ? hb_eol()
   ELSE
      DO WHILE oFile:MoreToRead()
         cQuery = oFile:ReadLine()
         IF ! Empty( cQuery )
            cStartTime = Time()
            IF sql_query( conn, cQuery  )
               ? Time() + " sql " + cQuery + hb_eol() + " OK " + ElapTime( cStartTime, Time() )
            ELSE
               ? "sql " + cQuery + hb_eol() + " error:", mysql_error( conn )
            ENDIF
         ENDIF
      ENDDO
      oFile:Close()
   ENDIF

   RETURN .T.
