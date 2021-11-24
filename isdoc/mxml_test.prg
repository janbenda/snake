REQUEST ZS
REQUEST HB_CODEPAGE_CS852
REQUEST HB_CODEPAGE_UTF8
#include "hblog.ch"

FUNCTION main ( cFileArg, cNode )

   LOCAL hTree, hNode, cStr := "", nNum, hTable, hElem, hI_H := zs_set( "I_H" ), xVal

   IF Empty( cFileArg )
      cFileArg = "FV19091834.ISDOC"
   ENDIF
   IF Empty( cNode )
      cNode = 'AccountingSupplierParty'
   ENDIF
   OutStd( "CONFIG", zs_set( "CONFIG" ) )
   hTree = mxmlLoadFile( NIL, cFileArg, @type_cb() )
   IF Empty( hTree )
      OutErr( "Unable to read XML file!" + hb_eol() )
      ErrorLevel( 1 )
      QUIT
   ENDIF
   hNode := mxmlFindPath( hTree, "*/" + cNode )
   IF Empty( hNode )
      OutErr( "ERROR: Unable to find value for", "*/" + cNode, hb_eol() )

      mxmlDelete( hTree )
      ErrorLevel( 1 )
      QUIT
   ENDIF
   OutStd( "mxmlGetType", mxmlGetType( hNode ), hb_eol() )
   OutStd( "mxmlGetOpaque", mxmlGetOpaque( hNode ), hb_eol() )

   OutStd( "hI_H", hb_ValToExp( hI_H ), hb_eol() )
   FOR EACH hTable in hI_H
      // jmeno tabulky a v nem
      OutStd( "mam htable", hb_eol() )
      OutStd( hTable:__enumkey(), hb_eol() )
      FOR EACH hElem in hTable:__enumvalue()
         OutStd( hElem:__enumkey(), "=>", hElem:__enumvalue(), hb_eol() )
         IF ValType( hElem ) = "H"
            OutStd( "Je to hash, extra zpracovat, zase table a v tom nekolik zaznamu pole polozek", hb_ValToExp( hElem:__enumvalue() ), hb_eol() )
            // {"ROOT"=>"*/Invoice/TaxTotal/TaxSubTotal", "ITEMS"=>{"MWST"=>"TaxCategory/Percent", "BETRAG"=>"TaxAmount", "ZAKLAD"=>"TaxableAmount"}}
            xVal = hElem:__enumvalue()["ROOT"]
            OutStd( xVal, hb_eol() )
            hNode := mxmlFindPath( hTree, xVal  )
            mxmlGetType(hNode)= MXML_ELEMENT
         ELSE
            xVal = hElem:__enumvalue()
            OutStd( xVal, hb_eol() )
            hNode := mxmlFindPath( hTree, xVal  )
         ENDIF

         IF Empty( hNode )
            OutErr( "ERROR: Unable to find value for", xVal, hb_eol() )
         ELSE
            cStr := Space( 16384 )
            IF ( nNum := mxmlSaveString( hNode, @cStr, @whitespace_cb() ) ) > 0
               OutStd( cStr + hb_eol() )
            ENDIF
         ENDIF
      NEXT hElem
   NEXT hTable

   /*
    * Print the XML tree...
    */

   IF !Empty( hNode )
      FErase( "out.xml" )
// mxmlSaveFile( hTree, "out.xml", @whitespace_cb() )
// mxmlSaveFile( hNode, "out.xml", @whitespace_cb() )
      mxmlSaveFile( hNode, "out.xml", @type_cb() )
   ENDIF

   /* XXX: */
   /*
    * Save the XML tree to a string and print it...
    */

   cStr := Space( 16384 )
   IF ( nNum := mxmlSaveString( hTree, @cStr, @whitespace_cb() ) ) > 0
// OutStd( cStr + hb_eol() )
   ENDIF
   OutStd( hb_ntos( nNum ) + hb_eol() )
   mxmlDelete( hTree )
   ErrorLevel( 0 )

   RETURN NIL


FUNCTION type_cb( hNode )

   LOCAL cType                            /* Type string */

   /*
    * You can lookup attributes and/or use the element name, hierarchy, etc...
    */

   IF Empty( cType := mxmlElementGetAttr( hNode, "type" ) )
      cType := mxmlGetElement( hNode )
   ENDIF

   SWITCH Lower( cType )
   CASE "integer" ;  RETURN MXML_INTEGER
   CASE "opaque"  ;  RETURN MXML_OPAQUE
   CASE "real"    ;  RETURN MXML_REAL
   ENDSWITCH

   RETURN MXML_TEXT

/*
 * 'whitespace_cb()' - Let the mxmlSaveFile() function know when to insert
 *                     newlines and tabs...
 */

/* O - Whitespace string or NIL */
/* I - Element node */
/* I - Open or close tag? */

FUNCTION whitespace_cb( hNode, nWhere )

   LOCAL hParent                          /* Parent node */
   LOCAL nLevel                           /* Indentation level */
   LOCAL cName                            /* Name of element */

   /*
    * We can conditionally break to a new line before or after any element.
    * These are just common HTML elements...
    */

   cName := Lower( mxmlGetElement( hNode ) )

   IF cName == "html" .OR. cName == "head" .OR. cName == "body" .OR. ;
         cName == "pre" .OR. cName == "p" .OR. ;
         cName == "h1" .OR. cName == "h2" .OR. cName == "h3" .OR. ;
         cName == "h4" .OR. cName == "h5" .OR. cName == "h6"

         /*
          * Newlines before open and after close...
          */

      IF nWhere == MXML_WS_BEFORE_OPEN .OR. nWhere == MXML_WS_AFTER_CLOSE
         RETURN hb_eol()
      ENDIF
   ELSEIF cName == "dl" .OR. cName == "ol" .OR. cName == "ul"

      /*
       * Put a newline before and after list elements...
       */

      RETURN hb_eol()
   ELSEIF cName == "dd" .OR. cName == "dd" .OR. cName == "li"

      /*
       * Put a tab before <li>s, <dd>s and <dt>s and a newline after them...
       */

      IF nWhere == MXML_WS_BEFORE_OPEN
         RETURN Space( 8 )
      ELSEIF nWhere == MXML_WS_AFTER_CLOSE
         RETURN hb_eol()
      ENDIF
   ELSEIF Left( cName, 4 ) == "?xml"
      IF nWhere == MXML_WS_AFTER_OPEN
         RETURN hb_eol()
      ELSE
         RETURN NIL
      ENDIF
   ELSEIF nWhere == MXML_WS_BEFORE_OPEN .OR. ;
         ( ( cName == "choice" .OR. cName == "option" ) .AND. nWhere == MXML_WS_BEFORE_CLOSE )
      nLevel := -1
      hParent := mxmlGetParent( hNode )
      DO WHILE ! Empty( hParent )
         nLevel++
         hParent := mxmlGetParent( hParent )
      ENDDO

      IF nLevel > 8
         nLevel := 8
      ELSEIF nLevel < 0
         nLevel := 0
      ENDIF

      RETURN Replicate( Chr( 9 ), nLevel )
   ELSEIF nWhere == MXML_WS_AFTER_CLOSE .OR. ;
         ( ( cName == "group" .OR. cName == "option" .OR. cName == "choice" ) .AND. ;
         nWhere == MXML_WS_AFTER_OPEN )

      RETURN hb_eol()
   ELSEIF nWhere == MXML_WS_AFTER_OPEN .AND. Empty( mxmlGetFirstChild( hNode ) )
      RETURN hb_eol()
   ENDIF

   /*
    * Return NULL for no added whitespace...
    */

   RETURN NIL
