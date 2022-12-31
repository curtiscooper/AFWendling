/*******************************************************************************
b_palmap1.p   - Displays Pallet Map from PICK_LABEL_DETAIL files.
Display File
07/18/19 Palmer only: print 22/30 pallet positions when blank
*******************************************************************************/
{_global.def}
{_printsh.def}
def shared stream PRINT.
def var i as int no-undo.
def var t-pcs as int no-undo.
def var t-cube as deci no-undo.
def var t-wt as deci no-undo.
def var p-pcs as int no-undo.
def var p-cube as deci no-undo.
def var p-wt as deci no-undo.
def var g-pcs as int no-undo.
def var g-cube as deci no-undo.
def var g-wt as deci no-undo.
def var palname as char format "X(30)" no-undo.
def var cnt as int no-undo.
def var pos1 as int no-undo.
def var pos2 as int no-undo.
def var pallet as char format "X(12)" extent 2 no-undo.
def var stop-range as char extent 2 no-undo.
def var cube as deci extent 2 no-undo.
def var pcs as deci extent 2 no-undo.
def var wt as deci extent 2 no-undo.
def var side-wt as deci extent 2 no-undo.
def var h-stop-range as char no-undo.
def var h-cube as deci no-undo.
def var h-pallet as char no-undo.
def var CustName             like OE.CUSTOMER.NAME                no-undo.
def var commnt as char extent 4 no-undo.
def var last-shtype as char no-undo.
def var commnt-str as char no-undo.
def var plt-left& as logi no-undo.


def temp-table W_COMPARTMENT no-undo
    field W_SHTYPE like SHIP_TYPE.SHIP_TYPE
    field W_COMPARTMENTID like SHIP_TYPE.TEMP_COMPARTMENT
    field W_COMPARTMENT as int.

def shared temp-table w_pallet no-undo
   field w_pallet as char
   field w_first_stop as int
   field w_compartment as int
   field w_last_stop as int
   field w_cube as deci
   field w_wt as deci
   field w_pos as int
   field w_pcs as int.

find ROUTE_HDR where recid(ROUTE_HDR) = r no-lock no-error.
last-shtype = ?.

i = 0.
for each SHIP_TYPE where SHIP_TYPE.CO = C[1] and
    SHIP_TYPE.BRANCH = ROUTE_HDR.BRANCH no-lock
    break by SHIP_TYPE.TEMP_COMPARTMENT:
    if first-of(SHIP_TYPE.TEMP_COMPARTMENT) then i = i + 1.
    
    create W_COMPARTMENT.
    assign W_COMPARTMENT.W_SHTYPE = SHIP_TYPE.SHIP_TYPE
           W_COMPARTMENT.W_COMPARTMENT = i
           W_COMPARTMENT.W_COMPARTMENTID = SHIP_TYPE.TEMP_COMPARTMENT.
end.

find TRUCK where TRUCK.CO = C[1] and
     TRUCK.TRUCK = ROUTE_HDR.TRUCK no-lock no-error.

