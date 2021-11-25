
REQUEST DBFNTX
REQUEST ZS
REQUEST HB_CODEPAGE_CSWIN
REQUEST HB_CODEPAGE_CSISO
REQUEST HB_CODEPAGE_UTF8

#include "hblog.ch"
MEMVAR hISDOC

FUNCTION main ( cISDOCFile )

   LOCAL oldCP := hb_cdpSelect( "UTF8" ), oldTCP := hb_SetTermCP( "UTF8" )
   LOCAL cISDOC, cISDOCEncoding
   LOCAL hTable, hElem, subElem, ssubElem, hItems, hI_H := zs_set( "I_H" ), xVal, hNode, tName, ttName
   PRIVA hISDOC

   LOG oldCP, oldTCP
   Set( _SET_DBCODEPAGE, zs_set( "cDbfEncoding" ) )
   IF Empty( cISDOCFile )
      cISDOCFile = zs_set( "cISDOCFile" ) // "FV19091834.ISDOC"
   ENDIF
/* je treba dodelat zjiteni kodovani a dle toho prekodovat do UTF8 */
   cISDOCEncoding = "UTF8"  // dle specifikace musi být v UTF8
   cISDOC := hb_Translate( hb_MemoRead( cISDOCFile  ), cISDOCEncoding, "UTF8" )
   hISDOC := hb_XMLtoHash( cISDOC, .T. )  // omit header

   FOR EACH hTable in hI_H
      // jmeno tabulky a v nem
      tName = hTable:__enumkey()
      OutStd( "tName", tName, hb_eol() )
      CreateDBFTable( tName )
      add_rec()      // hned si prodam vetu
      FOR EACH hElem in hTable:__enumvalue()
// OutStd( hElem:__enumkey(), "=>", hElem:__enumvalue(), hb_eol() )
         Select( tName )
         IF ValType( hElem:__enumvalue() ) $ "HA"  // kdyz hash tak ten seznam ma jen jeden prvek - ten hash, jinak to je pole hashu
            OutStd( "Je to hash nebo array, extra zpracovat, zase table a v tom nekolik zaznamu pole polozek", hb_eol() )
            /*
            { "ROOT" => "/Invoice/TaxTotal/TaxSubTotal",
              "ITEMS" => { "MWST" => "TaxCategory/Percent", "BETRAG" => "TaxAmount", "ZAKLAD" => "TaxableAmount" } }
            { "TaxableAmount" => "15493.5", "TaxAmount" => "3253.64", "TaxInclusiveAmount" => "18747.14", "AlreadyClaimedTaxableAmount" => "0", "AlreadyClaimedTaxAmount" => "0",
              "AlreadyClaimedTaxInclusiveAmount" => "0", "DifferenceTaxableAmount" => "15493.5", "DifferenceTaxAmount" => "3253.64", "DifferenceTaxInclusiveAmount" => "18747.14",
              "TaxCategory" => { "Percent" => "21" } }
            */
            ttName = tName + "_" + hElem:__enumkey()
            OutStd( "ttName", ttName, hb_eol() )
            CreateDBFTable( ttName )
            xVal = hElem:__enumvalue()[ "ROOT" ]
            hItems = hElem:__enumvalue()[ "ITEMS" ]
            hNode = EvalPath( hISDOC, xVal )
            FOR EACH subElem in if( ValType( hNode ) = "A", hNode, "1" )  // dam tam string delky jedna to by znamenalo projit jen jednou
               Select( ttName )
               OutStd( "subElem=", subElem, "subElem:__enumkey()=", subElem:__enumkey(), "subElem:__enumvalue()=", subElem:__enumvalue(), hb_eol() )
               LOG "OuterLoop subElem=", subElem, "subElem:__enumkey()=", subElem:__enumkey(), "subElem:__enumvalue()=", subElem:__enumvalue()
               add_rec()
               FOR EACH ssubElem in hItems
                  OutStd( ssubElem, ssubElem:__enumkey(), hb_ValToExp( EvalPath( if( ValType( subElem ) = "C" .AND. subElem = "1", hNode, subelem ), ssubElem ) ), hb_eol() )
                  LOG "InnerrLoop ssubElem=", ssubElem, "ssubElem:__enumkey()=", ssubElem:__enumkey(), "hodnota=", hb_ValToExp( EvalPath( if( ValType( subElem ) = "C" .AND. subElem = "1", hNode, subelem ), ssubElem ) ), ','
                  UpdateRec( ssubElem:__enumkey(), hb_ValToExp( EvalPath( if( ValType( subElem ) = "C" .AND. subElem = "1", hNode, subelem ), ssubElem ) ) )
               NEXT ssubElem
            NEXT subElem
         ELSE
            /* pro ICO zatim udelam rucne, obecny reseni az bude pripadne vice pripadu
            kdnr=icoTokdnr(sICO)
            */
            xVal = hElem:__enumvalue()
            OutStd( "FirstLevel", xVal, EvalPath( hISDOC, xVal ), hb_eol() )
            UpdateRec( hElem:__enumkey(), EvalPath( hISDOC, xVal ) )
         ENDIF
      NEXT hElem
   NEXT hTable
   Select( 1 )
   Browse()
   Select( 2 )
   Browse()
   Select( 3 )
   Browse()

   RETURN NIL

FUNCTION EvalPath( hIn, sPath )

   MEMVAR hOut
   LOCAL hPath := "" // , cKey:=substr(sPath,rat("/",sPath)+1)
   PRIVA hOut := hb_HClone( hIn )

// sPath=left(sPath,rat("/",sPath)-1)

   AEval( hb_ATokens( sPath, "/" ), {| token | hPath += if( Empty( token ), "", "['" + token + "']" ) } )

   RETURN    &( 'hOut' + hPath )
// RETURN    hb_hGetDef(&('hOut' + hPath),cKey,'Neexistuje'+'hOut' + hPath+cKey)

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
   IF ValType( xVal ) = "C"
      xVal = AllTrim( xVal )
   ENDIF
   // /
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
      ENDIF
// xVal = hb_Translate( xVal, 'UTF8', zs_set( "cDbfEncoding" ) )
   END CASE
   REPLA field->&cField WITH xVal

   RETURN NIL
