REQUEST DBFNTX
REQUEST HB_CODEPAGE_CSWIN
REQUEST HB_CODEPAGE_CSISO
REQUEST HB_CODEPAGE_CS852

PROCEDURE Main( sISDOC_CSV, sOutputName )

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
   LOCAL _sRoot, _sDelim, _sCurrTag, _sPrevTag, hLevel := { => }

   SET DELE ON
   SET EXCL OFF
   Set( _SET_DATEFORMAT, "dd.mm.yyyy" )
   SetMode( 60, 220 )
   hb_default( @sOutputName, sISDOC_CSV )
   sOutputName = lower( sOutputName )

   hb_cdpSelect ( "CSISO" )
   hb_SetTermCP ( "UTF8" )
   Set( _SET_DBCODEPAGE, "CSISO" )

   rddSetDefault( "DBFNTX" )

   DELETE FILE ( sOutputName + ".dbf" )
  // ?"Creating:" + sOutputName + ".dbf"
   dbCreate( sOutputName + ".dbf", aStruct, NIL, .T., "isdoc" )
   APPEND FROM &sISDOC_CSV DELIMITED WITH ( { '"', "," } )
   GO TOP
   IF Trim( Upper( field->TAG ) ) $ "TAG"
      DELETE FOR RecNo() <= 1
      __dbPack()
   ENDIF
   GO TOP
/* tady zkusim nejak doplnit cely TAG podle urovne, budu tam tagy sctitat oddelovat lomitkem */
   _sDelim = "/"
   _sCurrTag = _sDelim
   WHILE !Eof()
      IF field->children > 0
         // je to node s prvky musim je pocitat abych vedel kdy je plny a tedy ukoncit
         // ulozim si parent a pocet childu
         _sPrevTag = _sCurrTag
         _sCurrTag =  _sCurrTag + Trim( field->TAG ) + _sDelim
         hb_HSet( hLevel, _sCurrTag, { field->children, _sPrevTag } )
         IF hb_HHasKey( hLevel, _sPrevTag )
            hLevel[ _sPrevTag, 1 ] = hLevel[ _sPrevTag, 1 ] - 1
         ENDIF
         Lock()
         REPLA tagall WITH _sCurrTag
      ELSE
         IF hb_HHasKey( hLevel, _sCurrTag )
            hLevel[ _sCurrTag, 1 ] = hLevel[ _sCurrTag, 1 ] - 1
         ENDIF
         Lock()
         REPLA tagall WITH  _sCurrTag + Trim( field->TAG ) + _sDelim
      ENDIF
      IF hb_HHasKey( hLevel, _sCurrTag )
   //      ? PadL( Trim( field->TAG ), 40 ) + ' Pred: currtag:' + _sCurrTag + ' childs:' + hb_ntos( hLevel[ _sCurrTag, 1 ] ) + ' parent:' + hLevel[ _sCurrTag, 2 ]
      ENDIF
      SetNewTag( hLevel, @_sCurrTag, @_sPrevTag )
      IF hb_HHasKey( hLevel, _sCurrTag )
        // ? PadL( hb_ntos( field->children ), 40 ) + ' Po  : currtag:' + _sCurrTag + ' childs:' + hb_ntos( hLevel[ _sCurrTag, 1 ] ) + ' parent:' + hLevel[ _sCurrTag, 2 ]
      ENDIF
      SKIP
   ENDDO
//   Browse()
   CLOSE ALL

   RETURN


FUNCTION SetNewTag( hLevel, _sCurrTag, _sPrevTag )

   IF hb_HHasKey( hLevel, _sCurrTag )
      //? ' Old  : currtag:' + _sCurrTag + ' childs:' + hb_ntos( hLevel[ _sCurrTag, 1 ] ) + ' parent:' + hLevel[ _sCurrTag, 2 ]
      IF hLevel[ _sCurrTag, 1 ] <= 0
         _sCurrTag = hLevel[ _sCurrTag, 2 ]
         // po nastveni novy TAGU vezmu z nej i PrevTag
         IF hb_HHasKey( hLevel, _sCurrTag )
            _sPrevTag = hLevel[ _sCurrTag, 2 ]
            //? ' New  : currtag:' + _sCurrTag + ' childs:' + hb_ntos( hLevel[ _sCurrTag, 1 ] ) + ' parent:' + hLevel[ _sCurrTag, 2 ]
         ELSE
            //? 'Konec'
         ENDIF
      ENDIF
      IF hb_HHasKey( hLevel, _sCurrTag )
         IF hLevel[ _sCurrTag, 1 ] <= 0
            //?'recurse'
            SetNewTag( hLevel, @_sCurrTag, @_sPrevTag ) // a znovu recursivne dokud se to nevrati na spravnou uroven, tj dokud jsou childy 0
         ENDIF
      ENDIF
   ENDIF

   RETURN .T.
