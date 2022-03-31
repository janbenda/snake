// REQUEST SQLMIX, SDDODBC, SDDMY
REQUEST HB_TCPIO

REQUEST ZS
REQUEST HB_CODEPAGE_CSWIN
REQUEST HB_CODEPAGE_CS852C

#include "hblog.ch"
#include "fileio.ch"
#include "hbcurl.ch"
#include "hbgtinfo.ch"
// #include "box.ch"

#include "dbinfo.ch"

FUNCTION Main()

   LOCAL bLibreOffice, cPath, cReportTemplate, nLin, nCol, x
   LOCAL bErrBlck1, bErrBlck2, wbName, oExcel, oSheet
   LOCAL oServiceManager, oDesktop, oDoc, oParams
   LOCAL nLen, cBuffer, pFile, oWin, getlist := {}, cmr_server, hOutput, aFields, xField, cAll, xName, xVal, cKdnr

   // /pri teto kombinaci to je sparvne v Exelu i LO a bez transkodovani, asi to dela samo
   hb_cdpSelect ( "CS852C" )
   hb_SetTermCP ( "CP1250" )
   Set( _SET_DBCODEPAGE, 'CS852C' )

// SetMode( 5, 25 )
   SetMode( 50, 120 )
   IF !readcfg()
      LOG "INI KO!"
      RETURN .F.
   ENDIF
   cPath = hb_DirSepAdd( hb_DirBase() )
   cReportTemplate = zs_set( 'cReportTemplate' )
   bLibreOffice = zs_set( 'bLibreOffice' )
   cmr_server = zs_set( "cmr_server" )
   hOutput = zs_set( "hOutput" )
   hb_HSetCaseMatch( hOutput, .F. )
   LOG "hOutput", hOutput

   oWin = WOpen( 0, 0, MaxRow(), MaxCol(), .T. )
   Log "GT" + hb_gtVersion() + " " + hb_gtVersion( 1 )

   WSelect( oWin )
   WBox( 0 )
   cBuffer = "100003" // Space( 6 )
   @ 1, 1 SAY "Zakaznik:" GET cBuffer PICT "999999"
   READ
   WClose()
   LOG "Zadano", cBuffer

   pFile := hb_vfOpen( cmr_server, FO_READWRITE )
   IF !Empty( pFile )
      nLen := hb_vfWrite( pFile, cBuffer,, 1000 )
      LOG "Odesláno cBuffer", cBuffer, "delka", nLen
      cBuffer := Space( 4096 )
      cAll = ""
      WHILE ( nLen := hb_vfRead( pFile, @cBuffer, Len( cBuffer ) ) > 0 )
         LOG "Přijato", nLen, AllTrim( cBuffer )
         cAll += AllTrim( cBuffer )
         cBuffer := Space( 4096 )
      END
      hb_vfClose( pFile )
   ELSE
      LOG "pFile", pFile
      cBuffer = "Nepodarilo se spojit se zakladnou" + ' ' + cmr_server
      LOG cBuffer
      QUIT
   ENDIF
   aFields = hb_ATokens( cAll, "\n" )

   IF bLibreOffice
      IF ( oServiceManager := win_oleCreateObject( "com.sun.star.ServiceManager" ) ) != NIL
         oDesktop := oServiceManager:createInstance( "com.sun.star.frame.Desktop" )
         oParams := {}
         AAdd( oParams, oServiceManager:Bridge_GetStruct( "com.sun.star.beans.PropertyValue" ) )
         oParams[ 1 ]:Name := "Hidden"
         oParams[ 1 ]:Value := !zs_set( 'visible' )

         oDoc := oDesktop:loadComponentFromURL( OO_ConvertToURL( cPath + cReportTemplate ), "_blank", 0, oParams )
