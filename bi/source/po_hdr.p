/*******************************************************************************
po_hdr.p   Purchase Order Entry Header
Main Program
Created    03/10/92

Note: PO # ending in "D" defaults to Direct=yes, in "R" defaults to RETURN
todo: return auth # when r
      validation: deliv date > po dt
      add verbose mode echoing: ON ORDER last N months, lead time, last purch
          selectable by BUYER
      dont allow po # added which = vendor number (and in vendor.p dont allow
      vendor # which = po # )

1) Add default Carrier to vendor file?
2) Drop ship - add into qty ord?
3) IF Return get Return Auth #
4) Where Do Po #'s Come From: allow entry of buyer's counter in buyer.p
5) Get Freight Charge if vendor carries, Pickup allowance if our truck

05/04/96 Added PO_CONFIRM, PO.CONFIRM_DT, PO.CONFIRM_OP update
05/17/96 Added sched-dt and sched-tm to TOTAL frame
07/20/96 Moved "gen" to po_hdr1.p, added VTERMS validation
09/20/96 Assign PO SHOW in advance from sh_pohdr then release to on order
03/12/97 Added PO.SH_VENDOR to allow multiple shipto's for one PO vendor
         under Roadshow at na (Roadshow has 1 shipto per vendor only -
         sending the shipto vendor to roadshow)
05/22/97 Added PO.MERCH_VENDOR, split po_add.p for 63k
07/09/97 Added Lots option for customer assigned lots
08/14/97 Display Rcv schedule data, use po_hdrt.p
01/23/98 Duplicate PO/Vendor #
02/04/98 File_log
To do: update PO_ITEm.DIRECT& when PO.DIRECT& changed
09/14/16 Costas VENDOR_SHIPTO is based on 2 digit entry in PO.SH_VENDOR
01/14/20 Remove "Gen" and "GenNew" sets ITEM.SAFETY_STOCK interfers w/V8
*******************************************************************************/
{_global.def}
{_itemhlp.def new}
def var iteration  as int initial 0 no-undo.
def var h-rid as recid no-undo.
def var last-field as char no-undo.
def var j          as int no-undo.
def var x          as int no-undo.
def var rcv-cnt as int no-undo.
def var terms like VENDOR.VTERM no-undo.
def var shipcnt as char no-undo.
def new shared var vendor as char format "X(20)" no-undo.
def new shared var browse-prog as char init "ap/ap_vend1.p" no-undo.
def var h-phone    as char no-undo.
def new shared var index1 as logi no-undo.
def new shared var new-flag as logi no-undo.
def new shared var return-flag as logi no-undo.
def new shared var command as char no-undo.
def var po-new as char format "X(3)" init "NEW" no-undo.
def new shared var chs as char no-undo. /* po_hdr1.p */
def var add& as log no-undo.
def var h-pcs as int no-undo.
/* selkt also in po_hdrkl.p, po_vendchg.p */
def new shared var selkt as char extent 10 init
  ["Items","Review","Frt","Lots", "Comment","Header","PO",
  "VendChg","List","Notes" /* ,"Gen","GenNew"*/ ] no-undo.
def new shared var list-cost as deci no-undo.
def new shared var tot-cost as deci no-undo.
def new shared var drop-onhand& as logi no-undo.
def var answer& as logi format "Y/N" no-undo initial yes.
def new shared var h-reason as char no-undo.
def var temppo like PO.PO no-undo.
def new shared var po like PO.PO no-undo. /* po_hdr1 */
def var po-add like PO.PO no-undo.
def var ord like PO.PO extent 10 no-undo.
def var fr as int init 1 no-undo.
def var titl as char no-undo.
def var titl1 as char no-undo.
def var skip-flag as logi no-undo.
def var start-flag as int no-undo.
def var po-num as int no-undo.
def var h-buyer as char no-undo.
def var h-po-dt as date no-undo.
def var h-confirm& as logi no-undo.
def var frvend-name as char no-undo.
def var po-vendor& as log format "PO/Vendor" no-undo.
def new shared var apvend-name as char no-undo.
def var sched-dt as date no-undo.
def var sched-tm as char no-undo.
def var temp as char no-undo.
def var zero as int no-undo.
def new shared var show as char no-undo.
def new shared buffer PO for PO.  /* po_hdr1 */
def new shared buffer VENDOR for VENDOR. /* po_hdr1 */
def new shared buffer PO_CONTROL FOR PO_CONTROL.
def new shared buffer BUYER for BUYER.
def buffer BUYER1 for BUYER.
def buffer PO1 for PO.
def buffer VENDOR1 for VENDOR.
def new shared frame POHDR.
def new shared frame POSH.
def new shared frame PANEL.
def new shared frame POTOTL.

