/*******************************************************************************
po_hdr.p   Purchase Order Header
to do: complete field level validations in header, add
       pointer file updates in d_po, direct&, po_confirm...

DOCK_SCHED and CARRIER to be phased out
12/02/98 Added AP_CONTROL.AP_VENDOR&
10/26/22 CLC Added DELETE Confirmation

*******************************************************************************/
{_global.def}
{_but.def}
{_file.i AP_CONTROL BRANCH BUYER CARRIER CUSTOMER CUST_SHIPTO DOCK_SCHED}
{_file.i RC_SCHED RCV SHOW PO_ITEM RCV_ITEM RCV_PRIORITY TERMCAP VENDOR_SHIPTO}
{_file.i PO_SPEC_ORDER CUST_COMM COMPANY}
{_filenew.i INV_CONTROL PO PO_CONTROL PO_GEN VENDOR}
{_fileb.i VENDOR 1}
def var status& as log no-undo.
def var edit-whand as widget-handle no-undo.
def var buyer-name as cha no-undo.
def var frvend-name as cha no-undo.
def var apvend-name as cha no-undo.  /* rename */
def var branch-name as cha format "X(15)"  no-undo.
/*def var key-auto-assign& as log init yes no-undo.*/
def var last-find as cha no-undo.
def var po as cha no-undo.
def var po-add as cha no-undo.
def var show as cha no-undo.
def var shipcnt as cha no-undo.
def var cancel& as log no-undo.
def var new& as log no-undo.
def var status-off& as log no-undo.
def var startup& as log no-undo.
def var allow-update-cost& as logi init yes no-undo.
def var po-source as cha no-undo.
def var xlist-title as cha no-undo.
def var t-rowid as rowid no-undo.
def var shipto as cha extent 6 init ["S","H","I","P","T","O"] no-undo.
def var h-frt-vendor as cha no-undo.
def var h-sh-vendor as cha no-undo.
def var h-branch as cha no-undo.
def var temp-vend as cha no-undo.
/* xlist  */
def var ord as cha extent 10 no-undo.
def var fr as int init 1 no-undo.
def var fist-xlist-ord as cha no-undo.
def var last-xlist-ord as cha no-undo.
def var rcv-cnt as int no-undo.
/* total */
def var tot-cost as dec no-undo.
def var list-cost as dec no-undo.
def var sched-dt as date no-undo.
def var sched-tm as char no-undo.
def var backhl-vend-list as char no-undo.
def var enable-shipto& as logi init yes no-undo.

if trim(gb-coname) begins "Presto" then allow-update-cost& = no.

&GLOB prog  po_hdr.p
&GLOB frame_name editform
&GLOB enable_proc enable-rec
&GLOB file_name PO
&GLOB but1  Items,Header,POcomm,List,Freight,Notes,Split,Gen,Del,More  /* 10 */
&GLOB but3  Vendchg,Custlot,Rcv,Cnf,Review,lOg
&GLOB run1  run items.
&GLOB run2  run edit-hdr.
&GLOB run3  run comment.
&GLOB run4  run list.
&GLOB run5  run freight.
&GLOB run6  run notes.
&GLOB run7  run split.
&GLOB run8  run gen.
&GLOB run9  run delete.
&GLOB run11 run vendor-change.
&GLOB run15 run review.
&GLOB run16 run log.
&GLOB buthelp1  Edit PO Line Items
&GLOB buthelp2  Edit PO header above
&GLOB buthelp3  Edit PO Comments
&GLOB buthelp4  List or Fax PO
&GLOB buthelp5  Allocate fixed freight amount across lines
&GLOB buthelp6  Edit Vendor Notes
&GLOB buthelp7  Split PO into 2 POs
&GLOB buthelp8  Generate a Suggested PO for Review
&GLOB buthelp9  Delete PO
&GLOB buthelp10  <Vendchg> <Custlot> <Rcv> <Cnf> <Review> <Log>
&GLOB buthelp11 Change Vendor number
&GLOB buthelp12 Assign PO to Customer Lots
&GLOB buthelp13 Review Receivers for this PO
&GLOB buthelp14 Review Price Confirmations for this PO
&GLOB buthelp15 Review PO Header change log
{po_hdr.u}
&GLOB d1 po
&GLOB d2 t_vendor.VENDOR
&GLOB d3 t_vendor.NAME
&GLOB d4 t_vendor.ADDRESS[1]
&GLOB d5 t_vendor.ADDRESS[2]
&GLOB d6 t_vendor.CITY
&GLOB d7 t_vendor.STATE
&GLOB d8 t_vendor.ZIP
&GLOB d9 t_vendor.phone[1]
&GLOB d10 shipcnt
&GLOB d11 T_PO.TYPE 
&GLOB d12 shipto[1]
&GLOB d13 shipto[2]
&GLOB d14 shipto[3]
&GLOB d15 shipto[4]
&GLOB d16 shipto[5]
&GLOB d17 shipto[6]
&GLOB d18 t_vendor.ATTN[1]
&GLOB d19 t_PO.SHIPTO
&GLOB vi1f1    t_po.buyer
&GLOB vi1f2    buyer-name
&GLOB vi2f1    t_po.frt_vendor
&GLOB vi2f2    frvend-name
&GLOB vi3prog  if T_AP_CONTROL.AP_VENDOR then 'v_ap_vendor.p' else 'v_vendor.p'
&GLOB vi3f1    t_po.merch_vendor
&GLOB vi3f2    apvend-name
/*
&GLOB vi4f1    t_po.branch
&GLOB vi4f2    branch-name
*/
&GLOB vi5prog  v_rcvprior.p
&GLOB vi5f1    t_PO.rcv_priority
&GLOB vi5f2    t_RCV_PRIORITY.DESCRIPTION
&GLOB v1f1     t_po.vterms
&GLOB v2f1     t_po.currency  
&GLOB v2when   t_po_control.enable_currency&

