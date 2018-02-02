   local GetList:={}
   clear
   //aa=achoice(10,10,15,20,{"1","2"})
   aeval( hb_dirscan( ), {|x| qout( x[1] ) } )
   wait
   aeval( hb_dirscan( , , "D" ), {|x| qout( x[1] ) } )
   wait 
