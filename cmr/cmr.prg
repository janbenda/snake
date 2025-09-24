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
#include "inkey.ch"

#include "dbinfo.ch"

FUNCTION Main()

   LOCAL bLibreOffice, cPath, cReportTemplate, cReportTemplateCommon, nLin, nCol, x, i
   LOCAL bErrBlck1, bErrBlck2, wbName, oExcel, oSheet
   LOCAL oServiceManager, oDesktop, oDoc, oParams
   LOCAL nLen, cBuffer, pFile, oWin, getlist := {}, cmr_server, hOutput, aFields, xField, cAll, xName, xVal, cDL, cAppendix, xValRow, j, nCounter

   xhb_ErrorSys()  // loguji se chyby
   xhb_ErrorLog( , .T. )

   // /pri teto kombinaci to je spravne v Exelu i LO a bez transkodovani, asi to dela samo
   hb_cdpSelect ( "CS852C" )
   hb_SetTermCP ( "CP1250" )
   Set( _SET_DBCODEPAGE, 'CS852C' )

   SetMode( 4, 25 )
   // SetMode( 50, 120 )
   nCounter = zs_set( "nCounter" )
   IF ValType( nCounter ) = "C"
      nCounter = Val( nCounter )
   ENDIF
   cPath = hb_DirSepAdd( hb_DirBase() )
   cReportTemplate = zs_set( 'cReportTemplate' )
   cReportTemplateCommon = zs_set( 'cReportTemplateCommon' )  // sablona bez predvyplneneho dopravce, pouzije se kdyz se prijmen neprazdna treba car_strasse
   bLibreOffice = zs_set( 'bLibreOffice' )
   cmr_server = zs_set( "cmr_server" )
   hOutput = zs_set( "hOutput" )
   hb_HSetCaseMatch( hOutput, .F. )
   LOG "hOutput", hb_ValToExp( hOutput )

   oWin = WOpen( 0, 0, MaxRow(), MaxCol(), .T. )
   Log "GT" + hb_gtVersion() + " " + hb_gtVersion( 1 )

   WSelect( oWin )
   WBox( 0 )

   cDL = Space( 10 )
   @ 1, 1 SAY "Dod.list:" GET cDL PICT "!!!!!!!!!!"
   READ
   IF LastKey() = K_ESC
      LOG "ESC"
      QUIT
   ELSE
      LOG "Zadano: cDL", cDL
      cBuffer = cDL
   ENDIF

   pFile := hb_vfOpen( cmr_server, FO_READWRITE )
   IF !Empty( pFile )
      nLen := hb_vfWrite( pFile, cBuffer,, 1000 )
      LOG "Odeslano cBuffer", cBuffer, "delka", nLen
      cBuffer := Space( 4096 )
      cAll = ""
      WHILE ( nLen := hb_vfRead( pFile, @cBuffer, Len( cBuffer ) ) > 0 )
         LOG "Prijato", nLen, AllTrim( cBuffer )
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

         oDoc := oDesktop:loadComponentFromURL( OO_ConvertToURL( cPath + if( Lower( 'car_strasse' ) $ Lower( cAll ), cReportTemplateCommon, cReportTemplate ) ), "_blank", 0, oParams )
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
         FOR i = 0 TO 2   // pro vicenasobne pouziti v tiskopisu, pouzivam polozku s indexem napr ort_1, ort_2
            IF i = 0
               cAppendix = ""
            ELSE
               cAppendix = "_" + hb_ntoc( i )
            ENDIF
            xName = Left( xField, At( ":", xField ) - 1 )         + cAppendix
            xVal = AllTrim( SubStr( xField, At( ":", xField ) + 1 ) )
            IF Upper( xName ) $ "/CISLO/"  // pro pouziti v nazvu souboru
               cDL = xVal
            ENDIF
            IF !Empty( xName ) .AND. Left( Right( xName, 2 ), 1 ) <> "_"  // logovat jen opravdovou field
               LOG xField, "xName:", xName, "xVal:", xVal
            ENDIF
            IF hb_HHasKey( hOutput, xName )
               nlin = hOutput[ xName ][ 'row' ]
               nCol = hOutput[ xName ][ 'col' ]
               IF "|" $ xVal // viceradkova polozka
                  j = 0
                  FOR EACH xValRow in hb_ATokens( xVal, "|" )
                     WriteCell( bLibreOffice, oSheet, nLin + j, nCol, xValRow )
                     j += 1
                  NEXT xValRow
               ELSE
                  WriteCell( bLibreOffice, oSheet, nLin, nCol, xVal )
               ENDIF
            ELSE
               IF !Empty( xName ) .AND. Left( Right( xName, 2 ), 1 ) <> "_"  // logovat jen opravdovou field
                  LOG xName, "nema v konfiguraci zadane umisteni"
               ENDIF
            ENDIF
         NEXT i
      NEXT
      /* tisk eval hodnot */
      FOR EACH xField in hOutput
         xVal = xField:__enumKey()
         IF Left( xVal, 5 ) = "eval "
            nlin = xField[ 'row' ]
            nCol = xField[ 'col' ]
            xVal = &( SubStr( xVal, 6 ) )
            WriteCell( bLibreOffice, oSheet, nLin, nCol, xVal )
         ENDIF
      NEXT xFields


      // save
      bErrBlck2 := ErrorBlock( {| x | Break( x ) } )
      BEGIN SEQUENCE
         // if the file already exists and it's not open, it's overwritten without asking
         wbName := cPath + StrTran( StrTran( cReportTemplate, "cdl", cDl ), 'cas', StrTran( hb_TToC( hb_DateTime(), "YYMMDD", "HHMMSS" ), " ", "T" ) )
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
   zs_set( "nCounter", hb_ntoc( nCounter + 1 ) )
   readcfg( "counter.ini", .T. )
   LOG  "Zapsan incrementovany counter", nCounter, "?", "curdir()", CurDir(), "hb_dirbase()", hb_DirBase()

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

FUNCTION ReadCfgs()

   /* pro po  tadlo si ud l m odd len  config, at se nep episuje ten s polo kami ale vypada to, ze v ReadCfgs to jest neloguje*/
   IF hb_FileExists( "counter.ini" )
      IF !readcfg( "counter.ini" )
         LOG  "INI KO!"
         QUIT
         RETURN .F.
      ELSE
         LOG  "Nacten counter", " z ini", "counter.ini", "curdir()", CurDir()
      ENDIF
   ELSE
      LOG  "Ini s counter nenalezen", "curdir()", CurDir(), "je v hb_dirbase()", hb_DirBase(), "?"
      IF hb_FileExists( hb_DirBase() + "counter.ini" )
         LOG  "je tu"
      ELSE
         LOG  "Ini s counter nenalezen ani hb_DirBase()", hb_DirBase()
      ENDIF
   ENDIF
   IF !readcfg()
      LOG  "INI KO!"
      QUIT
      RETURN .F.
   ENDIF

   RETURN 0