/* &GLOB block0  t_po.direct& */
&GLOB block1  t_po.update_cost&
&GLOB block2  t_po.merch_vendor
&GLOB block3  t_po.sh_vendor

/* order_dt => deliv dt */
{_scrh.i po_hdr}

{_checkrun.i}
pause 0 before-hide.
{_find.i TERMCAP first-term_ terminal}
{_find.i AP_CONTROL find-co gb-co}
assign xlist-title = "PO" + fill(T_TERMCAP.GH,10) +
       "Vendor" + fill(T_TERMCAP.GH,13) +
       "Total" + fill(T_TERMCAP.GH,3) +
       "Lines" + fill(T_TERMCAP.GH,1) +
       "Perf" + fill(T_TERMCAP.GH,2) +
       "Rcvr" + fill(T_TERMCAP.GH,3) +
       "Due" + fill(T_TERMCAP.GH,6) +
       "By"
      backhl-vend-list = "BACKHL" + (if t_AP_CONTROL.BACKHL_SUPP_NAME > "" then
        "," + t_AP_CONTROL.BACKHL_SUPP_NAME else "").
 
{po_xlist.f 16 5}  /* frame XLIST also used by rc_hdr.f */
form {po_hdr8.f} with frame editform no-help overlay.
form {po_hdrt.f} with frame total.
{_but.in}            /* initialize but-frame */

{_find.i COMPANY find-co gb-co}
{_find.i PO_CONTROL find-co gb-co}
{_find.i BUYER find-co-realid gb-co,gb-realid}
disp shipto with frame editform.
run u/u_fldacc.p (frame editform:handle).
status input off.
{_find.i SHOW rowid gb-rowid}  /* from po_show.p */
if avail t_SHOW then do:
   show = t_SHOW.SHOW.
   message "Show # " + trim(show).
   frame editform:title = "SHOW # " + trim(show) + " PO HEADER".
   show:screen-value in frame editform  = "SHOW".
end.

/*
t_PO.BRANCH:private-data in frame editform =
         (if t_PO_control.branch_po& then "" else "not-req").
*/         
t_PO.RCV_PRIORITY:private-data in frame editform = "not-req".         
{_gbfind.i PO}
if avail t_po then do:
   startup& = yes.
   gb-rowid = t-po-rowid.  /* Forces auto-select of this PO instead of vendor */
   {_find.i VENDOR find-co-vendor t_po.co,t_po.vendor}
   run disp-rec.
end.
else do:
  {_gbfind.i VENDOR}
  if avail t_VENDOR then do:      
         startup& = yes.
         display t_vendor.vendor
                 t_vendor.name
                 t_VENDOR.ADDRESS[1]
                 t_VENDOR.ADDRESS[2]
                 t_VENDOR.CITY
                 t_VENDOR.STATE
                 t_VENDOR.ZIP
                 t_VENDOR.ATTN[1]
                 t_vendor.phone[1]
                 with frame editform.
     end.
end.

MAIN:
do while true:
  assign cancel& = no po-add = "" new& = no done& = no t-po-rowid = ?
         po-source = "".
  if not startup& then run find-po-or-vendor.
  else if avail t_PO then t-po-rowid = gb-rowid.
  
  if cancel& then leave MAIN.
  if t-po-rowid = ? then do:     /* vendor was selected, not po */
       run select-or-add-po.
       if cancel& and startup& then leave MAIN.
       if cancel& then next MAIN.
  end.
  if new& then do:       /* force edit-hdr and add at least 1 line */
      run edit-hdr.
      if cancel& then next MAIN.
  end.
  run disp-total.   
  if gb-flag = "header" then do:
      run edit-hdr. /* from us_genrev.p */
      gb-flag = "".
  end.
  
  {_canfind.i PO_SPEC_ORDER canfind-co-status_-vendor gb-co,'c',t_PO.VENDOR}
  if return-value begins "y" then do:
     run po_specadd.p (input t_PO.PO).
     {_find.i PO rowid t-po-rowid lock}  /* update totals */
     run disp-total.
  end.
  
  ADDLOOP: do while not done&:
        run but.      /* on return, done& = yes */
        /* refresh t_PO pointer */
        find first t_po no-error.
        if avail t_po then do:
            {_find.i PO_ITEM first-co-po t_po.co,t_po.po}
            if not avail t_PO_ITEM then do:
                message "Zero Line Items on PO" t_po.po + ".  Delete?"
                         view-as alert-box buttons yes-no update choice& as log.
                if choice& then do:
                    {_delete.i PO}
                    leave ADDLOOP.
                end.
                done& = no.
                next ADDLOOP.
            end.
        end.
  end. /* ADDLOOP */
  if avail t_po then do:
    {_unlock.i PO}
  end.
  hide frame total.
  clear frame editform.
  if startup& then leave.  /* one po only */
end.
hide frame editform.
/* if not startup& then gb-rowid = ?. */
gb-rowid = ?.

procedure find-po-or-vendor.
   def var t-rowid as rowid no-undo.
   /* row, PO?, last-find-entry, PO/Vendor rowid, return-val= yes,vendor/po */
    run f/f_vendor.p (5, yes, yes, input-output last-find, output t-rowid).
    if return-value begins "y" then do:
      if entry(2,return-value) = "Vendor" then do:
         {_find.i VENDOR rowid t-rowid}
         display t_vendor.vendor
                 t_vendor.name
                 t_VENDOR.ADDRESS[1]
                 t_VENDOR.ADDRESS[2]
                 t_VENDOR.CITY
                 t_VENDOR.STATE
                 t_VENDOR.ZIP
                 t_VENDOR.ATTN[1]
                 t_vendor.phone[1]
                 with frame editform.
      end.
      else do:
        {_find.i PO rowid t-rowid lock}
        if return-value begins "no,lock" then cancel& = yes.
        {_find.i VENDOR find-co-vendor gb-co,t_po.vendor}
        run disp-rec.
     end.
   end.
   else cancel& = yes.  /* no vendor/po selected */
