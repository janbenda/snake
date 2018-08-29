STATIC s_hZSset := { ;
'GLBL_FILES'=> 'S:\COMMON\' ;
}

FUNCTION zs_set( cName, xSetValue )

   LOCAL xGetValue := nil

   cName = Upper( cName )
   IF HB_ISSTRING( cName ) .AND. ! Empty( cName )
      IF !( cName $ s_hZSset )
         s_hZSset[ cName ] = nil
      ENDIF
      xGetValue := s_hZSset[ cName ]
      IF PCount() > 1
         s_hZSset[ cName ] := xSetValue
      ENDIF
   ENDIF

   RETURN xGetValue

FUNCTION ReadCfg( cName )

   LOCAL aIni, aSect
   LOCAL cSection
   LOCAL cKey, cVarName
   LOCAL cTest, bRet := .T.

   IF Empty( cName )
      cName := ExeName() + ".ini"
   ENDIF
   aIni := hb_iniRead( cName ) // default main section
   IF Empty( aIni )
      bRet = .F.
   ELSE
      FOR EACH cSection IN aIni:Keys
         aSect := aIni[ cSection ]
         FOR EACH cKey IN aSect:Keys
            cTest = AllTrim( Upper( hb_CStr( aSect[ cKey ] ) ) )
            IF Upper( cSection ) <> 'MAIN'
               cVarName = cSection + cKey
            ELSE
               cVarName =  cKey
            ENDIF
            // ? cVarName + " = " + aSect[ cKey ]
            IF Left( cTest, 1 ) = "{"
               zs_set( cVarName, &( aSect[ cKey ] ) )
            ELSEIF cTest $ '.T./.F./1/0/ON/OFF'
               zs_set( cVarName, &( aSect[ cKey ] ) )
            ELSEIF hb_regexHas( '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{4}', cTest )  // date
               zs_set( cVarName, hb_CToD( aSect[ cKey ] ) )
            ELSE
               zs_set( cVarName, aSect[ cKey ] )
            ENDIF
         NEXT
      NEXT
   ENDIF

   RETURN bRet

