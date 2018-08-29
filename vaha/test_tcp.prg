#include "fileio.ch"

#define F_BLOCK  9
#define F_PAUSE  2

REQUEST HB_TCPIO

FUNCTION Main( sIPVahy, cHFile )

   LOCAL nSrcBytes, pFile, lDone := .F., cBuffer, cRunFile := hb_dirBase() + "run.trg"
  hb_default(@sIPVahy,"192.168.1.2:10001")
  hb_default(@cHFile, hb_dirBase() + "h.txt")

   hb_MemoWrit( cRunFile, "1" )
   OutStd ( HB_GTVERSION(), HB_GTVERSION(1) )
   DO WHILE "1" $ hb_MemoRead( cRunFile )
      OutStd( Time() + ':Otviram ' + "tcp:" + sIPVahy )
      pFile := hb_vfOpen( "tcp:" + sIPVahy, FO_READWRITE )
      IF !Empty( pFile )
         cBuffer := Space( F_BLOCK )
         hb_vfWrite( pFile, "SP" + Chr( 13 ) )  // Activation for request S+P+<CR>
         hb_vfWrite( pFile, "SN" + Chr( 13 ) )  // Net weight   S+N+<CR>
         IF ( nSrcBytes := hb_vfRead( pFile, @cBuffer, F_BLOCK ) ) <>  F_BLOCK
            // neprecetlo se to spravne, zkusim znovu
            OutStd( Time() + ':' + 'Nacteno: ' + hb_ntos( nSrcBytes ) + " bytu, misto: " + hb_ntos( F_BLOCK ) + ", zkusim znovu." + hb_eol() )
         ELSE
            hb_MemoWrit( cHFile, Time() + ':' + hb_StrReplace( cBuffer, { Chr( 13 ) => '' } ) + hb_eol() )
            OutStd( Time() + ':' + hb_StrReplace( cBuffer, { Chr( 13 ) => '' } ) + hb_eol() )
         ENDIF
         hb_vfClose( pFile )
         hb_idleSleep( F_PAUSE )
      ELSE
         OutStd( Time() + ':' + 'Nepodarilo se otevrit connection k vaze' + hb_eol() )
      ENDIF
   ENDDO
   hb_MemoWrit( cRunFile, "0" )
   OutStd( "Konec" )

   RETURN .T.
