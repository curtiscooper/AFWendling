/*******************************************************************************
bi/source/printRouteForms.p   clc Created

Prints forms to print along with route

*******************************************************************************/

{_laser.def}

/*
define input parameter ipCo as character.
define input parameter ipDriver as character.
define input parameter ipDate as date.
define input parameter ipRouteNum as character.
*/
                                        



define variable truckNum as character no-undo.
define variable trailerNum as character no-undo.
define variable driverInit as character no-undo.
define variable routeDate as character no-undo.

define buffer lbufRoute_hdr for route_hdr.



define variable ipRouteNum as character. 
find first lbufRoute_hdr where
           lbufRoute_hdr.date_ <> ? and
           lbufRoute_hdr.trailer <> "" and
           lbufRoute_hdr.route <> "" no-lock no-error.
assign ipRouteNum = lbufRoute_hdr.route.


/*
find lbufRoute_hdr where 
     lbufRoute.co = ipCo and 
     lbufRoute.driver = ipDriver and
     lbufRoute.date_ = ipDate and
     lbufRoute.route = ipRoute no-lock no-error.
*/

if not available lbufRoute_hdr then
  assign 
    truckNum = "_______________"    
    trailerNum = "_______________"    
    driverInit = "_______________"    
    routeDate = "_______________".
else    
  assign 
    truckNum = if lbufRoute_hdr.truck = ? or lbufRoute_hdr.truck = "" then "N/A" 
                else trim(lbufRoute_hdr.truck) + fill(" ",10 - length(trim(lbufRoute_hdr.truck)))    
    trailerNum = if lbufRoute_hdr.trailer = ? or lbufRoute_hdr.trailer = "" then "N/A"
                  else trim(lbufRoute_hdr.trailer) + fill(" ",10 - length(trim(lbufRoute_hdr.trailer)))    
    driverInit = if lbufRoute_hdr.driver = ? or lbufRoute_hdr.driver = "" then "N/A"
                  else trim(lbufRoute_hdr.driver) + fill(" ",3 - length(trim(lbufRoute_hdr.driver)))    
    routeDate = if lbufRoute_hdr.date_ = ? then "N/A"
                  else string(lbufRoute_hdr.date_,"99/99/9999").
  
  


run printVehicleInspectionReport.

run printDriverRouteForm.

run printRouteTruckReeferLog.

run printRouteMerchandiseReturnForm.

run printTestBoxes.


  UNIX SILENT qprt -Plp90 -Bnn /bi/tmp/VehicleInspectionReport.txt.
  UNIX SILENT qprt -Plp90 -Bnn /bi/tmp/DriverRouteForm.txt.
  UNIX SILENT qprt -Plp90 -Bnn /bi/tmp/RouteTruckReeferLog.txt.  
  UNIX SILENT qprt -Plp90 -Bnn /bi/tmp/RouteMerchandiseReturnForm.txt.
  UNIX SILENT qprt -Plp90 -Bnn /bi/tmp/TestBoxes.txt.
  

  