do i = 1 to (if TRUCK.LONG_DISPLAY& then 30 else 22):
    if can-find(first PALLET where PALLET.CO = C[1] and
                      PALLET.DATE_ = ROUTE_HDR.DATE_ and
                      PALLET.ROUTE = ROUTE_HDR.ROUTE and
                      PALLET.PALLET begins trim(ROUTE_HDR.PALLET_POS[i]) and
        trim(ROUTE_HDR.PALLET_POS[i]) > "" )
    then do:
        create W_PALLET.
        assign W_PALLET.W_PALLET = trim(ROUTE_HDR.PALLET_POS[i])
               W_PALLET.W_POS = i
               p-wt = 0
               p-pcs = 0
               p-cube = 0.
        find first W_COMPARTMENT where 
                   W_COMPARTMENT.W_SHTYPE = substr(W_PALLET.W_PALLET,1,1)
                   no-lock no-error.
         W_PALLET.W_COMPARTMENT = 9999
                /* if avail W_COMPARTMENT then
                W_COMPARTMENT.W_COMPARTMENT else 9999 */.
        if ((substr(W_PALLET.W_PALLET,1,1) <> last-shtype) or 
            (last-shtype = ?)) then do:
            if last-shtype <> ? then do:
                assign g-wt = g-wt + t-wt
                       g-pcs = g-pcs + t-pcs
                       g-cube = g-cube + t-cube
                       t-wt = 0
                       t-pcs = 0
                       t-cube = 0.
            end.

            find SHIP_TYPE where SHIP_TYPE.CO = C[1] and
                 SHIP_TYPE.BRANCH = ROUTE_HDR.BRANCH and
                 SHIP_TYPE.SHIP_TYPE = substr(W_PALLET.W_PALLET,1,1)
                 no-lock no-error.
            palname = if avail SHIP_TYPE then SHIP_TYPE.DESCRIPTION 
                      else "PALLET TYPE NOT ENTERED".
        /*    put stream print palname format "X(20)" at 3 SKIP(1). */
            last-shtype = substr(W_PALLET.W_PALLET,1,1).
        end.
        
        W_PALLET.W_FIRST_STOP = ?.
        for each PALLET no-lock where PALLET.CO = C[1] and
                 PALLET.DATE_ = ROUTE_HDR.DATE_ and
                 PALLET.ROUTE = ROUTE_HDR.ROUTE and
                 PALLET.PALLET begins trim(ROUTE_HDR.PALLET_POS[i]) 
                 break by PALLET.SEQ descending:
            if W_PALLET.W_FIRST_STOP = ? then
                W_PALLET.W_FIRST_STOP = PALLET.SEQ.
            W_PALLET.W_LAST_STOP = PALLET.SEQ.
            assign W_PALLET.W_CUBE = W_PALLET.W_CUBE + PALLET.TTL_CUBE
                   W_PALLET.W_PCS = W_PALLET.W_PCS + PALLET.TTL_PCS
                   W_PALLET.W_WT = W_PALLET.W_WT + PALLET.TTL_WT
                   t-wt  = t-wt + PALLET.TTL_WT
                   t-pcs = t-pcs + PALLET.TTL_PCS
                   t-cube = t-cube + PALLET.TTL_CUBE
                   p-wt  = p-wt + PALLET.TTL_WT
                   p-pcs = p-pcs + PALLET.TTL_PCS
                   p-cube = p-cube + PALLET.TTL_CUBE.
            find CUSTOMER where CUSTOMER.CO = C[1] and
                 CUSTOMER.CUSTOMER = PALLET.CUSTOMER no-lock no-error.
            custname = if avail CUSTOMER then CUSTOMER.NAME else "NOT FOUND".
            put stream print
               caps(PALLET.PALLET) format "X(4)"
               PALLET.SEQ at 10 space(3)
               PALLET.TTL_WT format "ZZZZ.99-" space(2)
               PALLET.TTL_CUBE format "ZZ,ZZZ.99-" space(3)
               PALLET.TTL_PCS format "ZZZ9-" space(3)
               PALLET.CUSTOMER space(1)
               custname SKIP.
        end.

        put stream PRINT skip(1).  /* 02/09/16 restored break @ pallet for ja */
        assign p-wt = 0 p-cube = 0 p-pcs = 0.
    
    end.
end.

