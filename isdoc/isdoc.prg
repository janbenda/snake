


REQUEST DBFNTX
REQUEST ZS
REQUEST HB_CODEPAGE_CS852
REQUEST HB_CODEPAGE_CSWIN
REQUEST HB_CODEPAGE_CSISO
REQUEST HB_CODEPAGE_UTF8

#include "hblog.ch"
MEMVAR hISDOC

FUNCTION main ( cISDOCFile, cISDOCEncoding )

   LOCAL oldCP := hb_cdpSelect(  zs_set( "cDbfEncoding" ) )
   LOCAL cISDOC
   LOCAL hTable, hElem, subElem, ssubElem, hItems, hI_H := zs_set( "I_H" ), xVal, hNode, tName, ttName
   PRIVA hISDOC
   hb_SetTermCP( hb_defaultValue( zs_set( "TermCP" ), "CSISO" ) ) // hb_SetTermCP( "UTF8" )

   //Set( _SET_DBCODEPAGE, zs_set( "cDbfEncoding" ) )

   IF Empty( cISDOCFile )
      cISDOCFile = zs_set( "cISDOCFile" ) // "FV19091834.ISDOC"
   ENDIF
/* je treba dodelat zjiteni kodovani a dle toho prekodovat do UTF8 */
   hb_default( @cISDOCEncoding, "UTF8" )  // dle specifikace musi být v UTF8, ale budu to taky brat z parametru
   
   LOG "oldCP", oldCP, "ActualCP", hb_cdpSelect(), "cISDOCFile", cISDOCFile, "cISDOCEncoding", cISDOCEncoding, "cDbfEncoding", zs_set( "cDbfEncoding" ) 
   cISDOC := hb_MemoRead( cISDOCFile  )
   //zkusim konvertovat az pred zapisem do dbf,zatimbudu pracovat v utf8 cISDOC := hb_Translate( cISDOC, cISDOCEncoding, hb_cdpselect() )
   cISDOC := hb_Translate( cISDOC, cISDOCEncoding, "UTF8" )
   hISDOC := hb_XMLtoHash( cISDOC, .T. )  // omit header

   FOR EACH hTable in hI_H
      // jmeno tabulky a v nem
      tName = hTable:__enumkey()
      CreateDBFTable( tName )
      add_rec()      // hned si prodam vetu
      FOR EACH hElem in hTable:__enumvalue()
         Select( tName )
         IF ValType( hElem:__enumvalue() ) $ "HA"  // kdyz hash tak ten seznam ma jen jeden prvek - ten hash, jinak to je pole hashu
            /*
            { "ROOT" => "/Invoice/TaxTotal/TaxSubTotal",
              "ITEMS" => { "MWST" => "TaxCategory/Percent", "BETRAG" => "TaxAmount", "ZAKLAD" => "TaxableAmount" } }
            { "TaxableAmount" => "15493.5", "TaxAmount" => "3253.64", "TaxInclusiveAmount" => "18747.14", "AlreadyClaimedTaxableAmount" => "0", "AlreadyClaimedTaxAmount" => "0",
              "AlreadyClaimedTaxInclusiveAmount" => "0", "DifferenceTaxableAmount" => "15493.5", "DifferenceTaxAmount" => "3253.64", "DifferenceTaxInclusiveAmount" => "18747.14",
              "TaxCategory" => { "Percent" => "21" } }
            */
            ttName = tName + "_" + hElem:__enumkey()
            CreateDBFTable( ttName )
            xVal = hElem:__enumvalue()[ "ROOT" ]
            hItems = hElem:__enumvalue()[ "ITEMS" ]
            hNode = EvalPath( hISDOC, xVal )
            FOR EACH subElem in if( ValType( hNode ) = "A", hNode, "1" )  // dam tam string delky jedna to by znamenalo projit jen jednou
               Select( ttName )
               LOG "OuterLoop subElem=", subElem, "subElem:__enumkey()=", subElem:__enumkey(), "subElem:__enumvalue()=", subElem:__enumvalue()
               add_rec()
               FOR EACH ssubElem in hItems
                  LOG "InnerrLoop ssubElem=", ssubElem, "ssubElem:__enumkey()=", ssubElem:__enumkey(), "hodnota=", hb_ValToExp( EvalPath( if( ValType( subElem ) = "C" .AND. subElem = "1", hNode, subelem ), ssubElem ) ), ','
                  UpdateRec( ssubElem:__enumkey(), hb_ValToExp( EvalPath( if( ValType( subElem ) = "C" .AND. subElem = "1", hNode, subelem ), ssubElem ) ) )
               NEXT ssubElem
            NEXT subElem
         ELSE
            /* pro ICO zatim udelam rucne, obecny reseni az bude pripadne vice pripadu
            kdnr=icoTokdnr(sICO)
            */
            xVal = hElem:__enumvalue()
            UpdateRec( hElem:__enumkey(), EvalPath( hISDOC, xVal ) )
         ENDIF
      NEXT hElem
   NEXT hTable
   IF zs_set( 'bBrowse' )
      Select( 1 )
      Browse()
      Select( 2 )
      Browse()
      Select( 3 )
      Browse()
   ENDIF

   RETURN NIL