end.

procedure disp-rec.
 /* set shipcnt */
   h-frt-vendor = t_PO.FRT_VENDOR. /* for validation */
   po = t_po.po.
   run shipto-pickup(t_PO.FRT_VENDOR).
   {_edit.dsp}   /* disp d1..n u1..n */
   {_edit.in}    /* i1f1..n initializations */
end.

procedure shipto-pickup.
   def input param frt-vendor as cha no-undo.
   if lookup(frt-vendor, backhl-vend-list) > 0 then 
    assign shipto[1] = "P"
           shipto[2] = "I"
           shipto[3] = "C"
           shipto[4] = "K"
           shipto[5] = "U"
           shipto[6] = "P".
   else assign        
           shipto[1] = "S"
           shipto[2] = "H"
           shipto[3] = "I"
           shipto[4] = "P"
           shipto[5] = "T"
           shipto[6] = "O".
end.

procedure refresh-xlist.
    view frame XLIST.
    {_find.i PO rowid t-po-rowid lock}
    if not avail t_PO then do:
        run find-last-po.
        if avail t_po then last-xlist-ord = t_po.po.
        run find-first-po.
        if avail t_po then fist-xlist-ord = t_po.po.
     end.
    if not avail t_po then do:
       clear frame XLIST ALL.
       ord = "".
       display "No PO's for Vendor" @ t_PO.NAME with frame XLIST.
       return.
    end.

    do with frame XLIST:
    if frame-line > 0 then up frame-line - 1 with frame XLIST.
    ord = "".
    do while avail t_po and frame-line(XLIST) <= frame-down(XLIST):
       rcv-cnt = 0.
       {_find.i RCV first-co-po gb-co,t_po.po}
       do while avail t_rcv:
          rcv-cnt = rcv-cnt + 1.
         {_find.i RCV next-co-po gb-co,t_po.po}
       end.
       display t_PO.TYPE
               t_PO.PO
               t_PO.NAME
               t_PO.TTL_EXT format "ZZZZ,ZZ9.99-"
               t_PO.TTL_LN
               t_PO.TEMPD @ t_PO.TTL_COMPLETE 
               t_PO.DUE_DT
               rcv-cnt
               t_PO.STAMP_OP with frame XLIST.
      ord[frame-line(XLIST)] = t_PO.PO.
      down.
      if frame-line <= frame-down then run find-next-po.
    end.
    if fr > 1 and fr >= frame-line then fr = frame-line - 1.  /* past end */
    up 1 with frame XLIST.
    do while frame-line(XLIST) < frame-down(XLIST) with frame XLIST:
        down.
        clear no-pause.
    end.
    up frame-line - fr with frame XLIST. /* position to highlight line */
    color display messages t_po.PO with frame XLIST.
    po = ord[frame-line(XLIST)].
    disp po with frame editform.
  end.  /* with frame xlist */
end procedure.

procedure select-or-add-po.
  def var done& as log no-undo.
  def var choice& as log no-undo.
  run refresh-xlist.

  on cursor-up of po in frame editform do:
     if frame-line(XLIST) > 1 then do:
              color display normal t_PO.PO with frame XLIST.
              up 1 with frame XLIST.
              color display messages t_PO.PO with frame XLIST.
              display ord[frame-line(XLIST)] @ po with frame editform.
     end.
     else if ord[1] <> fist-xlist-ord then do: /* last frame line, page down */
        fr = -1.   /* signal frame-down(XLIST). */
        color display normal t_PO.PO with frame XLIST.
        apply "F11" to po in frame editform.
     end.
  end.

  on cursor-down of po in frame editform do:
     if ord[frame-line(XLIST) + 1] > "" then do:
              color display normal t_PO.PO with frame XLIST.
              down 1 with frame XLIST.
              color display messages t_PO.PO with frame XLIST.
              display ord[frame-line(XLIST)] @ po with frame editform.
     end.
     /* lastline, page down */
     else if ord[frame-line(XLIST)] <> last-xlist-ord then do:
        fr = -1. /* signal 1 */
        color display normal t_PO.PO with frame XLIST.
        apply "F12" to po in frame editform.
     end.
  end.

  on home of po in frame editform do:
        color display normal t_PO.PO with frame XLIST.
        fr = 1.
        run find-first-po.
        if t_PO.PO  = ord[1] then do:  /* first rec at line 1 */
             run find-last-po.
             do j = 1 to frame-down(XLIST) - 1:
                run find-prev-po.
                if not avail t_PO then run find-first-po.
             end.
             fr = frame-down(XLIST).
        end.
        run refresh-xlist.
   end.

  on F10 of po in frame editform do:
     if po-add = "" then run po/po_add.p (no, input-output po-add,
                                              input-output po-source).
     disp po-add @ po with frame editform.
  end.

  on f11 of po in frame editform do:  /* Prev */
     fr = if fr = -1 then frame-down(XLIST)   /* from cursor-up */
          else frame-line(XLIST).
     do j =  1 to (frame-down(XLIST) + frame-down(XLIST) - 1):
          run find-prev-po.
     end.
     if not avail t_PO then run find-first-po.
     run refresh-xlist.
  end.

  on f12 of po in frame editform do:  /* Next */
     fr = if fr = -1 then 1   /* from cursor-down */
          else frame-line(XLIST).
     run find-next-po.
     run refresh-xlist.
  end.

  on end-error of po in frame editform do:
     color display normal t_po.po with frame xlist.
     clear frame editform.
     cancel& = yes.
     done& = yes.
  end.

  on return of po in frame editform
     apply "GO" to po in frame editform.

  on go of po in frame editform do:
       if input po = "" then do:
          message "PO Number is required" view-as alert-box.
          return no-apply.
       end.
       color display normal t_po.po with frame xlist.
       assign po.
       if po = po-add then new& = yes.
       else do:
         {_find.i PO find-co-po gb-co,po lock}
         if return-value begins "no,lock" then return no-apply.
         if avail t_po then do:
            if t_po.vendor <> t_vendor.vendor then do:
               message "PO Number is for Vendor" t_po.vendor t_po.name
                        "Continue?" view-as alert-box 
                         buttons yes-no update choice& as log.
               if not choice& or choice& = ? then return no-apply.
               {_find.i VENDOR find-co-vendor gb-co,t_po.vendor}
            end.
            new& = no.
            status input off. 
            run disp-rec.
          end.
          else assign po-source = "M"
               new& = yes.  /* Entered a PO number that does not exist, add */
       end.
     /***  message new& avail t_po view-as alert-box. ***/
       done& = yes.
   end.