form {po_hdr.f} with frame POHDR.
form {po_hdrsh.f} with frame POSH row 2 side-labels.  /* short for page 2*/
form {po_totl.f} with frame POTOTL width 80 overlay.
{po_xlist.f 16 5}  /* frame XLIST also used by rc_hdr.f */
{_selkt.pan &sp=2 &1=5 &2=6 &3=3 &4=4 &5=7 &6=6 &7=2 &8=7 &9=4 &10=5 &10on=/*}
STATUS DEFAULT.
pause 0 before-hide.
if can-find(SHOW where SHOW.CO = C[1] and SHOW.SHOW = gb-flag) then do:
   assign show = gb-flag
          titl1 = "FOOD SHOW #" + trim(show) + " PO HEADER".
   disp "SHOW" @ show with frame POHDR.
end.
else titl1 = "PO HEADER".

find PO_CONTROL where PO_CONTROL.CO = C[1] no-lock no-error.
find AP_CONTROL where AP_CONTROL.CO = C[1] no-lock no-error.
find first TERMCAP where TERMCAP.TERM_ = terminal no-lock.
assign drop-onhand& = PO_CONTROL.DROP_ONHAND&
       titl = "PO" + fill(GH,10) +
       "Vendor" + fill(TERMCAP.GH,13) +
       "Total" + fill(TERMCAP.GH,3) +
       "Lines" + fill(TERMCAP.GH,1) +
       "Cmplt" + fill(TERMCAP.GH,1) +
       "Rcvr" + fill(TERMCAP.GH,3) +
       "Date" + fill(TERMCAP.GH,5) +
       "By".
    /*   + fill(TERMCAP.GH,1). */

/* " PO сссссссссс Vendor ссссссссссс Total сссс Lines с Date сс By ссссссс".*/

view frame POHDR.
do transaction:
    find PO where recid(PO) = rr[7] exclusive-lock no-error.
    if avail PO and PO.STATUS_ <> "X" then do:
       message "Edit existing PO".
       find VENDOR where VENDOR.CO = C[1] and
          VENDOR.VENDOR = PO.VENDOR no-lock no-error.
       assign
         return-flag = yes               /* return to caller on exit */
         iteration   = 2                 /* edit existing order */
         r       = recid(VENDOR).
    end.
end.

{_prognam.i 2}
if index(command, "po_reo.p") > zero or
   index(command,"rc_sched.p") > zero or
   index(command,"po_vreo.p") > zero then do:
   find PO_REORD where recid(PO_REORD) = rr[7] no-lock no-error.
   if avail PO_REORD then vendor = PO_REORD.VENDOR.
   find VENDOR where VENDOR.CO = C[1] and
        VENDOR.VENDOR = vendor no-lock no-error.
   start-flag = 1.  /* skip Vendor? prompt */
   if avail VENDOR then
    display VENDOR.VENDOR @ vendor VENDOR.NAME VENDOR.ADDRESS[1]
            VENDOR.ADDRESS[2] VENDOR.STATE VENDOR.CITY VENDOR.ZIP VENDOR.ATTN[1]
            with frame POHDR.
end.

MAIN:
do while true on error undo, leave:
  /* END-ERROR from oe_hdr block & after DELETE (iteration=3) */
  if keyfunction(lastkey) = "END-ERROR" or command = "Quit" then do:
     if PO.TTL_PCS <> h-pcs and
     lookup("PO",gb-filelog-str) > 0 or gb-watch-log& then do:
            if add& then run u/u_fillog.p (input "A,PO," + PO.PO).
            else run u/u_fillog.p (input "C,PO," + PO.PO).
     end.
     if iteration = 1 then iteration = 2.  /* end-err from Command = header */
     else do:
       iteration = zero.
       clear frame POHDR.
     end.
     vendor = TRIM(vendor).
  end.

  /* get po#, vendor #, vendor name */
  /* force uniqueness between po# and vendor # */
  FINDLOOP:
  do while iteration = zero on endkey undo, leave MAIN:
     if start-flag = zero then
       update vendor
        HELP "ENTER VENDOR NAME, NUMBER, OR PO #"
        validate(vendor > "", "ENTER VENDOR OR PRESS [CANCEL] TO LEAVE")
        with frame POHDR.
     else start-flag = zero.

     vendor = trim(vendor).
 /* Try PO Match First */
       find PO where PO.CO = C[1] and PO.PO = vendor no-lock no-error.
       r = recid(PO).
       if avail PO then do:
          temp = vendor.
          {_justify.i temp 6}
          find VENDOR where VENDOR.CO = C[1] and
               VENDOR.VENDOR = temp no-lock no-error.
          if avail VENDOR then do:
              do on endkey undo, leave:
                 message "Select PO or Vendor?" update po-vendor&.
              end.
              if not po-vendor& then do:
                 r = recid(VENDOR).
                 leave findloop.
              end.
          end.

          if PO.STATUS_ = "C" then do:
             bell. message "PO" PO.PO PO.NAME "has been cancelled".
             /* unlock PO here ? */
             next FINDLOOP.
          end.
          else do:
             r = recid(PO).
             find PO where PO.CO = C[1] and PO.PO = vendor exclusive
             no-wait no-error.
             if locked PO then do:
                 run l/l_po.p.     /* loop until sucessful Find or [Cancel] */
                 if keyfunct(lastkey) = "END-ERROR" then next FINDLOOP.
                 find PO where recid(PO) = r exclusive no-wait no-error.
             end.
             find VENDOR where VENDOR.CO = C[1] and
                VENDOR.VENDOR = PO.VENDOR no-lock no-error.
             assign iteration = 2    /* edit existing order */
                    r = recid(VENDOR).
             leave findloop.
          end.
    end.

    run ap/ap_vfi1.p.
    if r = ? then next FINDLOOP.
    leave FINDLOOP.

    end. /** FINDLOOP do while true **/

    find VENDOR where recid(VENDOR) = r no-lock.
    if not avail VENDOR then next MAIN.
    display VENDOR.VENDOR @ vendor VENDOR.NAME VENDOR.ADDRESS[1]
            VENDOR.ADDRESS[2] VENDOR.STATE VENDOR.CITY VENDOR.ZIP VENDOR.ATTN[1]
            with frame POHDR.

    if iteration = zero then do:

 /* clear frame XLIST all.*/
    view frame XLIST.
    {_povend.fi first}

    /* Get Default PO # to Add, make length a parameter from 4 - 9 */
    /* Buyer # as part of PO should by a pareter (prefix, suffix, or none)*/
    run po/po_add.p (output po-add).
    po-num = int(po-add).

    if avail PO then assign
       po        = PO.PO
       skip-flag = no.
    else do:
       display "No PO's for Vendor" @ PO.NAME with frame XLIST.
       assign po = po-add
              skip-flag = yes.
    end.

    loop1:
    do while true with frame XLIST:
    if frame-line > zero then up frame-line - 1 with frame XLIST.
    ord = "".
    do while avail PO and frame-line(XLIST) <= frame-down(XLIST):
       rcv-cnt = zero.
       for each RCV where RCV.CO = C[1] and RCV.PO = PO.PO no-lock:
          rcv-cnt = rcv-cnt + 1.
       end.
       display PO.TYPE PO.PO  PO.NAME PO.TTL_EXT PO.TTL_LN PO.TTL_COMPLETE
               PO.PO_DT rcv-cnt PO.STAMP_OP with frame XLIST.
      ord[frame-line(XLIST)] = PO.PO.
      down.
      if frame-line <= frame-down then do:
        {_povend.fi next}.
      end.
    end.
    if skip-flag = no then do:
      if fr > 1 and fr >= frame-line then fr = frame-line - 1.  /* past end */
      up 1 with frame XLIST.
      do while frame-line(XLIST) < frame-down(XLIST) with frame XLIST:
         down.
       clear no-pause.
      end.
      up frame-line - fr with frame XLIST. /* position to highlight line */
      color display messages PO.PO with frame XLIST.
      po = ord[frame-line(XLIST)].
     end.

     update po
     HELP "Enter new PO to Add, [Add] for new PO# or existing PO to Edit"
     validate(po > "", "ENTER PO OR PRESS [CANCEL] TO LEAVE")
     with frame POHDR /*row 3 col 70 overlay no-box no-label*/ editing:
         readkey.
         if keyfunction(lastkey) = "END-ERROR" then do:
            color display normal PO.PO with frame XLIST.
            hide frame XLIST.
            iteration = zero.
            undo, next MAIN.
         end.

         if lastkey = 310 /* Add */ then do:
            display po-add @ po with frame POHDR.
            next.
         end.

         if keylabel(lastkey) = "CURSOR-DOWN" then do:
           if ord[frame-line(XLIST) + 1] > "" then do:
              color display normal PO.PO with frame XLIST.
              down 1 with frame XLIST.
              color display messages PO.PO with frame XLIST.
              display ord[frame-line(XLIST)] @ po with frame POHDR.
           end.
           else next.
        end.

        else if keylabel(lastkey) = "CURSOR-UP" then do:
           if frame-line(XLIST) > 1 then do:
              color display normal PO.PO with frame XLIST.
              up 1 with frame XLIST.
              color display messages PO.PO with frame XLIST.
              display ord[frame-line(XLIST)] @ po with frame POHDR.
           end.
           else next.
        end.

        else if keyfunction(lastkey) = "PAGE-DOWN" or
        keyfunction(lastkey) = "PASTE" then do:
           fr = frame-line(XLIST).
           {_povend.fi next}
           if avail PO then next loop1.
        end.

        else if keyfunction(lastkey) = "PAGE-UP" or
        keyfunction(lastkey) = "COPY" then do:
           fr = frame-line(XLIST).
           do j =  1 to (frame-down(XLIST) + frame-down(XLIST) - 1):
              {_povend.fi prev}
           end.
           if not avail PO then {_povend.fi first}
           next loop1.
        end.

        else if keyfunction(lastkey) = "HOME" then do:
          color display normal PO.PO with frame XLIST.
          fr = 1.
          {_povend.fi first}
          if PO.PO  = ord[1] then do:  /* first rec at line 1 */
             {_povend.fi last}
             do j = 1 to frame-down(XLIST) - 1:
                {_povend.fi prev}
                if not avail PO then do:
                   {_povend.fi first}
                end.
             end.
             fr = frame-down(XLIST).
          end.
          next loop1.
        end.

        else if keyfunction(lastkey) = "GO" or lastkey = 13 then do:
            temppo = input frame POHDR po.
            find PO where PO.CO = C[1] and PO.PO = temppo no-lock no-error.
            if not avail PO then iteration = zero.   /* new PO */
            else do:
              if PO.STATUS_ = "X"  then do:
                bell.
                message "PO # " PO.PO "has been cancelled".
                apply 9.
                next.
              end.
              iteration = 2.
            end. /* if no-PO-flag */
            apply lastkey.
      end.
      else apply lastkey.

     end. /* editing */
     hide frame xlist.
     leave.
     end.    /* do while true */
     end.    /* if iteration = z */

     if iteration = 2 then do transaction:  /* edit a PO */
        rr[1] = recid(PO).
        find PO where recid(PO) = rr[1] exclusive no-wait no-error.
        if locked PO then do:
             run l/l_po.p.   /* loop until sucessful Find or [Cancel] */
             if keyfunction(lastkey) = "END-ERROR" then do:
                 iteration = zero.
                 next MAIN.
             end.
             find PO where recid(PO)= r exclusive no-wait no-error.
             find VENDOR where VENDOR.CO = C[1] and
                  VENDOR.VENDOR = PO.VENDOR no-lock.
             if VENDOR.VENDOR <> VENDOR then display
                VENDOR.VENDOR @ vendor with frame POHDR.
        end.
        r = recid(PO).
        h-pcs = PO.TTL_PCS.
        run u/u_lkcr.p (input "PO").
        r = recid(VENDOR).
     end.  /* if iteration =2 */

   add& = no.
   /*** Set up defaults for new PO ***/

  release PO_CARRIER.
  do TRANSACTION:
    if iteration = zero then do:
      find BUYER use-index REALID where BUYER.CO = C[1]
        and BUYER.REALID = gb-realid no-lock no-error.

     /* 09/14/16 root typically does not have a buyer assigned */
     if not avail BUYER then do:
        find first VENDOR_BUYER where VENDOR_BUYER.CO = C[1] and
             VENDOR_BUYER.VENDOR = VENDOR.VENDOR and
             VENDOR_BUYER.ITEM_COUNT > 0 no-lock no-error.
        if avail VENDOR_BUYER then do:
          find BUYER where BUYER.CO = C[1] and
               BUYER.BUYER =  VENDOR_BUYER.BUYER no-lock no-error.
        end. 
        else do:
          find first BUYER where BUYER.CO = C[1] no-lock no-error.
        end.
     end.

      run po/po_cr.p (temppo).
      h-pcs = PO.TTL_PCS.
  end. /* if iteration = 0 */

     find BUYER where BUYER.CO = C[1] and
          BUYER.BUYER = PO.BUYER no-lock no-error.
     find VENDOR1 where VENDOR1.CO = C[1] and
          VENDOR1.VENDOR = PO.FRT_VENDOR no-lock no-error.

     find last VENDOR_SHIPTO where VENDOR_SHIPTO.CO = C[1] and
                VENDOR_SHIPTO.VENDOR = VENDOR.VENDOR no-lock no-error.
     shipcnt = if avail VENDOR_SHIPTO then
              "(" + string(VENDOR_SHIPTO.VENDOR_SHIPTO) + ")" else "(0)".

     assign last-field = ""
            rr[2]= recid(VENDOR)  /* h_vship */
            h[2] = ?
           rr[8] = ?   /* CUSTOMER for h_vship/h_shipto help */
           h-po-dt     = PO.PO_DT
           h-buyer     = PO.BUYER
           h-confirm&  = PO.CONFIRM&
           frvend-name = if avail VENDOR1 then VENDOR1.NAME
                         else if PO.FRT_VENDOR = "BACKHL" then "Backhaul"
                         else if PO.FRT_VENDOR = AP_CONTROL.BACKHL_SUPP_NAME and
                                PO.FRT_VENDOR > "" then "2nd Backhl"
                         else "".

     find VENDOR1 where VENDOR1.CO = C[1] and
          VENDOR1.VENDOR = PO.MERCH_VENDOR no-lock no-error.
     apvend-name = if avail VENDOR1 then VENDOR1.NAME else "".

     if PO.DIRECT& then do:
         find CUSTOMER where CUSTOMER.CO = C[1] and
              CUSTOMER.CUSTOMER = PO.CUSTOMER no-lock no-error.
         rr[8] = recid(CUSTOMER).
     end.
     display {po_hdr.dsp} {po_hdr.u} with frame POHDR.


   EDITLOOP:

   do while iteration < 2 on endkey undo MAIN, next MAIN:
     update {po_hdr.u} with frame POHDR EDITING:
      readkey.
      if lastkey = 312 or lastkey = 311 then do: /*page-down/up */
         run po/po_hdrj.p.        /* select next field on "jump" block key */
         last-field = frame-field.
         next.
      end.
      else if keyfunction(lastkey) = "END-ERROR" and command="Header" then
           undo, leave.
      else do:
         {_edkey1.i}
      end.

  /* specialized CUST_SHIPTO help for DROP SHIP: display all vars */
    if substr(frame-field,1,3) = "SH_" then do:
     if input frame POHDR PO.DIRECT& then do:
       if lastkey = 310 /* add */ then do:
          assign h[2] = ?
                 r = rr[2]
                 r = recid(CUSTOMER).
          if r <> ? then run r/r_cushp.p.
          if h[2] <> ? then
               find last CUST_SHIPTO where CUST_SHIPTO.CO = C[1] and
                    CUST_SHIPTO.CUSTOMER = CUSTOMER.CUSTOMER no-lock no-error.
       end.
  /* true after successful add or successful h_shipto help */
       if h[2] <> ? then do:
             find CUST_SHIPTO where recid(CUST_SHIPTO) = h[2] no-lock no-error.
             view frame POHDR.
             if avail CUST_SHIPTO then display
                    CUST_SHIPTO.NAME          @ PO.SH_NAME
                    CUST_SHIPTO.ADDRESS[1]    @ PO.SH_ADDRESS[1]
                    CUST_SHIPTO.ADDRESS[2]    @ PO.SH_ADDRESS[2]
                    CUST_SHIPTO.CITY          @ PO.SH_CITY
                    CUST_SHIPTO.STATE         @ PO.SH_STATE
                    CUST_SHIPTO.ZIP           @ PO.SH_ZIP
                    CUST_SHIPTO.ATTN          @ PO.SH_ATTN with frame POHDR.
          h[2] = ?.
          next.
       end.
       disp no @ PO.UPDATE_COST&
            no @ PO.UPDATE_LEAD&
            (input frame POHDR PO.MERCH_VENDOR) @ PO.FRT_VENDOR
            with frame POHDR.
     end.  /* PO_DIRECT& = yes */
     else do:
       if lastkey = 310 /* add */ then do:

          assign h[2] = ?
                 r = rr[2]
                 r = recid(VENDOR).
          if r <> ? then run ap/ap_ship.p.
          /*
          if h[2] <> ? then
               find last CUST_SHIPTO where CUST_SHIPTO.CO = C[1] and
                    CUST_SHIPTO.CUSTOMER = CUSTOMER.CUSTOMER no-lock no-error.
          */
       end.

  /* true after successful add or successful h_vship help */
       if h[2] <> ? then do:
           find VENDOR_SHIPTO where recid(VENDOR_SHIPTO)=h[2] no-lock no-error.
           view frame POHDR.
           if avail VENDOR_SHIPTO then do:
              display
                    VENDOR_SHIPTO.NAME          @ PO.SH_NAME
                    VENDOR_SHIPTO.ADDRESS[1]    @ PO.SH_ADDRESS[1]
                    VENDOR_SHIPTO.ADDRESS[2]    @ PO.SH_ADDRESS[2]
                    VENDOR_SHIPTO.CITY          @ PO.SH_CITY
                    VENDOR_SHIPTO.STATE         @ PO.SH_STATE
                    VENDOR_SHIPTO.ZIP           @ PO.SH_ZIP
                    VENDOR_SHIPTO.ATTN          @ PO.SH_ATTN
                    VENDOR_SHIPTO.PHONE         @ PO.SH_PHONE with frame POHDR.
            end.
        end.
    end. /* PO.DIRECT& = no  */
 end.  /* SH_ */

 if frame-field <> last-field or go-pending
 /* keyfunction(lastkey) = "Page-up" or
    keyfunction(lastkey) = "Page-down"*/ then do with frame POHDR:
        message "".

       if last-field = "BUYER" then do:
             assign
               temppo = trim(input frame POHDR PO.BUYER)
               temppo = fill(" ",2 - length(temppo)) + temppo.
             find BUYER where BUYER.CO = C[1] and
                BUYER.BUYER = temppo no-lock no-error.
             if not avail BUYER then do:  /* note: dict validation also */
                message "Invalid Buyer".
                next-prompt PO.BUYER with frame POHDR.
                next.
             end.
             display BUYER.NAME BUYER.BUYER @ PO.BUYER with frame POHDR.
          /*******
             if iteration = 0 and BUYER.REALID <> gb-realid then do:
                   bell.
                   message "Warning: buyer does not match your login user id".
             end.
          *******/
       end.  /* buyer */

       if last-field = "MERCH_VENDOR" or go-pending then do:
             temppo = input frame POHDR PO.MERCH_VENDOR.
             {_justify.i temppo 6}
             find VENDOR1 where VENDOR1.CO = C[1] and
                  VENDOR1.VENDOR = temppo no-lock no-error.
             if not avail VENDOR1 then do:
                 bell. message "Invalid A/P Vendor".
                 next-prompt PO.MERCH_VENDOR with frame POHDR.
                 next.
             end.
             display VENDOR1.VENDOR @ PO.MERCH_VENDOR
                     VENDOR1.NAME @ apvend-name with frame POHDR.
       end.

       if last-field = "FRT_VENDOR" or go-pending then do:
           temppo = input frame POHDR PO.FRT_VENDOR.
           if not trim(gb-coname) begins "Costas" and /*shipto already assignd*/
              (index("BACKHL",temppo)>zero) or
               ((index(AP_CONTROL.BACKHL_SUPP_NAME,temppo)> zero) and
                (AP_CONTROL.BACKHL_SUPP_NAME > "")) then do:
              if index("BACKHL",temppo) > zero then
                  display "BACKHL" @ PO.FRT_VENDOR
                          "Backhaul" @ frvend-name with frame POHDR.
              else
                disp AP_CONTROL.BACKHL_SUPP_NAME @ PO.FRT_VENDOR
                    "2nd Backhl" @ frvend-name with frame O_HDR.
                    
           find first VENDOR_SHIPTO where VENDOR_SHIPTO.CO = C[1] and
                VENDOR_SHIPTO.VENDOR = VENDOR.VENDOR no-lock no-error.
           if input frame POHDR PO.SH_NAME = PO_CONTROL.SH_NAME and
           avail VENDOR_SHIPTO then do: display
                    VENDOR_SHIPTO.NAME          @ PO.SH_NAME
                    VENDOR_SHIPTO.ADDRESS[1]    @ PO.SH_ADDRESS[1]
                    VENDOR_SHIPTO.ADDRESS[2]    @ PO.SH_ADDRESS[2]
                    VENDOR_SHIPTO.CITY          @ PO.SH_CITY
                    VENDOR_SHIPTO.STATE         @ PO.SH_STATE
                    VENDOR_SHIPTO.ZIP           @ PO.SH_ZIP
                    VENDOR_SHIPTO.ATTN          @ PO.SH_ATTN
                    VENDOR_SHIPTO.PHONE         @ PO.SH_PHONE with frame POHDR.
              end.
           end.
           else do:
             {_justify.i temppo 6}
             find VENDOR1 where VENDOR1.CO = C[1] and
                  VENDOR1.VENDOR = temppo no-lock no-error.
             if not avail VENDOR1 then do:
                 bell. message "Invalid Freight Vendor".
                 next-prompt PO.FRT_VENDOR with frame POHDR.
                 next.
             end.
             display VENDOR1.VENDOR @ PO.FRT_VENDOR
                     VENDOR1.NAME @ frvend-name with frame POHDR.
          end.
     end.

    /*********************************
       if last-field = "CARRIER" then do:
             temppo = input frame POHDR PO.CARRIER.
             if index("BACKH",temppo)>0 then temppo = PO_CONTROL.BKHAUL_CARRIER.
             if temppo > "" then do:
               temppo = fill(" ",5 - length(temppo)) + temppo.
               find CARRIER where CARRIER.CO = C[1] and
                 CARRIER.CARRIER = temppo no-lock no-error.
               if avail CARRIER then
                  display CARRIER.NAME CARRIER.CARRIER @ PO.CARRIER
                  with frame POHDR.
               else do:
                  bell.
                  message "Invalid carrier".
                  next-prompt PO.CARRIER with frame POHDR.
                  next.
               end.
             end.
       end.  /* carrier */
    ******************/

       if last-field = "DUE_DT" or go-pending then do:
          if input frame POHDR PO.DUE_DT < input frame POHDR PO.PO_DT then do:
              bell. message "DUE DATE MAY NOT BE BEFORE ORDER DATE".
              next-prompt PO.DUE_DT with frame POHDR.
              next.
          end.
          if input frame POHDR PO.DUE_DT < today and
          PO.TTL_COMPLETE = zero then do:
              bell. message "DUE DATE MAY NOT BE BEFORE TODAY".
              next-prompt PO.DUE_DT with frame POHDR.
              next.
          end.
       end.

       if last-field = "TYPE" then do:
          if input frame POHDR PO.TYPE = "R" then do:
                display VENDOR.NAME     @ PO.SH_NAME
                        VENDOR.ADDRESS[1]  @ PO.SH_ADDRESS[1]
                        VENDOR.ADDRESS[2]  @ PO.SH_ADDRESS[2]
                        VENDOR.ATTN        @ PO.SH_ATTN
                        VENDOR.CITY        @ PO.SH_CITY
                        VENDOR.STATE       @ PO.SH_STATE
                        VENDOR.ZIP         @ PO.SH_ZIP with frame POHDR.
                apply 9.  /* skip DIRECT? */
         end.
         /* restore after switch from Return to PO */
         else if input frame POHDR PO.SH_NAME <> PO_CONTROL.SH_NAME then
                display PO_CONTROL.SH_NAME        @ PO.SH_NAME
                        PO_CONTROL.SH_ADDRESS[1]  @ PO.SH_ADDRESS[1]
                        PO_CONTROL.SH_ADDRESS[2]  @ PO.SH_ADDRESS[2]
                        PO_CONTROL.SH_ATTN        @ PO.SH_ATTN
                        PO_CONTROL.SH_CITY        @ PO.SH_CITY
                        PO_CONTROL.SH_STATE       @ PO.SH_STATE
                        PO_CONTROL.SH_ZIP         @ PO.SH_ZIP with frame POHDR.
        end.

       if last-field = "DIRECT&" then do:
      /** consider 1 type flag to handle PO/RETURN/DIRECT PO */
          if input frame POHDR PO.DIRECT& and
             input frame POHDR PO.TYPE  = "R" then do:
                bell.
                message "No direct ship for vendor return".
                next-prompt PO.DIRECT& with frame POHDR.
                next.
          end.
          else if input frame POHDR PO.DIRECT then do:
              if PO.CUSTOMER > "" then do:
                 find CUSTOMER where CUSTOMER.CO = C[1] and
                   CUSTOMER.CUSTOMER = PO.CUSTOMER no-lock no-error.
                 rr[8] = recid(CUSTOMER).
              end.
              else rr[8] = ?.
              run c/c_custf.p.
              if keyfunction(lastkey) = "END-ERROR" or rr[8] = ? then do:
                  next-prompt PO.DIRECT& with frame POHDR.
                  next.
              end.
              find CUSTOMER where recid(CUSTOMER) = rr[8] no-lock.
              h[2] = rr[8].
              PO.CUSTOMER = CUSTOMER.CUSTOMER.
              find first CUST_SHIPTO where CUST_SHIPTO.CO = C[1]
              and CUST_SHIPTO.CUSTOMER = CUSTOMER.CUSTOMER no-lock no-error.
              if avail CUST_SHIPTO then display
                    CUST_SHIPTO.NAME          @ PO.SH_NAME
                    CUST_SHIPTO.ADDRESS[1]    @ PO.SH_ADDRESS[1]
                    CUST_SHIPTO.ADDRESS[2]    @ PO.SH_ADDRESS[2]
                    CUST_SHIPTO.CITY          @ PO.SH_CITY
                    CUST_SHIPTO.STATE         @ PO.SH_STATE
                    CUST_SHIPTO.ZIP           @ PO.SH_ZIP
                    CUST_SHIPTO.ATTN          @ PO.SH_ATTN with frame POHDR.
              else display
                    CUSTOMER.NAME             @ PO.SH_NAME
                    CUSTOMER.ADDRESS[1]       @ PO.SH_ADDRESS[1]
                    CUSTOMER.ADDRESS[2]       @ PO.SH_ADDRESS[2]
                    CUSTOMER.CITY             @ PO.SH_CITY
                    CUSTOMER.STATE            @ PO.SH_STATE
                    CUSTOMER.ZIP              @ PO.SH_ZIP
                    CUSTOMER.ATTN             @ PO.SH_ATTN with frame POHDR.
          end.
          else  /* direct & = no */ if PO.CUSTOMER > "" then do:
                assign PO.CUSTOMER = ""
                       rr[8]       = ?.
                display PO_CONTROL.SH_NAME        @ PO.SH_NAME
                        PO_CONTROL.SH_ADDRESS[1]  @ PO.SH_ADDRESS[1]
                        PO_CONTROL.SH_ADDRESS[2]  @ PO.SH_ADDRESS[2]
                        PO_CONTROL.SH_ATTN        @ PO.SH_ATTN
                        PO_CONTROL.SH_CITY        @ PO.SH_CITY
                        PO_CONTROL.SH_STATE       @ PO.SH_STATE
                        PO_CONTROL.SH_ZIP         @ PO.SH_ZIP with frame POHDR.
        end.
       end.     /* if DIRECT& */

       if (last-field = "VTERMS" or go-pending) and
       not trim(gb-coname) begins "F. MCC" then do:
     /* parse for XX DAYS or 2%/10 NET XX or 2%/XX or XX */

          if input frame POHDR PO.VTERMS = "" then do:
              bell. message "PO TERMS REQUIRED".
              next-prompt PO.VTERMS with frame POHDR.
              next.
          end.

          run ap/ap_terms (input input frame POHDR PO.VTERMS,
                           output PO.DISCOUNT%, output PO.DISCDAYS,
                           output PO.DUE_DAYS).
          if PO.DISCOUNT% = zero and
             PO.DISCDAYS = zero AND
             PO.DUE_DAYS = zero then do:
              bell. message "INVALID TERMS. ENTER 10 DAYS, 2%/10, 2%/10 NET 30".
              next-prompt PO.VTERMS with frame POHDR.
              next.
          end.
          /*message VENDOR.DISCOUNT% VENDOR.DISCDAYS VENDOR.DUE_DAYS. pause. */
       end.  /* last-field = vterms */

       if last-field = "SH_VENDOR" and input
       frame POHDR PO.SH_VENDOR > "" then do:
           temp = input frame POHDR PO.SH_VENDOR.
           if (trim(gb-coname) begins "Costas" or
           trim(gb-coname) begins "Target") and
           length(temp) = 2 then do:
                x= int(temp) no-error.
                find VENDOR_SHIPTO where VENDOR_SHIPTO.CO = C[1] and
                     VENDOR_SHIPTO.VENDOR = VENDOR.VENDOR and
                     VENDOR_SHIPTO.VENDOR_SHIPTO = x no-lock no-error.
                if not avail VENDOR_SHIPTO then do:
                    message "Invalid Vendor Shipto".
                    next-prompt PO.SH_VENDOR with frame POHDR.
                    next.
                end.    
                assign
                  PO.SH_VENDOR     = string(VENDOR_SHIPTO.VENDOR_SHIPTO,"99")
                  PO.SH_NAME       = VENDOR_SHIPTO.NAME
                  PO.SH_ADDRESS[1] = VENDOR_SHIPTO.ADDRESS[1]
                  PO.SH_ADDRESS[2] = VENDOR_SHIPTO.ADDRESS[2]
                  PO.SH_ATTN       = VENDOR_SHIPTO.ATTN
                  PO.SH_CITY       = VENDOR_SHIPTO.CITY
                  PO.SH_STATE      = VENDOR_SHIPTO.STATE
                  PO.SH_ZIP        = VENDOR_SHIPTO.ZIP.
                  PO.SH_PHONE      = VENDOR_SHIPTO.PHONE.  
           end.
           else do:
             {_justify.i temp 6}
             find VENDOR1 where VENDOR1.CO = C[1] and
                  VENDOR1.VENDOR = temp no-lock no-error.
             if not avail VENDOR1 then do:
                bell. message "Invalid Vendor".
                next-prompt PO.SH_VENDOR with frame POHDR.
               next.
             end.
             /* to do: pop-up CUST_SHIPTO for VENDOR1 if any? */
             assign PO.SH_VENDOR   = VENDOR1.VENDOR
                  PO.SH_NAME       = VENDOR1.NAME
                  PO.SH_ADDRESS[1] = VENDOR1.ADDRESS[1]
                  PO.SH_ADDRESS[2] = VENDOR1.ADDRESS[2]
                  PO.SH_ATTN       = VENDOR1.ATTN[1]
                  PO.SH_CITY       = VENDOR1.CITY
                  PO.SH_STATE      = VENDOR1.STATE
                  PO.SH_ZIP        = VENDOR1.ZIP
                  PO.SH_PHONE      = VENDOR1.PHONE[1].
        end. /* else do */
        display PO.SH_VENDOR
                PO.SH_NAME
                PO.SH_ADDRESS[1]
                PO.SH_ADDRESS[2]
                PO.SH_ATTN
                PO.SH_CITY
                PO.SH_STATE
                PO.SH_ZIP 
                PO.SH_PHONE with frame POHDR.

      end. /* last-field = Sh_VENDOR */

     end.     /* if frame-field <> last-field */
     last-field = frame-field.
     end.   /* EDITING: */

   leave.
   end.   /* EDITLOOP */
   if iteration = zero and PO.PO = po-add then do:
      find BUYER where BUYER.CO = C[1] and
           BUYER.REALID = gb-realid exclusive no-error.
      if trim(gb-coname) begins "Kuna" or trim(gb-coname) begins "Natco"
        or trim(gb-coname) begins "XYZ"  then do:
        find first BUYER where BUYER.Co = C[1] exclusive no-error.
        message "First Buyer".
      end.
      if avail BUYER then do:
         assign BUYER.NEXT_PO    = po-num + 1
                BUYER.LAST_PO    = PO.PO
                BUYER.LAST_PO_DT = PO.PO_DT
                h-rid = recid(BUYER).
         find BUYER where recid(BUYER) = h-rid no-lock.
      end.
   end.
   if keyfunction(lastkey) <> 'END-ERROR' then do:
/* Maintain PO_CARRIER pointer for Backhaul carrier only */

   /* change FRT_VENDOR in receiving */
   for each RCV where RCV.CO = C[1] and
      RCV.PO = PO.PO and
      RCV.FRT_VENDOR <> PO.FRT_VENDOR:
        RCV.FRT_VENDOR = PO.FRT_VENDOR.
   end.


   if h-confirm& <> PO.CONFIRM& then do:
      if PO.CONFIRM& then assign
         PO.CONFIRM_DT = today
         PO.CONFIRM_OP = gb-realid.
      else assign
         PO.CONFIRM_DT = ?
         PO.CONFIRM_OP = gb-realid.
      disp PO.CONFIRM_DT with frame POHDR.
   end.
   if (PO.CONFIRM& or PO.TYPE = "R") and
   can-find(PO_CONFIRM where PO_CONFIRM.CO = C[1] and
   PO_CONFIRM.PO = PO.PO) then do:
      find PO_CONFIRM where PO_CONFIRM.CO = C[1] and
           PO_CONFIRM.PO = PO.PO exclusive no-error.
       if avail PO_CONFIRM then delete PO_CONFIRM.
   end.
   else if not PO.CONFIRM& and
   PO.TYPE = "P" and
   (h-po-dt <> PO.PO_DT or h-buyer <> PO.BUYER or
   not can-find(PO_CONFIRM where PO_CONFIRM.CO = C[1] and
   PO_CONFIRM.PO = PO.PO)) then do:
      find PO_CONFIRM where PO_CONFIRM.CO = C[1] and
           PO_CONFIRM.PO = PO.PO exclusive no-error.
      if not avail PO_CONFIRM then do:
          create PO_CONFIRM.
          assign PO_CONFIRM.CO       = C[1]
                 PO_CONFIRM.PO       = PO.PO
                 PO_CONFIRM.STAMP_DT = today
                 PO_CONFIRM.STAMP_OP = gb-realid
                 PO_CONFIRM.STAMP_TM = STRING(time,"HH:MM:SS").
       end.
       assign PO_CONFIRM.PO_DT = PO.PO_DT
              PO_CONFIRM.BUYER = PO.BUYER.
   end.

   if can-find(PO_CARRIER where PO_CARRIER.CO = C[1] and
   PO_CARRIER.PO = PO.PO) and PO.FRT_VENDOR <> "BACKHL" and
   ((PO.FRT_VENDOR <> AP_CONTROL.BACKHL_SUPP_NAME) or
    (AP_CONTROL.BACKHL_SUPP_NAME = "")) then do:
        find PO_CARRIER where PO_CARRIER.CO = C[1] and
        PO_CARRIER.PO = PO.PO exclusive no-error.
        if avail PO_CARRIER then delete PO_CARRIER.
   end.
   else if /*PO_CONTROL.BKHAUL_CARRIER > "" and*/
       (PO.FRT_VENDOR = "BACKHL") or
       ((PO.FRT_VENDOR > "") and (PO.FRT_VENDOR = AP_CONTROL.BACKHL_SUPP_NAME))
       then do:
              find PO_CARRIER where PO_CARRIER.CO = C[1] and
                   PO_CARRIER.PO = PO.PO exclusive no-error.
              if not avail PO_CARRIER then do:
                 create PO_CARRIER.
                 assign PO_CARRIER.CO = C[1]
                        PO_CARRIER.PO = PO.PO.
              end.
              assign PO_CARRIER.CARRIER  = PO_CONTROL.BKHAUL_CARRIER
                     PO_CARRIER.BUYER    = PO.BUYER
                     PO_CARRIER.DUE_DT   = PO.DUE_DT
                     PO_CARRIER.STAMP_DT = PO.STAMP_DT /* v8 */
                     PO_CARRIER.STAMP_TM = string(time,"HH:MM:SS")
                     PO_CARRIER.STAMP_OP = gb-realid.
        release PO_CARRIER.
  end.
 end. /* end-error */
end. /* transaction */

/* on edit existing PO, update PO STATUS */

  if iteration > zero then do:
      /**
      find PO_STATUS where PO_STATUS.CO = C[1] and
       PO_STATUS.PO = PO.PO exclusive.
      PO_STATUS.SALESREP    = PO.SALESREP.
      find first PO_STATUS where recid(PO_STATUS) = recid(PO_STATUS)
      no-lock.
     ***/
      /* display PO.TTL_EXT... with frame POTOTL */
      if PO.TTL_LN > zero then run po/po_hdrt.p.
  end.

assign
  rr[7] = recid(PO)
  rr[2] = recid(VENDOR).

ACTION:                                                 /****  control loop ***/
repeat:
     view frame POHDR.
     do on endkey undo, leave:
          assign command = "" iteration = 1.
          display selkt with frame panel row 22 center no-labels no-box.
          j = 61 - (time mod 60).  /* number of secs until minute changes */
          choose field selkt keys chs no-error pause j with frame panel.
        chs = "".
        if lastkey = -1 then do:
           {_time.i}
           next.
        end.
        if keyfunction(lastkey) = "CURSOR-LEFT" then do:  /* wrap */
             chs = selkt[10].
             next.
        end.
        if keyfunction(lastkey) = "CURSOR-RIGHT" then do:
             chs = selkt[1].
             next.
        end.
     end.       /* do on endkey undo */
     hide message no-pause.

     if keyfunction(lastkey) = "END-ERROR"            then Command = "Quit".
     else if keyfunction(lastkey) = "DELETE-CHARACTER" then command = "Delete".
     else if lastkey = 16                             then command = "PRINT".
     else if Command = "" and (lastkey = 13 or
     keyfunction(lastkey) = "GO") then do:
        if frame-value = "List" then do:
           hide frame panel.
           hide frame POTOTL.
           rr[1] = recid(PO).
           run u/u_runv1.p (input "po/po_lspo.p").
           view frame panel.
           next ACTION.
        end.
        else command = frame-value.    /* Header, Items, Comments, Confirm */
     end.

  if command = "Header" then next MAIN.  /* iteration = 1 */

  /* 01/14/20 Removed Gen/GenNew */
  if lookup(command,"Frt,Lots,Notes,Comment,GenNew,Gen") > zero then do:
      run po/po_hdr1.p.    /* Note: command, chs shared */
     if command = "Main" then next MAIN.
  end.

  if command = "Items" or command = "Review3" or command = "Review" then do:
     if substr(command,1,3) = "Rev" and
     not can-find(first PO_GEN where PO_GEN.CO = C[1] and
                  PO_GEN.VENDOR = PO.VENDOR and PO_GEN.PO = PO.PO) and
     not can-find(first PO_GEN where PO_GEN.CO = C[1] and
                 PO_GEN.VENDOR = PO.VENDOR and
                 PO_GEN.PO = "GEN" + trim(PO.VENDOR)) then do:
           bell. message "No Generated PO available to review".
           next ACTION.
     end.
     hide frame POHDR.
     hide frame PANEL.
     hide frame POTOTL.
     display PO.NAME PO.TTL_LN PO.TTL_EXT PO.TTL_WT PO.TTL_CUBE PO.PO
             with frame POSH.
     /**
     if command = "Review3" then do:
          {_run.i po/po_itdt3.p}
     end.
     ***/
     if command = "Review" then do:
          {_run.i po/po_itdt2.p}
     end.
     else /* command = "Items" then*/ run po/po_item.p.
     hide message no-pause.
     view frame POHDR.
     new-flag = no.

     if PO.TTL_LN > zero then do:
        run po/po_hdrt.p.  /* display PO.TTL_EXT... with frame POTOTL */
    /*  {cr_postat.cr transaction}  create PO_STATUS */
     end.

   end.  /* Items */

   if command = "Delete" then do transaction:
     find PO where recid(PO) = rr[7] exclusive-lock no-error.
     run po/po_hdrkl.p.
     if command = "" then next.
     assign command = "quit" iteration = 3.
     hide frame PANEL.
   end.

   if command = "PRINT" then do:
     hide frame POHDR.
     hide frame POTOTL.
     hide frame PANEL.
     run po/po_hdrp.p.
     view frame POHDR.
     view frame POTOTL.
     view frame panel.
   end.

   if command = "quit" then do transaction:
     if iteration <> 3 then do:    /* 3=> Just deleted PO */
         if PO.TTL_LN = zero then do:
            run po/po_hdrkl.p.
            if command = "" then next.
        end.
        if can-find(first PO_SPEC_ORDER where PO_SPEC_ORDER.CO = C[1] and
                          PO_SPEC_ORDER.STATUS_ = "C") then do:
            run po/po_specadd.p (input PO.PO).
        end.
        iteration = zero.
        hide frame POTOTL no-pause.
        hide frame PANEL.
     end.
     find PO where recid(PO) = rr[7] no-lock no-error.
     find LOCK where LOCK.RECID_ = rr[7] no-error.
     if avail LOCK then delete LOCK.
     assign rr[9]=zero rr[7]=zero.        /* PO recid */
     if return-flag then do:   /* return to caller */
        hide frame POHDR.
        return.
     end.
     next MAIN.        /* to VENDOR? */
  end.

  if command = "PO" then do:
    find first PO1 use-index PO where PO1.CO= C[1] and
    PO1.VENDOR = PO.VENDOR and PO1.STATUS_ <> "X"
    and PO1.PO <> PO.PO no-lock no-error.
    if avail PO then do:
        hide frame POTOTL.
        run po/po_sel.p.
        if keyfunction(lastkey) = "END-ERROR" or rr[1] = ? then do:
           run po/po_hdrt.p.
           next.
        end.
        else do transaction:
          find PO where recid(PO) = rr[1] exclusive no-error.
          if avail PO then iteration = 2.
          hide frame POTOTL.
          next MAIN.
        end.
   end.
   else do:
     bell.
     message "No other open purchase orders for " VENDOR.NAME.
   end.
  end.

  if command = "VendChg" then do:
     run po/po_vchg.p.
     if command = "" then next.
     find VENDOR where recid(VENDOR) = r no-lock.
     display {po_hdr.dsp} {po_hdr.u} with frame POHDR.
  end.

end. /* ACTION */
end. /* MAIN */

hide frame POHDR.
{_prog2.i}
assign rr[1] = ? gb-flag = "".  /* 01/27/96 clear for u_fax.p */
