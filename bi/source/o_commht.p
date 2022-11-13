/*******************************************************************************
o_commht.p   Update ORDER.COMMISSION by Order
Main Program
created     04/02/95

Credit calculation based on adding all invoices and credits, calc commission
for grand total, and assign credit incremental difference

Note: On a credit where comm% is based on multiple invoices (DELIVERY_STR)
recalc new comm% based on all invoices, but invoices not credited do not
have commission amount changed (not supported by current data structure as
an order/credit is required to carry the commission change - could apply
change to orders where commission not paid yet).

05/27/96 Added COMBINE_CUST& option
01/18/97 Added COMM_TABLE, COMM_METHOD override by salesrep
12/24/98 Added COMM_TABLE file to override SLS_CONTROL
*******************************************************************************/
{_global.def}
def var margin% as deci no-undo.
def var margin as deci no-undo.
def var comm% as deci no-undo.
def var comm as deci no-undo.
def var comm-level as int no-undo.
def var t-ext as deci no-undo.
def var t-sc as deci no-undo.
def var t-oc as deci no-undo.
def var t-lc as deci no-undo.
def var t-ic as deci no-undo.
def var t-cc as dec no-undo.
def var t-pcs as deci no-undo.
def var t-comm as deci no-undo.
def var i-ext as deci no-undo.
def var i-sc as deci no-undo.
def var i-oc as deci no-undo.
def var i-lc as deci no-undo.
def var i-ic as deci no-undo.
def var i-cc as dec no-undo.
def var i-pcs as deci no-undo.
def var i-comm as deci no-undo.
def var orig-order as char no-undo.
def var del-str as char no-undo.
def var qty as deci no-undo.
def var i as int no-undo.
def var comm-method as char no-undo.
def var comm-table as char no-undo.
def var sales-margin& as log no-undo.
def var cost-type as cha no-undo.
def var subtract-k12& as logi init no no-undo.
def var subtract-FreightLine& as logi init no no-undo.
def buffer ORDER1 for ORDER.
def buffer CUST_STOP1 for CUST_STOP.

if not can-find(first COMMISSION where COMMISSION.CO = C[1]) then return.

find SLS_CONTROL where SLS_CONTROL.CO = C[1] no-lock.
find ORDER where recid(ORDER) = r exclusive no-error.
find OE_CONTROL where OE_CONTROL.CO = C[1] no-lock no-error.
find SALESREP where SALESREP.CO = C[1] and
     SALESREP.SALESREP = ORDER.SALESREP no-lock no-error.
find CUSTOMER where CUSTOMER.CO = C[1]
 and CUSTOMER.CUSTOMER = ORDER.CUSTOMER no-lock no-error.
subtract-k12& = if trim(gb-coname) begins "Dennis Paper" then yes else no.
subtract-FreightLine& = if trim(gb-coname) begins "Jacmar" then yes else no.

comm-table   = if avail CUSTOMER and CUSTOMER.COMM_TABLE > ""
               then CUSTOMER.COMM_TABLE
               else if SALESREP.COMM_TABLE > "" then SALESREP.COMM_TABLE
               else SLS_CONTROL.COMM_TABLE.
/* At KUNA, use comm-table '03' for all will-calls or credits of will-calls */
if trim(gb-coname) begins "Kuna" then do:
    if (ORDER.TYPE = "P") then comm-table = "03".
    else if (ORDER.TYPE = "C") then do:
        find ORDER1 where ORDER1.CO = C[1]
         and ORDER1.ORDER = substr(ORDER.ORDER,1,6) + "00" no-lock no-error.
        if avail ORDER1 and ORDER1.TYPE = "P" then comm-table = "03".
    end.
end.   
find COMM_TABLE where COMM_TABLE.CO = C[1] and
     COMM_TABLE.COMM_TABLE = comm-table no-lock no-error.
sales-margin& = if avail COMM_TABLE then COMM_TABLE.SALES_MARGIN&
                else SLS_CONTROL.SALES_MARGIN&.
comm-method  = if SALESREP.COMM_METHOD > "" then SALESREP.COMM_METHOD
               else if avail COMM_TABLE then COMM_TABLE.COMM_METHOD
               else SLS_CONTROL.COMM_METHOD.