/*   po:help = "causes flashing". */
  status input "[F10] TO CREATE NEW PO, ENTER NEW PO, OR SELECT PO TO EDIT".
  enable po with frame editform.
  do while not done&:
     wait-for go, end-error of frame editform pause gb-pause.
     if lastkey = -1 then {_timeh.i}
  end.
  disable po with frame editform.
  hide frame xlist.
  status input off.
end.

procedure edit-hdr.
  if new& then do:
  /*   message "Create new PO:" po. */
     /* create t_po with defaults */
     run po/po_pocr.p (po, if avail t_buyer then t_buyer.buyer else "", 
                       po-source, show, gb-dt).  /* pass the PO order date */        find first t_po no-error.
  end.
  else do:
     message "Edit existing PO:" po.
     {_lock.i PO}
     if return-value = "no" then do:
         cancel& = yes.
         clear frame editform.
         return.
     end.
  end.
  
  enable-shipto& = t_PO.DIRECT&.

  t_PO.UPLOAD&:private-data in frame editform =
    "ALLOW PO TO BE EXPORTED TO EXTERNAL SYSTEM?".
  {_edit.tr}      /* standard validations */
  {_edit.block}   /* jump block */

  on {_helpkey.i} of t_PO.SH_NAME in frame editform,
    t_PO.SH_ADDRESS[1] in frame editform,
    t_PO.SH_ADDRESS[2] in frame editform,
    t_PO.SH_ATTN in frame editform,
    t_PO.SH_CITY in frame editform,
    t_PO.SH_STATE in frame editform,
    t_PO.SH_ZIP in frame editform,
    t_PO.SH_PHONE in frame editform do:
       disable all with frame editform.
       run h/h_vendorsh.p 
         (t-vendor-rowid, t_PO.SH_NAME:handle, t_PO.SH_ADDRESS[1]:handle,
          t_PO.SH_ADDRESS[2]:handle, t_PO.SH_ATTN:handle, t_PO.SH_CITY:handle,
          t_PO.SH_STATE:handle, t_PO.SH_ZIP:handle, t_PO.SH_PHONE:handle).
       run enable-rec.
       return no-apply.
  end.
  
  on leave of t_PO.FRT_VENDOR in frame editform do:
      if keyfunct(lastkey) <> "END-ERROR" then do:
        run v/v_frt_vendor.p
           (t_PO.FRT_VENDOR:HANDLE,frvend-name:handle,?,?,?).
        if return-value begins "no" then return no-apply.
        run shipto-pickup (t_PO.FRT_VENDOR:SCREEN-VALUE).
        disp shipto with frame editform.
        if t_PO.FRT_VENDOR:SCREEN-VALUE <> h-frt-vendor then do:
            run set-shipto-addr.
            h-frt-vendor = input t_PO.FRT_VENDOR.
        end.
      end.
  end.

  on leave of t_PO.SH_VENDOR in frame editform do:
      if keyfunct(lastkey) <> "END-ERROR" then do:
        if t_PO.DIRECT&:SCREEn-VALUE = "Yes" and
           t_PO.CUSTOMER > "" then do:
           if t_PO.SH_VENDOR:SCREEN-VALUE <> t_PO.CUSTOMER then do:
            message "Ship to must be" t_PO.CUSTOMER "for direct ship PO".
            t_PO.SH_VENDOR:SCREEN-VALUE = t_PO.CUSTOMER.
            return no-apply.
           end.
        end.
        else if t_PO.SH_VENDOR:SCREEN-VALUE > "" then do:
            run v/v_vendor.p (t_PO.SH_VENDOR:HANDLE,?,?,?,?).
            if return-value begins "no" then return no-apply.
        end.    
        if t_PO.SH_VENDOR:SCREEN-VALUE <> h-sh-vendor then do:
            run set-shipto-addr.
            h-sh-vendor = input t_PO.SH_VENDOR.
        end.
      end.
  end.
  
  on leave of t_PO.SHIPTO in frame editform do:
      if keyfunct(lastkey) <> "END-ERROR" then do:
          if t_PO.DIRECT&:SCREEN-VALUE = "Yes" and
             t_PO.CUSTOMER > "" then do:
              
              {_find.i CUST_SHIPTO find-co-customer-shipto
                gb-co,t_PO.CUSTOMER,t_PO.SHIPTO:SCREEN-VALUE}
              if not avail t_CUST_SHIPTO then do:
                message "Ship To #" t_PO.SHIPTO:SCREEN-VALUE "not found".
                return no-apply.
              end.
              else if t_PO.SHIPTO:SCREEN-VALUE <> t_PO.SHIPTO then do:
                t_PO.SHIPTO = t_CUST_SHIPTO.SHIPTO.
                display
                    T_CUST_SHIPTO.SHIPTO        @ t_PO.SHIPTO
                    T_CUST_SHIPTO.CUSTOMER      @ T_PO.SH_VENDOR
                    t_CUST_SHIPTO.NAME          @ t_PO.SH_NAME
                    t_CUST_SHIPTO.ADDRESS[1]    @ t_PO.SH_ADDRESS[1]
                    t_CUST_SHIPTO.ADDRESS[2]    @ T_PO.SH_ADDRESS[2]
                    t_CUST_SHIPTO.CITY          @ T_PO.SH_CITY
                    t_CUST_SHIPTO.STATE         @ T_PO.SH_STATE
                    t_CUST_SHIPTO.ZIP           @ T_PO.SH_ZIP
                    t_CUST_SHIPTO.ATTN          @ T_PO.SH_ATTN 
                    t_CUST_SHIPTO.PHONE         @ T_PO.SH_PHONE
                    with frame EDITFORM.
              
              end.
          end.    
      end.
  end.

