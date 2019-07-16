REQUEST DBFNTX
REQUEST HB_CODEPAGE_CSWIN
REQUEST HB_CODEPAGE_CSISO
REQUEST HB_CODEPAGE_CS852




 PROCEDURE Main( sISDOC_CSV )
         LOCAL aStruct := { ;
                            { "TAG", "C", 100, 0 }, ;
                            { "CHILDREN",   "N",  8, 0 }, ;
                            { "TEXT",    "C",  100, 0 }, ;
                            { "VERSION",      "C",  100, 0 }, ;
                            { "ID",   "C",  100, 0 }, ;
                            { "REF",     "C", 100, 0 }, ;
                            { "UNITCODE",     "C", 100, 0 }, ;
                            { "TAGALL", "C", 1000, 0 } ;
                          }
   LOCAL _sCurrTag,_sPrevTag, _nPrevLev
   SET DELE ON
   SET EXCL OFF
   Set( _SET_DATEFORMAT, "dd.mm.yyyy" )
/*
   hb_cdpSelect ( "UTF8" )
   hb_SetTermCP ( "CSWIN" )
   Set( _SET_DBCODEPAGE, "CSWIN" )
*/
   rddSetDefault( "DBFNTX" )


   delete file ( sISDOC_CSV + ".dbf" )
   ?"Creating:" + sISDOC_CSV + ".dbf"
   ?dbCreate( sISDOC_CSV + ".dbf", aStruct, nil, .T., "isdoc" )
   append from &sISDOC_CSV DELIMITED WITH ( { '"', "," } )
/* tady zkusim nejak doplnit cely TAG podle urovne, budu tam tagy sctitat oddelovat lomitkem
   go top
   while !eof()
     if field->children>=0
       
     skip
   enddo
   browse()
   close all

 RETURN