procedure printVehicleInspectionReport:

  
  output to "/bi/tmp/VehicleInspectionReport.txt".

  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  
  put "                                         Driver Vehicle Inspection Report" skip.
  put "" skip.
  
  put "\033(10U" "\033(s1p10v0s0b4148T". /* "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */  
  
  put "                                             Press Hard When Writing" skip.
  put skip.
  put "DRIVER POST TRIP_______________________________________________________________________________________________________" skip. 
  put " " skip.
  put " " skip.   
  put "Carrier:___________________   Location:_________________    Driver: " driverInit "   Date/Time In: " routeDate  skip.
  put " " skip. 
  put " " skip.   
  put "Truck/Tractor No: " truckNum " Mileage In:_____________ Trailer(s) No(s): " trailerNum "    Mileage In:________________" skip.
  put "_______________________________________________________________________________________________________________________" skip. 
  put "Check any defective item and provide details under 'Post Trip Remarks'                 " skip.
  put " " skip. 
  put "1 FRONT/ENGINE" at 1.
  put "2 COUPLING" at 24.
  put "3 TRAILER/BOX SIDE(S)" at 43.
  put "5 IN CAB CHECK" at 67.
  put skip.
  put "COMPARTMENT" at 1.        
  put skip.                                                                  
  put "___Windsheild fluid" at 1.
  put "___Fifth wheel" at 24.
  put "___ABS Light" at 43.
  put "___Horn" at 67.
  put skip.  
  put "   reservoir" at 1.
  put "___King pin" at 24.
  put "___Marker lights/" at 43.
  put "___Defroster/" at 67. 
  put skip.
  put "___Engine coolant" at 1.  
  put "___Air/Electrical" at 24.
  put "   Reflective tape" at 43.
  put "   Heater/AC " at 67. 
  put skip.
  put "   reservoir" at 1.  
  put "   lines/Gladhands" at 24.
  put "___Tires, Wheels"    at 43.
  put "___Steering" at 67. 
  put skip.
  put "___Obvious fluid leaks" at 1.  
  put "___Marker lights" at 24.
  put "   Mudflaps"    at 43.
  put "___Parking brake" at 67. 
  put skip.  
  put "___Belt/Hoses" at 1.  
  put "___Tractor tires" at 24.
  put "                " at 43.
  put "___Service brakes" at 67. 
  put skip.  
  put "___Steer tires, wheels" at 1.  
  put "    Wheels" at 24.
  put "4 TRAILER/BOX REAR" at 43.
  put "/ABS light" at 67. 
  put skip.  
  put "    Lugs and signs of" at 1.  
  put "___Mudflaps" at 24.
  put "___Reflective tape" at 43.
  put "   (ST Only)" at 67. 
  put skip.  
  put "    oil leakage" at 1.  
  put "    Reflective tape" at 24.
  put "___Doors work and" at 43.
  put "___Emergency" at 67. 
  put skip. 
  put "___Headlights" at 1.  
  put "             " at 24.
  put "   latch properly" at 43.
  put "   equipment" at 67.
  put skip. 
  put "___Turn signals" at 1.  
  put "             " at 24.
  put "___Liftgate operational" at 43.
  put "___Windsheild wipers" at 67. 
  put skip. 
  put "___Marker lights" at 1.  
  put "             " at 24.
  put "___Lights" at 43.
  put "___Mirrors" at 67. 
  put skip.   
  put "_______________________________________________________________________________________________________________________" skip.     
  put "Driver Post Trip Remarks       ___Truck-No Defects   ___Trailer-No Defects                  " skip.
  put skip.  
  put skip.  
  put skip.  
  put skip.  
  put skip.  
  put skip.
  put skip.  
  put " Driver Signature:__________________________________________ Driver's Phone Number: ___________________________________" skip. 
  put "_______________________________________________________________________________________________________________________" skip.   

  put " " skip.
  put " " skip.
  put "SHOP___________________________________________________________________________________________________________________" skip.
  put skip.
  put " ___Above Defects Corrected              ___Above Defects do not need to be corrected   " skip.
  put "                                           for safe vehicle operation                   " skip.
  put "Carrier/Agent - Remarks/Actions Taken                                                   " skip. 
  put skip.  
  put skip.  
  put skip.  
  put skip.
  put skip.  
  put "Carrier/Agent- Print Name:________________________________________" skip.
  put skip.
  put skip.
  put skip.  
  put "Carrier/Agent- Signature:_________________________________________           Date:___________________________" skip.
  put skip.  
  put "____PRETRIP/CSA________________________________________________________________________________________________________" skip.
  put skip.
  put skip.  
  put "Date/Time Out: " routeDate "     Truck No: " truckNum "     Mileage Out:____________________ Trailer(s) No(s): " trailerNum  skip.
  put skip.
  put "Signature below certifies the following: " skip.
  put "1) Previous DVIR was examined and power unit is safe to operate                        " skip.
  put "2) A pre-trip inspection was performed following the process detailed on the inside cover of this DVIR book     " skip.
  put "3) I am in compliance with the following CSA related items:                            " skip.
  put skip.
  put "   -Valid CDL License    -Medical Card is valid    -Permits/Vehicle Registration Documents are Proper        " skip.
  put "   -CDL Endorsements are -Required Glasses,        -Prior 7 Day Logs and/or OBC               " skip.
  put "    valid for run         Hearing Aids worn         Instruction Card are available       " skip.
  put "_______________________________________________________________________________________________________________________" skip.
  put "Driver Pre Trip Remarks                                                                " skip.
  put skip.  
  put skip.  
  put skip.  
  put skip.
  put skip.  
  put " Driver Signature:__________________________________________ Driver's Phone Number: ___________________________________" skip. 
  put "_______________________________________________________________________________________________________________________" skip.   
  
  output close.
