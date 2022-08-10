/*******************************************************************************
we_inv2hd.p Laser Formatted Invoice and Pickup Header Print
Modified: 02/01/99 ecc fixed bill/ship-to zip display

08/10/99   - Added Billback print option.
*******************************************************************************/
{_global.def}
{we_inv2w.def 50}
{_laser.def}
{_printsh.def}
def var k as dec no-undo.
def var coname like COMPANY.NAME no-undo.
def var pg-str as char no-undo.
def shared stream print.
def var seq as int no-undo.
def var t-charge as deci no-undo.
/*def var slsname as char no-undo. */
def var oset as deci no-undo.
def var bill-city like CUSTOMER.CITY no-undo.
def var bill-name like CUSTOMER.NAME no-undo.
def var bill-state like CUSTOMER.STATE no-undo.
def var bill-addr1 as char format "X(30)" no-undo.
def var bill-addr2 as char format "X(30)" no-undo.
def var bill-addr3 as char format "X(30)" no-undo.
def var bill-zip like CUSTOMER.ZIP no-undo.
def var bill-attn like CUSTOMER.ATTN no-undo.
def var ship-city like CUSTOMER.CITY no-undo.
def var ship-name like CUSTOMER.NAME no-undo.
def var ship-state like CUSTOMER.STATE no-undo.
def var ship-addr1 as char format "X(30)" no-undo.
def var ship-addr2 as char format "X(30)" no-undo.
def var ship-addr3 as char format "X(30)" no-undo.
def var ship-zip like CUSTOMER.ZIP no-undo.
def var ship-attn like CUSTOMER.ATTN no-undo.
def var t-zip like CUSTOMER.ZIP no-undo.
def var id as int no-undo.
def var disp-frz-cnt as char format "X(15)" no-undo.
def var disp-clr-cnt as char format "X(15)" no-undo.
def var disp-dry-cnt as char format "X(15)" no-undo.
def var disp-tot-cnt as char format "X(15)" no-undo.
def var orig-ord as char no-undo.


def buffer CUSTOMER1 for CUSTOMER.

release PALM_SIGNATURE.
if copy-id[1] <> "P" and copy-id[1] <> "B" then do:
    find ORDER where recid(ORDER) = rr[7] no-lock no-error.
    if avail ORDER then do:
        find SHIP_VIA where SHIP_VIA.CO =C[1] and
             SHIP_VIA.SHIP_VIA = ORDER.SHIP_VIA no-lock no-error.
        find PALM_SIGNATURE where PALM_SIGNATURE.CO = C[1]
         and PALM_SIGNATURE.ORDER = ORDER.ORDER no-lock no-error.
    end.         
end.
/*message "begin we_inv2hd:" copy-id[1] "*" copy-id[2]. pause.*/
/*** Start of Preformatted Form Layout **/
h-page = h-page + 1.  /* count physical pages */
put stream print control
        portrait
       "\033&n11WdPreprinted"
        legal
        "\033&l0E"    /* 0 top margin */
        "\033&l0L".   /* disable perforation skip (page break) */

put stream print control  /*"\033*p50Y"*/
        normal
        cpi12 lpi8
        "\033&a65R" "\033&a21C".  /* position */
/********** now they don't want it 3/9/99 
output stream print close.
find first SYS_CONTROL no-lock.
unix silent cat /4gl/data/csf_logo.pcl >>
                value(SYS_CONTROL.SPOOL_DIR + spoolfile).
output stream print to value(SYS_CONTROL.SPOOL_DIR + spoolfile)
      page-size 0 append.
***************/

put stream print control
        normal
        cpi12 lpi8.


/* gray bars 3 lines high */
/****** commented 10/30/96 pending approval ***/
/* Commented 08/28/97 For manual Faxing to Company 2 */
oset = 55.5.
id = 1.
do k = 0 to oset by 55.5:
   do i = 1 to 24 by 6:
     put stream print control
        cpi14 normal
        "\033&a" string(i + k + 23.5) "R"
        "\033*p+10Y"    /* down 10 points */
        "\033&a0C"      /* column 0 */
        "\033*c10.5G"   /* 11% gray (10=too light 11=too dark, not continuous)*/
        "\033*c2360A"   /* rectangle width */
        "\033*c110B"     /* rectangle height */
        "\033*c2P".      /* Shade fill */
     /*   "\033*p-35Y".   /* up 12 points */ */
   end.
