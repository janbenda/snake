REQUEST DBFNTX
REQUEST HB_CODEPAGE_CSWIN
REQUEST HB_CODEPAGE_CSISO
REQUEST HB_CODEPAGE_CS852

#include "hblibxlsxwriter.ch"
#include "dbstruct.ch"
#include "hbgtinfo.ch"

FUNCTION Main( sDbfFile, bFieldNames, sDbfEncoding )

   LOCAL workbook, worksheet, row, col, wbName, i, nFCount
   LOCAL dateformat

   IF ValType( bFieldNames ) = "C"
      bFieldNames = &bFieldNames
   ENDIF

   hb_default( @bFieldNames, .T. )
   hb_default( @sDbfEncoding, "cp852" )

   SET DELE ON
   SET EXCL OFF
   Set( _SET_DATEFORMAT, "dd.mm.yyyy" )
   hb_cdpSelect ( "CS852" )
   // hb_SetTermCP ( "CS852" )

   rddSetDefault( "DBFNTX" )
   IF !Empty( sDbfFile ) .AND. Upper( Right( sDbfFile, 4 ) ) <> ".DBF"
      sDbfFile = sDbfFile + ".dbf"
   ENDIF
   IF Empty( sDbfFile ) .OR. !File( sDbfFile )
      ?"Pouziti: dbf2xls  sDbfFile, bFieldNames, sDbfEncoding"
      QUIT
   ENDIF
   // ? "ZS_INIT " + ExeName() + " Initialized " + Version() + " " + rddSetDefault() + " indexExt:" + IndexExt() + " ordBagExt:" + ordBagExt() + " CP:" + hb_cdpSelect() + " GT" + hb_gtVersion() + " " + hb_gtVersion( 1 ) + " LockScheme:" + hb_ntos( Set( _SET_DBFLOCKSCHEME ) ) + " font size=" + AllTrim( Str( hb_gtInfo( HB_GTI_FONTSIZE ) ) )

   lxw_init()

   /* Start from the first cell. Rows and columns are zero indexed. */
   row := 0
   col := 0

   USE ( sDbfFile ) SHARED READONLY
   IF NetErr()
      ?"Chyba pri otevreni " + sDbfFile
      QUIT
   ENDIF

   /* Create a workbook and add a worksheet. */
   wbName := StrTran( sDbfFile, '.dbf', '.xlsx' )
   IF File( wbName )
      FErase( wbName )
   ENDIF
   workbook := lxw_workbook_new( wbName )
   worksheet := lxw_workbook_add_worksheet( workbook, NIL )
   dateformat  := lxw_workbook_add_format(workbook)
   lxw_format_set_num_format(dateformat, "DD.MM.YYYY")
   nFCount := FCount()
   FOR i := 1 TO nFCount
      lxw_worksheet_set_column( worksheet, col + i - 1, col + i - 1, Max( Len( FieldName( i ) ), FieldLen( i ) ) * 1.2, NIL )
   NEXT i
   IF bFieldNames
      FOR i := 1 TO nFCount
         WriteColumn( worksheet, row, col + i - 1, FieldName( i ), sDbfEncoding )
      NEXT i
      row = row + 1
   ENDIF
   GO TOP
   WHILE !Eof()
      FOR i := 1 TO nFCount
         WriteColumn( worksheet, row, col + i - 1, FieldGet( i ), sDbfEncoding, dateformat )
      NEXT i
      row = row + 1
      SKIP
   END

   /* Save the workbook and free any allocated memory. */

   RETURN lxw_workbook_close( workbook )

STATIC FUNCTION WriteColumn( worksheet, row, col, Value, sDbfEncoding, dateformat )

   SWITCH ValType( Value )
   CASE "C" ; lxw_worksheet_write_string( worksheet, row, col, hb_Translate( Value, sDbfEncoding, "UTF8" ), NIL );EXIT
   CASE "N" ; lxw_worksheet_write_number( worksheet, row, col, Value, NIL );EXIT
   CASE "L" ; lxw_worksheet_write_boolean( worksheet, row, col, iif( Value, 1, 0 ), NIL );EXIT
   CASE "D" ; lxw_worksheet_write_datetime( worksheet, row, col, Value, dateformat );EXIT
   ENDSWITCH

   RETURN .T.