cost-type = if avail COMM_TABLE and COMM_TABLE.COMM_COST_TYPE > "" then 
                COMM_TABLE.COMM_COST_TYPE 
            else if SLS_CONTROL.COMM_COST_TYPE > "" then
                SLS_CONTROL.COMM_COST_TYPE else "S".

/* Resum all invoices/credits, commission on credit is incremental difference*/
if ORDER.TYPE = "C" and
not trim(gb-coname) begins "Jacmar" and
not trim(gb-coname) begins "DDC" then do:  /* Credit */

     if trim(gb-coname) begins "NorthCenter" then do:
        /* Add back credits for selected reason codes */
        ORDER.TTL_ADDBACK= 0.  /* Add backs */
        for each ORDER_ITEM where ORDER_ITEM.CO = C[1] and
            ORDER_ITEM.ORDER = ORDER.ORDER and
            ORDER_ITEM.LINE > 0 no-lock:
               find REASON where REASON.CO = C[1] and
                    REASON.REASON = ORDER_ITEM.REASON no-lock no-error.
               if avail REASON and REASON.ADDBACK_COMM& then do:
                   i-ext = i-ext - ORDER_ITEM.EXTEND.
                   i-cc  = i-cc  - ((if ORDER_ITEM.PRICE_WT& then
                               ORDER_ITEM.WT_SHIP else ORDER_ITEM.QTY_SHIP) *
                              ORDER_ITEM.COMM_COST). /* negative to reduce sc */
                   i-sc  = i-sc  - ((if ORDER_ITEM.PRICE_WT& then
                               ORDER_ITEM.WT_SHIP else ORDER_ITEM.QTY_SHIP) *
                               ORDER_ITEM.SLS_COST). /* negative to reduce sc */
                   i-ic  = i-ic  - ((if ORDER_ITEM.PRICE_WT& then
                               ORDER_ITEM.WT_SHIP else ORDER_ITEM.QTY_SHIP) *
                               ORDER_ITEM.INV_COST). /* negative to reduce ic*/
                   i-lc  = i-lc  - ((if ORDER_ITEM.PRICE_WT& then
                               ORDER_ITEM.WT_SHIP else ORDER_ITEM.QTY_SHIP) *
                               (ORDER_ITEM.LOT_COST + ORDER_ITEM.FREIGHT)).
                               /* negative to reduce lc*/
                   i-oc  = i-oc  - ((if ORDER_ITEM.PRICE_WT& then
                               ORDER_ITEM.WT_SHIP else ORDER_ITEM.QTY_SHIP) *
                               ORDER_ITEM.OFF_COST). /* negative to reduce oc*/
        /* Addback is amount added back to margin so that these lines
           do not reduce commission */
                   ORDER.TTL_ADDBACK = ORDER.TTL_ADDBACK -
                                  ((if ORDER_ITEM.PRICE_WT& then
                              ORDER_ITEM.WT_SHIP else ORDER_ITEM.QTY_SHIP) *
                              (if cost-type = "S" then ORDER_ITEM.SLS_COST
                               else if cost-type = "L" then
                                    (ORDER_ITEM.LOT_COST + ORDER_ITEM.FREIGHT)
                               else if cost-type = "I" then ORDER_ITEM.INV_COST
                               else if cost-type = "C" then
                                (if ORDER_ITEM.COMM_COST <> 0 then
                                 ORDER_ITEM.COMM_COST else ORDER_ITEM.SLS_COST)
                               else if cost-type = "O" then ORDER_ITEM.OFF_COST
                          else ORDER_ITEM.COMM_COST)). /* positive for display*/
               end.
        end.
   end.
   if ORDER.UPDATE& = no then do:
         i-ext = i-ext + ORDER.TTL_EXT -
            (if trim(gb-coname) begins "American" then ORDER.FREIGHT else 0).
         i-sc  = i-sc  + ORDER.TTL_SC - ORDER.TTL_DEAL.
         i-lc  = i-lc  + ORDER.TTL_LOT_ACT - ORDER.TTL_DEAL.
         i-ic  = i-ic  + ORDER.TTL_IC - ORDER.TTL_DEAL.
         i-oc  = i-oc  + ORDER.TTL_OC - ORDER.TTL_DEAL.
         i-cc  = i-cc  + ORDER.TTL_COMM_COST - ORDER.TTL_DEAL.
         
         if trim(gb-coname) begins "Kuna" 
         or trim(gb-coname) begins "Vesuvio"
         then do:
             for each ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                      ORDER_ITEM.ORDER = ORDER.ORDER and
                      (ORDER_ITEM.ITEM = "FREIGHT" or
                       ORDER_ITEM.ITEM = "RESTOCK" or
                       ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT_ITEM) no-lock:
                 assign i-ext = i-ext - ORDER_ITEM.EXTEND
                        qty = if ORDER_ITEM.PRICE_WT& then ORDER_ITEm.WT_SHIP
                              else ORDER_ITEM.QTY_SHIP
                        i-lc = i-lc - (ORDER_ITEM.LOT_COST + 
                                       ORDER_ITEM.FREIGHT) * qty
                        i-ic = i-ic - ORDER_ITEM.INV_COST * qty
                        i-oc = i-oc - ORDER_ITEM.OFF_COST * qty
                        i-sc = i-sc - ORDER_ITEM.SLS_COST * qty
                        i-cc = i-cc - ORDER_ITEM.SLS_COST * qty.
             end.
         end.
         if subtract-FreightLine& then do:
             
             for each ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                      ORDER_ITEM.ORDER = ORDER.ORDER and
                      (ORDER_ITEM.ITEM = "FREIGHT" or
                       ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT_ITEM or
                       ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT2_ITEM or
                       ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT3_ITEM) no-lock:
                 assign i-ext = i-ext - ORDER_ITEM.EXTEND
                        qty = if ORDER_ITEM.PRICE_WT& then ORDER_ITEm.WT_SHIP
                              else ORDER_ITEM.QTY_SHIP
                        i-lc = i-lc - (ORDER_ITEM.LOT_COST + 
                                       ORDER_ITEM.FREIGHT) * qty
                        i-ic = i-ic - ORDER_ITEM.INV_COST * qty
                        i-oc = i-oc - ORDER_ITEM.OFF_COST * qty
                        i-sc = i-sc - ORDER_ITEM.SLS_COST * qty
                        i-cc = i-cc - ORDER_ITEM.SLS_COST * qty.
             end.
         end.
   end.
   if subtract-k12& then do:
        for each ORDER_ALLOCATION where ORDER_ALLOCATION.CO = C[1] and
                 ORDER_ALLOCATION.ORDER = ORDER.ORDER no-lock:
            find ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                 ORDER_ITEM.ORDER = ORDER_ALLOCATION.ORDER and
                 ORDER_ITEM.LINE = ORDER_ALLOCATIOn.LINE no-lock no-error.
            if not avail ORDER_ITEM then next.
            i-sc = i-sc - (ORDER_ALLOCATION.ALLOCATION_AMT *
                             (if ORDER_ITEM.PRICE_WT& then ORDER_ITEM.WT_SHIP
                                 else ORDER_ITEM.QTY_SHIP)).
        end.
   end.
   for each ORDER1 where ORDER1.CO = C[1] and
      ORDER1.ORDER begins substr(ORDER.ORDER,1,6) and
      ORDER1.UPDATE& = yes and
      ORDER1.ORDER_DT <= (if ORDER.UPDATE& = yes then ORDER.ORDER_DT
                          else gb-dt) and
      (ORDER1.REGISTER <> "     0" or ORDER.REGISTER = "     0") no-lock:
         i-ext = i-ext + ORDER1.TTL_EXT -
            (if trim(gb-coname) begins "American" then ORDER.FREIGHT else 0).
         i-sc  = i-sc  + ORDER1.TTL_SC - ORDER1.TTL_DEAL.
         i-oc  = i-oc  + ORDER1.TTL_OC - ORDER1.TTL_DEAL.
         i-ic  = i-ic  + ORDER1.TTL_IC - ORDER1.TTL_DEAL.
         i-lc  = i-lc  + ORDER1.TTL_LOT_ACT - ORDER1.TTL_DEAL.
         i-cc  = i-cc  + ORDER1.TTL_COMM_COST - ORDER1.TTL_DEAL.
         if ORDER1.ORDER <> ORDER.ORDER then
             t-comm= t-comm + ORDER1.TTL_COMMISSION.
             
         if trim(gb-coname) begins "Kuna" then do:
             for each ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                      ORDER_ITEM.ORDER = ORDER1.ORDER and
                      (ORDER_ITEM.ITEM = "FREIGHT" or
                       ORDER_ITEM.ITEM = "RESTOCK") no-lock:
                 assign i-ext = i-ext - ORDER_ITEM.EXTEND
                        qty = if ORDER_ITEM.PRICE_WT& then ORDER_ITEm.WT_SHIP
                              else ORDER_ITEM.QTY_SHIP
                        i-lc = i-lc - (ORDER_ITEM.LOT_COST + 
                                       ORDER_ITEM.FREIGHT) * qty
                        i-ic = i-ic - ORDER_ITEM.INV_COST * qty
                        i-oc = i-oc - ORDER_ITEM.OFF_COST * qty
                        i-sc = i-sc - ORDER_ITEM.SLS_COST * qty
                        i-cc = i-cc - ORDER_ITEM.SLS_COST * qty.
             end.
         end.

         if subtract-FreightLine& then do:
             
             for each ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                      ORDER_ITEM.ORDER = ORDER1.ORDER and
                      (ORDER_ITEM.ITEM = "FREIGHT" or
                       ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT_ITEM or
                       ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT2_ITEM or
                       ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT3_ITEM) no-lock:
                 assign i-ext = i-ext - ORDER_ITEM.EXTEND
                        qty = if ORDER_ITEM.PRICE_WT& then ORDER_ITEm.WT_SHIP
                              else ORDER_ITEM.QTY_SHIP
                        i-lc = i-lc - (ORDER_ITEM.LOT_COST + 
                                       ORDER_ITEM.FREIGHT) * qty
                        i-ic = i-ic - ORDER_ITEM.INV_COST * qty
                        i-oc = i-oc - ORDER_ITEM.OFF_COST * qty
                        i-sc = i-sc - ORDER_ITEM.SLS_COST * qty
                        i-cc = i-cc - ORDER_ITEM.SLS_COST * qty.
             end.
         end.
         
        if subtract-k12& then do:
            for each ORDER_ALLOCATION where ORDER_ALLOCATION.CO = C[1] and
                     ORDER_ALLOCATION.ORDER = ORDER1.ORDER no-lock:
                find ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                     ORDER_ITEM.ORDER = ORDER_ALLOCATION.ORDER and
                     ORDER_ITEM.LINE = ORDER_ALLOCATIOn.LINE no-lock no-error.
                if not avail ORDER_ITEM then next.
                i-sc = i-sc - (ORDER_ALLOCATION.ALLOCATION_AMT *
                             (if ORDER_ITEM.PRICE_WT& then ORDER_ITEM.WT_SHIP
                                 else ORDER_ITEM.QTY_SHIP)).
            end.
        end.
    end.
    find ORDER1 where ORDER1.CO = C[1] and
         ORDER1.ORDER = substr(ORDER.ORDER,1,6) + "00" no-lock no-error.
    if avail ORDER1 then assign
      comm% = ORDER1.COMM_RATE
      orig-order = ORDER1.ORDER
      del-str = ORDER1.DELIVERY_STR. /* commission rate override from original*/
    if trim(gb-coname) begins "tri-city" and avail ORDER1 then
        for each ORDER1 where ORDER1.CO = C[1] and
              ORDER1.CUSTOMER = ORDER.CUSTOMER and
              ORDER1.SALESREP = ORDER.SALESREP and
              ORDER1.ORDER_DT = ORDER.ORDER_DT and
              ORDER1.TYPE <> "C" no-lock:
            if substr(ORDER1.ORDER,1,6) <> substr(orig-order,1,6) and
                 lookup(substr(ORDER1.ORDER, 1, 6), del-str) = 0 then
                 del-str = del-str + (if del-str > "" then "," else "") +
                 substr(ORDER1.ORDER,1,6).
        end.