end.
/* */
/*****/
/* 7055 orig */
oset = 7055.
id = 1.
do k = 0 to oset by 7055.
  if copy-id[id] > "" then do:
  put stream print  "~033%0B"          /* pen mode for drawing lines */
     "IN;SP1;PA0," string(11060 - k) ";"
     "PD8000," string(11060 - k) ";"    /* hor above Item # U/M ... */
     "PU0,"    string(10940 - k) ";"
     "PD8000," string(10940 - k) ";"   /*            below                */
     "PU0,"    string(7500 - k) ";"
     "PD8000," string(7500 - k) ";"        /* hor above Subtotal, tax */
     "PU0,"    string(7380 - k) ";"
     "PD8000," string(7380 - k) ";"        /*            below                */
     "PU0,"    string(7380 - k) ";"
     "PD0,"    string(11060 - k) ";"           /* ver left margin            */
     "PU8000," string(6730 - k) ";"
     "PD8000," string(11060 - k) ";"     /* ver right margin           */

     "PU4200," string(7160 - k) ";"
     "PD8000," string(7160 - k) ";"        /* hor subtotal...total         */
     "PU7130," string(6940 - k) ";"
     "PD8000," string(6940 - k) ";"        /*                                */
     "PU7130," string(6720 - k) ";"
     "PD8000," string(6720 - k) ";"        /*                                */

     "PU4200," string(7160 - k) ";"
     "PD4200," string(7500 - k) ";"        /* ver left of subtot       */

     "PU7130," string(6720 - k) ";"
     "PD7130," string(7500 - k) ";"        /* ver left  of subtot       */
     "PU6200," string(7160 - k) ";"
     "PD6200," string(7500 - k) ";"        /* ver right of subtot    */
     "PU5200," string(7160 - k) ";"
     "PD5200," string(7500 - k) ";"        /* ver right of tx        */

     "~033%0A".       /* return to normal mode after line drawing */
  end.
  id = id + 1.
  if copy-id[id] = "" then leave.
end.

find COMPANY where COMPANY.CO = C[1] no-lock.
put stream print control /* cpi11 bold */
   "\033(s1p11v0s0b4148T"    /* 9 points medium univers */
    bold
  /********************************
    "\033&a" trim(string(4))    "R\033&a63C" trim(COMPANY.NAME)
    "\033&a" trim(string(5.5))  "R\033&a63C" trim(COMPANY.ADDRESS[1])
    "\033&a" trim(string(7))    "R\033&a63C" trim(COMPANY.CITY) + ", " +
        trim(COMPANY.STATE) + "  " + trim(COMPANY.ZIP)
  ********************************/
 /* bottom address at left */
  /*******************************
    "\033&a" trim(string(4 + 55.5)) "R\033&a63C" trim(COMPANY.NAME)
    "\033&a" trim(string(5.3 + 55.5)) "R\033&a63C" trim(COMPANY.ADDRESS[1])
    "\033&a" trim(string(6.6 + 55.5)) "R\033&a63C" trim(COMPANY.CITY) + ", " +
        trim(COMPANY.STATE) + "  " + trim(COMPANY.ZIP)
    "\033&a" trim(string(7.9 + 55.5))  "R\033&a63C" string(COMPANY.PHONE[1],
            "(XXX) XXX-XXXX")
  ******************************/
  .

oset = 55.5.
id = 1.
do k = 0 to oset by 55.5:
if copy-id[id] > "" then do:
put stream print control /* cpi11 bold */
   "\033(s1p11v0s0b4148T"    /* 9 points medium univers */
    bold
    "\033&a" trim(string(2 + k))

     (if copy-id[id] = "C" and not copy-flag& then
       ("R\033&a65C" + "Customer Copy")
     else if copy-id[id] = "C" and copy-flag& then "R\033&a62C" +
                  "Extra Customer Copy"
     else if copy-id[id] = "P" then "R\033&a63C" + "Customer Return"
     else if copy-id[id] = "B" then "R\033&a63C" + "Vendor Billback"
     else "R\033&a69C" + "Driver Copy")

     if copy-id[id] = "P" then "\033&a117C" + "Pickup:"
     else if copy-id[id] = "B" then "\033&a117C" + "Billbk:"
                          else "\033&a117C" +
                          (if avail ORDER and ORDER.TYPE <> "C" then
                          "Invoice:" else "Credit:")

    "\033&a" trim(string(4 + k))  "R\033&a117C" "Page:   "
    "\033&a" trim(string(6 + k))  "R\033&a117C" "Date:   "
    "\033&a" trim(string(8 + k))  "R\033&a20C"  "HACCP CERTIFIED"
    "\033&a" trim(string(8 + k))  "R\033&a117C" "Route:  "
    "\033&a" trim(string(10 + k)) "R\033&a117C" "Driver: "
    "\033&a" trim(string(12 + k)) "R\033&a117C" "Acct Mgr:"
    "\033&a" trim(string(14 + k)) "R\033&a117C" "Cust PO: "
    "\033&a" trim(string(16 + k)) "R\033&a117C" "Ship Via: "
    "\033&a" trim(string(17 + k)) "R\033&a3C"  "Terms:"
    "\033&a" trim(string(17.5 + k)) "R\033&a117C" "Collected"
    "\033&a" trim(string(18.1 + k)) "R\033&a3.2C"  "Instr:"
    "\033&a" trim(string(18.6 + k)) "R\033&a117C" "On Account:_______________"
    .

