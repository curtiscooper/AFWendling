/*******************************************************************************
bi/source/printRouteForms.p   clc Created

Prints forms to print along with route

*******************************************************************************/

/*{_laser.def}*/

/*define input parameter ipOrderNum as character.*/
/*define input parameter ipRouteNum as character.*/

define variable ipOrderNum as character. 
define variable ipRouteNum as character. 



define variable truckNum as character no-undo.
define variable trailerNum as character no-undo.
define variable driverInit as character no-undo.
define variable routeDate as character no-undo.


find first route_hdr where
           route_hdr.date_ <> ? and
           route_hdr.trailer <> "" and
           route_hdr.route <> "" no-lock no-error.

assign ipRouteNum = route_hdr.route.

assign 
  truckNum = trim(route_hdr.truck) + fill(" ",10 - length(trim(route_hdr.truck)))    
  trailerNum = trim(route_hdr.trailer) + fill(" ",10 - length(trim(route_hdr.trailer)))    
  driverInit = trim(route_hdr.driver) + fill(" ",3 - length(trim(route_hdr.driver)))    
  routeDate = string(route_hdr.date_,"99/99/9999").
  
  


run printVehicleInspectionReport.

run printDriverRouteForm.

run printRouteTruckReeferLog.

run printRouteMerchandiseReturnForm.


procedure printVehicleInspectionReport:

  
  output to "/bi/tmp/VehicleInspectionReport.txt".

  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  
  put "                                  Driver Vehicle Inspection Report" skip.
  put "" skip.
  
  put "\033(10U" "\033(s1p12v0s0b4148T". /* "12:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */.
  
  
  
  put "Press Hard When Writing" skip.

  put "\033(10U" "\033(s1p10v0s0b4148T". /* "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */

  put "___DRIVER POST TRIP_______________________________________________________________________" skip. 
  put "| Carrier                  Location         Driver                Date / Time In         |" skip.
  put "|------------------------|-----------------|---------------------|-----------------------|" skip.
  put "|                        |                 | " + driverInit + "                 | " + routeDate + "             |" skip.
  put "|________________________|_________________|_____________________|_______________________|" skip. 
  put "| Truck / Tractor No        Mileage In        Trailer(s) No(s)    Mileage In             |" skip.
  put "|------------------------|-----------------|-------------------|-------------------------|" skip.
  put "|       " + truckNum + "       |                 |     " + trailerNum + "    |                          |" skip.
  put "|________________________|_________________|___________________|_________________________|" skip. 
  put "| Check any defective item and provide details under 'Post Trip Remarks'                 |" skip.
  put "| 1 FRONT/ENGINE         2 COUPLING         3 TRAILER/BOX SIDE(S)   5 IN CAB CHECK       |" skip.
  put "|   COMPARTMENT                                                                          |" skip.
  put "| ___Windsheild fluid    ___Fifth wheel     ___ABS Light            ___Horn              |" skip.  
  put "|    reservoir           ___King pin        ___Marker lights/       ___Defroster/        |" skip.
  put "| ___Engine coolant      ___Air/Electrical     Reflective tape         Heater/AC         |" skip.
  put "|    reservoir              lines/Gladhands ___Tires, Wheels        ___Steering          |" skip.
  put "| ___Obvious fluid leaks ___Marker lights      Mudflaps             ___Parking brake     |" skip.
  put "| ___Belt/Hoses          ___Tractor tires                           ___Service brakes    |" skip.        
  put "| ___Steer tires, wheels    Wheels          4 TRAILER/BOX REAR         /ABS light        |" skip.
  put "|    Lugs and signs of   ___Mudflaps        ___Reflective tape         (ST Only)         |" skip.
  put "|    oil leakage            Reflective tape ___Doors work and       ___Emergency         |" skip.
  put "| ___Headlights                                latch properly          equipment         |" skip.
  put "| ___Turn signals                           ___Liftgate operational ___Windsheild wipers |" skip.
  put "| ___Marker lights                          ___Lights               ___Mirrors           |" skip.
  put "|________________________________________________________________________________________|" skip. 
  put "| Driver Post Trip Remarks ___Truck-No Defects   ___Trailer-No Defects                   |" skip.
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip. 
  put "|________________________________________________________________________________________|" skip. 
  put "| Driver     |                                         | Driver's                        |" skip. 
  put "| Signature  |                                         | Phone Number                    |" skip.  
  put "|____________|_________________________________________|_________________________________|" skip. 
  put " " skip.
  put "____SHOP__________________________________________________________________________________" skip.
  put "| ___Above Defects Corrected              ___Above Defects do not need to be corrected   |" skip.
  put "|                                            for safe vehicle operation                  |" skip.
  put "| Carrier/Agent - Remarks/Actions Taken                                                  |" skip. 
  put "|________________________________________________________________________________________|" skip.   
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip.     
  put "|________________________________________________________________________________________|" skip.   
  put "| Carrier/Agent- Print Name  |                                    |                      |" skip.
  put "|____________________________|____________________________________| Date                 |" skip.     
  put "| Carrier/Agent- Signature   |                                    |      " + routeDate + "      |" skip.
  put "|____________________________|____________________________________|______________________|" skip.   
  put " " skip.
  put "|____PRETRIP/CSA_________________________________________________________________________|" skip.
  put "| Date/Time Out           Truck No          Mileage Out            Trailer(s) No(s)      |" skip.
  put "|------------------------|-----------------|---------------------|-----------------------|" skip.
  put "|  " + routeDate + "            | " + truckNum + "    |                     | " + trailerNum + "            |" skip.
  put "|________________________|_________________|_____________________|_______________________|" skip.   
  put "| Signature below certifies the following:                                               |" skip.
  put "| 1) Previous DVIR was examined and power unit is safe to operate                        |" skip.
  put "| 2) A pre-trip inspection was performed following the process detailed on the inside    |" skip.
  put "|    cover of this DVIR book                                                             |" skip.
  put "| 3) I am in compliance with the following CSA related items:                            |" skip.
  put "|                                                                                        |" skip.
  put "|    -Valid CDL License    -Medical Card is valid    -Permits/Vehicle Registration       |" skip.
  put "|    -CDL Endorsements are -Required Glasses,         Documents are Proper               |" skip.
  put "|     valid for run         Hearing Aids worn        -Prior 7 Day Logs and/or OBC        |" skip.
  put "|                                                     Instruction Card are available     |" skip.
  put "|                                                                                        |" skip.
  put "|________________________________________________________________________________________|" skip.
  put "| Driver Pre Trip Remarks                                                                |" skip.
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip. 
  put "|                                                                                        |" skip.     
  put "|________________________________________________________________________________________|" skip.     
  put "|                    |                                    | Driver's                     |" skip.
  put "| Driver Signature   |                                    | Phone Number                 |" skip.  
  put "|____________________|____________________________________|______________________________|" skip.     
  
  output close.
  
