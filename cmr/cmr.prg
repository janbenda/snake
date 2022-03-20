
REQUEST SQLMIX, SDDODBC, SDDMY

REQUEST ZS
REQUEST HB_CODEPAGE_CSWIN
REQUEST HB_CODEPAGE_CS852C

#include "hblog.ch"
#include "fileio.ch"
#include "hbcurl.ch"

#include "dbinfo.ch"

FUNCTION Main()

   LOCAL bSQLMIX, bLibreOffice, cPath, cReportTemplate, nField, nFields
   LOCAL conn, sSQL, sSQL1, sSQL2, cKurz, cRok, nRows, nRow, resrow, X
   LOCAL bErrBlck1, bErrBlck2, wbName, oExcel, oSheet, nLin, nCol, xCol, res
   LOCAL oServiceManager, oDesktop, oDoc, oParams

   // /pri teto kombinaci to je sparvne v Exelu i LO a bez transkodovani, asi to dela samo
   hb_cdpSelect ( "CS852C" )
   hb_SetTermCP ( "CP1250" )
   Set( _SET_DBCODEPAGE, 'CS852C' )

   SetMode( 40, 80 )
   IF !readcfg()
      LOG "INI KO!"
      RETURN .F.
   ENDIF
   cPath = hb_DirSepAdd( hb_DirBase() )
   cReportTemplate = zs_set( 'cReportTemplate' )
   sSQL1 = zs_set( 'cSQL_Sales_Contract_Master' )
   sSQL2 = zs_set( 'cSQL_Sales_Contract_Details' )
   cKurz = zs_set( 'cKurz' )
   cRok = zs_set( 'cRok' )
   bLibreOffice = zs_set( 'bLibreOffice' )
   bSQLMIX = zs_set( 'bSQLMIX' )
   IF bLibreOffice .AND. !bSQLMIX
      LOG "V LibreOffice pracuje jen s SQLMIX"
      Alert( "V LibreOffice pracuje jen s SQLMIX" ) // protoze pro zapis do libre potrebuju znat typ promenne z SQl jsem mel vse jako text, datum treba jako "20120-01-001", do excelu se to zapise spravne jako datum, ale v LO to musim znat (asi by sel typ zjistit i SQL, ale v SQLMIX to je taky)
      QUIT
   ENDIF

   IF bSQLMIX
      conn := rddInfo( RDDI_CONNECT, { 'MYSQL', zs_set( 'server' ), zs_set( 'user' ), zs_set( 'pass' ), zs_set( 'cDB' ) }, "SQLMIX" )
      IF conn == 0
         LOG  "Could not connect to SQL server", rddInfo( RDDI_ERRORNO ), rddInfo( RDDI_ERROR )
         QUIT
         RETURN .T.
      ENDIF
      rddInfo( RDDI_EXECUTE, "set character_set_results = 'cp852'", "SQLMIX" ) // CSWIN
   ELSE
      IF ( conn := zs_opendb( nil,  nil,  nil ) ) == nil
         LOG "Connection error:", mysql_error( conn )
         RETURN .F.
      ENDIF
   ENDIF
   sSQL = StrTran( StrTran( sSQL1, "__ROK__", cRok ), "__KURZ__", cKurz )
   LOG sSQL
   IF bSQLMIX
      dbUseArea( .F., "SQLMIX", sSQL, "report" )
      nRows = RecCount()
   ELSE
      IF !zs_query( conn, sSQL )
         LOG "sql " + sSQL + hb_eol() + " error:", mysql_error( conn )
         Alert( mysql_error( conn ) )
         QUIT
      ENDIF
      res = mysql_store_result( conn )
      nRows := mysql_num_rows( res )
   ENDIF
   IF nRows == 0
      LOG "Zadna smlouva"
      res = nil
      conn = nil
      RETURN .F.
   ELSE
      LOG "SQL vraci radku:" + Str( nRows )
   ENDIF
   IF bLibreOffice
      IF ( oServiceManager := win_oleCreateObject( "com.sun.star.ServiceManager" ) ) != NIL
         oDesktop := oServiceManager:createInstance( "com.sun.star.frame.Desktop" )
         oParams := {}
         AAdd( oParams, oServiceManager:Bridge_GetStruct( "com.sun.star.beans.PropertyValue" ) )
         oParams[ 1 ]:Name := "Hidden"
         oParams[ 1 ]:Value := .T.

         oDoc := oDesktop:loadComponentFromURL( OO_ConvertToURL( cPath + cReportTemplate ), "_blank", 0, oParams )
         oSheet := oDoc:getSheets:getByName( 'Sales Contract Master' )
      ELSE
         LOG 'Error: Libre/Open Office not available. [' + win_oleErrorText() + ']'
         RETURN .F.
      ENDIF
   ELSE
      IF ( oExcel := win_oleCreateObject( 'Excel.Application' ) ) == NIL
         LOG 'Error: Excel not available. [' + win_oleErrorText() + ']'
         RETURN .F.
      ENDIF
      oExcel:Visible := .F.
      oExcel:DisplayAlerts := .F.
      oExcel:WorkBooks:Add( cPath + cReportTemplate )
      oSheet := oExcel:Sheets( 'Sales Contract Master' )
   ENDIF
      
   SaveFormat( oSheet, bLibreOffice )
   oSheet := oExcel:Sheets( 'Sales Contract Details' )
   SaveFormat( oSheet, bLibreOffice )
   oSheet := oExcel:Sheets( 'Inventory' )
   SaveFormat( oSheet, bLibreOffice )
   oSheet := oExcel:Sheets( 'CL100' )
   SaveFormat( oSheet, bLibreOffice )
   quit

   // catch any errors
   bErrBlck1 := ErrorBlock( {| x | Break( x ) } )
   BEGIN SEQUENCE
      nLin = 2
      IF bSQLMIX
         nFields = FCount()
      ENDIF
      FOR nRow := 1 TO nRows
         IF bSQLMIX
            nCol = 1
            FOR nField = 1 TO nFields
               // LOG ncol, xCol
               // &( FieldName( nField )
               WriteCell( bLibreOffice, oSheet, nLin, nCol, FieldGet( nField ) )
               nCol++
            NEXT
            SKIP
         ELSE
            resrow := mysql_fetch_row( res )
            nCol = 1
            FOR EACH xCol in resrow
               // LOG ncol, xCol
               WriteCell( bLibreOffice, oSheet, nLin, nCol, xCol )
               nCol++
            NEXT
         ENDIF
         nLin++
         IF Mod( nRow, 1000 ) = 0
            ?nLin, Time()
         ENDIF
      NEXT
      res = nil
      conn = nil
      // another sheet, radsi otevru spojeni znovu protoze to mohlo byt zavreno pro neaktivitu
      IF ( conn := zs_opendb( nil,  nil,  nil ) ) == nil
         LOG "Connection error:", mysql_error( conn )
         // RETURN .F.
      ENDIF

      sSQL = StrTran( StrTran( sSQL2, "__ROK__", cRok ), "__KURZ__", cKurz )
      LOG sSQL
      IF bSQLMIX
         dbUseArea( .F., "SQLMIX", sSQL, "report" )
         nRows = RecCount()
      ELSE
         IF !zs_query( conn, sSQL )
            LOG "sql " + sSQL + hb_eol() + " error:", mysql_error( conn )
            Alert( mysql_error( conn ) )
            QUIT
         ENDIF
         res = mysql_store_result( conn )
         nRows := mysql_num_rows( res )
      ENDIF
      LOG "SQL vraci radku:" + Str( nRows )
      IF bLibreOffice
         oSheet := oDoc:getSheets:getByName( 'Sales Contract Details' )
      ELSE
         oSheet := oExcel:Sheets( 'Sales Contract Details' )
      ENDIF
      SaveFormat( oSheet, bLibreOffice )
      nLin = 2
      IF bSQLMIX
         nFields = FCount()
      ENDIF
      FOR nRow := 1 TO nRows
         IF bSQLMIX
            nCol = 1
            FOR nField = 1 TO nFields
               // LOG ncol, xCol
               WriteCell( bLibreOffice, oSheet, nLin, nCol, FieldGet( nField ) )
               nCol++
            NEXT
            SKIP
         ELSE
            resrow := mysql_fetch_row( res )
            nCol = 1
            FOR EACH xCol in resrow
               // LOG ncol, xCol
               WriteCell( bLibreOffice, oSheet, nLin, nCol, xCol )
               nCol++
            NEXT
         ENDIF
         nLin++
         IF Mod( nRow, 1000 ) = 0
            ?nLin
         ENDIF
      NEXT
      res = nil
      // save
      bErrBlck2 := ErrorBlock( {| x | Break( x ) } )
      BEGIN SEQUENCE
         // if the file already exists and it's not open, it's overwritten without asking
         wbName := cPath + StrTran( StrTran( cReportTemplate, "ZYYY", cRok ), 'CC', 'CZ' )
         IF bLibreOffice
            oParams := {}
            AAdd( oParams, oServiceManager:Bridge_GetStruct( "com.sun.star.beans.PropertyValue" ) )
            oParams[ 1 ]:Name := "Overwrite"
            oParams[ 1 ]:Value := .T.
            AAdd( oParams, oServiceManager:Bridge_GetStruct( "com.sun.star.beans.PropertyValue" ) )
            oParams[ 2 ]:Name := 'FilterName'
            oParams[ 2 ]:Value := 'Calc MS Excel 2007 XML'
            oDoc:storeAsURL( OO_ConvertToURL( wbName ), oParams )
            oDoc:Close( .T. )
            oDesktop:Terminate()
         ELSE
            oSheet:SaveAs( wbName )
            // close and remove the copy of EXCEL.EXE from memory
            oExcel:WorkBooks:Close()
            oExcel:Quit()
         ENDIF
         LOG  wbName + ' was created !!!'
         LOG "Jdu na upload"
         IF Upload2sFTP( wbName )
            LOG  wbName + ' was Uploaded'
         ELSE
            LOG  wbName + ' was not Uploaded'
         ENDIF
      RECOVER USING x
         // if oSheet:SaveAs() fails, show the error
         LOG x:Description, "Excel Error"

         // close and remove the copy of EXCEL.EXE from memory
         hb_SendMail( "smtp.zepter.cz", 25, 'scheuer@zepter.cz', 'scheuer@zepter.cz', NIL, { nil }, '', 'Chyba report oSheet:SaveAs() fails, show the error ' + x:Description, nil, NIL, NIL, NIL, NIL, NIL, .F., .F., .T., NIL, NIL, NIL, NIL, "windows-1250", 'base64', NIL )
         IF bLibreOffice
            oDoc:Close( .T. )
            oDesktop:Terminate()
         ELSE
            oExcel:WorkBooks:Close()
            oExcel:Quit()
         ENDIF
         LOG hb_DirBase() + wbName + ' was not created !!!'
         QUIT
      END SEQUENCE

      ErrorBlock( bErrBlck2 )
   RECOVER USING x
      LOG  x:Description, "Excel Error"
      hb_SendMail( "smtp.zepter.cz", 25, 'scheuer@zepter.cz', 'scheuer@zepter.cz', NIL, { nil }, '', 'Chyba report Excel Error ' + x:Description, nil, NIL, NIL, NIL, NIL, NIL, .F., .F., .T., NIL, NIL, NIL, NIL, "windows-1250", 'base64', NIL )
      oSheet := NIL
      oExcel := NIL
      QUIT
   END SEQUENCE
   ErrorBlock( bErrBlck1 )

   oSheet := NIL
   oExcel := NIL
   conn = nil

   RETURN .T.