if keyfunction(lastkey) <> "END-ERROR" then do:
    if last-shtype <> ? then do:
        assign g-wt = g-wt + t-wt
               g-pcs = g-pcs + t-pcs
               g-cube = g-cube + t-cube
               t-wt = 0
               t-pcs = 0
               t-cube = 0.
    end.

    put stream print /*   fill("=",80) format "X(80)" */ " " at 1 SKIP
        "GRAND TOTAL" format "X(12)"
        space(1)
        g-wt format "ZZ,ZZZ.99" SPACE(3)
        g-cube format "ZZ,ZZZ.99-" SPACE(3)
        g-pcs format "ZZZ9-"  SKIP(2).
    
    find TRUCK where TRUCK.CO = C[1] and
         TRUCK.TRUCK = ROUTE_HDR.TRUCK no-lock no-error.
    
    page stream print.
    commnt[1] = " Truck:" + string(ROUTE_HDR.TRUCK,"X(4)") 
            + " Route:" + string(ROUTE_HDR.ROUTE,"X(4)") 
            + " Driver:" + string(ROUTE_HDR.DRIVER,"X(4)").
    put stream print
        "           ------------------------------------ " SKIP
        "           |"  commnt[1] format "X(34)" 
                                                      "|" SKIP
        "           |                NOSE              | " SKIP
        "       --------------------------------------------"
        skip.

    assign side-wt = 0 plt-left& = yes.
    do i = 1 to (if TRUCK.LONG_DISPLAY& then 30 else 22) by 2 while plt-left&:
      assign
        pos1 = i
        pos2 = i + 1.
      find W_PALLET where W_PALLET.W_POS = pos1 no-error.
      commnt[1] = "".
      commnt[2] = "".
      
      if avail W_PALLET then do:
       assign 
        pallet[1] = caps(W_PALLET.W_PALLET)
        cube[1] = W_PALLET.W_CUBE
        pcs[1] = W_PALLET.W_PCS
        wt[1] = W_PALLET.W_WT
        stop-range[1] = string(W_PALLET.W_FIRST_STOP) + "-" +
                        string(W_PALLET.W_LAST_STOP).
       
       find first PALLET where PALLET.CO = C[1] and
           PALLET.PALLET begins W_PALLET.W_PALLET and
           PALLET.ROUTE = ROUTE_HDR.ROUTE and
           PALLET.DATE_ = ROUTE_HDR.DATE_ and
           PALLET.COMMENT > "" no-lock no-error.
                                   
       commnt-str =  if avail PALLET and PALLET.COMMENT > "" 
                     then caps(W_PALLET.W_PALLET) + "-" + PALLET.COMMENT
                     else  "".
                   
      end.
      else if avail TRUCK and TRUCK.PALLET_POSITION&[pos1] = no then do:
         assign  
           pallet[1] = "XXXXXXXXXXXXXXXXXXXX"
           cube[1] = 0
           pcs[1] = 0
           wt[1] = 0
           stop-range[1] = 'XXXXXXXXXXXXXXX'.
      end.
      else do:
       assign
        pallet[1] = "---"
        cube[1] = 0
        pcs[1] = 0
        wt[1] = 0
        stop-range[1] = "-".
      end.
      find W_PALLET where W_PALLET.W_POS = pos2 no-error.
      if avail W_PALLET then do:
       assign
        pallet[2] = caps(W_PALLET.W_PALLET)
        cube[2] = W_PALLET.W_CUBE
        pcs[2] = W_PALLET.W_PCS
        wt[2] = W_PALLET.W_WT
        stop-range[2] = string(W_PALLET.W_FIRST_STOP) + "-"
                      + string(W_PALLET.W_LAST_STOP).
                      
        find first PALLET where PALLET.CO = C[1] and
           PALLET.PALLET begins W_PALLET.W_PALLET and
           PALLET.ROUTE = ROUTE_HDR.ROUTE and
           PALLET.DATE_ = ROUTE_HDR.DATE_ and
           PALLET.COMMENT > "" no-lock no-error.
                                
        commnt-str = string(commnt-str,"X(56)") +
                     if avail PALLET and PALLET.COMMENT > "" 
                     then caps(W_PALLET.W_PALLET) 
                               + '-' + PALLET.COMMENT
                     else "".
      end.
      else if avail TRUCK and TRUCK.PALLET_POSITION&[pos2] = no then do:
         assign
           pallet[2] = "XXXXXXXXXXXXXXXXXXXXX"
           cube[2] = 0
           pcs[2] = 0
           wt[2] = 0
           stop-range[2] = 'XXXXXXXXXXXXXXXX'.
      end.
      else do:
       assign
        pallet[2] = "---"
        cube[2] = 0
        pcs[2] = 0
        wt[2] = 0
        stop-range[2] = "-".
      end.

      commnt[1] = substring(commnt-str,1,28).
      commnt[2] = substring(commnt-str,29,28).
      commnt[3] = substring(commnt-str,57,28).
      commnt[4] = substring(commnt-str,85,28).
      /****
      put stream print
          "|" at 8  pallet[1] format "X(3)" at 10 " -" pcs[1] format "zzz9"
          "|" at 31 pallet[2] format "X(3)" at 33 " -" pcs[2] format "zzz9"
          "|" at 51 commnt[1] at 52 format "X(28)"
          skip
          "|" at 8  stop-range[1] format "X(15)" at 10 
          "|" at 31 stop-range[2] format "X(15)" at 34 "|" at 51
          commnt[2] at 52 format "X(28)"
          skip
          "|" at 8  cube[1] format "zz9.9"      
          at 10 "|" at 31 cube[2] format "zz9.9" at 34  "|" at 51
          commnt[3] at 52 format "X(28)"  
          skip
          "       |------------------------------------------|" 
          commnt[4] at 52 format "X(28)"
           skip.                                                   
     ****/
     assign side-wt[1] = side-wt[1] + wt[1]
            side-wt[2] = side-wt[2] + wt[2].
     put stream print
       "|"                             at  8
       pallet[1]      format "X(3)"    at 10 
       "-" 
       pcs[1]         format "ZZZ9"
       wt[1]          format "ZZZZ9#"  at 25
       "|"                             at 31
       pallet[2]      format "X(3)"    at 33
       "-"
       pcs[2]         format "ZZZ9"
       wt[2]          format "ZZZZ9#"  at 45
       "|"                             at 51
       commnt[1]      format "X(28)"   at 52
       SKIP
      
       "|"                             at  8
       stop-range[1]  format "X(10)"   at 10
       cube[1]        format "ZZ9.9"   at 26
       "|"                             at 31
       stop-range[2]  format "X(10)"   at 33
       cube[2]        format "ZZ9.9"   at 46
       "|"                             at 51
       commnt[2]      format "X(28)"   at 52
       SKIP
       
       "       |------------------------------------------|"
       commnt[3]      format "X(28)"   at 52
       SKIP.
            
      assign pallet = "" cube = 0 stop-range ="" cnt = 0.
      
      /*** Check to see if anything left to print on the truck ***/
      release W_PALLET.
      find first W_PALLET where W_PALLET.W_POS > pos2 no-error. 
      if not avail W_PALLET then do:
        plt-left& = no.        
        /* 07/18 Palmer: print all 22/30 pallet positions with blanks */
        if trim(gb-coname) begins "Palmer" then 
          assign plt-left& = yes commnt-str = "".
      end. 
               
    end. /* do i, each W_PALLET */

    put stream print                                        
       "       *                 TAIL                     *" skip
       "        *    " 
       side-wt[1] format "ZZZZ9"
       " LBS            "
       side-wt[2] format "ZZZZ9" 
       " LBS      *"  skip
       "         *                                      *".
    
end.

run printRouteForms(input ROUTE_HDR.CO,
                    input ROUTE_HDR.DRIVER,
                    input ROUTE_HDR.DATE_,
                    input ROUTE_HDR.ROUTE).