/*  UNIX SILENT qprt -Plp8 -Bnn VehicleInspectionReport.*/
  

end procedure.  

procedure printDriverRouteForm:
  
  output to "/bi/tmp/DriverRouteForm.txt".

  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  
  put "                               Driver Route Form" skip.
  put "" skip.

  put "\033(10U" "\033(s1p10v0s0b4148T". /* "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */

  put "What is my Name:_" + driverInit + "_________________________" skip.
  put "" skip.
  put "Date:__" + routeDate + "______    Route#:___" + ipRouteNum + "___" skip.
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
  put "Truck#:__" + truckNum + "_____          Tolls:________________________" skip.
  put "" skip.
  put "" skip.
  put "Truck Fuel:______________" skip.
  put "" skip.
  put "" skip.
  put "Trailer#:__" + trailerNum + "_____        Total Miles:________________" skip.
  put "" skip.
  put "" skip.
  put "Reefer Fuel:______________" skip.
  put "" skip.
  put "" skip.  
  put "Def Gallons:______________" skip.


  output close.
  
/*  UNIX SILENT qprt -Plp8 -Bnn DriverRouteForm.*/
 
end procedure.  




 
procedure printRouteTruckReeferLog:

  output to "/bi/tmp/RouteTruckReeferLog.txt".

  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  
  put "                               A.F. Wendling Route Truck Reefer Log" skip.
  put "" skip.

  put "\033(10U" "\033(s1p10v0s0b4148T". /* "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */


  put "Date:__" + routeDate + "__  Route#:__" + ipRouteNum + "__  Trailer#:__" + trailerNum + "__  Truck#: __" + truckNum + "____" skip.
  put "" skip.
  put "" skip.  
  put "Driver:__" + driverInit + "____________________        " skip.
  put "" skip.
  put "" skip.
  put "Time:___________________ (Start of shift first temp check)" skip.  
  put "" skip.
  put "                                                                    #1" skip.
  put "REEFER SET POINT:___________FRZ                                                         ACTUAL TEMP:___________FRZ" skip.
  put "" skip.
  put "" skip.
  put "                 ___________CLR                                                                     ___________CLR" skip.
  put "" skip.
  put "" skip.
  put "Time:___________________ (3 hours after first temp check)" skip.  
  put "" skip.
  put "                                                                    #2" skip.
  put "REEFER SET POINT:___________FRZ                                                         ACTUAL TEMP:___________FRZ" skip.
  put "" skip.
  put "" skip.
  put "                 ___________CLR                                                                     ___________CLR" skip.
  put "" skip.
  put "" skip.
  put "Time:___________________ (3 hours after second temp check)" skip.  
  put "" skip.
  put "                                                                    #3" skip.
  put "REEFER SET POINT:___________FRZ                                                         ACTUAL TEMP:___________FRZ" skip.
  put "" skip.
  put "" skip.
  put "                 ___________CLR                                                                     ___________CLR" skip.
  put "" skip.
  put "" skip.
  put "Time:___________________ (3 hours after third temp check)" skip.  
  put "" skip.
  put "                                                                    #4" skip.  
  put "REEFER SET POINT:___________FRZ                                                         ACTUAL TEMP:___________FRZ" skip.
  put "" skip.
  put "" skip.
  put "                 ___________CLR                                                                     ___________CLR" skip.
  put "" skip.
  put "" skip.
  put "" skip.
  put "" skip.
  put "" skip.
  put "ATTENTION Driver Reefer Temp Logs are a daily requirement" skip.
  put "Please drop all completed Reefer Logs in mailbox outside of Saftey Office" skip.
  put "Report any issues immediately to supervisor" skip.

  output close.
  