end.
else do:
    assign i-ext = ORDER.TTL_EXT -
              (if trim(gb-coname) begins "American" then ORDER.FREIGHT else 0)
            i-sc  = ORDER.TTL_SC - ORDER.TTL_DEAL
            i-ic  = ORDER.TTL_IC - ORDER.TTL_DEAL
            i-lc  = ORDER.TTL_LOT_ACT - ORDER.TTL_DEAL
            i-oc  = ORDER.TTL_OC - ORDER.TTL_DEAL
            i-cc  = ORDER.TTL_COMM_COST - ORDER.TTL_DEAL
            del-str = ORDER.DELIVERY_STR
            orig-order = ORDER.ORDER
            comm% = ORDER.COMM_RATE.

     if trim(gb-coname) begins "Kuna" then do:
         for each ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                  ORDER_ITEM.ORDER = ORDER.ORDER and
                  (ORDER_ITEM.ITEM = "FREIGHT" or
                   ORDER_ITEM.ITEM = "RESTOCK") no-lock:
             assign i-ext = i-ext - ORDER_ITEM.EXTEND
                    qty = if ORDER_ITEM.PRICE_WT& then ORDER_ITEm.WT_SHIP
                          else ORDER_ITEM.QTY_SHIP
                    i-lc = i-lc - (ORDER_ITEM.LOT_COST + 
                                   ORDER_ITEM.FREIGHT) * qty
                    i-ic = i-ic - ORDER_ITEM.INV_COST * qty
                    i-oc = i-oc - ORDER_ITEM.OFF_COST * qty
                    i-sc = i-sc - ORDER_ITEM.SLS_COST * qty
                    i-cc = i-cc - ORDER_ITEM.SLS_COST * qty.
         end.
     end.
     
     if subtract-FreightLine& then do:
             
         for each ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                  ORDER_ITEM.ORDER = ORDER.ORDER and
                  (ORDER_ITEM.ITEM = "FREIGHT" or
                   ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT_ITEM or
                   ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT2_ITEM or
                   ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT3_ITEM) no-lock:
             assign i-ext = i-ext - ORDER_ITEM.EXTEND
                    qty = if ORDER_ITEM.PRICE_WT& then ORDER_ITEm.WT_SHIP
                          else ORDER_ITEM.QTY_SHIP
                    i-lc = i-lc - (ORDER_ITEM.LOT_COST + 
                                   ORDER_ITEM.FREIGHT) * qty
                    i-ic = i-ic - ORDER_ITEM.INV_COST * qty
                    i-oc = i-oc - ORDER_ITEM.OFF_COST * qty
                    i-sc = i-sc - ORDER_ITEM.SLS_COST * qty
                    i-cc = i-cc - ORDER_ITEM.SLS_COST * qty.
         end.
     end.
         
    if subtract-k12& then do:
        for each ORDER_ALLOCATION where ORDER_ALLOCATION.CO = C[1] and
                 ORDER_ALLOCATION.ORDER = ORDER.ORDER no-lock:
            find ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                 ORDER_ITEM.ORDER = ORDER_ALLOCATION.ORDER and
                 ORDER_ITEM.LINE = ORDER_ALLOCATIOn.LINE no-lock no-error.
            if not avail ORDER_ITEM then next.
            i-sc = i-sc - (ORDER_ALLOCATION.ALLOCATION_AMT *
                             (if ORDER_ITEM.PRICE_WT& then ORDER_ITEM.WT_SHIP
                                 else ORDER_ITEM.QTY_SHIP)).
        end.
    end.
