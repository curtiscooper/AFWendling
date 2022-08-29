/*
Procedure:  we_testBarcodePrint.p

08/11/2022  clc     Created

*/

/*{_init.i}                               */
/*{_print.def 5 6 7}                      */
/*{_hdr132.def}                           */
/*                                        */
/*def var last-field as char no-undo.     */
/*def var last-index as int no-undo.      */
/*                                        */
/*{_print.i                               */
/*    &lpp       =  60                    */
/*    &frow      =  2                     */
/*    &choices   =  5                     */
/*    &choose    =  _choosep.chs          */
/*    &choosef   =  _choosef.chs          */
/*    &choosefe  =  _choosefe.chs         */
/*    &page1     =  _nul.i                */
/*    &progname  =  cc_testBarcodePrint.p */
/*    &dispfile  =  cc_testBarcodePrint.di*/
/*    &promptfil =  cc_testBarcodePrint.pi*/
/*    &promptvar =  _nul.i                */
/*    &title     =  "Test Barcode"        */
/*    &form      =  132_3b.f              */
/*    &ff        =  yes                   */
/*    }                                   */
/*                                        */
/*                                        */
/*                                        */

define variable orderNumber as character no-undo.

assign orderNumber = "G2038300".

{_laser.def}
output to "testz".

  put stream print control
    "\033(12Yesc(s1p36v0s0b28685T"    /* Code128TT-Regular 1/2 inch */
     "\033&a" string(50.5 + k) "R" "\033&a102C"
     orderNumber.      
         

  put stream print control
    "\033(12Yesc(12Yesc(s1p36v0s0b28686T"    /* Code128-NarrowTT-Regular 1/2 inch  */
     "\033&a" string(50.5 + k) "R" "\033&a102C"
     orderNumber.     
     
     
  put stream print control
    "\033(12Yesc(s1p36v0s0b28687T"    /* Code128-WideTT-Regular Regular 1/2 inch */
     "\033&a" string(50.5 + k) "R" "\033&a102C"
     orderNumber.     
     
                      /*  put "univers" skip(1).                                      */
            /*  put "\033(10U\033(s1p13v0s0b4148T".                         */
            /*  put "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip.*/
            /*  put "\033(10U" "\033(s1p12v0s0b4148T".                      */
            /*  put "12:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip.*/
            /*  put "\033(10U" "\033(s1p11v0s0b4148T".                      */
            /*  put "11:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip.*/
            /*  put "\033(10U" "\033(s1p10v0s0b4148T".                      */
            /*  put "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip.*/
            /*  put "\033(10U" "\033(s1p9v0s0b4148T".                       */
            /*  put "9:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */
            /*  put "\033(10U" "\033(s1p8v0s0b4148T".                       */
            /*  put "8:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */
            /*  put "\033(10U" "\033(s1p7v0s0b4148T".                       */
            /*  put "7:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */
            /*  put skip(3).                                                */
            /*                                                              */
            /*                                                              */
            /*  put "CG Times:" skip(1).                                    */
            /*                                                              */
            /*  put "\033(10U" "\033(s1p9v0s0b4101T".                       */
            /*  put "9:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */
            /*  put "\033(10U" "\033(s1p8v0s0b4101T".                       */
            /*  put "8:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */
            /*  put "\033(10U" "\033(s1p7v0s0b4101T".                       */
            /*  put "7:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */



put reset.
output close.

UNIX SILENT qprt -Plp8 -Bnn testz.