/* **********
  on leave of t_PO.BRANCh in frame editform do:
    run v/v_branch.p (t_PO.BRANCH:HANDLE,branch-name:handle,?,?,?).
    if return-value begins "no" then return no-apply.
    if input t_PO.BRANCH <> h-branch then do:
       h-branch = input t_PO.BRANCH.
       {_find.i BRANCH find-co-branch gb-co,h-branch}
       if avail t_BRANCH then display
                    t_BRANCH.SH_NAME            @ t_PO.SH_NAME
                    t_BRANCH.SH_ADDRESS[1]      @ t_PO.SH_ADDRESS[1]
                    t_BRANCH.SH_ADDRESS[2]      @ T_PO.SH_ADDRESS[2]
                    t_BRANCH.SH_CITY            @ T_PO.SH_CITY
                    t_BRANCH.SH_STATE           @ T_PO.SH_STATE
                    t_BRANCH.SH_ZIP             @ T_PO.SH_ZIP
                    t_BRANCH.SH_ATTN            @ T_PO.SH_ATTN 
                    with frame EDITFORM.
    end.
  end.
********** */
  
   on leave of t_PO.RCV_PRIORITY in frame editform do:
    run v/v_rcvprior.p 
        (t_PO.RCV_PRIORITY:HANDLE,t_RCV_PRIORITY.DESCRIPTION:handle,?,?,?).
    if return-value begins "no" then return no-apply.
    if trim(gb-coname) begins "Benjamin" and
       input frame EDITFORM t_PO.RCV_PRIORITY <> t_PO.RCV_PRIORITY
    then run set-shipto-addr.
   end.
  
  on leave of t_PO.DIRECT& in frame editform do:
      if input t_PO.DIRECT& = yes and t_PO.E3_DESTINATION <> "DROPSHIP" then do:
        last-find = t_PO.CUSTOMER. 
        disable all with frame editform.
        run f/f_customer.p (10, no, no, input-output last-find, output t-rowid).
        enable-shipto& = yes.
        run enable-rec.
        if return-value begins "Y" then do:
            {_find.i CUSTOMER rowid t-rowid}
            assign t_PO.CUSTOMER = t_CUSTOMER.CUSTOMER
                   t_PO.SHIPTO = "".
            {_find.i CUST_SHIPTO first-co-customer t_PO.CO,t_PO.CUSTOMER}
            if avail t_CUST_SHIPTO then do:
                run br/br_custship.p (input t_CUST_SHIPTO.CUSTOMER,
                                      output t-rowid).
                if return-value begins "Y" then do:
                    {_find.i CUST_SHIPTO rowid t-rowid}
                end.
            end.
            if avail t_CUST_SHIPTO then do:
                t_PO.SHIPTO = t_CUST_SHIPTO.SHIPTO.
                display
                    T_CUST_SHIPTO.SHIPTO        @ t_PO.SHIPTO
                    T_CUST_SHIPTO.CUSTOMER      @ T_PO.SH_VENDOR
                    t_CUST_SHIPTO.NAME          @ t_PO.SH_NAME
                    t_CUST_SHIPTO.ADDRESS[1]    @ t_PO.SH_ADDRESS[1]
                    t_CUST_SHIPTO.ADDRESS[2]    @ T_PO.SH_ADDRESS[2]
                    t_CUST_SHIPTO.CITY          @ T_PO.SH_CITY
                    t_CUST_SHIPTO.STATE         @ T_PO.SH_STATE
                    t_CUST_SHIPTO.ZIP           @ T_PO.SH_ZIP
                    t_CUST_SHIPTO.ATTN          @ T_PO.SH_ATTN 
                    t_CUST_SHIPTO.PHONE         @ t_PO.SH_PHONE
                    with frame EDITFORM.
            end.
            else display
                    ""                          @ T_PO.SHIPTO
                    T_CUSTOMER.CUSTOMER         @ T_PO.SH_VENDOR
                    T_CUSTOMER.NAME             @ T_PO.SH_NAME
                    T_CUSTOMER.ADDRESS[1]       @ T_PO.SH_ADDRESS[1]
                    T_CUSTOMER.ADDRESS[2]       @ T_PO.SH_ADDRESS[2]
                    T_CUSTOMER.CITY             @ T_PO.SH_CITY
                    T_CUSTOMER.STATE            @ T_PO.SH_STATE
                    T_CUSTOMER.ZIP              @ T_PO.SH_ZIP
                    T_CUSTOMER.ATTN             @ T_PO.SH_ATTN 
                    T_CUSTOMEr.PHONE[1]         @ t_PO.SH_PHONE
                    with frame EDITFORM.
            /* Default PO Comment to customer's manifest comment */
            if t_PO.COMMENT = "" then do:
                {_find.i CUST_COMM find-co-customer-code
                    gb-co,t_CUSTOMER.CUSTOMER,'DEL'}
                if avail t_CUST_COMM then do:
                    t_PO.COMMENT = t_CUST_COMM.COMMENT.
                end.
            end.
        end. /* return-value y */
        disp no @ t_PO.UPDATE_COST&
             no @ t_PO.UPDATE_LEAD&
             (input frame EDITFORM t_PO.MERCH_VEND) @ t_PO.FRT_VEND
             with frame EDITFORM.
    end.    /* direct = yes */
    else if enable-shipto& then do:
        disable t_PO.SHIPTO with frame EDITFORM.
        enable-shipto& = no.
    end.        
    
    if input t_PO.direct& = no and t_PO.CUSTOMER > "" then do:
        assign t_PO.CUSTOMER = ""
               t_PO.SHIPTO = "".
        run set-shipto-addr.
    end.
  end.  /* direct */
   
   on entry anywhere do:
           if valid-handle(self:handle) and
           not status-off& and
           keyfunct(lastkey) <> "END-ERROR" then
                 status input entry(1,self:private-data).
   end.

   on end-error of frame editform do:
    run disp-rec.  /* eliminate any changes */
    cancel& = yes.
    if not new& then {_unlock.i po}
    if temp-label <> "Header" and 
    gb-flag <> "Header" then clear frame editform.
  end.

  on leave of t_po.due_dt in frame editform do:
      if keyfunct(lastkey) <> "END-ERROR" and
       input t_po.due_dt < gb-dt and
       gb-realid <> "paul8" then do:
             message "Delivery due date may not be before today"
             view-as alert-box.
             return no-apply.
      end.
  end.

  on leave of t_po.pickup_dt in frame editform do:
      if keyfunct(lastkey) <> "END-ERROR" and
       input t_po.pickup_dt < gb-dt and
       gb-realid <> "paul8" then do:
             message "Pickup date may not be before today"
             view-as alert-box.
             return no-apply.
      end.
  end.

  on go of frame editform do:
       if input t_po.due_dt < input t_po.po_dt then do:
          message "Delivery date may not be before Order date" 
          view-as alert-box.
          return no-apply.
       end.
       if input t_po.pickup_dt < input t_po.po_dt then do:
          message "Pickup date may not be before Order date" 
          view-as alert-box.
          return no-apply.
       end.
       status input off.
       status-off& = yes.   /* move to _edit.go */
       {_edit.go}   /* validations */
       status-off& = no.
       assign {_edit.u}.
       if new& then do:
          {_create.i po no}
          {_lock.i po}
          if po <> t_po.po then do:
             message "PO # already in use.  Generated new PO #.".
             po = t_po.po.
            disp po with frame editform.
          end.
       end.
       else do:
          {_update.i po lock}
       end.
  end.   /* on GO */

   run disp-rec.
   run enable-rec.
   if t_po.ttl_ln = 0 then
       edit-whand = t_po.type:handle in frame editform.
   else edit-whand = t_po.direct&:handle in frame editform.
   apply "Entry" to edit-whand.
   wait-for go, end-error of frame editform focus edit-whand.
   disable all with frame editform.

   new& = no.
