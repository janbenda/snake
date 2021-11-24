
REQUEST DBFNTX
REQUEST ZS
REQUEST HB_CODEPAGE_CSWIN
REQUEST HB_CODEPAGE_CSISO
REQUEST HB_CODEPAGE_UTF8

#include "hblog.ch"
MEMVAR hISDOC

FUNCTION main ( cISDOCFile )

   LOCAL oldCP := hb_cdpSelect( "UTF8" ), oldTCP := hb_SetTermCP( "UTF8" )
   LOCAL cISDOC
   LOCAL hTable, hElem, subElem, ssubElem, hItems, hI_H := zs_set( "I_H" ), xVal, hNode, tName, ttName
   PRIVA hISDOC

   LOG oldCP, oldTCP
   IF Empty( cISDOCFile )
      cISDOCFile = zs_set( "cISDOCFile" ) // "FV19091834.ISDOC"
   ENDIF
/* je treba dodelat zjiteni kodovani a dle toho prekodovat do UTF8 */
   cISDOC := hb_Translate( hb_MemoRead( cISDOCFile  ), "CSWIN", "UTF8" )
   hISDOC := hb_XMLtoHash( cISDOC, .T. )  // omit header

   FOR EACH hTable in hI_H
      // jmeno tabulky a v nem
      tName = hTable:__enumkey()
      OutStd( "tName", tName, hb_eol() )
      FOR EACH hElem in hTable:__enumvalue()
// OutStd( hElem:__enumkey(), "=>", hElem:__enumvalue(), hb_eol() )
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
            xVal = hElem:__enumvalue()[ "ROOT" ]
            hItems = hElem:__enumvalue()[ "ITEMS" ]
            hNode = EvalPath( hISDOC, xVal )
            FOR EACH subElem in if( ValType( hNode ) = "A", hNode, "1" )  // dam tam string delky jedna to by znamenalo projit jen jednou
               FOR EACH ssubElem in hItems
                  OutStd( ssubElem, ssubElem:__enumkey(), hb_ValToExp( EvalPath( if( ValType( subElem ) = "C" .AND. subElem = "1", hNode, subelem ), ssubElem ) ), ',' )
               NEXT ssubElem
               OutStd( hb_eol() )
            NEXT subElem
            OutStd( hb_eol() )
         ELSE
            /* pro ICO zatim udelam rucne, obecny reseni az bude pripadne vice pripadu
            kdnr=icoTokdnr(sICO)
            */
            xVal = hElem:__enumvalue()
            OutStd( xVal, EvalPath( hISDOC, xVal ), hb_eol() )
         ENDIF
      NEXT hElem
      OutStd( hb_eol() )
   NEXT hTable
   OutStd( hb_eol() )

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

FUNCTION CreateTable()

   LOCAL tName := "t_faimde"
   LOCAL aStruct := { ;
      { "TAGALL", "C", 250, 0 }, ;
      { "SNAFIELD",   "C",  250, 0 }, ;
      { "POPIS",    "C",  250, 0 };
      }

   dbCreate( tName, aStruct, "DBFNTX", .T., "MYALIAS" )
   Browse()

   RETURN NIL