STATIC FUNCTION Upload2sFTP( sFile )

   LOCAL _ret := 0
   LOCAL curl
   LOCAL lVerbose := .T.
   LOCAL cFtpHost, cFtpPort, cFtpUser, cFtpPass, cFtpUrl

   cFtpHost = zs_set( 'cFtpHost' )
   cFtpPort = zs_set( 'cFtpPort' )
   cFtpUser = zs_set( 'cFtpUser' )
   cFtpPass = zs_set( 'cFtpPass' )

   cFtpUrl = 'ftp://' + cFtpHost + ':' + cFtpPort + '/'

   LOG "INIT:", curl_global_init()
   LOG "k uploadu soubor:", sFile
   LOG "na URL:", cFtpUrl

   IF ! Empty( curl := curl_easy_init() )

      curl_easy_setopt( curl, HB_CURLOPT_UPLOAD )
      curl_easy_setopt( curl, HB_CURLOPT_USE_SSL, 0 )
      curl_easy_setopt( curl, HB_CURLOPT_URL, cFtpUrl + hb_FNameNameExt( sFile )  )
      curl_easy_setopt( curl, HB_CURLOPT_USERPWD, cFtpUser + ':' + cFtpPass )

      curl_easy_setopt( curl, HB_CURLOPT_UL_FILE_SETUP, sFile )
      curl_easy_setopt( curl, HB_CURLOPT_VERBOSE, lVerbose )
      // curl_easy_setopt( curl, HB_CURLOPT_SSH_PRIVATE_KEYFILE, "gpg\zepter" )

      IF ( _ret := curl_easy_perform( curl ) ) = 0
         LOG " Successfully upload na sftp " + hb_FNameNameExt( sFile )
      ELSE
         LOG "Error uploading na sftp " + hb_FNameNameExt( sFile ), _ret
      ENDIF
      curl_easy_reset( curl )

   ENDIF

   curl_global_cleanup()

   RETURN if( _ret == 0, .T., .F. )