if copy-id[id] = "P" then
  put stream print control
    "\033&a" trim(string(20 + k)) "R\033&a61C"  "This is Not a Credit".

/* if copy-id[id] = "C" and copy-cnt > 1 then do: */
put stream print
   "\033(s0p30h0s0b4099T"    /* courier */
    cpi12 bold
    "\033&a" string(9.5 + k)  "R\033&a0C" "S                              B"
    "\033&a" string(10.5 + k) "R\033&a0C" "H                              I"
    "\033&a" string(11.5 + k) "R\033&a0C" "I                              L"
    "\033&a" string(12.5 + k) "R\033&a0C" "P                              L"
    "\033&a" string(14 + k)   "R\033&a0C" "T                              T"
    "\033&a" string(15 + k)   "R\033&a0C" "O                              O".

/* put stream print control normal cpi12 lpi8 "\033&a14R". */
disp-frz-cnt = trim(string(totcases[1],'->>>9'))
             + 'cs/'
             + trim(string(totsplts[1],'->>9'))
             + 'ea'.
disp-clr-cnt = trim(string(totcases[2],'->>>9'))
             + 'cs/'
             + trim(string(totsplts[2],'->>9'))
             + 'ea'.
disp-dry-cnt = trim(string(totcases[3],'->>>9'))
             + 'cs/'
             + trim(string(totsplts[3],'->>9'))
             + 'ea'.
disp-tot-cnt = trim(string(totcases[1] + totcases[2] + totcases[3],'->>>9'))
             + 'cs/'
             + trim(string(totsplts[1] + totsplts[2] + totsplts[3],'->>9'))
             + 'ea'.
                                 

put stream print control
    normal
   "\033(s1p9v0s0b4148T"    /* 9 points medium univers */
    cpi14
    "\033&a" string(21 + k) "R\033&a0C"
    /**if copy-id[id] = "C" then **/
    " Item#    Qty  U/M  Brand                  Description                  " +
    "                     Pack            Manuf#       Unit Price     Price"
    "   Sts   Amount"
    /*****
    else /* copy-id[id] = "D" */
    "   Slot      Qty    U/M   Brand                Description             " +
    "                         Pack           Item      Weight      Price" +
    "   Sts      Amount"
    ***************/
    /***
    "\033&a" + string(49 + k) + "R\033&a5C" +
          "Dry: " + string(totpieces[1])

    "\033&a" + string(49 + k) + "R\033&a25C" +
          "Refr: " + string(totpieces[2]) 

    "\033&a" + string(49 + k) + "R\033&a45C" +
          "Froz: " + string(totpieces[3]) 

    "\033&a" + string(49 + k) + "R\033&a65C" +
              "PIR: " + string(totpieces[4])
              
    "\033&a" + string(49 + k) + "R\033&a81C" +
          "Total: " 
          + string(totpieces[1] + totpieces[2] + totpieces[3] + totpieces[4]) 
    ******/
    "\033&a" + string(49 + k) + "R\033&a5C" +
           "FRZ " + trim(disp-frz-cnt)
      + "   CLR " + trim(disp-clr-cnt)
      + "   DRY " + trim(disp-dry-cnt)
      + "      ALL " + trim(disp-tot-cnt)                                
    
    "\033&a" string(49 + k) "R\033&a100C"
    "        Subtotal                Tax         "
/** "        Bev Tax         Total"  **/
    "                             Total"
    
    "\033&a" string(52.3 + k) "R\033&a153C"
    "Return"
    "\033&a" string(52.3 + k) "R\033&a176C"
    "_____________"
    "\033&a" string(54.0 + k) "R\033&a153C"
    "Corr Amount"
    "\033&a" string(54.0 + k) "R\033&a176C"
    "_____________"
    .

put stream print control
 "\033(s1p5v0s0b4148T"    /* 5 points medium univers */
