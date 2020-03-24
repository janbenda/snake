ANNOUNCE HB_GT_SYS
REQUEST HB_GT_NUL_DEFAULT

#include "fileio.ch"

#define F_BLOCK  17

REQUEST HB_TCPIO

FUNCTION Main( sIPVahy, sVaha, sPath )

   LOCAL nSrcBytes, pFile, lDone := .F., cBuffer, cHileTmp, cHFile, cRunFile := "run.trg"
   LOCAL reVaha, sPatternVaha := '\s+([0-9]+\.[0-9]),kg', aMatches

// pridani cteni konfiguracniho ini souboru, zatim pro nPause (prodleva mezi ctenimi z vahy)
   IF !readcfg()
      OutStd( Time() + ':' + "INI KO!" + hb_eol() )
      RETURN .F.
   ENDIF
   OutStd( Time() + ':' + 'Nacteno pausa: ' + iif( ValType( zs_set( 'nPause' ) ) = 'N', hb_ntos( zs_set( 'nPause' ) ), zs_set( 'nPause' ) ) + hb_eol() )

   hb_default( @sIPVahy, "192.168.1.2:10001" )

// 18/04 JK modifikace na pracoviste vaha   01 nebo 02
   cHFileTmp := sPath + '/.h' + sVaha + '.txt'
   cHFile := sPath + '/h' + sVaha + '.txt'
   cRunFile := sPath + '/run' + sVaha + '.trg'

   hb_MemoWrit( cRunFile, "1" )
   OutStd( Time() + ': regexp ' + sPatternVaha + hb_eol() )
// HB_RegExComp( <cPattern> [ , <lCaseSensitive>, <lMultiLine> ] )
   reVaha := hb_regexComp( sPatternVaha, .T., .F. )
   DO WHILE "1" $ hb_MemoRead( cRunFile )
      d_OutStd( 'Otviram ' + "tcp:" + sIPVahy + hb_eol() )
      pFile := hb_vfOpen( "tcp:" + sIPVahy, FO_READ )
      IF !Empty( pFile )
         cBuffer := Space( F_BLOCK )
         IF ( nSrcBytes := hb_vfRead( pFile, @cBuffer, F_BLOCK ) ) <>  F_BLOCK .OR. !( hb_regexHas( sPatternVaha, cBuffer, .T., .T. ) )
            // neprecetlo se to spravne zkusim znovu
            d_OutStd( 'Nacteno: ' + hb_ntos( nSrcBytes ) + " bytu, misto: " + hb_ntos( F_BLOCK ) + ", zkusim znovu. Precteno " + cBuffer + hb_eol() )
         ELSE
            aMatches := hb_regex( reVaha, cBuffer )
            IF Len( aMatches ) >= 2
               d_OutStd( 'Extrahovano :' + aMatches[ 2 ] + ' z : ' + cBuffer + hb_eol() )
               hb_MemoWrit( cHFileTmp, Time() + ':' + aMatches[ 2 ] + hb_eol() )
               d_OutStd( hb_StrReplace( cBuffer, { Chr( 13 ) => '' } ) + hb_eol() )
               IF FRename( cHFileTmp, cHFile ) == -1
                  d_OutStd( "Can't rename file to " + cHFile + " : " + Str( FError(), 2 ) )
               ENDIF
            ELSE
               OutStd( Time() + ':' + "Divna data, vaha nejde extrahovat:" + cBuffer + hb_eol() )
            ENDIF
         ENDIF
         hb_vfClose( pFile )
         readcfg()
         hb_idleSleep( Val( iif( ValType( zs_set( 'nPause' ) ) = 'N', hb_ntos( zs_set( 'nPause' ) ), zs_set( 'nPause' ) ) ) )
      ELSE
         d_OutStd( 'Nepodarilo se otevrit connection k vaze' + hb_eol() )
      ENDIF
   ENDDO
// close virtual file.
   // cBuffer = hb_StrReplace( cBuffer, { Chr( 10 ) => '_Chr10_', Chr( 13 ) => '_Chr13_' } )
   // OutStd( cBuffer )
   OutStd( "Konec" + hb_eol() )

   RETURN .T.

STATIC FUNCTION d_OutStd( sText )

   IF zs_set( 'debug' ) = 1
      OutStd( Time() + ':' + sText )
   ENDIF

   RETURN .T.