/*  UNIX SILENT qprt -Plp8 -Bnn RouteTruckReeferLog.*/
  
end procedure.  

procedure printRouteMerchandiseReturnForm:
  output to "/bi/tmp/RouteMerchandiseReturnForm.txt".

  put "\033(10U\033(s1p13v0s0b4148T". /* "13:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" */
  
  put "                               A.F. Wendling's Food Service" skip.
  put "                                    A.F. Wendling Inc." skip.
  put "                                      P.O. Box 661" skip.
  put "                                  Buckhannon, WV 26201" skip.
  put "                                  PHONE: 304-472-5500" skip.
  
  put "\033(10U" "\033(s1p10v0s0b4148T". /* "10:  F41000       DURKEE MELFRY XXXXXXXXXXXXXXXX" skip. */
  put "________________________________________________________________________________________________" skip.
  put "" skip.
  put "" skip.  
  put "Name:_____________________________ Route: " + ipRouteNum + "       Mileage Out:_________________" skip.
  put "" skip.
  put "" skip.  

  put "Date:__" + routeDate + "____                       Time In:__________________" skip.
  put "" skip.
  put "temp    8am              noon            4pm              8am              noon            4pm" skip.  
  put "" skip.
  put "cooler  ________________________________________________|________________________________________________" skip.
  put "" skip.
  put "frozen  ________________________________________________|________________________________________________" skip.
  put "" skip.
  put "Truck#  ___" + truckNum + " ________ Trailer# _____" + trailerNum + "_____" skip.
  put "__________________________________________________________________________________________________________________________" skip.
  put "|                                        |                REASON RETURNED                         |         WAREHOUSE    |" skip.
  put "|                MERCHANDISE             |  (If product is spoiled, please explain why... molded, |           CHECK      |" skip.
  put "|                                        |          broken seal, etc.)                            |                      |" skip.
  put "|_________________________________________|_______________________________________________________|______________________|" skip.
  put "|                                   WAREHOUSE                                                                            |" skip.
  put "|________________________________________________________________________________________________________________________|" skip.
  put "| Item#   |  QTY    |  Product Description  | Acct#       |    Reason Description                 |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|                                   COOLER                                                                               |" skip.
  put "|________________________________________________________________________________________________________________________|" skip.
  put "| Item#   |  QTY    |  Product Description  | Acct#       |    Reason Description                 |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|                                   FREEZER                                                                              |" skip.
  put "|________________________________________________________________________________________________________________________|" skip.
  put "| Item#   |  QTY    |  Product Description  | Acct#       |    Reason Description                 |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  put "|         |         |                       |             |                                       |                      |" skip.
  put "|_________|_________|_______________________|_____________|_______________________________________|______________________|" skip.
  
   
  output close.
  
/*  UNIX SILENT qprt -Plp8 -Bnn RouteMerchandiseReturnForm.*/
  
end procedure.  