/* "\033(s0p30h0s0b4099T"    /* restore courier */ */
/* "~033(s35H" lpi14         /* cpi25*/ */
 "\033&a" string(50 + k) "R\033&a0C"
 "Claims for shortages and damages must be noted by your truck driver the day"
 " of delivery.   No Credit will be issued on goods"
 "\033&a" string(50.5 + k) "R\033&a0C"
 "returned without authorization from our office.  Service charge will be asses"
 "sed to all past due accounts.  Ownership of items"
 "\033&a" string(51 + k) "R\033&a0C"
 "shown on this invoice are not transferred until invoice is paid in full.  All"
 " returned checks are subject to a return check fee."
 "\033&a" string(51.5 + k) "R\033&a0C"
 "Perishable products are not eligible for return after delivery."
 .

   if copy-id[id] = "D" or copy-id[id] = "C" then do:
     put stream print control
    /*   cpi17 lpi10 */
       "\033(s1p8v0s0b4148T"    /* 8 points medium univers */
       "\033&a" string(52.5 + k) "R\033&a0C"
       "    You must check your"
       "\033&a" string(53.5 + k) "R\033&a0C"
       " merchandise before signing".

     put stream print control
      "\033(s0p30h0s0b4099T"    /* restore courier */
       cpi6 lpi10 normal
       "\033&a" string(53.5 + k) "R\033&a12C"
       "X_____________________".
     if copy-id[id] = "D" and avail PALM_SIGNATURE and
        PALM_SIGNATURE.SIGNATURE_DATA > "" then do:
         run draw-vector (3000, (if id = 1 then 6500 else 0),
                            PALM_SIGNATURE.SIGNATURE_DATA).
     end.
  end.
  end.
  id = id + 1.
/*   message "1: ID:" id. pause.*/
  if copy-id[id] = "" then leave.
end. /* k = 0 to oset */
put stream print control "\033(s0p30h0s0b4099T".    /* restore courier */
 /*** End of preformatted form layout ***/

if copy-id[1] = "B" then do:
   find BILLBK where recid(BILLBK) = rr[7] no-lock no-error.
   find VENDOR where recid(VENDOR) = rr[2] no-lock.
end.
else do:
   if copy-id[1] = "P" then
        find PICKUP where recid(PICKUP) = rr[7] no-lock no-error.
   find CUSTOMER where recid(CUSTOMER) = rr[2] no-lock.
end.   

/***
find ORDER where ORDER.CO = C[1] and
     ORDER.ORDER = "00027000" no-lock no-error.
find CUSTOMER where CUSTOMER.CO = C[1] and
     CUSTOMER.CUSTOMER = ORDER.CUSTOMER no-lock no-error.
***/
find OE_CONTROL where OE_CONTROL.CO = C[1] no-lock.
find COMPANY where COMPANY.CO = C[1] no-lock.

assign
  pg     = pg + 1
  driver = ""
  seq    = 0
  rt     = ""
  line   = 0.

/* message pg copy-id[1] copy-id[2]. pause. */
  if copy-id[1] <> "B" then do:
     find first ROUTE_SEQ where ROUTE_SEQ.CO = C[1] and
          ROUTE_SEQ.DATE_= (if avail ORDER then ORDER.SHIP_DT
                            else PICKUP.PICKUP_DT) and
          ROUTE_SEQ.ORDER= (if avail ORDER then ORDER.ORDER
                            else PICKUP.PICKUP) no-lock no-error.
     if avail ROUTE_SEQ then do:
       find first ROUTE_HDR where ROUTE_HDR.CO = C[1] and
            ROUTE_HDR.ROUTE = ROUTE_SEQ.ROUTE and
            ROUTE_HDR.DATE_ = ROUTE_SEQ.DATE_ no-lock no-error.
       find DRIVER where DRIVER.CO = C[1] and
            DRIVER.DRIVER = ROUTE_HDR.DRIVER no-lock no-error.
     end.
     if avail ROUTE_HDR and avail ROUTE_SEQ then assign
         seq    = ROUTE_SEQ.STOP_  /* was ROUTE_SEQ.SEQ */
         rt     = ROUTE_HDR.ROUTE
         driver = if avail DRIVER then
                     trim(ROUTE_HDR.DRIVER) + "--" + trim(DRIVER.NAME)
                  else trim(ROUTE_HDR.DRIVER).

     if CUSTOMER.BILL_TO > "" then find CUSTOMER1 where CUSTOMER1.CO = C[1] and
          CUSTOMER1.CUSTOMER = CUSTOMER.BILL_TO no-lock no-error.

     /* **************************************************
      ** REMOVED UNTIL CAN SETUP NEW CHAIN STRUCTURE ***
      **************************************************
     if CUSTOMER.BILL_TO = "C" then
        find CHAIN where CHAIN.CO = C[1] and
             CHAIN.CHAIN = CUSTOMER.CHAIN no-lock no-error.
     else if CUSTOMER.BILL_TO = "F" then
        find FRANCHISE where FRANCHISE.CO = C[1] and
             FRANCHISE.FRANCHISE = CUSTOMER.FRANCHISE no-lock no-error.
     */
     release CHAIN.
     release FRANCHISE.


     find SALESREP where SALESREP.CO = C[1] and
          SALESREP.SALESREP = (if avail ORDER then ORDER.SALESREP
                              else PICKUP.SALESREP) no-lock no-error.
     slsname = if avail SALESREP then SALESREP.NAME else "".
     find TERMS where TERMS.CO = C[1] and
          TERMS.TERMS = (if avail ORDER then ORDER.TERMS
                        else CUSTOMER.TERMS) no-lock no-error.
     termsdesc = if avail TERMS then TERMS.DESCRIPTION else "".
  end.
  else do:
      if not avail VENDOR then
        find VENDOR where VENDOR.CO = C[1] and
             VENDOR.VENDOR = BILLBK.VENDOR no-lock no-error.
  end.         

