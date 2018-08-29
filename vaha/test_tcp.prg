#include "fileio.ch"

#define F_BLOCK  9

REQUEST HB_TCPIO

FUNCTION Main( sIPVahy, sVaha, sPath )

   LOCAL nSrcBytes, pFile, lDone := .F., cBuffer, cHFile := "h.txt", cRunFile := "run.trg"

// pridani cteni konfiguracniho ini souboru, zatim pro nPause (prodleva mezi ctenimi z vahy)
   IF !readcfg()
      OutStd( Time() + ':' + "INI KO!" )
      RETURN .F.
   ENDIF
   OutStd( Time() + ':' + 'Nacteno pausa: ' + zs_set( 'nPause' ) )

   hb_default( @sIPVahy, "192.168.1.2:10001" )

// 18/04 JK modifikace na pracoviste vaha   01 nebo 02
   cHFile := sPath + '/h' + sVaha + '.txt'
   cRunFile := sPath + '/run' + sVaha + '.trg'

// socket communication example:


   hb_MemoWrit( cRunFile, "1" )
   DO WHILE "1" $ hb_MemoRead( cRunFile )
      OutStd( Time() + ':Otviram ' + "tcp:" + sIPVahy )
      pFile := hb_vfOpen( "tcp:" + sIPVahy, FO_READWRITE )
      IF !Empty( pFile )
         cBuffer := Space( F_BLOCK )
         hb_vfWrite( pFile, "SP" + Chr( 13 ) )  // Activation for request S+P+<CR>
         hb_vfWrite( pFile, "SN" + Chr( 13 ) )  // Net weight   S+N+<CR>
         IF ( nSrcBytes := hb_vfRead( pFile, @cBuffer, F_BLOCK ) ) <>  F_BLOCK
            // neprecetlo se to sparvne zkusim znovu
            OutStd( Time() + ':' + 'Nacteno: ' + hb_ntos( nSrcBytes ) + " bytu, misto: " + hb_ntos( F_BLOCK ) + ", zkusim znovu." + hb_eol() )
         ELSE
            hb_MemoWrit( cHFile, Time() + ':' + hb_StrReplace( cBuffer, { Chr( 13 ) => '' } ) + hb_eol() )
            OutStd( Time() + ':' + hb_StrReplace( cBuffer, { Chr( 13 ) => '' } ) + hb_eol() )
         ENDIF
         hb_vfClose( pFile )
         hb_idleSleep( Val( zs_set( 'nPause' ) ) )
      ELSE
         OutStd( Time() + ':' + 'Nepodarilo se otevrit connection k vaze' + hb_eol() )
      ENDIF
   ENDDO
// close virtual file.
   // cBuffer = hb_StrReplace( cBuffer, { Chr( 10 ) => '_Chr10_', Chr( 13 ) => '_Chr13_' } )
   // OutStd( cBuffer )
   OutStd( "Konec" )

   RETURN .T.