end procedure.

procedure set-shipto-addr.

    if input frame editform t_PO.DIRECT& = no then do:
    
        if (lookup(input frame editform t_PO.FRT_VENDOR, backhl-vend-list) > 0)
           or (input frame EDITFORM t_PO.SH_VENDOR > "")
        then do:
            if input frame editform t_PO.SH_VENDOR > "" then
                   temp-vend = input t_PO.SH_VENDOR.
            else temp-vend = t_PO.VENDOR.
            
            {_find.i VENDOR_SHIPTO first-co-vendor t_PO.CO,temp-vend}
            if avail t_VENDOR_SHIPTO then do:
                assign t_PO.SH_NAME:SCREEN-VALUE    = t_VENDOR_SHIPTO.NAME
                       t_PO.SH_ADDR[1]:SCREEN-VALUE = t_VENDOR_SHIPTO.ADDRESS[1]
                       t_PO.SH_ADDR[2]:SCREEN-VALUE = t_VENDOR_SHIPTO.ADDRESS[2]
                       t_PO.SH_CITY:SCREEN-VALUE    = t_VENDOR_SHIPTO.CITY      
                       t_PO.SH_STATE:SCREEN-VALUE   = t_VENDOR_SHIPTO.STATE
                       t_PO.SH_ZIP:SCREEN-VALUE     = t_VENDOR_SHIPTO.ZIP
                       t_PO.SH_ATTN:SCREEN-VALUE    = t_VENDOR_SHIPTO.ATTN
                       t_PO.SH_PHONE:SCREEN-VALUE   = t_VENDOR_SHIPTO.PHONE.
            end.
            else do:
                {_find.i VENDOR1 find-co-vendor t_PO.CO,temp-vend}
                if avail t_VENDOR1 then do:
                    assign t_PO.SH_NAME:SCREEN-VALUE    = t_VENDOR1.NAME
                           t_PO.SH_ADDR[1]:SCREEN-VALUE = t_VENDOR1.ADDRESS[1]
                           t_PO.SH_ADDR[2]:SCREEN-VALUE = t_VENDOR1.ADDRESS[2]
                           t_PO.SH_CITY:SCREEN-VALUE    = t_VENDOR1.CITY      
                           t_PO.SH_STATE:SCREEN-VALUE   = t_VENDOR1.STATE
                           t_PO.SH_ZIP:SCREEN-VALUE     = t_VENDOR1.ZIP
                           t_PO.SH_ATTN:SCREEN-VALUE    = t_VENDOR1.ATTN[1]
                           t_PO.SH_PHONE:SCREEN-VALUE   = t_VENDOR1.PHONE[1].
                end.
            end.
        end.
        else do:
            if trim(gb-coname) begins "Benjamin" and
               trim(input frame EDITFORM t_PO.RCV_PRIORITY) = "A" and
               input frame EDITFORM t_PO.DIRECT& = no then do:
                assign t_PO.SH_NAME:SCREEN-VALUE    =  "Americold Logistics LLC"
                       t_PO.SH_ADDR[1]:SCREEN-VALUE = "Hatfield"
                       t_PO.SH_ADDR[2]:SCREEN-VALUE = "2525 Bergey Road"
                       t_PO.SH_CITY:SCREEN-VALUE    = "Hatfield"
                       t_PO.SH_STATE:SCREEN-VALUE   = "PA"
                       t_PO.SH_ZIP:SCREEN-VALUE     = "19440"
                       t_PO.SH_ATTN:SCREEN-VALUE    = ""
                       t_PO.SH_PHONE:SCREEN-VALUE   = "2157210700".
                   
            end.
            else do:
                assign t_PO.SH_NAME:SCREEN-VALUE = t_PO_CONTROL.SH_NAME
                   t_PO.SH_ADDR[1]:SCREEN-VALUE = t_PO_CONTROL.SH_ADDRESS[1]
                   t_PO.SH_ADDR[2]:SCREEN-VALUE = t_PO_CONTROL.SH_ADDRESS[2]
                   t_PO.SH_ATTN:SCREEN-VALUE = t_PO_CONTROL.SH_ATTN
                   t_PO.SH_CITY:SCREEN-VALUE =  t_PO_CONTROL.SH_CITY
                   t_PO.SH_STATE:SCREEN-VALUE = t_PO_CONTROL.SH_STATE
                   t_PO.SH_ZIP:SCREEN-VALUE =  t_PO_CONTROL.SH_ZIP
                   t_PO.SH_PHONE:SCREEN-VALUE = 
                        if avail t_COMPANY then t_COMPANY.PHONE[1] else "".
            end.
        end.
    end.  /* Direct ship handled above */    