assign
bill-name  = if avail VENDOR then VENDOR.NAME 
             else if avail CUSTOMER1 then CUSTOMER1.NAME
             else if avail CHAIN then CHAIN.NAME
             else if avail FRANCHISE then FRANCHISE.NAME
             else CUSTOMER.NAME
bill-city  = if avail VENDOR then trim(VENDOR.CITY)
             else if avail CUSTOMER1 then trim(CUSTOMER1.CITY)
             else if avail CHAIN then trim(CHAIN.CITY)
             else if avail FRANCHISE then trim(FRANCHISE.CITY)
             else trim(CUSTOMER.CITY)
bill-state = if avail VENDOR then VENDOR.STATE
             else if avail CUSTOMER1 then CUSTOMER1.STATE
             else if avail CHAIN then CHAIN.STATE
             else if avail FRANCHISE then FRANCHISE.STATE
             else CUSTOMER.STATE
bill-addr1 = if avail VENDOR then VENDOR.ADDRESS[1] 
             else if avail CUSTOMER1 then CUSTOMER1.ADDRESS[1]
             else if avail CHAIN then CHAIN.ADDRESS[1]
             else if avail FRANCHISE then FRANCHISE.ADDRESS[1]
             else CUSTOMER.ADDRESS[1]
bill-addr2 = if avail VENDOR then VENDOR.ADDRESS[2] 
             else if avail CUSTOMER1 then CUSTOMER1.ADDRESS[2]
             else if avail CHAIN then CHAIN.ADDRESS[2]
             else if avail FRANCHISE then FRANCHISE.ADDRESS[2]
             else CUSTOMER.ADDRESS[2]
bill-addr3 = if avail VENDOR then VENDOR.ADDRESS[3] 
             else if avail CUSTOMER1 then CUSTOMER1.ADDRESS[3]
             else if avail CHAIN then CHAIN.ADDRESS[3]
             else if avail FRANCHISE then FRANCHISE.ADDRESS[3]
             else CUSTOMER.ADDRESS[3]
bill-zip   = if avail VENDOR then VENDOR.ZIP
             else if avail CUSTOMER1 then CUSTOMER1.ZIP
             else if avail CHAIN then CHAIN.ZIP
             else if avail FRANCHISE then FRANCHISE.ZIP
             else CUSTOMER.ZIP
bill-attn =  if avail VENDOR then VENDOR.ATTN[1]
             else if avail CUSTOMER1 then CUSTOMER1.ATTN
             else if avail FRANCHISE then FRANCHISE.ATTN
             else CUSTOMER.ATTN.
             
if bill-zip <> "" then do:                                             
   if length(bill-zip) < 6 or substring(bill-zip,6,4) <> "9999" then   
      t-zip = string(bill-zip,"X(5)").                                
   else t-zip = string(bill-zip, "XXXXX-XXXX").                       
end.
bill-zip = t-zip.         

/*
assign
bill-name  = CUSTOMER.NAME
bill-city  = CUSTOMER.CITY
bill-state = CUSTOMER.STATE
bill-addr1 = CUSTOMER.ADDRESS[1]
bill-addr2 = CUSTOMER.ADDRESS[2]
bill-zip   = CUSTOMER.ZIP
bill-attn  = CUSTOMER.ATTN.
*/

