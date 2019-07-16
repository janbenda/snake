FUNCTION Main( file )
  Local pRoot, hHash, sFile:= hb_memoread( file )
  pRoot :=   mxmlLoadString( NIL, sfile,  @type_cb() )
  hHash := XMLtoHash( pRoot, "" )
  mxmlDelete( pRoot )

  hb_memowrit( ( file+'.json' ), hb_jsonEncode( hHash, .T. ) )
 RETURN nil

STATIC FUNCTION type_cb( node ) ;  RETURN MXML_OPAQUE
 

// ---------------------------------------------------------------------------//
FUNCTION XMLtoHash( pRoot, cElement )
   Local pNode, hNext
   Local Map := {=>}

   if empty( cElement )
      pNode := pRoot
   else  
      pNode := mxmlFindElement( pRoot, pRoot, cElement, NIL, NIL, MXML_DESCEND )
   endif
     
   IF Empty( pNode )
      RETURN Map
   ENDIF

   hNext := mxmlWalkNext( pNode, pNode, MXML_DESCEND )
   Map :=  NodeToHash( hNext )

  return Map
// ---------------------------------------------------------------------------//
STATIC FUNCTION NodeToHash( node  )
   Local wt := 0
   Local hNext
   Local hHashChild := {=>}
   Local hHash := {=>}

   WHILE node != NIL
         
         IF mxmlGetType( node ) == MXML_ELEMENT

            if HB_HHASKEY( hHash, mxmlGetElement( node ) )
               if valtype( hHash[ mxmlGetElement( node ) ] ) <> "A"
                  hHash[ mxmlGetElement( node ) ] := mxmlGetOpaque( node )
               else
                 // Es un array, por lo tanto, no lo tocamos
               endif  
            else                  
               hHash[ mxmlGetElement( node ) ] := mxmlGetOpaque( node )
            endif    
            if HB_MXMLGETATTRSCOUNT( node ) > 0
               hHash[ mxmlGetElement( node ) + "@attribute"] := HB_MXMLGETATTRS( node )
            endif  
 
              if empty( mxmlGetOpaque( node ) ) // Miramos dentro
               hNext := mxmlWalkNext( node, node, MXML_DESCEND )  
               if hNext != NIL
                  if empty( hHash[ mxmlGetElement( node ) ]  )
                     hHash[ mxmlGetElement( node ) ] := {}
                  endif  
                   hHashChild :=  NodeToHash( hNext  )
                   if hHashChild != NIL
                      AADD( hHash[ mxmlGetElement( node ) ], hHashChild )
                   endif  
               endif  
            endif
         ENDIF   

         node := mxmlGetNextSibling( node )
                    
   END WHILE

RETURN hHash 