end.
if trim(gb-coname) begins "tri-city" and ORDER.TYPE <> "C" then
    for each ORDER1 where ORDER1.CO = C[1] and
          ORDER1.CUSTOMER = ORDER.CUSTOMER and
          ORDER1.SALESREP = ORDER.SALESREP and
          ORDER1.ORDER_DT = ORDER.ORDER_DT and
          ORDER1.TYPE <> "C"               and
          ORDER1.TYPE     = ORDER.TYPE no-lock:

        if substr(ORDER1.ORDER,1,6) <> substr(orig-order,1,6) and
             lookup(substr(ORDER1.ORDER, 1, 6), del-str) = 0 then
             del-str = del-str + (if del-str > "" then "," else "") +
             substr(ORDER1.ORDER,1,6).
    end.
assign t-ext = i-ext
       t-sc  = i-sc
       t-oc  = i-oc
       t-lc  = i-lc
       t-ic  = i-ic
       t-cc  = i-cc
       t-pcs = i-pcs.
       
find first CUST_STOP where CUST_STOP.CO = c[1]
       and CUST_STOP.CUSTOMER = ORDER.CUSTOMER no-lock no-error.
if avail CUST_STOP then do:
    for each CUST_STOP1 no-lock where CUST_STOP1.CO = C[1]
         and CUST_STOP1.STOP_ = CUST_STOP.STOP_:
        for each ORDER1 no-lock use-index ORDER_CUST where ORDER1.Co = C[1]
             and ORDER1.CUSTOMER = CUST_STOP1.CUSTOMER
             and ORDER1.ORDER_DT = ORDER.ORDER_DT
             and ORDER1.TYPE <> "C":
            if substr(ORDER1.ORDER,1,6) <> substr(orig-order,1,6) and
                 lookup(substr(ORDER1.ORDER, 1, 6), del-str) = 0
            then del-str = del-str + (if del-str > "" then "," else "") +
                           substr(ORDER1.ORDER,1,6).
        end.
    end.