/* page stream printForms.*/

  

end procedure.  

procedure printDriverRouteForm:
  
  output to "/bi/tmp/DriverRouteForm.txt".

  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  
  put "                               Driver Route Form" skip.
  put "" skip.

  put "\033(10U" "\033(s1p10v0s0b4148T". /* "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */

  put "What is my Name: " driverInit " _________________________" skip.
  put "" skip.
  put "Date: " routeDate "       Route#: " ipRouteNum  skip.
  put "" skip.
  put "" skip.
  put "Time Out:______________________           Time In:____________________" skip.
  put "" skip.
  put "" skip.
  put "Mileage Out:___________________         Mileage In:___________________" skip.  
  put "" skip.
  put "" skip.
  put "State Mileage In:______________         State Mileage Out:____________" skip.
  put "" skip.
  put "" skip.
  put "_______________________________         ______________________________" skip.
  put "" skip.
  put "" skip.
  put "_______________________________         ______________________________" skip.
  put "" skip.
  put "" skip.
  put "_______________________________         ______________________________" skip.
  put "" skip.
  put "" skip.
  put "_______________________________         ______________________________" skip.
  put "" skip.
  put "" skip.
  put "_______________________________         ______________________________" skip.
  put "" skip.
  put "" skip.
  put "_______________________________         ______________________________" skip.
  put "" skip.
  put "" skip.
  put "_______________________________         ______________________________" skip.
  put "" skip.
  put "" skip.
  put "Truck#: " truckNum "                    Tolls:________________________" skip.
  put "" skip.
  put "" skip.
  put "Truck Fuel:______________" skip.
  put "" skip.
  put "" skip.
  put "Trailer#: " trailerNum "                  Total Miles:________________" skip.
  put "" skip.
  put "" skip.
  put "Reefer Fuel:______________" skip.
  put "" skip.
  put "" skip.  
  put "Def Gallons:______________" skip.


  output close.
  
  
 
end procedure.  




 
procedure printRouteTruckReeferLog:

  output to "/bi/tmp/RouteTruckReeferLog.txt".

  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  
  put "                                  A.F. Wendling Route Truck Reefer Log" skip.
  put "" skip.

  put "\033(10U" "\033(s1p10v0s0b4148T". /* "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */


  put "Date: " routeDate "    Route#: " ipRouteNum "    Trailer#: " trailerNum "    Truck#: " truckNum  skip.
  put "" skip.
  put "" skip.  
  put "Driver: " driverInit " ____________________        " skip.
  put "" skip.
  put "" skip.
  put "Time:___________________ (Start of shift first temp check)" skip.  
  put "" skip.
  put "                                                                    #1" skip.
  put "REEFER SET POINT:" at 1.
  put "___________FRZ" at 20.
  put "ACTUAL TEMP:" at 51. 
  put "___________FRZ" 70 skip.
  put "" skip.
  put "" skip.
  put "___________CLR" at 20.
  put "___________CLR" at 70 skip.
  put "" skip.
  put "" skip.
  put "Time:___________________ (3 hours after first temp check)" skip.  
  put "" skip.
  put "                                                                    #2" skip.
  put "REEFER SET POINT:" at 1.
  put "___________FRZ" at 20.
  put "ACTUAL TEMP:" at 51. 
  put "___________FRZ" 70 skip.
  put "" skip.
  put "" skip.
  put "___________CLR" at 20.
  put "___________CLR" at 70 skip.
  put "" skip.
  put "" skip.
  put "Time:___________________ (3 hours after second temp check)" skip.  
  put "" skip.
  put "                                                                    #3" skip.
  put "REEFER SET POINT:" at 1.
  put "___________FRZ" at 20.
  put "ACTUAL TEMP:" at 51. 
  put "___________FRZ" 70 skip.
  put "" skip.
  put "" skip.
  put "___________CLR" at 20.
  put "___________CLR" at 70 skip.
  put "" skip.
  put "" skip.
  put "Time:___________________ (3 hours after third temp check)" skip.  
  put "" skip.
  put "                                                                    #4" skip.  
  put "REEFER SET POINT:" at 1.
  put "___________FRZ" at 20.
  put "ACTUAL TEMP:" at 51. 
  put "___________FRZ" 70 skip.
  put "" skip.
  put "" skip.
  put "___________CLR" at 20.
  put "___________CLR" at 70 skip.
  put "" skip.
  put "" skip.
  put "" skip.
  put "" skip.
  put "" skip.
  put "ATTENTION Driver Reefer Temp Logs are a daily requirement" skip.
  put "Please drop all completed Reefer Logs in mailbox outside of Saftey Office" skip.
  put "Report any issues immediately to supervisor" skip.

  output close.
  
  
