/*******************************************************************************
b_palmap.p    List Delivery Stops by Pallet Pate version
              Truck diagram footer
see also   b_map.p    (List Delivery Stops by Pallet, fill-in Picker each pallt)
           o_trkmap.p (List Pallets by Customer/Stop for driver)
11/28/95 Doug V Added skip to grand total
12/05/95 Incorporated r_palmap.p code to locate pallets on truck
09/30/96 Skip hardcoded bin areas for truck/pallet diagram
*******************************************************************************/
{_init.i}
{_print.def 5 6 7}
{_oebatch.def}
def var str as char no-undo.
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
/* vars added for Pallet locator */
def var pallet as char format "X(12)" extent 2 no-undo.
def var first-stop as int no-undo.
def var stop-range as char extent 2 no-undo.
def var cube as deci extent 2 no-undo.
def var pcs as deci extent 2 no-undo.
def var h-stop-range as char no-undo.
def var h-cube as deci no-undo.
def var h-pallet as char no-undo.
def var cnt as int no-undo.
def var skip-str as char no-undo.
def var palmap1-prog as char no-undo.

palmap1-prog = 'b/b_palmap1.p'.
if (trim(gb-coname) begins "Ace") or
   (trim(gb-coname) begins "Target") then
  palmap1-prog = 'ace/ace_palmap2.p'.
else if (trim(gb-coname) begins "Benjamin") then
  palmap1-prog = 'bn/bn_palmap1.p'.

def new shared temp-table w_pallet no-undo
   field w_pallet as char
   field w_first_stop as int
   field w_compartment as int
   field w_last_stop as int
   field w_cube as deci
   field w_wt as deci
   field w_pos as int
   field w_pcs as int.
{_oetrk.def}

{_print.i
    &lpp       = 59
    &frow      = 4
    &choices   = 5
    &choose    = _choosep.chs
    &choosef   = _choosef.chs
   &choosefe  =  _choosefe.chs
    &page1     = _nul.i
    &progname  = b_palmap.p
    &dispfile  = b_palmap.di
    &promptfil = _oetrk-p.i
    &promptvar = _oetrk-v.i
    &title     = "PALLET MAP BY TRUCK"
    &form      = 080_1b.f
    &ff        = no  }


if h-page > 0 then do transaction:
   find ROUTE_HDR where RECID(ROUTE_HDR) = r exclusive no-error.
   if avail ROUTE_HDR then do:
      ROUTE_HDR.DONE_[2] = "X".
      find ROUTE_HDR where recid(ROUTE_HDR) = r no-lock.
   end.
end.