end.

/* Sum total pieces/margin 1 delivery to determine comm% */
if SLS_CONTROL.COMBINE_CUST& and del-str > "" then
do i = 1 to num-entries(del-str):
    if orig-order = entry(i,del-str) then next.
    for each ORDER1 where ORDER1.CO = C[1] and
         ORDER1.ORDER begins substr(entry(i,del-str),1,6) and
         ORDER1.UPDATE& = yes and
         ORDER1.ORDER_DT <= ORDER.ORDER_DT no-lock:
             t-ext = t-ext + ORDER1.TTL_EXT -
                (if trim(gb-coname) begins "American" then ORDER.FREIGHT
                 else 0).
             t-sc  = t-sc  + ORDER1.TTL_SC - ORDER1.TTL_DEAL.
             t-oc  = t-oc  + ORDER1.TTL_OC - ORDER1.TTL_DEAL.
             t-lc  = t-lc  + ORDER1.TTL_LOT_ACT - ORDER1.TTL_DEAL.
             t-ic  = t-ic  + ORDER1.TTL_IC - ORDER1.TTL_DEAL.
             t-cc  = t-cc  + ORDER1.TTL_COMM_COST - ORDER1.TTL_DEAL.

         if trim(gb-coname) begins "Kuna" then do:
             for each ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                      ORDER_ITEM.ORDER = ORDER1.ORDER and
                      (ORDER_ITEM.ITEM = "FREIGHT" or
                       ORDER_ITEM.ITEM = "RESTOCK") no-lock:
                 assign t-ext = t-ext - ORDER_ITEM.EXTEND
                        qty = if ORDER_ITEM.PRICE_WT& then ORDER_ITEm.WT_SHIP
                              else ORDER_ITEM.QTY_SHIP
                        t-lc = t-lc - (ORDER_ITEM.LOT_COST +
                                        ORDER_ITEM.FREIGHT) * qty
                        t-ic = t-ic - ORDER_ITEM.INV_COST * qty
                        t-oc = t-oc - ORDER_ITEM.OFF_COST * qty
                        t-sc = t-sc - ORDER_ITEM.SLS_COST * qty
                        t-cc = t-cc - ORDER_ITEM.SLS_COST * qty.
             end.
         end.
       
         if subtract-FreightLine& then do:
             
             for each ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                      ORDER_ITEM.ORDER = ORDER1.ORDER and
                      (ORDER_ITEM.ITEM = "FREIGHT" or
                       ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT_ITEM or
                       ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT2_ITEM or
                       ORDER_ITEM.ITEM = OE_CONTROL.FREIGHT3_ITEM) no-lock:
                 assign i-ext = i-ext - ORDER_ITEM.EXTEND
                        qty = if ORDER_ITEM.PRICE_WT& then ORDER_ITEm.WT_SHIP
                              else ORDER_ITEM.QTY_SHIP
                        i-lc = i-lc - (ORDER_ITEM.LOT_COST + 
                                       ORDER_ITEM.FREIGHT) * qty
                        i-ic = i-ic - ORDER_ITEM.INV_COST * qty
                        i-oc = i-oc - ORDER_ITEM.OFF_COST * qty
                        i-sc = i-sc - ORDER_ITEM.SLS_COST * qty
                        i-cc = i-cc - ORDER_ITEM.SLS_COST * qty.
             end.
         end.
         
        if subtract-k12& then do:
            for each ORDER_ALLOCATION where ORDER_ALLOCATION.CO = C[1] and
                     ORDER_ALLOCATION.ORDER = ORDER1.ORDER no-lock:
                find ORDER_ITEM where ORDER_ITEM.CO = C[1] and
                     ORDER_ITEM.ORDER = ORDER_ALLOCATION.ORDER and
                     ORDER_ITEM.LINE = ORDER_ALLOCATIOn.LINE no-lock no-error.
                if not avail ORDER_ITEM then next.
                t-sc = t-sc - (ORDER_ALLOCATION.ALLOCATION_AMT *
                             (if ORDER_ITEM.PRICE_WT& then ORDER_ITEM.WT_SHIP
                                 else ORDER_ITEM.QTY_SHIP)).
            end.
        end.
    end.   /* each ORDER2 */