id = 1.
do k = 0 to oset by 55.5:
   if copy-id[id] > "" then do:
   put stream print cpi9 normal
          "\033&a" string(2 + k) "R\033&a60C"
                   string(if avail PICKUP then PICKUP.PICKUP
                   else if avail BILLBK then BILLBK.BILLBK
                   else ORDER.ORDER,"XXXXXX-XX") format "X(9)".

   if copy-flag& and k > 0 then pg = pg + 1.  /* extras 2 to a page */
   pg-str = string(pg) + " of " + string(if copy-id[id] = "C" then cust-pg
                                  else if copy-id[id] = "D" then driver-pg
                                  else pickup-pg).

   put stream print cpi10 normal
      "\033&a" string(4 + k) "R\033&a66C" pg-str  /* format "ZZ9" */
      "\033&a" string(6 + k) "R\033&a66C" 
                (if avail ORDER then ORDER.SHIP_DT 
                    else if avail PICKUP then PICKUP.PICKUP_DT else gb-dt)
      "\033&a" string(8 + k) "R\033&a66C" trim(rt) +
                                          (if rt > "" then "-" else " ") +
                                          trim(string(seq,"ZZZZZ"))
                                          format "X(10)"
      "\033&a" string(10 + k) "R\033&a66C" driver
      "\033&a" string(12 + k) "R\033&a66C"
           trim(if avail PICKUP then PICKUP.SALESREP
                else if avail ORDER then ORDER.SALESREP else "") + " " +
           slsname format "X(20)"
      "\033&a" string(14 + k) "R\033&a66C" 
           (if avail ORDER then ORDER.CUST_ORNBR
            else if avail BILLBK then BILLBK.VENDOR_PO else "") format "X(14)"
      "\033&a" string(16 + k) "R\033&a66C"
           trim(if avail BILLBK or avail PICKUP then "" else if
                  avail SHIP_VIA then SHIP_VIA.DESCRIPTION
                  else ORDER.SHIP_VIA) format "X(15)".

   put stream print control
        cpi8 normal
       "\033&a" string(9.8 + k) "R"
                   "\033&a2C"  "CUST#: "
                               trim(if avail VENDOR then VENDOR.VENDOR 
                                    else CUSTOMER.CUSTOMER)
                   "\033&a22C" "CUST#: "
                               trim(if avail VENDOR then VENDOR.VENDOR
                               else if avail CUSTOMER1 then CUSTOMER1.CUSTOMER                                       else CUSTOMER.CUSTOMER).

   put stream print control cpi12 normal.
   assign
     ship-name =  if avail ORDER and trim(ORDER.SH_NAME) > "" then ORDER.SH_NAME
                  else if avail PICKUP then PICKUP.SH_NAME
                  else if avail BILLBK then BILLBK.NAME
                  else bill-name
     ship-addr1 = if avail ORDER then ORDER.SH_ADDRESS[1]
                  else if avail PICKUP then PICKUP.SH_ADDRESS[1]
                  else bill-addr1
     ship-addr2 = if avail ORDER then ORDER.SH_ADDRESS[2]
                  else if avail PICKUP then PICKUP.SH_ADDRESS[2]
                  else bill-addr2
     ship-addr3 = if avail ORDER then ORDER.SH_ADDRESS[3]
                  else if avail PICKUP then PICKUP.SH_ADDRESS[3]
                  else bill-addr3
     ship-city =  if avail ORDER then trim(ORDER.SH_CITY)
                  else if avail PICKUP then trim(PICKUP.SH_CITY)
                  else bill-city
     ship-state = if avail ORDER then ORDER.SH_STATE
                  else if avail PICKUP then PICKUP.SH_STATE
                  else bill-state
     ship-zip  =  if avail ORDER then ORDER.SH_ZIP
                  else if avail PICKUP then PICKUP.SH_ZIP
                  else bill-zip.

   if (trim(ship-name) = "SAME") or (trim(ship-name) = "" and
        trim(ship-addr1) = "") then assign
     ship-name = bill-name
     ship-addr1= bill-addr1
     ship-addr2= bill-addr2
     ship-city = bill-city
     ship-state = bill-state
     ship-zip  = bill-zip.

   if ship-zip <> bill-zip then do:                                    
      if length(ship-zip) < 6 or substring(ship-zip,6,4) <> "9999" then                   t-zip = string(ship-zip,"X(5)").                    
      else t-zip = string(ship-zip, "XXXXX-XXXX").           
   end.

   
   put stream print
       "\033&a" string(11 + k) "R"
                "\033&a3C"  ship-name  format "X(25)"
                "\033&a34C" bill-name  format "X(25)"
       "\033&a" string(12 + k) "R"
                "\033&a3C"  ship-addr1 format "X(25)"
                "\033&a34C" bill-addr1 format "X(25)"
       "\033&a" string(13 + k) "R"
                "\033&a3C"  ship-addr2 format "X(25)"
                "\033&a34C" bill-addr2 format "X(25)"
       "\033&a" string(14 + k) "R"
                "\033&a3C"  ship-city + ", " + ship-state + 
                            " " + ship-zip format "X(25)"
                "\033&a34C" bill-city + ", " + bill-state +
                            " " + bill-zip format "X(25)"
       "\033&a" string(15 + k) "R\033&a3C" 
            if avail VENDOR then VENDOR.PHONE[1] else    
            if avail CUSTOMER then CUSTOMER.PHONE[1]
            else "" format "(XXX)XXX-XXXX"               
       "\033&a" string(17 + k) "R" "\033&a11C"  termsdesc format "X(18)"
       "\033&a" string(18 + k) "R" "\033&a11C"
                   if avail PICKUP then PICKUP.INSTRUCTION
                   else if avail ORDER then ORDER.INSTRUCTION 
                   else "" format "X(60)".

     /***/
       if avail ORDER then do:
             find first CUST_COMM where CUST_COMM.CO = C[1] and
                  CUST_COMM.CUSTOMER = CUSTOMER.CUSTOMER and
                  CUST_COMM.CODE = "DEL" no-lock no-error.
             if avail CUST_COMM then do:
                put stream print
                  "\033&a" string(19 + k) "R" "\033&a11C"
                   CUST_COMM.COMMENT.
             end.
       end.
     /***/  
   end.
   id = id + 1.
   /*message "2: id:" id. pause. */
   if copy-id[id] = "" then leave.