STATIC FUNCTION OO_ConvertToURL( cString )

   // ; Handle UNC paths
   IF !( Left( cString, 2 ) == "\\" )
      cString := StrTran( cString, ":", "|" )
      cString := "///" + cString
   ENDIF

   cString := StrTran( cString, "\", "/" )
   cString := StrTran( cString, " ", "%20" )

   RETURN "file:" + cString

STATIC FUNCTION WriteCell( bLibreOffice, oSheet, nLin, nCol, xCol )

   IF bLibreOffice
      switch ValType( xCol )
      CASE "C"
         oSheet:GetCellByPosition( ncol - 1, nLin - 1 ):setString(  xCol )
         EXIT
      CASE "N"
         oSheet:GetCellByPosition( ncol - 1, nLin - 1 ):setValue( xCol )
         EXIT
      CASE "D"
         oSheet:GetCellByPosition( ncol - 1, nLin - 1 ):setValue( xCol )
         oSheet:GetCellByPosition( ncol - 1, nLin - 1 ):setPropertyValue( "NumberFormat", 36 )
         EXIT
      OTHERWISE
         oSheet:GetCellByPosition( ncol - 1, nLin - 1 ):setString( xCol )
         EXIT
      END switch
   ELSE
      oSheet:Cells( nLin, nCol ):Value := xCol
   ENDIF

   RETURN .T.

FUNCTION SaveFormat( oSheet, bLibreOffice )

   // ulozi format hlavicky pro pouzit v libxlswriteru (ten neumi nacist sablonu, umi jen excel vytvorit
   LOCAL oParams := {}
   LOCAL xCursorPropsInfo, prt, prts, hPrts, nCol

   IF zs_set( 'bSaveFormat' )

      IF bLibreOffice
         FOR nCol = 1 TO 50
            AAdd( oParams, {} )
            xCursorPropsInfo = oSheet:GetCellByPosition( ncol - 1, 0 ):getPropertySetInfo()
            prts = xCursorPropsInfo:getProperties()
            hPrts = { 'getString' => oSheet:GetCellByPosition( ncol - 1, 0 ):getString() }
            FOR EACH prt in prts
               hb_HMerge( hPrts, { prt:name => oSheet:GetCellByPosition( ncol - 1, 0 ):getPropertyValue( prt:name ) } )
            NEXT
            oParams[ nCol ] = hPrts
         NEXT
         hb_MemoWrit( 'ColumnsDef' + iif( bLibreOffice, 'LO', 'Excel' ) + hb_ntos( oSheet:RangeAddress:Sheet ) + '.hash', hb_Serialize( oParams ) )
         hb_MemoWrit( 'ColumnsDef' + iif( bLibreOffice, 'LO', 'Excel' ) + hb_ntos( oSheet:RangeAddress:Sheet ) + '.txt', hb_ValToExp( oParams ) )
      ELSE
         FOR nCol = 1 TO 50
            AAdd( oParams, {} )
            hPrts = { 'Value' => oSheet:Cells( 1, ncol ):value }
            hb_HMerge( hPrts, { 'NumberFormat' => oSheet:Cells( 1, ncol ):NumberFormat } )
            hb_HMerge( hPrts, { 'WrapText' => oSheet:Cells( 1, ncol ):WrapText } )
            hb_HMerge( hPrts, { 'Font:Name' => oSheet:Cells( 1, ncol ):Font:Name } )
            hb_HMerge( hPrts, { 'Font:FontStyle' => oSheet:Cells( 1, ncol ):Font:FontStyle } )
            hb_HMerge( hPrts, { 'Font:Size' => oSheet:Cells( 1, ncol ):Font:Size } )
            hb_HMerge( hPrts, { 'Font:ColorIndex' => oSheet:Cells( 1, ncol ):Font:ColorIndex } )
            hb_HMerge( hPrts, { 'Interior:ColorIndex' => oSheet:Cells( 1, ncol ):Interior:ColorIndex } )
            oParams[ nCol ] = hPrts
         NEXT
         hb_MemoWrit( 'ColumnsDef' + iif( bLibreOffice, 'LO', 'Excel' ) + hb_ntos( oSheet:index ) + '.hash', hb_Serialize( oParams ) )
         hb_MemoWrit( 'ColumnsDef' + iif( bLibreOffice, 'LO', 'Excel' ) + hb_ntos( oSheet:index ) + '.txt', hb_ValToExp( oParams ) )
      ENDIF
   ENDIF

   RETURN .T.

function WIN_OLECREATEOBJECT()
return nil
function  WIN_OLEERRORTEXT()
return nil