end.   /* i = 1 to */

assign margin  = t-ext - (if cost-type = "C" then t-cc 
                          else if cost-type = "L" then t-lc
                          else if cost-type = "I" then t-ic
                          else if cost-type = "O" then t-oc
                          else t-sc)
       margin% = round(((margin) * 100) / t-ext,2).
/*message "t-ext" t-ext "t-sc" t-sc "margin" margin margin% ORDER.ORDER. pause*/

if trim(gb-coname) begins "Beasley" and ORDER.TYPE = "C" then do:
    find ORDER1 where ORDER1.CO = C[1] and
         ORDER1.ORDER = substr(ORDER.ORDER,1,6) + "00" no-lock no-error.
    if not avail ORDER1 or ORDER1.REGISTER = "     0" then do:
        ORDER.TTL_COMMISSION = 0.
        return.
    end.
end.

if ((trim(gb-coname) begins "Jacmar") or (trim(gb-coname) begins "DDC")) and
(ORDER.TYPE = "C" or ORDER.SHIP_VIA = "R") then do:
  comm% = 0.
  if ORDER.SHIP_VIA = "R" then do:   /* redelivery at fixed commission */
   comm% = 2.
   sales-margin& = yes.
  end.
/* Credit commission at same rate as original invoice */
  if ORDER.TYPE = "C" then do:
        find ORDER1 where ORDER1.CO = C[1] and
             ORDER1.ORDER = substr(ORDER.ORDER,1,6) + "00" no-lock no-error.
    if avail ORDER1 then do:
        comm% = ORDER1.COMM_RATE.
        if ORDER1.SHIP_VIA = "R" then sales-margin&= yes.
    end.
  end.
