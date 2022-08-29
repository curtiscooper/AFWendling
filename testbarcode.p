
/*------------------------------------------------------------------------
    File        : testbarcode.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Curtis
    Created     : Tue Aug 09 23:31:38 EDT 2022
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */



/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */


DEF VAR cbarcodetype    AS CHAR.
DEF VAR cinputstring    AS CHAR FORMAT 'x(20)'.
DEF VAR creturnedstring AS CHAR FORMAT 'x(40)'.

ASSIGN
   cbarcodetype = 'A'
   cinputstring = '33156611'.
   
run we_barcodeConvert.p (INPUT cbarcodetype, INPUT cinputstring, OUTPUT creturnedstring).   

message creturnedstring
view-as alert-box.