end. /* k = 0 to oset */

/* adding message ecc 3/1/99 */
if pg = 1 and copy-id[1] <> "B" then do:
  assign
    inv-mess&   = if (OE_CONTROL.INVOICE_MESS[1] + OE_CONTROL.INVOICE_MESS[2] +
                  OE_CONTROL.INVOICE_MESS[3] + OE_CONTROL.INVOICE_MESS[4] +
                  OE_CONTROL.INVOICE_MESS[5]) > "" and
                  gb-dt >= OE_CONTROL.INV_MESS_START_DT and
                  gb-dt <= OE_CONTROL.INV_MESS_END_DT then yes else no.
                  
/***** to do: add this
    chain-mess& = no
    cust-mess&  = if CUSTOMER.INV_MESS_STR > "" and
                  gb-dt >= CUSTOMER.INV_MESS_START_DT and
                  gb-dt <= CUSTOMER.INV_MESS_END_DT then yes else no.
 /*   if cust-mess& = yes and CUSTOMER.INV_MESS_PRINT& = no then
           inv-mess& = no. */
  if CUSTOMER.CHAIN > "" then do:
     find CHAIN where CHAIN.CO = C[1] and
          CHAIN.CHAIN = CUSTOMER.CHAIN no-lock no-error.
     chain-mess& = if CHAIN.INV_MESS_STR > "" and
                  gb-dt >= CHAIN.INV_MESS_START_DT and
                  gb-dt <= CHAIN.INV_MESS_END_DT then yes else no.
  /*  if chain-mess& = yes and CHAIN.INV_MESS_PRINT& = no then
           inv-mess& = no. */
  end.

  if inv-mess& = yes then do i = 1 to 5:
   if trim(OE_CONTROL.INVOICE_MESS[i]) > "" then do:
      if substr(OE_CONTROL.INVOICE_MESS[i],1,2) = "/n" then
         put stream PRINT " " skip.
      else put stream PRINT OE_CONTROL.INVOICE_MESS[i] at 25 SKIP.
      line = line + 1.
   end.
  end.

/* print CUSTOMER or CHAIN invoice header message */
  if cust-mess& = yes then comm = CUSTOMER.INV_MESS_STR.
  else if chain-mess& = yes then comm = CHAIN.INV_MESS_STR.
  do while index(comm, chr(254)) > 0:
       assign txt  = substr(comm,1,max(index(comm, chr(254)) - 1, 0))
              comm = substr(comm, index(comm, chr(254)) +  1)
              line = line + 1.
          put stream PRINT txt format "X(70)" at 25 skip.
  end.
  print-line = line.
end.
******/

end.
/***
if gb-realid = "root" then do:
  output to "temp.inv".
  for each W_CUST:
     disp W_CUST.W_TXT format "X(78)" with frame x.
  end.
end.
***/
find first W_CUST no-error.
find first W_DRIVER no-error.