end.
if ((trim(gb-coname) begins "Campus")) and
    (ORDER.TYPE = "C" or ORDER.SHIP_VIA = "W") then do:
  if ORDER.SHIP_VIA = "W" then do:   /* Will Call at fixed commission */
    comm% = 8.2.
    sales-margin& = yes.
  end.
  /* Credit commission at same rate as original invoice */
  if ORDER.TYPE = "C" then do:
    find ORDER1 where ORDER1.CO = C[1] and
         ORDER1.ORDER = substr(ORDER.ORDER,1,6) + "00" no-lock no-error.
    if avail ORDER1 then do:
      comm% = ORDER1.COMM_RATE.
      if ORDER1.SHIP_VIA = "W" then sales-margin&= yes.
    end.
  end.
end.  /* Campus Custom */
                           
else do:
  if avail CUSTOMEr and CUSTOMER.COMM_OVERRIDE& = yes then do:
      assign comm% = CUSTOMER.COMM_RATE
             sales-margin& = if CUSTOMER.COMM_FIXED_TYPE = "S" then yes else no.
  end.
  /* Jacmar uses COMM_RATE field to store original commission rate on orders */
  /* but we want to force a relculation instead of using old commision rate */
  else if trim(gb-coname) begins "Jacmar" or trim(gb-coname) begins "DDC" then
    comm% = 0.
    
end.

