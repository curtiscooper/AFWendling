/*
Procedure:  cc_testBarcodePrint.p

08/11/2022  clc     Created

*/

define variable orderNumber as character no-undo.

define stream print.

assign orderNumber = "G2038300".

{_laser.def}
/*
output to "testz".
*/
output stream print thru lp -dlp8. 

/*put stream print control                            */
/*    "\033(s1p36v0s0b32777T"    /* Code 39 Regular */*/
/*    orderNumber.                                    */
 

put stream print control
    "\033&p8x"    /* Transparent print data command */
    orderNumber.      
    
put stream print
    skip "orderNumber No control " orderNumber skip.

put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "Transparent print data command".

put stream print 
    skip "Transparent print data command NC" skip skip. 




    
put stream print control
    "(s23591T"    /* USPS Zebra code */
    orderNumber.      

put stream print
    skip "orderNumber No control " orderNumber skip.
    
put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "USPS Zebra code".

put stream print 
    skip "USPS Zebra code NC" skip skip. 





put stream print control
    "(s24640T"    /* Interleaved 2 of 5 */
    orderNumber.      

put stream print
    skip "orderNumber No control " orderNumber skip.
    
put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "Interleaved 2 of 5".
    
put stream print 
    skip "Interleaved 2 of 5 NC" skip skip. 


    

put stream print control
    "(s24644T"    /*   USPS tray label, 10-digit 2 of 5 */
    orderNumber.      

put stream print
    skip "orderNumber No control " orderNumber skip.
    
put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "USPS tray label, 10-digit 2 of 5".
    
put stream print 
    skip "USPS tray label, 10-digit 2 of 5 NC" skip skip. 



    
    
put stream print control
    "(s24645T"    /*   USPS sack label, 8-digit 2 of 5 */
    orderNumber.    

put stream print
    skip "orderNumber No control " orderNumber skip.
        
put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "USPS sack label, 8-digit 2 of 5".

put stream print 
    skip "USPS sack label, 8-digit 2 of 5 NC" skip skip. 
    





put stream print control
    "(s24650T"    /*   Industrial 2 of 5 */
    orderNumber.    

put stream print
    skip "orderNumber No control " orderNumber skip.
    
put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "Industrial 2 of 5".
    
put stream print 
    skip "Industrial 2 of 5 NC" skip skip. 







    
    
put stream print control
    "(s24660T"    /*   Matrix 2 of 5 */
    orderNumber.    

put stream print
    skip "orderNumber No control " orderNumber skip.
    
put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "Matrix 2 of 5".

put stream print 
    skip "Matrix 2 of 5 NC" skip skip. 




        
put stream print control
    "(s24670T"    /*    Code 3 of 9 */
    orderNumber.        

put stream print
    skip "orderNumber No control " orderNumber skip.
    
put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "Code 3 of 9".

put stream print 
    skip "Code 3 of 9 NC" skip skip. 





    
put stream print control
    "(s24672T"    /*  Code 3 of 9 space encoding */
    orderNumber.        

put stream print
    skip "orderNumber No control " orderNumber skip.
    
put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "Code 3 of 9 space encoding".

put stream print 
    skip "Code 3 of 9 space encoding NC" skip skip. 





    
put stream print control
    "(s24680T"    /*    Code 3 of 9 extended */
    orderNumber.   

put stream print
    skip "orderNumber No control " orderNumber skip.
    
put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "Code 3 of 9 extended".

put stream print 
    skip "Code 3 of 9 extended NC" skip skip. 




    
put stream print control
    "(s24750T"    /*    Codabar */
    orderNumber.   

put stream print
    skip "orderNumber No control " orderNumber skip.
    
put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "Codabar".

put stream print 
    skip "Codabar NC" skip skip. 






        
put stream print control
    "(s24760T"    /*    MSI */
    orderNumber.          

put stream print
    skip "orderNumber No control " orderNumber skip.
    
put stream print control
    "(s0p4.5h0s0b4099T"    /*    4.5 Courier */
    "MSI".

put stream print 
    skip "MSI NC" skip skip. 
    
        
    
/***
  put stream print control
    "\033(12Yesc(s1p36v0s0b28685T"    /* Code128TT-Regular 1/2 inch */
     orderNumber.      
         

  put stream print control
    "\033(12Yesc(12Yesc(s1p36v0s0b28686T"    /* Code128-NarrowTT-Regular 1/2 inch  */
     orderNumber.     
     
     
  put stream print control
    "\033(12Yesc(s1p36v0s0b28687T"    /* Code128-WideTT-Regular Regular 1/2 inch */
     orderNumber.     
***/
     
     



/*
put reset.
*/

output close.

/*
UNIX SILENT qprt -Plp8 -Bnn testz.
*/