// oSheet := oDoc:getSheets:getByName( 'ZCA LIVE Current' )
         oSheet := oDoc:getSheets:getByIndex( 0 )
      ELSE
         LOG 'Error: Libre/Open Office not available. [' + win_oleErrorText() + ']'
         RETURN .F.
      ENDIF
   ELSE
      IF ( oExcel := win_oleCreateObject( 'Excel.Application' ) ) == NIL
         LOG 'Error: Excel not available. [' + win_oleErrorText() + ']'
         RETURN .F.
      ENDIF
      oExcel:Visible := zs_set( 'visible' )
      oExcel:DisplayAlerts := .F.
      oExcel:WorkBooks:Add( cPath + cReportTemplate )
      oSheet := oExcel:ActiveSheet
   ENDIF

   // catch any errors
   bErrBlck1 := ErrorBlock( {| x | Break( x ) } )
   BEGIN SEQUENCE
      LOG "aFields"
      FOR EACH xField in aFields
         xName = Left( xField, At( ":", xField ) - 1 )
         xVal = AllTrim( SubStr( xField, At( ":", xField ) + 1 ) )
         IF Upper( xName ) $ "KDNR/CISLO"  // pro pouziti v nazvu souboru
            cKdnr = xVal
         ENDIF
         LOG xField, "xName:", xName, "xVal:", xVal
         IF hb_HHasKey( hOutput, xName )
            nlin = hOutput[ xName ][ 'row' ]
            nCol = hOutput[ xName ][ 'col' ]
            WriteCell( bLibreOffice, oSheet, nLin, nCol, xVal )
         ELSE
            LOG xName, "nema v konfiguraci zadane umisteni"
         ENDIF
      NEXT
      // save
      bErrBlck2 := ErrorBlock( {| x | Break( x ) } )
      BEGIN SEQUENCE
         // if the file already exists and it's not open, it's overwritten without asking
         wbName := cPath + StrTran( StrTran( cReportTemplate, "kdnr", cKdnr ), 'cas', StrTran( hb_TToC( hb_DateTime(), "YYMMDD", "HHMMSS" ), " ", "T" ) )
         IF bLibreOffice
            oParams := {}
            AAdd( oParams, oServiceManager:Bridge_GetStruct( "com.sun.star.beans.PropertyValue" ) )
            oParams[ 1 ]:Name := "Overwrite"
            oParams[ 1 ]:Value := .T.
            AAdd( oParams, oServiceManager:Bridge_GetStruct( "com.sun.star.beans.PropertyValue" ) )
            oParams[ 2 ]:Name := 'FilterName'
            oParams[ 2 ]:Value := 'Calc MS Excel 2007 XML'
            oDoc:storeAsURL( OO_ConvertToURL( wbName ), oParams )
            IF !zs_set( 'visible' )
               oDoc:Close( .T. )
               oDesktop:Terminate()
            ENDIF
         ELSE
            oSheet:SaveAs( wbName )
            // close and remove the copy of EXCEL.EXE from memory
            IF !zs_set( 'visible' )
               oExcel:WorkBooks:Close()
               oExcel:Quit()
            ENDIF
         ENDIF
         LOG  wbName + ' was created !!!'
      RECOVER USING x
         // if oSheet:SaveAs() fails, show the error
         LOG x:Description, "Excel Error"

         // close and remove the copy of EXCEL.EXE from memory
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
      oSheet := NIL
      oExcel := NIL
      QUIT
   END SEQUENCE
   ErrorBlock( bErrBlck1 )

   IF !zs_set( 'visible' )
      oSheet := NIL
      oExcel := NIL
   ENDIF

   RETURN .T.



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
      LOG "Zapisuji xCol=", xCol, "ValType( xCol )=", ValType( xCol )
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
         LOG "Zapsano xCol=", xCol, "ValType( xCol )=", ValType( xCol ),  "NumberFormat:", 36
         EXIT
      CASE "T"
         oSheet:GetCellByPosition( ncol - 1, nLin - 1 ):setValue( xCol )
         oSheet:GetCellByPosition( ncol - 1, nLin - 1 ):setPropertyValue( "NumberFormat", 36 )
         LOG "Zapsano xCol=", xCol, "ValType( xCol )=", ValType( xCol ),  "NumberFormat:", 36
         EXIT
      OTHERWISE
         oSheet:GetCellByPosition( ncol - 1, nLin - 1 ):setString( xCol )
         EXIT
      END switch
   ELSE
      oSheet:Cells( nLin, nCol ):Value := xCol
   ENDIF

   RETURN .T.