if /*margin% > 0 and*/  margin% <> ? then do:
/* commission rate manually overridden this order */
    if comm% <> 0 then do:
       comm% = comm% / 100.
       comm = if sales-margin& /* SLS_CONTROL.SALES_MARGIN&*/ then i-ext * comm%
              else (i-ext - (if cost-type = "C" then i-cc 
                             else if cost-type = "L" then i-lc
                             else if cost-type = "I" then i-ic
                             else if cost-type = "O" then i-oc 
                              else i-sc)) * comm%.
    end.
    else do:
/* Table => Lookup based on "at least" COMMISSION.MARGIN% */
       find last COMMISSION where COMMISSION.CO = C[1] and
            COMMISSION.MARGIN% <= margin% and
            COMMISSION.COMM_TABLE = comm-table no-lock no-error.
       if not avail COMMISSION then do:
           if ORDER.TYPE = "C" and not trim(gb-coname) begins "Jacmar" and
              not trim(gb-coname) begins "DDC" then
              ORDER.TTL_COMMISSION = - t-comm.
           else ORDER.TTL_COMMISSION = 0.
           return.  /* less than lowest */
       end.

/* Commission based on margin% only */
       if comm-method = "MARGIN" or comm-method = "" then do:
          comm% = if avail COMMISSION then COMMISSION.COMMISSION% / 100
                  else 0.
       end.

/* Commission based on matrix of Margin% and margin amount */
       else if comm-method = "MARGSIZE" then do:
          /* Table => Lookup based on Margin "Under" COMM_SIZE.COMM_SIZE */
          find first COMM_SIZE where COMM_SIZE.CO = C[1] and
               COMM_SIZE.COMM_SIZE > margin and
               COMM_SIZE.COMM_TABLE = comm-table no-lock no-error.
          if not avail COMM_SIZE then
            find last COMM_SIZE where COMM_SIZE.CO = C[1] and
                COMM_SIZE.COMM_SIZE > 0 and
                COMM_SIZE.COMM_TABLE = comm-table no-lock no-error.
          comm-level = if avail COMM_SIZE then COMM_SIZE.SEQ else 1.
          comm%      = if avail COMMISSION then COMM_SIZE%[comm-level] / 100
                       else 0.
/*message COMMISSION.MARGIN% "level:" comm-level "percent comm" comm%. pause.*/
       end.

/* Commission based on matrix of Margin% and order amount */
       else if comm-method = "ORDSIZE" then do:
         /* Table => Lookup based on Order amount "Under" COMM_SIZE.COMM_SIZE */
          find first COMM_SIZE where COMM_SIZE.CO = C[1] and
               COMM_SIZE.COMM_SIZE > t-ext and
               COMM_SIZE.COMM_TABLE = comm-table no-lock no-error.
          if not avail COMM_SIZE then
            find last COMM_SIZE where COMM_SIZE.CO = C[1] and
                COMM_SIZE.COMM_SIZE > 0 and
                COMM_SIZE.COMM_TABLE = comm-table no-lock no-error.
          comm-level = if avail COMM_SIZE then COMM_SIZE.SEQ else 1.
          comm%      = if avail COMMISSION then COMM_SIZE%[comm-level] / 100
                       else 0.
/* message COMMISSION.MARGIN% "level:" comm-level "percent comm" comm%. pause.*/
       end.

/* commission% applied against sales or margin amount */
       comm = if sales-margin& /* SLS_CONTROL.SALES_MARGIN&*/ then i-ext * comm%
              else (i-ext - (if cost-type = "C" then i-cc 
                             else if cost-type = "L" then i-lc
                             else if cost-type = "I" then i-ic
                             else if cost-type = "O" then i-oc 
                             else i-sc)) * comm%.

    end.  /* else do */
end.

if ORDER.TYPE = "C" and not trim(gb-coname) begins "Jacmar" and
    not trim(gb-coname) begins "DDC" then
     ORDER.TTL_COMMISSION = comm - t-comm.
else ORDER.TTL_COMMISSION = comm.

if trim(gb-coname) begins "Jacmar" or trim(gb-coname) begins "DDC" then
   ORDER.COMM_RATE = comm% * 100. /* to calc commission on subsequent credit */