end.

procedure enable-rec.
   enable {_edit.u} with frame editform.
end.

procedure find-first-po.
   {_find.i PO first-co-vendor gb-co,t_vendor.vendor}
end.

procedure find-next-po.
   {_find.i PO next-co-vendor gb-co,t_vendor.vendor}
end.

procedure find-prev-po.
   {_find.i PO prev-co-vendor gb-co,t_vendor.vendor}
end.

procedure find-last-po.
   {_find.i PO last-co-vendor gb-co,t_vendor.vendor}
end.

procedure visible-all.
   def input param visible& as log no-undo.
   if visible& then assign 
     frame editform:visible = visible&
     frame total:visible    = visible&
     but-frh[but-fr]:visible    = visible&.
   else do:
      hide all.
   /* frame total:visible    = visible&. */
      if valid-handle(gb-screenh) then gb-screenh:visible = yes.
   end.
end.

procedure items.
    def var h-rowid like t-po-rowid no-undo.
    h-rowid = t-po-rowid.
    run visible-all (no).
    {_run.i po_item.p}
    {_find.i PO rowid h-rowid lock}
    run visible-all (yes).
    run disp-total.   /* refresh totals */
end.

procedure list.
   run visible-all (no).
   gb-rowid = t-po-rowid.
   gb-flag  = "No-Playback".
   {_run.i po_lspo.p PO}
   run visible-all (yes).
   run disp-total.   /* refresh totals */
end.


procedure notes.  /* from po_vend */
  def var h-notes as cha no-undo.
  {_find.i vendor rowid t-vendor-rowid lock}
  if avail t_vendor then do:
     h-notes = t_vendor.notes.
     but-frh[but-fr]:visible = no.
     run u/u_edit.p (8, 10, "Vendor: " + trim(t_vendor.vendor) + " " +
                 t_vendor.name + " Notes", input-output t_vendor.notes).
     if return-value begins "y" and h-notes <> t_vendor.notes then do:
        {_update.i vendor}
     end.
     else do:
        {_unlock.i vendor}
     end.
     but-frh[but-fr]:visible = yes.
  end.
end.

procedure comment.
  def var h-comment as cha no-undo.
  if avail t_po then do:
     {_lock.i PO}
     h-comment = t_po.comment.
     but-frh[but-fr]:visible = no.
     run u/u_edit.p (13, 5, "PO: " + t_po.po + " " + t_vendor.name + " Comment",
                     input-output t_po.comment).
     if return-value begins "y" and h-comment <> t_po.comment then do:
        {_update.i PO lock}
        run disp-total.
     end.
     else do:
        {_unlock.i PO}
     end.
     but-frh[but-fr]:visible = yes.
  end.
end.

procedure log.
   but-frh[but-fr]:visible = no.
   gb-flag = "PO:" + t_po.po.
   run u/u_fldlog.p.
   but-frh[but-fr]:visible = yes.
end procedure.

procedure split.
   def var h-rowid as rowid no-undo.
   run visible-all (no).
   h-rowid = t-po-rowid.
   {_run.i po_split.p PO}
   {_find.i PO rowid h-rowid lock}
   run disp-total.
   run visible-all (yes).
