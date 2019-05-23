#include "box.ch"
 
REQUEST HB_CODEPAGE_RU866
REQUEST HB_CODEPAGE_RU1251
REQUEST HB_CODEPAGE_CSWIN
 
Static mutex1
Static aNew := {}
 
Function Main()
Local pThread, lEnd := .F., nkey
 
   hb_cdpSelect( "CSWIN" )
   hb_inetInit()
 
   // Create a mutex to synchronize threads when accessing the array aNew
   mutex1 := hb_mutexCreate()
   // Create a thread to check for updates with clipper.borda.ru
   pThread := hb_threadStart( @GetData(), @lEnd )
 
   // Just waiting for user input.
   CLEAR SCREEN
   @ 24, 1 SAY "Press Esc to complete the program, F5 - changes"
   read
   DO WHILE ( nKey := Inkey(0) ) != 27
      IF nKey == -4    // F5
         ShowUpd()
      ENDIF
   ENDDO
 
   // Send via lEnd completion signal to a thread and are looking forward to it.
   lEnd := .T.
   hb_threadJoin( pThread )
 
   hb_inetCleanup()
 
Return .T.
 
// This function is called by F5 and shows the changes to the site
Function ShowUpd()
Local arr, bufc, i, l
 
   // Here we need a mutex we read an array aNew, which could in this
   // time modified by a second thread
   hb_mutexLock( mutex1 )
   IF ( l := !Empty( aNew ) )
      arr := {}
      FOR i := 1 TO Len( aNew )
         Aadd( arr, Padr( hb_translate( Trim(aNew[i,2])+": " ;
            +Trim(aNew[i,3])+" "+Trim(aNew[i,4]),"RU1251","RU866" ),64 ) )
      NEXT
   ENDIF
   hb_mutexUnLock( mutex1 )
 
 
   bufc := Savescreen( 7,7,13,73 )
   @ 7,7,13,73 BOX B_DOUBLE_SINGLE + Space(1)
   IF l
      AChoice( 8,8,12,72,arr )
   ELSE
      @ 10, 35 SAY "Ничего нового..."
      Inkey(1)
   ENDIF
   Restscreen( 7,7,13,73, bufc )
   hb_dispOutAt( 0, 69, "          ", "GR+/N" )
 
Return .T.
 
// This function analyzes the main page of the site and looking for there the necessary changes.
// In order to better understand it, look at the source text of the main page clipper.borda.ru
Static Function CheckAns( cBuf )
Local nPos1 := 1, nPos2, aItems, aRes := {}
Local aStru := { {"ID","C",2,0}, {"NAME","C",16,0}, {"TM","C",10,0}, {"LOGIN","C",16,0}, {"TITLE","C",32,0} }
Local fname := "cl_borda.dbf", lFirstTime := .F.
Field ID, NAME, TM, LOGIN, TITLE
 
   IF !File( fname )
      dbCreate( fname, aStru )
      lFirstTime := .T.
   ENDIF
   USE (fname) NEW EXCLUSIVE
   
   DO WHILE ( nPos1 := hb_At( "st(", cBuf, nPos1 ) ) != 0
      IF ( nPos2 := hb_At( ")", cBuf, nPos1 ) ) != 0
 
         aItems := hb_aTokens( Substr(cBuf,nPos1+3,nPos2-nPos1-3), ",", .T. )
         aItems[1] := Padr( Substr( aItems[1], 2, Min( aStru[1,3],Len(aItems[1])-2 ) ), aStru[1,3] )
         aItems[2] := Padr( Substr( aItems[2], 2, Min( aStru[2,3],Len(aItems[2])-2 ) ), aStru[2,3] )
         aItems[5] := Padr( Substr( aItems[5], 2, Min( aStru[3,3],Len(aItems[5])-2 ) ), aStru[3,3] )
         aItems[8] := Padr( Substr( aItems[8], 2, Min( aStru[4,3],Len(aItems[8])-2 ) ), aStru[4,3] )
         aItems[9] := Padr( Substr( aItems[9], 2, Min( aStru[5,3],Len(aItems[9])-2 ) ), aStru[5,3] )
 
         IF lFirstTime
            APPEND BLANK
            REPLACE ID WITH aItems[1], NAME WITH aItems[2], TM WITH aItems[5], ;
                  LOGIN WITH aItems[8], TITLE WITH aItems[9]
         ELSE
            LOCATE FOR ID == aItems[1]
            IF !Found()
               APPEND BLANK
               REPLACE ID WITH aItems[1], NAME WITH aItems[2], TM WITH aItems[5], ;
                     LOGIN WITH aItems[8], TITLE WITH aItems[9]
               Aadd( aRes, {aItems[1],aItems[2],aItems[8],aItems[9]} )
            ELSEIF TM != aItems[5] .OR. LOGIN != aItems[8] .OR. TITLE != aItems[9]
               REPLACE TM WITH aItems[5], LOGIN WITH aItems[8], TITLE WITH aItems[9]
               Aadd( aRes, {aItems[1],aItems[2],aItems[8],aItems[9]} )
            ENDIF
         ENDIF
 
         nPos1 := nPos2 + 1
      ELSE
         EXIT
      ENDIF
   ENDDO
   USE
 
Return aRes
 
// This is the 2nd flow
Function GetData( lEnd )
Local nCount := 0, hSocket, cUrl, cServer, cBuf, aRes
 
   cServer := "clipper.borda.ru"
   cURL := "GET http://" + cServer + "/ HTTP/1.1" +Chr(13)+Chr(10)
   cURL += "Host: " + cServer + Chr(13)+Chr(10)
   cURL += "User-Agent: test_util"+Chr(13)+Chr(10)
   cUrl += Chr(13)+Chr(10)
 
   DO WHILE !lEnd
      IF nCount == 0
         hb_dispOutAt( 0, 61, "Читаем.", "GR+/N" )
         hSocket := hb_inetCreate()                   // create a socket
         hb_inetConnect( cServer, 80, hSocket )       // connect to the web site of the forum
         IF hb_inetErrorCode( hSocket ) != 0
            hb_dispOutAt( 0, 61, "Сбой...", "GR+/N" ) 
         ENDIF
 
         // Send the request, formed above,  and waiting for a reply.
         IF hb_inetSendAll( hSocket, cURL ) > 0 .AND. !Empty( cBuf := hb_inetRecvEndBlock( hSocket, "main2(",,,4096 ) )
            IF !Empty( aRes := CheckAns( cBuf ) )
               hb_dispOutAt( 0, 69, "!! Есть !!", "GR+/N" )
               // Use a mutex for the safe aNew modification
               hb_mutexLock( mutex1 )
               aNew := aRes
               hb_mutexUnLock( mutex1 )
            ENDIF
            hb_dispOutAt( 0, 61, "       ", "GR+/N" )
         ELSE
            hb_dispOutAt( 0, 61, "Сбой...", "GR+/N" )
         ENDIF
 
         // Close the socket
         hb_inetClose( hSocket ) 
      ENDIF
      hb_idleSleep(2)
      IF ++nCount >= 60
         nCount := 0
      ENDIF
   ENDDO
 
Return Nil