end procedure.  

procedure printRouteMerchandiseReturnForm:
  output to "/bi/tmp/RouteMerchandiseReturnForm.txt".

  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  
  put "                                       A.F. Wendling's Food Service" skip.

  put "\033(10U" "\033(s1p10v0s0b4148T". /* "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */

  put "                                                                A.F. Wendling Inc." skip.
  put "                                                                  P.O. Box 661" skip.
  put "                                                              Buckhannon, WV 26201" skip.
  put "                                                              PHONE: 304-472-5500" skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put "" skip.
  put "" skip.  
  put "Name:_____________________________ Route: " ipRouteNum "       Mileage Out:_________________" skip.
  put "" skip.
  put "" skip.  

  put "Date: " routeDate "                       Time In:__________________" skip.
  put "" skip.
  put "Truck# " truckNum "    Trailer# " trailerNum  skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  put "REASON RETURNED" at 65.
  put "WAREHOUSE" at 100.
  put skip.
  put "MERCHANDISE" at 10.
  put "\033(10U" "\033(s1p8v0s0b4148T". /* "8:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */
  put "(If product is spoiled, please explain why:molded,broken seal, etc.)" at 15.
  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  put "CHECK" at 105.
  put skip.

  put "\033(10U" "\033(s1p10v0s0b4148T". /* "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */
  put "_________________________________________________________________________________________________________________________" skip.
  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  put "                                  WAREHOUSE" skip.
  put "\033(10U" "\033(s1p10v0s0b4148T". /* "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */
  put "_________________________________________________________________________________________________________________________" skip.
  put " Item#     QTY      Product Description   Acct#           Reason Description                                       " skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */  
  put "                                   COOLER                                                                               " skip.
  put "\033(10U" "\033(s1p10v0s0b4148T". /* "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */
  put "_________________________________________________________________________________________________________________________" skip.
  put " Item#     QTY      Product Description   Acct#           Reason Description                                       " skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */  
  put "                                   FREEZER                                                                              " skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put " Item#     QTY      Product Description   Acct#           Reason Description                                       " skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  put skip.
  put "_________________________________________________________________________________________________________________________" skip.
  
   
  output close.
  
  
end procedure.  

procedure printTestBoxes:
  output to "/bi/tmp/TestBoxes.txt".

  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  
  put "                                       Test Print Boxes" skip.

  put control "~033%0B"

    /*ship to */
    "PU0000,9300;PD3950,9300;"
    "PU0000,8100;PD3950,8100;"
    "PU0000,8100;PD0000,9300;"
    "PU3950,8100;PD3950,9300;" 
    . 

  put control
    "~033%0A".       /* return to normal */
    
  put control
    "\033(s1p12v0s3b4148T"

    "\033&a8.2R\033&a1C"     "Bill To:"
    "\033&a8.2R\033&a72C"    "Ship To:".
           
  output close.
  
  
end procedure.  

