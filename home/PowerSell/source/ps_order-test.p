
/*------------------------------------------------------------------------
    File        : ps_order-test.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Curtis
    Created     : Fri Sep 09 22:36:33 EDT 2022
    Notes       :
  ----------------------------------------------------------------------*/

define var company      as char no-undo format "x(003)".
define var confirm-line as char no-undo format "x(60)".
define var item         as char no-undo.

    assign
      confirm-line =
                  "Line " +
                  "Item       " +
                  "Unit " +
                  "QtyO " +
                  "QtyS " +
                  "Sub  " +

                  "Status ".

display confirm-line no-label.

for each order_item no-lock:
       find first ITEM
/*        where ITEM.CO   = "01"*/
          and ITEM.ITEM = ORDER_ITEM.ITEM
                  no-lock no-error.


assign
  item    = ORDER_ITEM.ITEM
  item    = item + fill(" ",10 - length(item))
  confirm-line =
 /* *****

xxxxxxxxxxqqqqeppppppppccccccccssssssssss   //Item line
  ****** */
/*                    item + string(tt-Confirm-Item.QtyShip,"9999") + "N" +*/
/*                    tt-Confirm-Item.NetPrice + tt-Confirm-Item.Cost     +*/
/*                    substr(tt-Confirm-Item.Msg,1,30).                    */
string(ORDER_ITEM.LINE,"-9999") + " " +
                    item + " " +
         ORDER_ITEM.UNIT + " " +

string(ORDER_ITEM.QTY_ORD,"-9999") + " " +
string(ORDER_ITEM.QTY_SHIP,"-9999") + " " +
string(ORDER_ITEM.SUB&) + " " +
if available item then ITEM.STOCK_STATUS else "".


display confirm-line no-label.


  end.