end procedure.

procedure vendor-change.
    def var t-rowid as rowid no-undo.

    but-frh[but-fr]:visible = no.
    {_run.i po_vchg.p}
    if return-value begins "y" then do:
        find first t_po no-error.
        {_find.i VENDOR find-co-vendor gb-co,t_po.vendor}
        run disp-rec.
    end.
    but-frh[but-fr]:visible = yes.
end procedure.

procedure delete.
  define variable h-po as character  no-undo.
  define variable cInput as character format "X(20)" no-undo.
   
   
   h-po = t_po.po.
   
   {_find.i RCV first-co-po t_po.co,t_po.po}
   if avail t_rcv  then do:
      message "PO was received on" string(t_rcv.rcv_dt) + ".   Cannot delete."
               view-as alert-box.
      return.
   end.

   /** Added second check 03/02/10 in case hasn't tabbed off RCV header **/
   {_find.i RCV_ITEM first-co-po t_po.co,t_po.po}
   if avail t_rcv_item then do:
      message "PO was received on" string(t_rcv_item.rcv_dt) + 
              ".   Cannot delete." view-as alert-box.
      return.
   end.

   message "Delete PO" t_po.po + "?"
            view-as alert-box buttons yes-no update choice& as log.
   /***/
   if choice& = yes then do:
    hide message no-pause.
    
    form "Type DELETE:" cInput skip
         "   "                 skip
         "ENTER to Continue F4 to CANCEL" skip
         with frame userAlert row 12 centered.

    update cInput no-labels with frame userAlert overlay row 12 centered.
    
    hide frame userAlert.
    
    if keyfunc(lastkey) = "F4" then
       cInput = "".
    
    if cInput = "DELETE" then
      do /* transaction*/ :
         /* > 35 lines causes error (40) abort in 1 transaction */
           
           if t_PO.TTL_LN > 30 then do:
             gb-flag = "delete-all," + t_po.po.  /* flag d_poitem no decrement */
             {_find.i PO_ITEM first-co-po t_po.co,t_po.po lock}
             do while avail t_po_item transaction:
              /*   message "Deleting Line" t_PO_ITEM.LINE. */
                 {_delete.i PO_ITEM}  
                 {_find.i PO_ITEM first-co-po t_po.co,t_po.po lock}
             end.
             gb-flag = "".
           end.
           do transaction:
             {_delete.i PO}
           end.
           if return-value = "yes,delete" then do:
              message "PO" h-po "Deleted".
             done& = yes.
           end.
       end. /* Transaction */
   end. /* choice& = yes */
end.

procedure gen.
   def var review& as log no-undo.
   gb-rowid = t-po-rowid.
   but-frh[but-fr]:visible = no.
   {_run.i po_genreq.p PO}
   review&  = return-value = "yes,review". 
   {_find.i PO rowid t-po-rowid lock} 
   if review& then run review.
   else run disp-total.
end.

procedure freight.
   gb-rowid = t-po-rowid.
   {_run.i po_frt PO}
   {_find.i PO rowid t-po-rowid lock} 
   run disp-total.
end.

procedure review.
/* last pogen created from this po */
  {_find.i po_gen find-co-po_gen gb-co,t_po.po_gen}
  /* consider: find last generated PO this vendor */
  if not avail t_po_gen then do:
    message "No Generated PO to Review" view-as alert-box.
    return.
  end.
  gb-rowid = t-po-rowid.  /* signal reviewing from a PO */
  run visible-all (no).
  if t_PO_GEN.TRUCK_CNT <= 1 then do:
        {_run.i us_genrev.p PO}   /* {_run.i po/po_genrev.p} */
  end.
  else do:
      {_run.i po_genrevt.p PO}
  end.
  {_find.i PO rowid t-po-rowid lock}  /* update totals */
  run visible-all (yes).
  run disp-total.
end.

procedure disp-total.
  {_find.i RC_SCHED last-co-po t_po.co,t_po.po}
  {_release.i CARRIER}
  {_find.i DOCK_SCHED last-co-po t_po.co,t_po.po}
  if avail t_DOCK_SCHED then do:
     {_find.i CARRIER find-co-carrier gb-co,t_dock_sched.carrier}
  end.

  if avail t_RC_SCHED then assign
    sched-dt = t_RC_SCHED.DATE_
    sched-tm = t_RC_SCHED.START_TM.
  else if avail t_DOCK_SCHED then assign
    sched-dt = t_DOCK_SCHED.RCV_DT
    sched-tm = t_DOCK_SCHED.RCV_TM.
  else assign sched-dt = ? sched-tm = "".

  disp t_po.TTL_EXT
       t_po.TTL_DEAL
       (t_po.TTL_EXT + t_po.TTL_DEAL) @ list-cost
        t_po.FREIGHT
        t_po.TTL_WT
        t_po.TTL_CUBE
        t_po.TTL_COMPLETE
        t_PO.TEMPD
        (t_po.TTL_EXT + t_po.FREIGHT) @ tot-cost
        t_po.STAMP_DT
        t_po.TTL_LN
        t_po.STAMP_OP
        t_po.TTL_PCS
        (if avail t_CARRIER then t_CARRIER.NAME
         else if t_PO.COMMENT > "" then t_PO.COMMENT
        else "None") @ t_PO.COMMENT
        sched-dt
        sched-tm
        with frame TOTAL.
      /* dcolor? */
  /*    if opsys = "UNIX" then
             color display uline t_po.TTL_DEAL with frame TOTAL. */
end procedure.
{_but.i}       /* but-frame procedures */
{_edit.val}    /* validate subroutines */
{_check.i}
