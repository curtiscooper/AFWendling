/*
Procedure:  we_barcodeConvert.p
Purpose:  Converts a character string to a 128A or a 128B barcode string.
Input  :  ipcBarCodeType = "A" for barcode type 128A and "B" barcode type 128B.
          ipcInputString = The character string to be converted to barcode string.
Output :  Formatted Barcode 
Syntax:  RUN BarCode128AOr128BStringConvert.p(INPUT ipcBarCodeType, INPUT ipcInputString, OUTPUT opcReturnedString).
*/

define input parameter  cBarCodeType    as character   no-undo.
define input parameter  cInputString    as character   no-undo.
define output parameter cReturnedString as character no-undo.

define variable cCurrentCharacter       as character no-undo.
define variable iCurrentAsciiValue      as integer     no-undo.
define variable cStartString            as character no-undo.
define variable iCheckSumValue          as integer   no-undo.
define variable iRunningTotal           as integer   no-undo.
define variable cCheckSumCharacter      as character no-undo.
define variable iCounter                as integer   no-undo.

/* Initialize source and target strings */
assign
    cReturnedString = ""
    cInputString  = trim(cInputString).

/* Barcode type is assumed to be 128B if not 128A */
/* Initialize the starting value and start string */
if cBarCodeType = "A" then
    assign
        iRunningTotal  = 103
        cStartString = chr(123).
else
    assign
        iRunningTotal  = 104
        cStartString = chr(124).

/* Calculate the checksum, mod 103 and build output string */

do iCounter = 1 to length(cInputString):
    cCurrentCharacter = substring(cInputString, iCounter, 1).
    /* get the ASCiCounter value of the current character */
    iCurrentAsciiValue = asc(cCurrentCharacter).
    /* get the barcode 128 value of the current character */
    if iCurrentAsciiValue < 127 then
        iCurrentAsciiValue = iCurrentAsciiValue - 32.
    else
        iCurrentAsciiValue = iCurrentAsciiValue - 103.

    /* Update the checksum running total */
    iRunningTotal = iRunningTotal + iCurrentAsciiValue * iCounter.
    
    /*Compute output string, no spaces in TrueType fonts, quotes replaced for Word mailmerge bug */
    case cCurrentCharacter:
        when chr(32) then
            cReturnedString = cReturnedString + CHR(228).
        when chr(34) then
            cReturnedString = cReturnedString + CHR(226).
        when chr(123) then
            cReturnedString = cReturnedString + CHR(194).
        when chr(124) then
            cReturnedString = cReturnedString + CHR(195).
        when chr(125) then
            cReturnedString = cReturnedString + CHR(196).
        when chr(126) then
            cReturnedString = cReturnedString + CHR(197).
        otherwise
            cReturnedString = cReturnedString + cCurrentCharacter.
    end case.
end.

iCheckSumValue = iRunningTotal modulo 103.
if iCheckSumValue gt 90 then
    cCheckSumCharacter = chr(iCheckSumValue + 103).
else
    if iCheckSumValue gt 0 then
        cCheckSumCharacter = chr(iCheckSumValue + 32).
    else
        cCheckSumCharacter = chr(228).
assign
    cReturnedString = cStartString + cReturnedString + cCheckSumCharacter  + CHR(126) + CHR(32).

/*The following 'Run' procedure with input string and output results as an example:*/
/*                                                                                 */
/*DEF VAR cbarcodetype    AS CHAR.                                                 */
/*DEF VAR cinputstring    AS CHAR FORMAT 'x(20)'.                                  */
/*DEF VAR creturnedstring AS CHAR FORMAT 'x(40)'.                                  */
/*                                                                                 */
/*ASSIGN                                                                           */
/*   cbarcodetype = 'A'                                                            */
/*   cinputstring = '33156611'.                                                    */
/*                                                                                 */
/*                                                                                 */
/*                                                                                 */
/*RUN BarCode128AOr128BStringConvert.p                                             */
/*   (INPUT cbarcodetype, INPUT cinputstring, OUTPUT creturnedstring).             */