id = 1.
do k = 0 to oset by 55.5:
  if copy-id[id] > "" then do:
  /* message "Item Loop:" id copy-id[1] copy-id[2]. pause. */
  if copy-id[id] = "C" or copy-id[id] = "P" or copy-id[id] = "B" then do:
      if last-cust-rid <> ? then
          find first W_CUST where recid(W_CUST) = last-cust-rid no-error.
      if not avail W_CUST then find first W_CUST no-error.
  end.
  else do:
      if last-driver-rid <> ? then
          find first W_DRIVER where recid(W_DRIVER)= last-driver-rid no-error.
      if not avail W_DRIVER then find first W_DRIVER no-error.
  end.

  if copy-id[id] = "C" or copy-id[id] = "P" or copy-id[id] = "B" then
     do i = 1 to 24:
     /*message "Cust Row:" (i + k + 21.5). pause. */
     put stream print control
        cpi14 normal
        "\033&a" string(i + k + 21.5) "R" "\033&a0.2C" W_CUST.W_TXT.
        
        find next W_CUST no-error.
        last-cust-rid = recid(W_CUST).
        if not avail W_CUST then do:
           /* ecc adding invoice message */                            
           /***
           if inv-mess& = yes then do j = 1 to 5:                               
              if trim(OE_CONTROL.INVOICE_MESS[j]) > "" and                      
                 (i + k + 21.5 + j) <= (26 + k + 21.5) then do:                
                    put stream print control cpi12 normal                                                "\033&a" string(i + k + j + 21.5) "R" "\033&a17C"  
                    if substr(OE_CONTROL.INVOICE_MESS[j],1,2) = "/n" then " "                        else OE_CONTROL.INVOICE_MESS[j].                  
              end. /* if trim(OE_CONTROL...) */                              
           end. /* if inv-mess& = yes */     
           ***/                                  
           leave.                                                               
        end. /* if not avail w_cust */                                       
  end. /* copy-id = C */
  if copy-id[id] = "D" then do i = 1 to 24:
     /*message "Driver Row:" (i + k + 21.5) "Avail:" avail W_DRIVER. pause.*/
     /*message "driver line" string(i + k + 21.5) w_driver.w_txt. pause. */
     put stream print control
        cpi14 normal
        "\033&a" string(i + k + 21.5) "R" "\033&a0.2C" W_DRIVER.W_TXT.
        find next W_DRIVER no-error.
        last-driver-rid = recid(W_DRIVER).
        if not avail W_DRIVER then do:
        /* ecc adding invoice message */                              
           /***
           if inv-mess& = yes then do j = 1 to 5:                              
              if trim(OE_CONTROL.INVOICE_MESS[j]) > "" and     
                 (i + k + 21.5 + j) <= (26 + k + 21.5) then do:                                     put stream print control cpi12 normal                      
                        "\033&a" string(i + k + j + 21.5) "R" "\033&a17C"     
                    if substr(OE_CONTROL.INVOICE_MESS[j],1,2) = "/n" then " "
                    else OE_CONTROL.INVOICE_MESS[j].                    
              end. /* if trim(OE_CONTROL...) */                
           end. /* if inv-mess& = yes */  
           ***/                                    
           leave.                                                               
        end. /* if not avail w_driver */                                     
  end. /* copy-id = D */

  if avail ORDER then do:
    t-charge = 0.
    for each ORDER_CHARGE where ORDER_CHARGE.CO = C[1] and
      ORDER_CHARGE.ORDER = ORDER.ORDER no-lock:
      t-charge = t-charge + ORDER_CHARGE.AMOUNT.
    end.
  end.
         

  /* totals */

   if (copy-id[id] = "D" and not avail W_DRIVER) or
      (copy-id[id] = "C" and not avail W_CUST)  or
      (copy-id[id] = "B" and not avail W_CUST)  
      /**** No totals for Pickups, they aree not Credits
      (copy-id[id] = "P" and not avail W_CUST) 
      ****/
      then do:
     /**
     if CUSTOMER.INV_PRICING = "N" 
     then 
     put stream print
       cpi14 normal
       "\033&a" string(50.5 + k) "R" "\033&a60C"
       ""   format "              "     
       ""   format "              "
       ""   format "             "
       bold
       ""   format "           "
       normal.
     else
     **/
     if CUSTOMER.INV_PRICING <> "N" then
     put stream print
       cpi14 normal
       "\033&a" string(50.5 + k) "R" "\033&a60C"
       (totext[1] + t-charge + (if avail ORDER then ORDER.TTL_ADF else 0))                                            format " ZZZ,ZZZ.99-  "
       if avail ORDER then ORDER.TTL_TAX else tax
                                      format "ZZZ,ZZZ.99-   "
       if avail ORDER then /*ORDER.TTL_ADF*/ 0 else 0
                                      format "ZZZ,ZZZ.99-  "
       bold
       (totext[1] + t-charge +
        (if avail ORDER then ORDER.TTL_TAX else tax) +
        (if avail ORDER then ORDER.TTL_ADF else 0)) format "ZZZ,ZZZ.99-"
       normal.
   end.
   else if (copy-id[id] = "P" and not avail W_CUST) then do:
     put stream print
        cpi14 normal
        "\033&a" string(50.5 + k) "R" "\033&a102C"
        "---".
   end.                       
   else do:
    put stream print
       cpi14 normal
       "\033&a" string(50.5 + k) "R" "\033&a102C"
       "CONTINUED".

  /***     "\033&a" string(52 + k) "R" "\033&a101C"
       "ZZZ,ZZZ.99-"
       "\033&a" string(54 + k) "R" "\033&a101C"
       "ZZZ,ZZZ.99-".  ***/
   end.
   end.
   id = id + 1.
   if copy-id[id] = "" then leave.
end.

{o_sign.i}