FUNCTION EvalPath( hIn, sPath )

   MEMVAR hOut
   LOCAL hPath := "", cKey := SubStr( sPath, RAt( "/", sPath ) + 1 ) // s pouzitim posledniho klice, budu testovat existenci a pripadne vracet ""
   PRIVA hOut := hb_HClone( hIn )

   sPath = Left( sPath, RAt( "/", sPath ) - 1 )  // zbytek mam v sKey

   AEval( hb_ATokens( sPath, "/" ), {| token | hPath += if( Empty( token ), "", "['" + token + "']" ) } )

   IF !hb_HHasKey( &( 'hOut' + hPath ), cKey )
      LOG 'Neexistuje klic:', cKey, 'v', 'hOut' + hPath
   ENDIF

   RETURN    hb_HGetDef( &( 'hOut' + hPath ), cKey, '' )
// RETURN    &( 'hOut' + hPath )

/*
FUNCTION icoTokdnr( sICO )

   LOCAL sRet

   RETURN sRet
*/


FUNCTION CreateDBFTable( tName )

   LOCAL aStruct := zs_set( tName )

   tName = Lower( tName )
   DELETE FILE ( tName + ".dbf" )
   dbCreate( tName, aStruct, "DBFNTX", .T., tName )
   LOG "Table", tName, "created"

   RETURN NIL

FUNCTION UpdateRec( cField, xVal )

   cField = Left( cField, 10 )  // zkratim nazev polozky na 10
   /**/
   DO CASE
   CASE ValType( field->&cField ) = "D"
      xVal = hb_CToD( xVal, "YYYY:MM:DD" )
   CASE ValType( field->&cField ) = "N"
      IF Right( xVal, 1 ) = '"'
         xVal = Val( hb_StrShrink( SubStr( xVal, 2 ) ) )  // kdyz jsou tak orezu krajni uvozovky
      ELSE
         xVal = Val(  xVal )  // kdyz jsou tak orezu krajni uvozovky
      ENDIF
   CASE ValType( field->&cField ) = "C"
      IF Right( xVal, 1 ) = '"'
         xVal = hb_StrShrink( SubStr( xVal, 2 ) )   // kdyz jsou tak orezu krajni uvozovky
      else
         xVal = trim( xVal )    // kdyz jsou tak orezu krajni uvozovky
      ENDIF
     xVal = hb_Translate( xVal, hb_cdpselect(), zs_set('cDbfEncoding'))  //melo by to delat nastaveni _SET_DB...
   END CASE
   REPLA field->&cField WITH xVal

   RETURN NIL
