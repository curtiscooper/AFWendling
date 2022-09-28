/* *****
    ProgramName: ps_order.p
         Author: EANLLC for Howell Consulting
    DateWritten: 02/11/2019
    Description: PowerSell Order/Confirmations/Guide
      FileNames: LTOnnnnnnn - Order/Confirmation Files
                 LTHnnnnnnn - Order Guide Header Updates
                 LTGnnnnnnn - Order Guide Updates
                 where: nnnnnnn - a sevendigit number
           Note: Order and Confirm files must match.
           
           
    8/28/2022 CLC   Changed outbound confirmation in Process-Order-Confirmations            
    
***** */
{we_session.def TRUE}
{we_messages.def new}
/*
{we_dbgproc.def  new}
*/
{we_debug.def    new}
{_global.def     }
if not gb-jobstream&
then assign gb-jobstream& = yes.
{_oeroy.def   new}
{_oeprice.def new}
{_oedeal.def  new}
{_oeship.def  new}
{ps_oremote.def new}
{_fax.def     new}  /* Fax back code */
{_printsh.def new}  /* Fax back code */
{ps_order.def new}

def var prog-name  as char no-undo init "ps_order.p".

define new shared var w-delim as char no-undo init "|".
define var submit-dir   as char no-undo format "x(30)".
define var confirm-dir  as char no-undo format "x(30)".
define var subproc-dir  as char no-undo format "x(30)".
define var cnfproc-dir  as char no-undo format "x(30)".
define var witem-cnt    as int  no-undo format "9999".
define var dttm         as char no-undo.
define var shut&        as log  no-undo init no.
define var shuts        as char no-undo extent 2
    init ["/tmp/ps_order_prod.shut","/etc/nologin"].
define var shut         as char no-undo.
define var ps-lock-prod as char no-undo init "/tmp/ps_order_prod.lk".
define var ps-lock-test as char no-undo init "/tmp/ps_order_test.lk".
define var ps-lock      as char no-undo.
define var dbconnected  as char no-undo.
define var linecnt      as int  no-undo.
define var cntline      as int  no-undo.
define var ordercnt     as int  no-undo.
define var cntorder     as int  no-undo.
define var ordercnts    as int  no-undo extent 10.
define var trace&       as log  no-undo.
define var trace-dsn    as char no-undo.
define var trace-dsns   as char no-undo extent 5
    init ["/tmp/ps_order_prod.traceall",
          "/tmp/ps_order_prod.tracedebug",
          "/tmp/ps_order_prod.tracedbgproc",
          "/tmp/ps_order_prod.tracerun",
          "/tmp/ps_order_prod.traceftp"].
define var shipto       as char no-undo.

define buffer SHIPTO_CUSTOMER for CUSTOMER. /* EAN - 08/30/2019 SHIPTO */

assign
    w-crlf   = chr(13) + chr(10)
    w-tab    = chr(09)
    start-dt = today
    start-tm = string(time,"HH:MM:SS")
    dbconnected = os-getenv("DB")
    {_dttm.i start-dttm start-dt start-tm}.
    
    {we_run.i Check-Trace}
    
{we_dbgproc.i ps_order.p "Begins"}
assign scriptlog = os-getenv("PSLOGNM").

/* 06/09/97: Allow only 1 ps_order.p to execute at 1 time */

Run-Only-One: do while true:
    {we_dbgproc.i "Run-Only-One" "Begins"}
    if dbconnected begins "/v10db/"
    then assign ps-lock = ps-lock-test.
    else assign ps-lock = ps-lock-prod.
    message ps-lock search(ps-lock) = ps-lock view-as alert-box.
    if search(ps-lock)  = ps-lock
    then do:
        message "ps_order.p already running - " search(ps-lock).
        message "This copy of ps_order.p - shutting down".
        return.
    end.
    unix silent value("touch " + ps-lock).
    leave Run-Only-One.
end. /* Run-Only-One: */
{we_dbgproc.i "Run-Only-One" "Ends"}
pause 0 before-hide.
message "No other ps_order.p running.  Begin processing.".

{we_dbgproc.i Mainline "Begins"}
assign debug& = yes.
Mainline: do while true:
    {we_dbgproc.i Mainline "Begins"}
    {we_run.i Clear-Temp-Tables}.
    {we_run.i Initialization}.
    {we_run.i Load-tt-FTP-Files}.
    if not can-find(first tt-FTP-Files)
    then do:
        {we_run.i Wait-Time}.
        if shut&
        then leave Mainline.
        else next Mainline.
    end.
    {we_run.i FTP-Order-Submits}.
    if can-find(first tt-FTP-Files where tt-FTP-Files.Type = "LTO")
    then do:
        {we_run.i Load-tt-LTO-Lines}.
        {we_run.i Load-tt-Rem-Tables}.
        {we_run.i Setup-Remote-Orders}.
        {we_run.i Submit-Remote-Orders}.
        {we_run.i Load-Order-Confirmations}.
        {we_run.i Process-Order-Confirmations}.
        {we_run.i FTP-Order-Confirmations}.
    end. /* if can-find(first tt-FTP-Files [LTO] */
    if can-find(first tt-FTP-Files where tt-FTP-Files.Type = "LTP")
    then do:
        {we_run.i Load-tt-LTP-Lines}.
        {we_run.i Load-Pickup-Tables}.
        {we_run.i ps/ps_orempu1.p}.
    end. /* if can-find(first tt-FTP-Files [LTP] */
    if can-find(first tt-FTP-Files
        where tt-FTP-Files.Type = "LTH"
           or tt-FTP-Files.Type = "LTG")
    then {we_run.i ps/ps_oguide.p}.
    {we_run.i Cleanup}.
    {we_run.i Wait-Time}.
    if shut& then leave Mainline.
end. /* Mainline: */

pause 5 no-message.

if search(shuts[1]) = shuts[1]
then unix silent value("rm " + shuts[1]).
run Set-Dbg-DTTM.
assign messages-line = dbg-dttm + " " + prog-name + ": Exiting".
message messages-line.
unix silent value("rm " + ps-lock).

{we_dbgproc.i Mainline "Ends"}
{we_dbgproc.i ps_order.p "Ends"}

Procedure Cleanup:
define var ftp-cmd  as char no-undo.
define var ftp-line as char no-undo.
define var ftp-name as char no-undo.

{we_dbgproc.i Cleanup "Begins"}.
define var unix-cmd as char no-undo.
    if not available(tt-Controls)
    then find first tt-Controls no-error.
    Move-2-Processed: for each tt-FTP-Files use-index Seed
        where tt-FTP-Files.Submit-Name  = search(tt-FTP-Files.Submit-Name)
           or tt-FTP-FIles.Confirm-Name = search(tt-FTP-Files.Confirm-Name):
        Submit-Name: do transaction:
            assign
                unix-cmd =
                    replace(tt-FTP-Files.Submit-Name,
                            "submits/","submits/processed/")
                unix-cmd = substr(unix-cmd,1,r-index(unix-cmd,"/")) + "."
                unix-cmd = "mv " + tt-FTP-Files.Submit-Name + "* " + unix-cmd.
            {we_debug.i "'Debug Submits Processed' skip 'CMD: ' unix-cmd"} 
            {we_debug.i "'InFile:' tt-FTP-Files.Submit-Name"}.
            unix silent value(unix-cmd).
        end. /* Submit-Name: */
        Confirm-Name: do transaction:
            if tt-FTP-Files.Type = "LTO" /* Confirms Only for LTO Files */
            then do:
                assign
                    unix-cmd =
                        replace(tt-FTP-Files.Confirm-Name,
                                "confirms/","confirms/processed/")
                    unix-cmd = substr(unix-cmd,1,r-index(unix-cmd,"/"))
                    unix-cmd = "mv " + tt-FTP-Files.Confirm-Name +
                               "* " + unix-cmd + ".".
                {we_debug.i "'Debug Confirms Processed'  skip 'CMD:' unix-cmd"}
                unix silent value(unix-cmd).
            end. /* if tt-FTP-Files.Type = "LTO" */
        end. /* Confirm-Name: */
    end. /* Move-2-Processed: */
    
    Cleanup-Server: do transaction:
        assign
            ftp-cmd-ini[1] = replace(ftp-cmd-ini[5],"[TMP]",temp-dir)
            ftp-cmd-ini[1] = replace(ftp-cmd-ini[1],"[PGMNAME]",prog-name)
            ftp-cmd-ini[1] = replace(ftp-cmd-ini[1],"[FTPDTTM]",ftp-dttm).
        {we_dbgftp.i
            "Cleanups" "output stream s-ftpinis to value(ftp-cmd-ini[1])"}.
        {we_dbgftp.i
            "Cleanups" "'user ' + tt-Controls.User-Name + ' ' +
                                 tt-Controls.User-Password"}
        {we_dbgftp.i "Cleanups" "'ascii'"}
        {we_dbgftp.i "Cleanups" "'cd ' + remote-submit-dir"}
        {we_dbgproc.i "Cleanups" "Next"}.
        Cleanups: for each tt-FTP-Files use-index Seed:
            {we_dbgftp.i
                "Cleanups" "'del ' + substr(tt-FTP-Files.Submit-Name,
                            r-index(tt-FTP-Files.Submit-Name,'/') + 1)"}
        end. /* Cleanups: */
        {we_dbgftp.i "Cleanups" "'bye'"}
        output stream s-ftpinis close.
        unix silent 
            value("/bin/chmod 777 " + SYS_CONTROL.TEMP_DIR +
                  tt-Controls.Pgm-Name + "*").

        {we_debug.i "'********** Cleanups Begins **********'"}.
        {we_dbgftp.i
            "Cleanups" "'ftp -i -n ' + ftp-verb + ' ' +
             tt-Controls.Remote-Confirm-Addr + ' < ' + ftp-cmd-ini[1]"}
        
        input stream s-ftpcmds through value(ftp-cmd).
        Import-Cleanups: repeat on error undo, leave Import-Cleanups:
            import stream s-ftpcmds unformatted ftp-line.
            {we_debug.i ftp-line}.
        end. /* Import-Cleanups: */
        input stream s-ftpcmds close.
        {we_debug.i "'*********** Cleanups Ends ***********'"}.
    end. /* Cleanup-Server: */
    {we_dbgproc.i Cleanup Ends}
end. /* Cleanup: */

Procedure FTP-Order-Submits:
define var ftp-cmd  as char no-undo.
define var ftp-line as char no-undo.
define var ftp-name as char no-undo.

    {we_dbgproc.i FTP-Order-Submits "Begins"} 
    if not available(tt-Controls)
    then find first tt-Controls no-error.
    output stream s-ftpinis to value(ftp-cmd-ini[1]).
    {we_dbgftp.i
        'FTP-Order-Submits' "'user ' + tt-Controls.User-Name + ' ' + 
        tt-Controls.User-Password"}
    {we_dbgftp.i 'FTP-Order-Submits' "'ascii'"}
    {we_dbgftp.i 'FTP-Order-Submits' "'cd '  + remote-submit-dir"}
    {we_dbgftp.i 'FTP-Order-Submits' "'lcd ' + local-submit-dir"}
    Get-tt-FTP-Files: for each tt-FTP-Files use-index FTP-Name:
        {we_dbgftp.i 'FTP-Order-Submits' "'get ' + tt-FTP-Files.FTP-Name"}
    end. /* Get-tt-FTP-Files: */
    {we_dbgftp.i 'FTP-Order-Submits' "'bye'"}
    output stream s-ftpinis close.
    if dbgproc&
    then message ftp-dttm + ": ********** FTP of Submits Begins **********".
    
    {we_dbgftp.i "FTP-Order-Submits" 
     "'ftp -i -n ' + ftp-verb + ' ' + tt-Controls.Remote-Submit-Addr +
            ' < ' + ftp-cmd-ini[1]"}
             
    input  stream s-ftpcmds through value(ftp-cmd).
    FTP-Files: repeat on error undo, leave FTP-Files:
        import stream s-ftpcmds unformatted ftp-line.
        if debug&
        then do:
            run Set-Dbg-DTTM.
            message dbg-dttm + ": " + prog-name + " " + ftp-line.
        end. /* if debug& */
        if ftp-line begins "226 Successfully transferred"
        then do:
            if debug&
            or ftp-verb = " -d "
            then do:
                run Set-Dbg-DTTM.
                message dbg-dttm + ": " + prog-name + " " + ftp-line.
            end. /* if debug& */
            assign
                ftp-name = entry(4,ftp-line," ")
                ftp-name = substr(ftp-name,r-index(ftp-name,"/"))
                ftp-name = trim(trim(trim(ftp-name,'/'),'"')).
            find tt-FTP-Files use-index FTP-Name
                where tt-FTP-Files.FTP-Name = ftp-name
                no-error.
            assign tt-FTP-Files.FTP& = yes.
        end.
    end. /* FTP-Files: */
    input stream s-ftpcmds close.
    if dbgproc&
    then message ftp-dttm + ": ********** FTP of Submits Ends **********".
    {we_dbgproc.i "FTP-Order-Submits" "Ends"}
end procedure. /* FTP-Order-Submits: */

Procedure Load-tt-FTP-Files:
define var ftp-cmd  as char no-undo.
define var ftp-line as char no-undo.
define var ftp-mmm  as char no-undo.
define var ftp-mm   as char no-undo.
define var ftp-dd   as char no-undo.
define var ftp-yyyy as char no-undo.
define var ftp-time as char no-undo.
define var ftp-name as char no-undo.
define var mmm      as char no-undo 
    init "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec".
define var i        as int  no-undo.
define var j        as int  no-undo.
                         
    {we_dbgproc.i "Load-tt-FTP-Files" "Begins"}
    if not available(SYS_CONTROL)
    then find first SYS_CONTROL no-lock no-error.
    if not available(tt-Controls)
    then find first tt-Controls no-error.
    assign
        /* "[TMP][PGMNAME]_FTPORDER_DTTM.ini.[FTPDTTM]" */
        ftp-cmd-ini[1] = replace(ftp-cmd-ini[4],"[TMP]",SYS_CONTROL.TEMP_DIR)
        ftp-cmd-ini[1] = replace(ftp-cmd-ini[1],"[PGMNAME]",
                                 tt-Controls.Pgm-Name)
        ftp-cmd-ini[1] = replace(ftp-cmd-ini[1],"[FTPDTTM]",ftp-dttm) 
        ftp-cmd-ini[1] = trim(ftp-cmd-ini[1],".")
        /* "[TMP][PGMNAME]_FTPORDER_DTTM.log.[FTPDTTM]" */
        ftp-cmd-log[1] = replace(ftp-cmd-log[4],"[TMP]",SYS_CONTROL.TEMP_DIR)
        ftp-cmd-log[1] = replace(ftp-cmd-log[1],"[PGMNAME]",
                                 tt-Controls.Pgm-Name)
        ftp-cmd-log[1] = replace(ftp-cmd-log[1],"[FTPDTTM]",ftp-dttm).
    output stream s-ftpinis to value(ftp-cmd-ini[1]).
    {we_dbgftp.i "Load-tt-FTP-Files" 
        "'user ' + tt-Controls.User-Name + ' ' + tt-Controls.User-Password"}
    {we_dbgftp.i "Load-tt-FTP-Files" "'ascii'"}
    {we_dbgftp.i "Load-tt-FTP-Files" "'cd ' + remote-submit-dir"}
    {we_dbgftp.i "Load-tt-FTP-Files" "'dir'"}
    {we_dbgftp.i "Load-tt-FTP-Files" "'bye'"}
    output stream s-ftpinis close.
    assign ftp-cmd =
        "ftp -i -n " + tt-Controls.Remote-Submit-Addr + " < " + 
        ftp-cmd-ini[1].
    input stream s-ftps through value(ftp-cmd).
    FTP-File-Names: repeat on error undo, leave FTP-File-Names:
        import stream s-ftps unformatted ftp-line.
        do i = 1 to length(ftp-line) by 1:
            assign ftp-line = replace(ftp-line,"ftp ftp ","ftp ftp").
        end.
        assign ftp-line = replace(ftp-line,"ftp ftp","ftp ftp ").
        /* original version 
        assign
            ftp-mmm  = entry(6,ftp-line," ")
            ftp-mm   = string(lookup(ftp-mmm,mmm),"99")
            ftp-dd   = entry(7,ftp-line," ")
            ftp-time = entry(8,ftp-line," ") + ":00"
            ftp-time = replace(ftp-time,":","")
            ftp-yyyy = string(year(today),"9999")
            ftp-name = trim(entry(9,ftp-line," "),'"')
            ftp-date = ftp-yyyy + ftp-mm + ftp-dd
            ftp-dttm = ftp-date + "@" + ftp-time.
        */
        /****
        The code below replaces the assign statement above to correct
        an issue with how the dir command was displaying on the remote 
        server.  Sometimes, instead of the HH:MM being in column 8, the 
        year was inexplicably displayed instead thus creating two space 
        delimiters between the date and the time.  This messed up the 
        parsing for the ftp-name and created an issue that killed the 
        polling program.  
        ****/
        assign
            ftp-mmm  = entry(6,ftp-line," ")
            ftp-mm   = string(lookup(ftp-mmm,mmm),"99")
            ftp-dd   = entry(7,ftp-line," ")
            ftp-time = entry(8,ftp-line," ").
        if ftp-time = "" 
        then ftp-time = "00:00".
        ftp-time = ftp-time + ":00". 
        assign
            ftp-time = replace(ftp-time,":","")
            ftp-yyyy = string(year(today),"9999")
            ftp-date = ftp-yyyy + ftp-mm + ftp-dd
            ftp-dttm = ftp-date + "@" + ftp-time
            ftp-name = trim(entry(9,ftp-line," "),'"'). 
        if ftp-name = string(year(today)) 
        then ftp-name = trim(entry(10,ftp-line," "),'"').
        /**** end of new logic ****/
        
        create tt-FTP-Files.
        assign 
            tt-FTP-Files.Type         = substr(ftp-name,1,3)
            tt-FTP-Files.Submit-Name  =
                tt-Controls.Local-Submit-Dir  + ftp-name
            tt-FTP-Files.Submit-Name  =
                replace(tt-FTP-Files.Submit-Name,
                        "[BATCHDIR]",batch-dir) 
            tt-FTP-Files.Confirm-Name =
                tt-Controls.Local-Confirm-Dir + ftp-name
            tt-FTP-Files.Confirm-Name =
                replace(tt-FTP-Files.Confirm-Name,
                        "[BATCHDIR]",batch-dir)
            tt-FTP-Files.Log-Name     = tt-FTP-Files.Submit-Name + ".out"
            tt-FTP-Files.Log-Name     =
                replace(tt-FTP-Files.Log-Name,
                        "[BATCHDIR]",batch-dir)
            tt-FTP-Files.FTP-Name     = ftp-name
            tt-FTP-Files.FTP-Date     = ftp-date
            tt-FTP-Files.FTP-Time     = ftp-time
            tt-FTP-Files.FTP-DTTM     = replace(ftp-dttm,"@","")
            tt-FTP-Files.PS-Order     = ftp-name
            tt-FTP-Files.Seed         = 
                "PS." + tt-FTP-Files.FTP-Name + "." +
                replace(replace(ftp-dttm,"@",""),":","").
        if debug&
        then do:
            display tt-FTP-Files
                with frame frm-dbg-ftpfiles 2 column title "tt-FTP-Files".
            pause.
        end.
    end. /* FTP-File-Names: */
    input stream s-ftps close.
    {we_dbgproc.i Load-tt-FTP-Files "Ends"}
end procedure. /* Load-tt-FTP-Files: */

Procedure Setup-Remote-Orders: 
    {we_dbgproc.i Setup-Remote-Orders "Begins"}
    Rem-Header: for each tt-Rem-Header use-index Seed
        break by tt-Rem-Header.Seed:
        Rem-Order: for each tt-Rem-Order use-index Seed
            where tt-Rem-Order.Seed begins tt-Rem-Header.Seed
            break by tt-Rem-Order.Seed:
            if first-of(tt-Rem-Order.Seed)
            then do:
                assign
                    ps-co     = tt-Rem-Order.Company
                    ps-operid = tt-Rem-Order.Operid
                    ps-seed   = tt-Rem-Order.Seed.
            end. /* if first-of(tt-Rem-Order.Seed) */
            {we_run.i Setup-W_ORDER}.
            if last-of(tt-Rem-Order.Seed)
            then do:
                assign
                    ps-co     = tt-Rem-Order.Company
                    ps-operid = tt-Rem-Order.Operid
                    ps-seed   = tt-Rem-Order.Seed.
            end.
        end. /* Rem-Order: */
        if debug&
        then message "tt-Rem-Header.Seed"
                "last-of(tt-Rem-Header.Seed)"              skip
                "FTSeed: [" + tt-FTP-Files.Seed      + "]" skip
                "ROSeed: [" + tt-Rem-Order.Seed      + "]" skip
                "RHSeed: [" + tt-Rem-Header.Seed     + "]" skip
                "RHOCnt: [" + tt-Rem-Header.OrderCnt + "]" skip
                view-as alert-box title "last-of(tt-Rem-Header.Seed)".
    end. /* Rem-Header: */
    {we_dbgproc.i Setup-Remote-Orders "Ends"}
end procedure. /* Setup-Remote-Orders: */

Procedure Setup-W_ORDER:
define var w-shipstr as char no-undo.
define var w-mm      as int  no-undo.
define var w-dd      as int  no-undo.
define var w-yyyy    as int  no-undo.
    {we_dbgproc.i Setup-W_ORDER "Begins"}
    find CUSTOMER
        where CUSTOMER.CO       = tt-Rem-Header.Company
          and CUSTOMER.CUSTOMER = tt-Rem-Order.Customer
        no-lock no-error.
    
    create W_ORDER.
    assign
        W_ORDER.W_TIMESTAMP   = tt-Rem-Order.StampDTTM
        W_ORDER.W_CO          = CUSTOMER.CO
        W_ORDER.W_STAMP_OP    = tt-Rem-Order.OperID
        W_ORDER.W_MESS        = tt-Rem-Order.OrderMsg
        W_ORDER.W_CUSTOMER    = tt-Rem-Order.Customer
        W_ORDER.W_NAME        = tt-Rem-Order.Name
        W_ORDER.W_PO          = tt-Rem-Order.PO         /* optional */
        W_ORDER.W_SHIP_STR    = tt-Rem-Order.ShipStr    /* optional */
        W_ORDER.W_SHIP_INSTR  = tt-Rem-Order.ShipInst   /* optional */
        W_ORDER.W_AR_INSTR    = tt-Rem-Order.ARInst     /* optional */
        W_ORDER.W_SEED        = tt-Rem-Order.SEED
        W_ORDER.W_SHIPTO_CUST = tt-Rem-Order.ShipToCust
        W_ORDER.W_SHIPTO_NO   = tt-Rem-Order.ShipToNo
        W_ORDER.W_SHIPNAME    = tt-Rem-Order.ShipName
        W_ORDER.W_SHIPATTN    = tt-Rem-Order.ShipAttn
        W_ORDER.W_SHIPADDR[1] = tt-Rem-Order.ShipAddr[1]
        W_ORDER.W_SHIPADDR[2] = tt-Rem-Order.ShipAddr[2]
        W_ORDER.W_SHIPADDR[3] = tt-Rem-Order.ShipAddr[3]
        W_ORDER.W_SHIPCITY    = tt-Rem-Order.ShipCity[1]
        W_ORDER.W_SHIPSTATE   = tt-Rem-Order.ShipState
        W_ORDER.W_SHIPJUR     = CUSTOMER.JUR
        W_ORDER.W_SHIPZIP     = tt-Rem-Order.ShipZip
        W_ORDER.W_SHIPPHONE   = 
            replace(
                replace(
                    replace(tt-Rem-Order.ShipPhone,"(",""),")",""),"-","") 
        W_ORDER.W_SHIPFAX     = 
            replace(
                replace(
                    replace(tt-Rem-Order.ShipFax,"(",""),")",""),"-","")
        W_ORDER.W_FAXBACK     =
            replace(
                replace(
                    replace(tt-Rem-Order.FaxBack,"(",""),")",""),"-","")
        W_ORDER.W_LNE_CNT     = dec(tt-Rem-Order.LineCnt)
        W_ORDER.W_SHIP_VIA    = tt-Rem-Order.ShipVia
        W_ORDER.W_CASH        = tt-Rem-Order.Cash
        W_ORDER.W_OID         = tt-Rem-Order.LaptopID
        W_ORDER.W_ORDER       = tt-Rem-Order.Order.
    assign
        w-shipstr = trim(W_ORDER.W_SHIP_STR)
        w-shipstr = if w-shipstr > ""
                    and length(w-shipstr) = 8
                    then substr(w-shipstr,5,2) + "/" +
                         substr(w-shipstr,7,2) + "/" +
                         substr(w-shipstr,1,4)
                    else ?.
        W_ORDER.W_SHIP_DT = date(w-shipstr).
    {we_run.i "u/u_date.p" "(input w-shipstr, output W_ORDER.W_SHIP_DT)"}.
    if debug&
    then message "DEBUG create W_ORDER" skip
            "RHSeed: [" + tt-Rem-Header.Seed + "]" skip
            "ROSeed: [" + tt-Rem-Order.Seed  + "]" skip
            "WOSeed: [" + W_ORDER.W_SEED     + "]" skip
            view-as alert-box title "create W_ORDER".
    {we_run.i Setup-W_ITEM}.
    if witem-cnt = 0
    then do:
        assign
            messages-line     = ""
            messages-lines[1] = "ORDER DELETED"
            messages-lines[2] = "Header: [" + tt-Rem-Header.Seed + "]"
            messages-lines[3] = " Order: [" + tt-Rem-Order.Seed  + "]"
            messages-dsn      = tt-Rem-Header.LogFile.
        run Messages.
        delete W_ORDER.
    end.
    {we_dbgproc.i Setup-W_ORDER "Ends"}
end procedure. /* Setup-W_ORDER: */

Procedure Setup-W_ITEM:
{we_dbgproc.i Setup-W_ITEM "Begins"}

assign witem-cnt = 0.
Rem-Item: for each tt-Rem-Item use-index Seed
    where tt-Rem-Item.Seed begins tt-Rem-Order.Seed
      and tt-Rem-Item.RecType = "ORDITEM":
    if int(tt-LTO-Lines.QtyOrd) < 0 /* Order Quantity by Velocity */
    then do:
        find VELOCITY
            where VELOCITY.CO = C[1]
              and VELOCITY.CUSTOMER = W_ORDER.W_CUSTOMER
              and VELOCITY.ITEM     = trim(tt-LTO-Lines.Item)
              and VELOCITY.UNIT     = trim(tt-LTO-Lines.Unit)
            exclusive-lock no-error.
        if available(VELOCITY)
        then do:
            assign VELOCITY.REORDER& = no.
            if enable-filelog&
            then {we_run.i u/u_fillog.p 
                    "(input (if VELOCITY.REORDER& = no then 'D' else 'C') +
                           ',VELOCITY,' + VELOCITY.CUSTOMER + ',' +
                           VELOCITY.ITEM + ',' + VELOCITY.UNIT)"}.
        end. /* if available(VELOCITY) */
        assign W_ORDER.W_LNE_CNT = W_ORDER.W_LNE_CNT - 1.
    end. /* if int(tt-LTO-Lines.ShipQty) < 0 */
    else do:
        find ITEM
            where ITEM.CO   = tt-Rem-Header.Company
              and ITEM.ITEM = tt-Rem-Item.Item
            no-lock no-error.
        do i = 1 to 3 by 1:
            if ITEM.UNIT[i] begins trim(tt-LTO-Lines.Unit) then leave.
        end. /* do i = 1 to 3 by 1: */
        if int(tt-Rem-Item.QtyOrd) > 0
        then do:
            create W_ITEM.
            assign 
                witem-cnt             = witem-cnt + 1
                W_ITEM.W_ITEM         = tt-Rem-Item.Item
                W_ITEM.W_SEED         = tt-Rem-Item.Seed
                W_ITEM.W_QTY          = int(tt-Rem-Item.QtyOrd)
                W_ITEM.W_UNIT         = tt-Rem-Item.Unit
                W_ITEM.W_PRICE        = 
                    if trim(tt-Rem-Item.Pricing) = "T"
                    /**/
                    or (trim(tt-Rem-Item.Pricing) = "O"
                    and (W_ORDER.W_CUSTOMER = "  4719"
                         or can-find (first CUST_LIST
                                      where CUST_LIST.CO = C[1]
                                  and CUST_LIST.CUST_LIST = " 293"
                                  and CUST_LIST.CUSTOMER = W_ORDER.W_CUSTOMER)))
                    /**/
                    then dec(tt-Rem-Item.Price) else dec(0.00)
                W_ITEM.W_PRICING      =
                    if trim(tt-Rem-Item.Pricing) = "T"
                    /**/
                    then (if (W_ORDER.W_CUSTOMER = "  4719"
                         or can-find (first CUST_LIST
                                      where CUST_LIST.CO = C[1]
                                   and CUST_LIST.CUST_LIST = " 293"
                                   and CUST_LIST.CUSTOMER = W_ORDER.W_CUSTOMER))                          then "MNT"
                          else "MN")
                    else if (trim(tt-Rem-Item.Pricing) = "O"
                         and (W_ORDER.W_CUSTOMER = "  4719"
                         or can-find (first CUST_LIST
                                     where CUST_LIST.CO = C[1]
                                  and CUST_LIST.CUST_LIST = " 293"
                                  and CUST_LIST.CUSTOMER = W_ORDER.W_CUSTOMER)))
                    then "MN"
                    /**/
                    else ""
                W_ITEM.W_LINE         = int(tt-Rem-Item.Line)
                W_ITEM.W_TAX          = tt-Rem-Item.Tax
                W_ITEM.W_COMMENT      = trim(tt-Rem-Item.Comment)
                W_ITEM.W_COMMENT_TYPE =
                    (if trim(tt-Rem-Item.CommentType) = "2"
                     then "I"
                     else if trim(tt-Rem-Item.CommentType) = "3"
                          then "P" else "A")
                W_ITEM.W_UNITNUM      = dec(i)
                W_ITEM.W_DESCR        = ITEM.DESCRIPTION
                W_ITEM.W_SC           = 0.
            if debug&
            then message "tt-Rem-Item Create"   skip
                    "RHS:" tt-Rem-Header.Seed   skip
                    "ROS:" tt-Rem-Order.Seed    skip
                    "RIS:" tt-Rem-Item.Seed     skip
                    "WOS:" W_ORDER.W_SEED       skip
                    "WIS:" W_ITEM.W_SEED        skip
                    view-as alert-box.
        end. /* if int(tt-Rem-Item.QtyOrd) > 0 */
        if trim(tt-Rem-Item.Pricing) = "O"
        or trim(tt-Rem-Item.Pricing) = "R"
        then do:
            create tt-Rem-Quote.
            {ps_order_remquote.asg}
            if debug&
            then message
                    "DEBUG create tt-Rem-Quote" skip
                    "  QCo: [" + tt-Rem-Quote.Company   + "]" skip
                    "QCust: [" + tt-Rem-Quote.Customer  + "]" skip
                    "RIPrc: [" + tt-Rem-Item.Price      + "]" skip
                    "RIMg%: [" + tt-Rem-Item.Margin%    + "]" skip
                    "QMAmt: [" + tt-Rem-Quote.MarkupAmt + "]" skip
                    "CnfID: [" + ConfirmationID         + "]" skip
                    "QSeed: [" + tt-Rem-Quote.Seed      + "]" skip
                    view-as alert-box title "create tt-Rem-Quote".
            if tt-Rem-Quote.Customer = "" then delete tt-Rem-Quote.
        end. /* if tt-Rem-Item.Pricing = "O" */
    end. /* else - if int(tt-LTO-Lines.ShipQty) < 0 */
    if debug&
    then message "DEBUG create W_ITEM" skip
            "ROCust: [" + tt-Rem-Order.Customer        + "]" skip
            "RIItem: [" + tt-Rem-Item.Item             + "]" skip
            "ROUnit: [" + tt-Rem-Item.Unit             + "]" skip
            "WOCust: [" + W_ORDER.W_CUSTOMER           + "]" skip
            "WIItem: [" + W_ITEM.W_ITEM                + "]" skip
            "WIUnit: [" + W_ITEM.W_UNIT                + "]" skip(1)
            "RHSeed: [" + tt-Rem-Header.Seed           + "]" skip
            "ROSeed: [" + tt-Rem-Order.Seed            + "]" skip
            "RISeed: [" + tt-Rem-Item.Seed             + "]" skip
            "WOSeed: [" + W_ORDER.W_SEED               + "]" skip
            "WISeed: [" + W_ORDER.W_SEED               + "]" skip
            "WILine: [" + string(W_ITEM.W_LINE,"9999") + "]" skip
            view-as alert-box title "create W_ITEM".
end. /* Rem-Item: */
{we_dbgproc.i Setup-W_ITEM "Ends"}
end procedure. /* Setup-W_ITEM: */

Procedure Submit-Remote-Orders:
    {we_dbgproc.i Submit-Remote-Orders "Begins"}
    
    if can-find(first tt-Rem-Quote)
    then do:
        {we_dbgproc.i Process-Quotes "Begins"}
        /* *****
        Process-Quotes: for each tt-Rem-Quote use-index Seed:
            if tt-Rem-Quote.Customer = ""
            then do:
                delete tt-Rem-Quote.
                next Process-Quotes.
            end. /* if tt-Rem-Quote.Customer = "" */
            if debug&
            then display tt-Rem-Quote
                with frame frm-remquote 2 column title "Before Run".
            assign quote-rid = recid(tt-Rem-Quote).
        ***** */
            {we_run.i ps/ps_oremqt.p}.
        /* end. /* Process-Quotes: */ */
        {we_dbgproc.i Process-Qutoes "Ends"} 
        for each tt-Rem-Quote: delete tt-Rem-Quote. end.
    end. /* if can-find(first tt-Rem-Quote) */

    {we_run.i ps/ps_oremote.p}. /* Load W_ORDER/W_ITEM into ORDER/ORDER_ITEM */

    if available(POLL_LOG_HDR)
    then do transaction:
        create POLL_LOG.
        assign
            POLL_LOG.POLLER_LOG_ID  = "OF" +
                trim(CALL_REMOTE.LAPTOP_ID) + start-dttm
            POLL_LOG.STAMP_DT       = start-dt
            POLL_LOG.DATE_          = POLL_LOG_HDR.DATE_
            POLL_LOG.STAMP_TM       = start-tm
            POLL_LOG.STAMP_DTTM     = start-dttm
            POLL_LOG.TRANS_TYPE     = "OF"  /* for Order Finished */
            POLL_LOG.LAPTOP_ID      = CALL_REMOTE.LAPTOP_ID
            POLL_LOG.CALL_          = call-number
            POLL_LOG.PID            = string(dest-pid)
            POLL_LOG.PORT           = string(dest-port )
            POLL_LOG.TEXT_[1]       = "Processed " + 
                string(ordr-entries)   + " orders and " + 
                string(pickup-entries) + " pickups".
        for each W_ORDER
            where W_ORDER.W_ORDER > "" no-lock
            by W_ORDER.W_ORDER:
            assign POLL_LOG.TEXT_[2] = POLL_LOG.TEXT_[2] + 
                string(W_ORDER.W_ORDER, "XXXXXX-XX") + ",".
        end.
        if POLL_LOG.TEXT_[2] > ""
        then POLL_LOG.TEXT_[2] = substr(POLL_LOG.TEXT_[2],1,
                                        length(POLL_LOG.TEXT_[2]) - 1).
    end. /* if available(POLL_LOG_HDR) */
    {we_dbgproc.i Submit-Remote-Orders "Ends"}
end procedure. /* Submit-Remote-Orders: */

Procedure Load-Order-Confirmations:
define var company      as char no-undo format "x(003)".
define var customer     as char no-undo format "x(010)".
define var order        as char no-undo format "x(010)".
define var price        as char no-undo format "x(008)".
define var netprice     as char no-undo format "x(008)".
define var confirm-line as char no-undo format "x(060)".
    {we_dbgproc.i Load-Order-Confirmations "Begins"}
    Process-Orders: for each tt-FTP-Files use-index Seed
        where tt-FTP-Files.Type = "LTO",
        each tt-Rem-Header use-index Seed
        where tt-Rem-Header.Seed begins tt-FTP-Files.Seed,
        each tt-Rem-Order  use-index Seed
        where tt-Rem-Order.Seed begins tt-Rem-Header.Seed,
        each W_ORDER use-index W_SEED
        where W_ORDER.W_SEED = tt-Rem-Order.Seed
        break by tt-FTP-Files.Seed by tt-Rem-Header.Seed by tt-Rem-Order.Seed:
        if first-of(tt-Rem-Header.Seed)
        then do:
            create tt-Confirm-Header.
            buffer-copy tt-Rem-Header to tt-Confirm-Header.
            assign tt-Confirm-Header.OrderCnt = "0000".
            if debug&
            then do:
                message "tt-Confirm-Header Create"          skip
                    "RHdr:" available(tt-Rem-Header)        skip
                    "ROrd:" available(tt-Rem-Order)         skip
                    "CHdr:" available(tt-Confirm-Header)    skip
                    " FTP:" tt-FTP-Files.Seed               skip
                    " WOS:" W_Order.W_Seed                  skip
                    " RHS:" tt-Rem-Header.Seed              skip
                    " ROS:" tt-Rem-Order.Seed               skip
                    " CHS:" tt-Confirm-Header.Seed          skip
                    view-as alert-box.
            end. /* if debug& */ 
        end. /* if first-of(tt-Rem-Header.Seed) */
        if first-of(tt-Rem-Order.Seed)
        then do:
            create tt-Confirm-Order.
            buffer-copy tt-Rem-Order  to tt-Confirm-Order.
            assign
                tt-Confirm-Order.Company   = W_ORDER.W_CO
                tt-Confirm-Order.Customer  = W_ORDER.W_CUSTOMER
                tt-Confirm-Order.Order     = W_ORDER.W_ORDER
                tt-Confirm-Order.Msg       = W_ORDER.W_MESS
                tt-Confirm-Order.LineCnt   = "0000"
                tt-Confirm-Header.OrderCnt =
                    string(int(tt-Confirm-Header.OrderCnt) + 1,"9999").
            if debug&
            then do:
                message "tt-Confirm-Order Create"        skip
                    "RHdr:" available(tt-Rem-Header)     skip
                    "ROrd:" available(tt-Rem-Order)      skip
                    "CHdr:" available(tt-Confirm-Header) skip
                    " FTP:" tt-FTP-Files.Seed            skip
                    " WOS:" W_Order.W_Seed               skip
                    " RHS:" tt-Rem-Header.Seed           skip
                    " ROS:" tt-Rem-Order.Seed            skip
                    " CHS:" tt-Confirm-Header.Seed       skip
                    view-as alert-box.
            end. /* if debug& */
        end. /* if first-of(tt-Rem-Order.Seed) */

        Process-W_ITEM: for each W_ITEM use-index W_SEED
            where W_ITEM.W_SEED begins W_ORDER.W_SEED
            by W_ITEM.W_SEED by W_ITEM.W_LINE:
            find first tt-Rem-Item use-index SEED
                where tt-Rem-Item.Seed = W_ITEM.W_SEED
                  and not tt-Rem-Item.Processed&
                no-error.
            find ORDER_ITEM use-index ORDER_LINE
                where ORDER_ITEM.CO    = W_ORDER.W_CO
                  and ORDER_ITEM.ORDER = W_ORDER.W_ORDER
                  and ORDER_ITEM.LINE  = W_ITEM.W_LINE
                no-lock no-error.
            find ITEM_UNIT
                where ITEM_UNIT.CO   = W_ORDER.W_CO
                  and ITEM_UNIT.ITEM = W_ITEM.W_ITEM
                  and ITEM_UNIT.UNIT = W_ITEM.W_UNIT
                no-lock no-error.
            create tt-Confirm-Item.
            buffer-copy tt-Rem-Item to tt-Confirm-Item.
            assign
                tt-Confirm-Item.Company  = W_ORDER.W_CO
                tt-Confirm-Item.Customer = W_ORDER.W_CUSTOMER
                tt-Confirm-Item.Order    = W_ORDER.W_ORDER
                tt-Confirm-Item.LineNo   = string(W_ITEM.W_LINE,"9999")
                tt-Confirm-Item.Item     = W_ITEM.W_ITEM
                tt-Confirm-Item.Cost     =
                    if available(ORDER_ITEM)
                    then if ORDER_ITEM.SLS_COST >= 0
                         then string((ORDER_ITEM.SLS_COST * 100),"99999999")
                         else string((ORDER_ITEM.SLS_COST * 100),"-9999999")
                    else if W_ITEM.W_SC >= 0
                         then string((W_ITEM.W_SC * 100),"99999999")
                         else string((W_ITEM.W_SC * 100),"-9999999")
                tt-Confirm-Item.Pricing  = 
                    if available(ORDER_ITEM)
                    then ORDER_ITEM.PRICING else W_ITEM.W_PRICING
                tt-Confirm-Item.NetPrice =
                    if available(ORDER_ITEM)
                    then if ORDER_ITEM.PRICE >= 0
                         then string((ORDER_ITEM.PRICE * 100),"99999999")
                         else string((ORDER_ITEM.PRICE * 100),"-9999999")
                    else string(0,"99999999")
                tt-Confirm-Item.QtyShip  = 
                    if W_ITEM.W_QTY >= 0
                    then string(W_ITEM.W_QTY,"9999")
                    else string(W_ITEM.W_QTY,"-999")
                tt-Confirm-Item.WtShip   = 
                    if available(ORDER_ITEM)
                    then if W_ITEM.W_WT_SHIP >= 0
                         then string((W_ITEM.W_WT_SHIP * 10000),"99999999")
                         else string((W_ITEM.W_WT_SHIP * 10000),"-9999999")
                    else string(0,"99999999")
                tt-Confirm-Item.PSItem   = ITEM_UNIT.SPS_ITEM
                tt-Confirm-Order.LineCnt =
                    string(int(tt-Confirm-Order.LineCnt) + 1,"9999")
                tt-Rem-Item.Processed&   = yes
                tt-Confirm-Item.Msg = fill(" ",30).
            if tt-Confirm-Order.LineCnt > "9990"
            then do:
                message "tt-Confirm-Order.LineCnt" tt-Confirm-Order.LineCnt.
                quit.
            end. /* if tt-Confirm-Order.LineCnt > "9990" */
            if debug&
            then do:
                message "tt-Confirm-Item Create - Part1"    skip
                    "RHdr:" available(tt-Rem-Header)        skip
                    "ROrd:" available(tt-Rem-Order)         skip
                    "RItm:" available(tt-Rem-Item)          skip
                    "CHdr:" available(tt-Confirm-Header)    skip
                    "COrd:" available(tt-Confirm-Order)     skip
                    "CItm:" available(tt-Confirm-Item)      skip
                    view-as alert-box.
                message "tt-Confirm-Item Create - Part2"    skip
                    " FTP:" tt-FTP-Files.Seed               skip
                    " WOS:" W_ORDER.W_SEED                  skip
                    " WIS:" W_ITEM.W_SEED                   skip
                    " RHS:" tt-Rem-Header.Seed              skip
                    " ROS:" tt-Rem-Order.Seed               skip
                    " RIS:" tt-Rem-Item.Seed                skip
                    " CHS:" tt-Confirm-Header.Seed          skip
                    " COS:" tt-Confirm-Order.Seed           skip
                    " CIS:" tt-Confirm-Item.Seed            skip
                    " WOS:" W_ORDER.W_SEED                  skip
                    " WIS:" W_ITEM.W_SEED                   skip
                    view-as alert-box.
            end. /* if debug& */
        end. /* Process-W_ITEM: */
    end. /* Process-Orders: */
    {we_dbgproc.i Load-Order-Confirmations "Ends"}
end procedure. /* Load-Order-Confirmations: */

Procedure Process-Order-Confirmations:
/* *****
Confirmations:
    At the end of the confirmation will be the parseable section of the order.
We need to decide a protocol for what is returned. Most installations only send
back order exceptions - variances in quantity, price, or substitution. You may
want to create a line for every item ordered.

Parsed section details:
POWERSELL DATA FOLLOWS                      //Trigger line
ccccccccccmmtoooooooooo                     //Order info line
xxxxxxxxxxqqqqeppppppppccccccccssssssssss   //Item line - repeat as needed
.
POWERSELL ORDER END                         //multi-order separator line
Ccccccccccmmtoooooooooo                     //Order info line
xxxxxxxxxxqqqqeppppppppccccccccssssssssss   //Item line - repeat as needed
.
POWERSELL DATA END                          //End line
Symbol      Length  Value
cccccccccc  10      Customer number - left justified - padded with spaces
mm          2 or 3  Memo number - size tied to Admin setting for memo size
t           1       Order type - blank if not custom coded
oooooooooo  10      Order number assigned by host
xxxxxxxxxx  10      Item number - left justified - padded with spaces
qqqq        4       Quantity shipped
e           1       Y=broken case; N=case
pppppppp    8       Net Sell Price
cccccccc    8       Net Cost
ssssssssss  30      Substitute item number or other error message- left
                    justified - padding not needed

Additions: 12/19/2016
Section for Order Status - Can be used alone or with the Parsed section detail.
Order Status Details - MUST BE OUTSIDE (BEFORE OR AFTER) Parsed section details
PSELL ORDER STATUS //trigger line
ooooooo //status line, one line ONLY containing ONE of the values below
Symbol      Length  Value
ooooooo     7 (max) Order Status - must be one of the following:
                        GOOD //no changes, order good
                        HRDERR //hard error
                        CRHOLD //hold
                        CHANGED //order changed - substitute, shorted items,
                            price changes, price warnings and/or out of stock
                            items
                        Note: 1). The status will be displayed in a field in the
                              Transmitted Order Header. Coloring of the various
                              status states can be set in PowerSellAdmin
                              5.7.1.21 or higher.
                              2). If a parseable section is available, coloring
                              for OUTOFSTOCK, SHORTED, SUBSTITUTED, PRICECHNG,
                              & BOTHCHG items can also be controlled IF the
                              PSELL ORDER STATUS is set to CHANGED.
***** */
define var companyNum      as char no-undo format "x(003)".
define var customerNum     as char no-undo format "x(10)".
define var orderNum       as char no-undo format "x(10)".
define var type         as char no-undo format "x".
define var confirm-line as char no-undo format "x(60)".
define var cItem        as char no-undo.
define variable lineNum   as character no-undo.
define variable cUnit   as character no-undo.
define variable qtyOrd as character no-undo.
define variable qtyShip     as character no-undo.
define variable cSub         as character no-undo.
define variable stockStatus as character no-undo.
define variable itemDesc as character no-undo format "x(30)".
define variable customerName as character no-undo.
define variable shipDate as date no-undo.
define variable shipVia as character no-undo.
define variable extPrice as decimal no-undo.
define variable lException as logical no-undo.

define buffer bufOrder for order.
define buffer bufOrder_hold for order_hold.
define buffer bufItem for item.


    {we_dbgproc.i Process-Order-Confirmations "Begins"}
    Process-Confirm-Files: for each tt-FTP-Files use-index Seed /* FTPFiles */
        where tt-FTP-Files.Type = "LTO",
        each tt-Confirm-Header use-index Seed                   /* Conf Hdr */
        where tt-Confirm-Header.Seed begins tt-FTP-Files.Seed,
        each tt-Confirm-Order  use-index Seed                   /* Conf Ord */
        where tt-Confirm-Order.Seed begins tt-Confirm-Header.Seed
        break by tt-FTP-Files.Seed
              by tt-Confirm-Header.Seed
              by tt-Confirm-Order.Seed:
        if first-of(tt-Confirm-Header.Seed)
        then do:
            assign
                outfile      = tt-Confirm-Header.OutFile
                messages-dsn = tt-Confirm-Header.LogFile.
            output stream s-confirms to value(outfile).
            if debug&
            then do:
                run Set-Dbg-DTTM.
                message
                    dbg-dttm + ": if first-of(tt-Confirm-Header.Seed)"  skip
                    "OutFile: [" + outfile      + "]"                   skip
                    "LogFile: [" + logfile      + "]"                   skip
                    "CnfLine: [" + confirm-line + "]"                   skip
                    view-as alert-box
                        title "Debug - Process-Order-Confirmations".
            end. /* if debug& */
        end. /* if first-of(tt-Confirm-Header.Seed) */
        if first-of(tt-Confirm-Order.Seed)
        then do:
            /* Print Order Header ******************************************** */
            assign
                ordercnt        = int(tt-Confirm-Header.OrderCnt)
                cntorder        = 0
                companyNum      = tt-Confirm-Order.Company
                customerNum     = tt-Confirm-Order.Customer
                orderNum        = tt-Confirm-Order.Order
                .
            find customer where
                 customer.co        = tt-Confirm-Order.Company and
                 customer.customer  = tt-Confirm-Order.Customer no-lock no-error.

            find bufOrder where
                 bufOrder.co        = tt-Confirm-Order.Company and
                 budOrder.order     = tt-Confirm-Order.Order no-lock no-error.
                 
            
            assign 
                customerName = if available customer then customer.name else " "
                shipDate     = if available bufOrder then bufOrder.SHIP_DT else ?
                shipVia      = if available bufOrder then bufOrder.SHIP_VIA else " ".
                 
            put stream s-confirms unformatted substitute("Order confirmation for order &1",orderNum) skip.
            put stream s-confirms unformatted substitute("Cutomer &1 &2",customerNum,customerName) skip.
            put stream s-confirms unformatted substitute("Ship date: &1 Ship Via: &2",string(shipDate,"99/99/9999"),shipVia) skip skip.
            
            /* Line Item Header ******************************************************************* */
            assign 
                confirm-line = 
                    "Line " +
                    "Item       " +
                    "Description                   " + 
                    "Unit " +
                    "QtyO " +
                    "QtyS " +
                    "Ext      " +        /* Net Price */
                    "Sub  " +
                    "Status ".
            put stream s-confirms unformatted confirm-line skip.
            
            if debug&
            then do:
                run Set-Dbg-DTTM.
                message
                    dbg-dttm + ": " + "if first-of(tt-Confirm-Order.Seed)"
                        skip
                    "CnfLine: [" + confirm-line + "]" skip
                    view-as alert-box
                        title "Debug - Process-Order-Confirmations".
            end. /* if debug& */
        end. /* if first-of(tt-Confirm-Order.Seed) */
        assign cntorder = cntorder + 1.
        Process-Confirm-Items: for each tt-Confirm-Item use-index Seed
            where tt-Confirm-Item.Seed begins tt-Confirm-Order.Seed:
            find ORDER_ITEM
                where ORDER_ITEM.CO    = tt-Confirm-Order.Company /* ORDER.CO */
                  and ORDER_ITEM.ORDER = tt-Confirm-Item.Order /* ORDER.ORDER */
                  and ORDER_ITEM.ITEM  = tt-Confirm-Item.ITEM
                  and ORDER_ITEM.UNIT  = tt-Confirm-Item.Unit
                no-error.
            if not available(ORDER_ITEM)
            then do:
                assign
                    messages-line     = ""
                    messages-lines[1] =
                           "[N/A ORDER_ITEM] "                             +
                           "       Co:[" + tt-Confirm-Order.Co       + "]" +
                           " Customer:[" + tt-Confirm-Order.Customer + "]"
                    messages-lines[2] =
                           "[N/A ORDER_ITEM] "                             +
                           "    Order:[" + tt-Confirm-Item.Order     + "]" +
                           "     Line:[" + tt-Confirm-Item.Line      + "]"
                    messages-lines[3] =
                           "[N/A ORDER_ITEM] "                       +
                           "     Item:[" + tt-Confirm-Item.Item      + "]" +
                           "     Unit:[" + tt-Confirm-Item.Unit      + "]".
                run Set-Dbg-DTTM.
                run Messages.
            end. /* if not available(ORDER_ITEM) */ 

            else if available(ORDER_ITEM) 
            then do:            
                find first bufItem where 
                    bufItem.CO   = ORDER_ITEM.CO and
                    bufItem.ITEM = ORDER_ITEM.ITEM
                    no-lock no-error.
                
                assign
                    cntline = cntline + 1
                    cItem    = ORDER_ITEM.ITEM
                    cItem    = cItem + fill(" ",10 - length(cItem))
                    itemDesc = tt-Confirm-Item.ItemDesc
                    cLine = string(ORDER_ITEM.LINE,"9999")
                    cUnit = ORDER_ITEM.UNIT
                    cQtyOrd = string(ORDER_ITEM.QTY_ORD,"-9999")
                    cQtyShip = string(ORDER_ITEM.QTY_SHIP,"-9999")
                    extPrice = string(ORDER_ITEM.EXTEND,"$-9999.99"          
                    cSub     = string(ORDER_ITEM.SUB&)
                    cStockStatus = if available item then ITEM.STOCK_STATUS else "N/A" no-error.                                 
                    
                    
                put stream s-confirms unformatted substitute("&1 &2 &3 &4 &5 &6 &7 &8   &9",cLine,cItem,itemDesc,cUnit,cQtyOrd,cQtyShip,extPrice,cSub,cStockStatus) skip.
                
                if ORDER_ITEM.SUB& = yes then
                    assign lException = yes.     
            end. /* Avail ORDER_ITEM */
                        
            if debug&
            then do:
                run Set-Dbg-DTTM.
                message
                    dbg-dttm + ": " + "Process-Confirm-Items" skip
                    "CnfLine: [" + confirm-line + "]"         skip
                    view-as alert-box
                        title "Debug - Process-Order-Confirmations".
            end. /* if debug& */ 
        end. /* Process-Confirm-Items: */
        {we_dbgproc.i "if last-of(tt-Confirm-Order.Seed)" Here}
        if last-of(tt-Confirm-Order.Seed)
        then do:
            if not ordercnt = cntorder
            then do:
                assign confirm-line = "POWERSELL ORDER END".
                put stream s-confirms unformatted confirm-line skip.
                if debug&
                then do:
                    run Set-Dbg-DTTM.
                    message
                        dbg-dttm + ": " + "if not ordercnt = cntorder" skip
                        "CnfLine: [" + confirm-line + "]"              skip
                        view-as alert-box
                            title "Debug - Process-Order-Confirmations".
                end. /* if debug& */
            end. /* if not ordercnt = cntorder */
        end. /* if last-of(tt-Confirm-Order.Seed) */
        {we_dbgproc.i "if last-of(tt-Confirm-Header.Seed)" Here}
        if last-of(tt-Confirm-Header.Seed)
        then do:
/*            assign confirm-line = "POWERSELL DATA END".         */
/*            put stream s-confirms unformatted confirm-line skip.*/
/*            assign confirm-line = "PSELL ORDER STATUS".         */
/*            put stream s-confirms unformatted confirm-line skip.*/
/*            assign confirm-line = "GOOD".                       */
/*            put stream s-confirms unformatted confirm-line skip.*/

            /* Print Order Footer ****************************************************************** */
          
            find first bufOrder_hold no-lock where 
                       bufOrder_hold.co = tt-Confirm-Order.company and
                       bufOrder_hold.order = tt-Confirm-Order.company) no-error. 
            if available bufOrder_hold then
                do:                        
                    put stream s-confirms unformatted substitute("***WARNING ORDER MAY NOT SHIP. ORDER IS ON &1 HOLD",bufOrder_hold.type) no-error.                     
                end.
                        
            is lException = yes then
                put stream s-confirms unformatted "Order Status: There is an order Exception" skip.
            else
                put stream s-confirms unformatted "Order Status: Good" skip.
                    
            
              
            
            {we_dbgproc.i "output stream s-confirms close" Here}
            output stream s-confirms close.
            run Set-Dbg-DTTM.
            assign
                messages-line = trim(tt-Confirm-Header.InFile)
                messages-line =
                    substr(messages-line,r-index(messages-line,"/"))
                messages-line =
                    dttm + "-" + prog-name + ": Confirmation for" + 
                    messages-line.
            message messages-line.
        end. /* if last-of(tt-Confirm-Header.Seed) */
    end. /* Process-Confirm-Files: */
    {we_dbgproc.i Process-Order-Confirmations "Ends"}
end procedure. /* Process-Order-Confirmations: */

Procedure FTP-Order-Confirmations:
define var ftp-cmd      as char no-undo.
define var ftp-line     as char no-undo.
    {we_dbgproc.i FTP-Order-Confirmations Begins}
    assign
        ftp-cmd-ini[1] = replace(ftp-cmd-ini[3],"[TMP]",temp-dir)
        ftp-cmd-ini[1] =
            replace(ftp-cmd-ini[1],"[PGMNAME]",prog-name)
        ftp-cmd-ini[1] = replace(ftp-cmd-ini[1],"[FTPDTTM]",ftp-dttm)
        ftp-cmd-log[1] = replace(ftp-cmd-log[3],"[TMP]",temp-dir)
        ftp-cmd-log[1] =
            replace(ftp-cmd-log[1],"[PGMNAME]",prog-name)
        ftp-cmd-log[1] = replace(ftp-cmd-log[1],"[FTPDTTM]",ftp-dttm).
    if debug&
    then do:
        run Set-Dbg-DTTM.
        message
            dbg-dttm + " "   + prog-name + ": FTP-Order-Confirmations"  skip
            "   temp-dir: [" + temp-dir       + "]"                     skip
            "   ftp-dttm: [" + ftp-dttm       + "]"                     skip
            "ftp-cmd-ini: [" + ftp-cmd-ini[1] + "]"                     skip
            "ftp-cmd-log: [" + ftp-cmd-log[1] + "]"
            view-as alert-box title "FTP-Order-Confirmations".
    end. /* if debug& */
    {we_dbgftp.i "FTP-Order-Confirmations"
        "output stream s-ftpinis to value(ftp-cmd-ini[1])"}.
    {we_dbgftp.i "FTP-Order-Confirmations" "'user ' + tt-Controls.User-Name +
        ' ' + tt-Controls.User-Password"}
    {we_dbgftp.i "FTP-Order-Confirmations" "'ascii'"}
    {we_dbgftp.i "FTP-Order-Confirmations" "'cd '   + remote-confirm-dir"}
    {we_dbgftp.i "FTP-Order-Confirmations" "'lcd '  + local-confirm-dir"}
    Put-Confirms: for each tt-FTP-Files use-index Seed
        where tt-FTP-Files.Type = "LTO":
        {we_dbgftp.i "Put-Confirms" "'put ' + substr(tt-FTP-Files.Confirm-Name,
                              r-index(tt-FTP-Files.Confirm-Name,'/') + 1)"}
    end. /* Put-Confirms: */
    {we_dbgftp.i "FTP-Order-Confirmations" "'bye'"}
    {we_dbgftp.i "FTP-Order-Confirmations" "output stream s-ftpinis close"}.
    unix silent 
        value("/bin/chmod 777 " + SYS_CONTROL.TEMP_DIR +
              tt-Controls.Pgm-Name + "*").
    
    {we_dbgftp.i "FTP-Order-Confirmations" "'ftp -i -n ' + ftp-verb + ' ' +
        tt-Controls.Remote-Confirm-Addr + ' < ' + ftp-cmd-ini[1]"}
    {we_dbgftp.i
         "FTP-Order-Confirmations"
         "input stream s-ftpcmds through value(ftp-cmd)"}.
    Import-Confirms: repeat on error undo, leave Import-Confirms:
        import stream s-ftpcmds unformatted ftp-line.
        if debug&
        or ftp-verb begins " -d "
        then do:
            run Set-Dbg-DTTM.
            message dbg-dttm + " " + prog-name + " FTP-Order-Confirmation: " +
                ftp-line.
        end. /* if debug& */
        else do:
            if ftp-line begins "226"
            then do:
                run Set-Dbg-DTTM.
                message dbg-dttm + " " + prog-name +
                    " FTP-Order-Confirmation: "    +
                    ftp-line.
            end. /* if ftp-line begins "226" */
        end. /* else - if debug& */
    end. /* Import-Confirms: */
    {we_dbgftp.i "FTP-Order-Confirmations" "input stream s-ftpcmds close"}.
    /* unix silent value("rm -f " + ftp-cmd-dsn[1]). */
    unix silent value("rm -f " + ftp-cmd-ini[2]).
    /* unix silent value("rm -f " + ftp-cmd-log[3]). */
    {we_dbgproc.i FTP-Order-Confirmations "Ends"}
end procedure. /* FTP-Order-Confirmations: */

Procedure Load-tt-Rem-Tables:
define var company  as char     no-undo.
define var customer as char     no-undo.
define var item     as char     no-undo.
define var unit     as char     no-undo.
define var price    as char     no-undo.
define var hdrrecid as recid    no-undo.
define var ordrecid as recid    no-undo.
define var itmrecid as recid    no-undo.
define var shiptono as int      no-undo.
define var shipto   as char     no-undo.
define var h-c1     as char     no-undo.
    {we_dbgproc.i Load-tt-Rem-Tables "Begins"}
    FTP-Files: for each tt-FTP-Files
        where tt-Ftp-Files.Type = "LTO"
        break by tt-FTP-Files.Seed:
        {we_debug.i
            "'DEBUG: @FTP-Files:'                           skip
             'SubName: [' + tt-FTP-Files.Submit-Name  + ']' skip
             'CnfName: [' + tt-FTP-Files.Confirm-Name + ']' skip
             'FTPSeed: [' + tt-FTP-Files.Seed         + ']'"}
        LTO-Lines: for each tt-LTO-Lines use-index Seed
            where tt-LTO-Lines.Seed begins tt-FTP-Files.Seed
            break by tt-LTO-Lines.Seed     by tt-LTO-Lines.Company
                  by tt-LTO-Lines.Customer by tt-LTO-Lines.LineNo:
            
            if first-of(tt-LTO-Lines.Seed)
            then do:
                assign C[1] = " " + trim(tt-LTO-Lines.Company).
                create tt-Rem-Header.
                {ps_order_remhdr.asg}
                assign
                    hdrrecid = recid(tt-Rem-Header)
                    ordercnt = 0
                    linecnt  = 0.
            end. /* if first-of(tt-LTO-Lines.Seed) */
            if first-of(tt-LTO-Lines.Customer)
            then do:
                assign
                    company  = " " + trim(tt-LTO-Lines.Company)
                    customer = trim(tt-LTO-Lines.Customer)
                    customer = fill(" ",6 - length(customer)) + customer
                    ordercnt = ordercnt + 1
                    linecnt  = 0.
                find CUSTOMER 
                    where CUSTOMER.CO       = company
                      and CUSTOMER.CUSTOMER = customer
                    no-lock no-error.
                assign
                    shipto = trim(tt-LTO-Lines.ShipAddr[1])
                    shipto = fill(" ",6 - length(shipto)) + shipto.
                
                if CUSTOMER.CUSTOMER = shipto
                and can-find(first CUST_SHIPTO
                        where CUST_SHIPTO.CO       = CUSTOMER.CO
                          and CUST_SHIPTO.CUSTOMER = CUSTOMER.CUSTOMER)
                then find first CUST_SHIPTO
                        where CUST_SHIPTO.CO       = CUSTOMER.CO
                          and CUST_SHIPTO.CUSTOMER = CUSTOMER.CUSTOMER
                        no-lock no-error.
                else do:
                    find SHIPTO_CUSTOMER
                        where SHIPTO_CUSTOMER.CO       = CUSTOMER.CO
                          and SHIPTO_CUSTOMER.CUSTOMER = shipto
                        no-lock no-error.
                    if available(SHIPTO_CUSTOMER)
                    then find first CUST_SHIPTO
                        where CUST_SHIPTO.CO       = SHIPTO_CUSTOMER.CO
                          and CUST_SHIPTO.CUSTOMER = SHIPTO_CUSTOMER.CUSTOMER
                        no-lock no-error.
                end. /* else - if CUSTOMER.CUSTOMER = shipto */
                    
                create tt-Rem-Order.
                {ps_order_remord.asg}
                release SHIPTO_CUSTOMER.
                release CUST_SHIPTO.
                assign shipto = "".
                
                assign ordrecid = recid(tt-Rem-Order).
                if debug&
                then message "DEBUG create tt-Rem-Order" skip
                        "  LTOCo: [" + tt-LTO-Lines.Company  + "]" skip
                        "LTOCust: [" + tt-LTO-Lines.Customer + "]" skip
                        "RemCust: [" + tt-Rem-Order.Customer + "]" skip
                        "FTPSeed: [" + tt-FTP-Files.Seed     + "]" skip
                        "LTOSeed: [" + tt-LTO-Lines.Seed     + "]" skip
                        " ROSeed: [" + tt-Rem-Order.Seed     + "]" skip
                        view-as alert-box title "create tt-Rem-Order".
            end. /* if first-of(tt-LTO-Lines.Customer) */
            if trim(tt-LTO-Lines.Insts1) > ""
            then do:
                find CUST_COMM
                    where CUST_COMM.CO = tt-LTO-Lines.Company
                      and CUST_COMM.CUSTOMER = tt-LTO-Lines.Customer
                      and CUST_COMM.CODE     = "DEL"
                    exclusive-lock no-error.
                if not available(CUST_COMM)
                then do:
                    create CUST_COMM.
                    assign
                        CUST_COMM.CO = tt-LTO-Lines.Company
                        CUST_COMM.CUSTOMER = tt-LTO-Lines.Customer
                        CUST_COMM.CODE     = "DEL".
                end. /* if not available(CUST_COMM) */
                assign CUST_COMM.COMMENT = trim(tt-LTO-Lines.Insts1).
                release CUST_COMM.
            end. /* if trim(tt-LTO-Lines.Inst1) > "" */
            assign
                item  = trim(tt-LTO-Lines.Item)
                unit  = trim(tt-LTO-Lines.Unit)
                price = trim(tt-LTO-Lines.GrossPrice)
                price = trim(string((dec(price) / 100),">>>>>9.99-")).
            find tt-Rem-Order where recid(tt-Rem-Order) = ordrecid.
            find ITEM
                where ITEM.CO   = company
                  and ITEM.ITEM = item
                no-lock no-error.
            find first ITEM_UNIT
                where ITEM_UNIT.CO   = company
                  and ITEM_UNIT.ITEM = item
                  and ITEM_UNIT.UNIT begins unit
                no-lock no-error.
            assign linecnt = linecnt + 1.
            Find-Unit-Number: do i = 1 to 3 by 1:
                if ITEM_UNIT.UNIT = ITEM.UNIT[I] then leave.
            end. /* Find-Unit-Number: */
            create tt-Rem-Item.
            {ps_order_remitm.asg}
            assign tt-Rem-Item.Line = string(linecnt,"9999").
            
            if last-of(tt-LTO-Lines.Customer)
            then do:
                find tt-Rem-Order where recid(tt-Rem-Order) = ordrecid.
                assign 
                    tt-Rem-Order.LineCnt = string(linecnt,"9999")
                    linecnt = 0.
            end. /* if last-of(tt-LTO-Lines.Customer) */
        
            if last-of(tt-LTO-Lines.Company)
            then do:
                find tt-Rem-Header where recid(tt-Rem-Header) = hdrrecid.
                assign
                    tt-Rem-Header.OrderCnt = string(ordercnt,"9999")
                    ordercnt = 0.
            end. /* if last-of(tt-LTO-Lines.Company) */
            if debug&
            and last-of(tt-LTO-Lines.Seed)
            then message "DEBUG last-of(tt-LTO-Lines.Seed)"
                "Comp: [" + tt-LTO-Lines.Company   + "]"    skip
                "Cust: [" + tt-LTO-Lines.Customer  + "]"    skip
                " LTO: [" + tt-LTO-Lines.Seed      + "]"    skip
                "RemH: [" + tt-Rem-Header.Seed     + "]"    skip
                "RemO: [" + tt-Rem-Order.Seed      + "]"    skip
                "RemI: [" + tt-Rem-Item.Seed       + "]"    skip
                "Ords: [" + tt-Rem-Header.OrderCnt + "]"    skip
                view-as alert-box title "last-of(tt-LTO-Lines.Seed)".
        end. /* LTO-Lines: */
    end. /* FTP-Files: */
    {we_dbgproc.i Load-tt-Rem-Tables "Ends"}
end procedure. /* Load-tt-Rem-Tables: */

Procedure Load-tt-LTO-Lines:
    {we_dbgproc.i Load-tt-LTO-Lines "Begins"}
    Get-FTP-Files: for each tt-FTP-Files use-index Seed
        where tt-FTP-Files.Type = "LTO":
        input stream s-submits from value(tt-FTP-Files.Submit-Name).
        Create-tt-LTO-Lines: repeat on endkey undo, leave Create-tt-LTO-Lines
                                    on error  undo, leave Create-tt-LTO-Lines:
            import stream s-submits unformatted ftp-line.
            {we_debug.i "'Create-tt-LTO-Lines:' ftp-line"}.
            if ftp-line = "" then next Create-tt-LTO-Lines.
            create tt-LTO-Lines.
            {ps_order_lto.asg}
            find ITEM_UNIT
                where ITEM_UNIT.CO = " " + trim(tt-LTO-Lines.Company)
                  and ITEM_UNIT.SPS_ITEM = trim(tt-LTO-Lines.PSItem)
                no-lock no-error.
            if not avail ITEM_UNIT then delete tt-LTO-Lines.
            else do: 
                assign
                    tt-LTO-Lines.Item = ITEM_UNIT.ITEM
                    tt-LTO-Lines.Unit = ITEM_UNIT.Unit.
                if debug&
                then message "DEBUG create tt-LTO-Lines" skip
                "Line: [" + string(tt-LTO-Lines.LineNo,"9999") + "]"    skip
                "Item: [" + tt-LTO-Lines.Item + "]"                     skip
                "Unit: [" + tt-LTO-Lines.Unit + "]"                     skip
                "LapI: [" + tt-LTO-Lines.LaptopID + "]"                 skip
                "FTPS: [" + tt-FTP-Files.Seed + "]"                     skip
                "LTOS: [" + tt-LTO-Lines.Seed + "]"                     skip
                "MODD: [" + substr(ftp-line,418,008) + "]"              skip
                view-as alert-box title "create tt-LTO-Lines".
            end.
        end. /* Create-tt-LTO-Lines: */
    end. /* Get-FTP-Files: */
    if debug&
    then do:
        for each tt-LTO-Lines:
            display tt-LTO-Lines with 2 column title "tt-LTO-Lines".
        end.
    end.
    {we_dbgproc.i Load-tt-LTO-Lines "Ends"}
end procedure. /* Load-tt-LTO-Lines: */

Procedure Load-tt-LTP-Lines:
define var company      as char no-undo format "x(003)".
define var customer     as char no-undo format "x(010)".
define var creditcode   as char no-undo format "x(002)".
define var order        as char no-undo format "x(010)".
define var item         as char no-undo.
define var unit         as char no-undo.
define var price        as char no-undo format "x(008)".
define var netprice     as char no-undo format "x(008)".
    {we_dbgproc.i Load-tt-LTP-Lines "Begins"}
    Get-FTP-Files: for each tt-FTP-Files use-index Seed
        where tt-FTP-Files.Type = "LTP"
        break by tt-FTP-Files.Seed:
        if first-of(tt-FTP-Files.Seed)
        then assign messages-dsn = tt-FTP-Files.Log-Name.
        input stream s-submits from value(tt-FTP-Files.Submit-Name).
        Create-tt-LTP-Lines: repeat on endkey undo, leave Create-tt-LTP-Lines
                                    on error  undo, leave Create-tt-LTP-Lines:
            import stream s-submits unformatted ftp-line.
            if ftp-line = "" then next Create-tt-LTP-Lines.
            {we_debug.i "'Create tt-LTP-Lines Messages:' messages-dsn"}.
            create tt-LTP-Lines.
            {ps_order_ltp.asg}
            if length(trim(tt-LTP-Lines.InvoiceNum)) = 7
            then assign
                    tt-LTP-Lines.InvoiceNum = tt-LTP-Lines.InvoiceNum + "0".
            find ORDER_ITEM
                where ORDER_ITEM.CO    = tt-LTP-Lines.Company
                  and ORDER_ITEM.ORDER = tt-LTP-Lines.InvoiceNum
                  and ORDER_ITEM.LINE  = int(tt-LTP-Lines.LineNum)
                no-lock no-error.
            if not available(ORDER_ITEM)
            then do:
                assign messages-line =
                        "NO SUCH ORDER LINE EXIST for" +
                        " CUSTOMER: [" + trim(tt-LTP-Lines.Customer)   + "]" +
                        " ORDER: ["    + trim(tt-LTP-Lines.InvoiceNum) + "]" +
                        " LINE: ["     + trim(tt-LTP-Lines.LineNum)    + "]".
                {we_debug.i messages-line}
                run Messages.
                delete tt-LTP-Lines.
                next Create-tt-LTP-Lines.
            end. /* if not available(ORDER_ITEM) */
            assign
                tt-LTP-Lines.Item = ORDER_ITEM.ITEM
                tt-LTP-Lines.Unit = ORDER_ITEM.UNIT.
            {we_debug.i
                "'DEBUG create tt-LTP-Lines'                skip
                 'Order: [' + tt-LTP-Lines.InvoiceNum + ']' skip
                 ' Line: [' + tt-LTP-Lines.LineNum    + ']' skip
                 ' Item: [' + tt-LTP-Lines.Item       + ']' skip
                 ' Unit: [' + tt-LTP-Lines.Unit       + ']' skip
                 ' FTPS: [' + tt-FTP-Files.Seed       + ']' skip
                 ' LTPS: [' + tt-LTP-Lines.Seed       + ']'"}
        end. /* Create-tt-LTP-Lines: */
    end. /* Get-FTP-Files: */
    {we_debug.i
        "for each tt-LTP-Lines:
             display tt-LTP-Lines with 2 column title 'Load-tt-LTP-Lines'.
         end."}
    {we_dbgproc.i Load-tt-LTP-Lines "Ends"}
end procedure. /* Load-tt-LTP-Lines: */

Procedure Load-Pickup-Tables:
define var company  as char     no-undo.
define var customer as char     no-undo.
define var item     as char     no-undo.
define var unit     as char     no-undo.
define var price    as char     no-undo.
define var hdrrecid as recid    no-undo.
define var ordrecid as recid    no-undo.
define var itmrecid as recid    no-undo.
define var h-c1     as char     no-undo.
    {we_dbgproc.i Load-Pickup-Tables "Begins"}
    FTP-Files: for each tt-FTP-Files
        where tt-Ftp-Files.Type = "LTP"
        break by tt-FTP-Files.Seed:
        assign messages-dsn = tt-FTP-Files.Log-Name.
        if  debug&
        then do:
            assign
                messages-lines[1] = "DEBUG - FTP Files"
                messages-lines[2] =
                    "SubName: [" + tt-FTP-Files.Submit-Name  + "]"
                messages-lines[3] =
                    "CnfName: [" + tt-FTP-Files.Confirm-Name + "]"
                messages-lines[4] =
                    "LogName: [" + tt-FTP-Files.Log-Name     + "]"
                messages-lines[5] =
                    "FTPSeed: [" + tt-FTP-Files.Seed         + "]"
                messages-lines[6] =
                    "MsgsDSN: [" + messages-dsn              + "]".
            run Set-Dbg-DTTM.
            message dbg-dttm + " " + prog-name + ": " skip
                messages-lines[1] skip
                messages-lines[2] skip
                messages-lines[3] skip
                messages-lines[4] skip
                messages-lines[5] skip
                messages-lines[6] skip
                view-as alert-box title "DEBUG - FTP Files".
            run Messages.
        end. /* if debug& */
        LTP-Lines: for each tt-LTP-Lines use-index Seed
            where tt-LTP-Lines.Seed begins tt-FTP-Files.Seed
            break by tt-LTP-Lines.Company    by tt-LTP-Lines.Customer
                  by tt-LTP-Lines.InvoiceNum by tt-LTP-Lines.LineNum:
            if first-of(tt-LTP-Lines.Customer)
            then assign cntorder = 0 ordercnt = 0 linecnt  = 0 cntline  = 0.
            if first-of(tt-LTP-Lines.InvoiceNum)
            then do:
                assign
                    company      = " " + trim(tt-LTP-Lines.Company)
                    customer     = trim(tt-LTP-Lines.Customer)
                    customer     = fill(" ",6 - length(customer)) + customer
                    messages-dsn = tt-LTP-Lines.OutFile
                    ordercnt     = ordercnt + 1
                    linecnt      = 0.
                find CUSTOMER
                    where CUSTOMER.CO       = company
                      and CUSTOMER.CUSTOMER = customer
                    no-lock no-error.
                {we_run.i Create-W_PICKUP}.
            end. /* if first-of(tt-LTP-Lines.InvoiceNum) */
            assign
                item  = trim(tt-LTP-Lines.Item)
                unit  = trim(tt-LTP-Lines.Unit)
                price = trim(tt-LTP-Lines.CreditPrice)
                price = trim(string((dec(price) / 100),">>>>>9.99-")).
            find ITEM
                where ITEM.CO   = company
                  and ITEM.ITEM = item
                no-lock no-error.
            find ITEM_UNIT
                where ITEM_UNIT.CO   = company
                  and ITEM_UNIT.ITEM = item
                  and ITEM_UNIT.UNIT = unit
                no-lock no-error.
            Find-Unit-Number: do i = 1 to 3 by 1:
                if ITEM_UNIT.UNIT = ITEM.UNIT[i] then leave.
            end. /* Find-Unit-Number: */
            run Create-W_PUITEM.
            assign linecnt = linecnt + 1.
            if last-of(tt-LTP-Lines.InvoiceNum)
            then do:
                assign 
                    W_PICKUP.W_LNE_CNT = linecnt
                    linecnt = 0.
            end. /* if last-of(tt-LTP-Lines.InvoiceNum) */
            if last-of(tt-LTP-Lines.Company)
            then assign ordercnts[int(tt-LTP-Lines.Company)] = ordercnt.
        end. /* LTP-Lines: */
    end. /* FTP-Files: */
    {we_dbgproc.i Load-Pickup-Tables "Ends"}
end procedure. /* Load-Pickup-Tables: */

Procedure Create-W_PICKUP:
{we_dbgproc.i Create-W_PICKUP Begins}.
define var wpu-recid as recid no-undo.
    LTP-Lines: for each tt-LTP-Lines use-index Seed
        break by tt-LTP-Lines.Seed:
        if first-of(tt-LTP-Lines.Seed)
        then assign messages-dsn = tt-LTP-Lines.OutFile.
        find CUSTOMER
            where CUSTOMER.CO       = tt-LTP-Lines.Company
              and CUSTOMER.CUSTOMER = tt-LTP-Lines.Customer
            no-lock no-error.
        find CUST_SHIPTO
            where CUST_SHIPTO.CO       = tt-LTP-Lines.Company
              and CUST_SHIPTO.CUSTOMER = tt-LTP-Lines.CUSTOMER
            no-lock no-error.
        find ORDER use-index ORDER
            where ORDER.CO    = tt-LTP-Lines.Company
              and ORDER.ORDER = tt-LTP-Lines.InvoiceNum
            no-lock no-error.
        
        if first-of(tt-LTP-Lines.Seed)
        then do:
            {we_debug.i "'create W_PICKUP. Messages:' messages-dsn"}.
            create W_PICKUP.
            assign
                W_PICKUP.W_SEED             = tt-LTP-Lines.Seed
                W_PICKUP.W_PICKUP           = ""
                /* Changed to CreditCode because RequestType is coming
                   across as "P" which is not a valid REASON 
                W_PICKUP.W_REASON           = tt-LTP-Lines.RequestType
                */
                W_PICKUP.W_REASON           = tt-LTP-Lines.CreditCode
                W_PICKUP.W_TIMESTAMP        = tt-LTP-Lines.TimeStamp
                                              /* MYYYYMDDHHMMSS */
                W_PICKUP.W_CUSTOMER         =
                    if available(ORDER)
                    then ORDER.CUSTOMER
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.CUSTOMER
                         else if available(CUSTOMER)
                         then CUSTOMER.CUSTOMER
                         else tt-LTP-Lines.CUSTOMER 
                W_PICKUP.W_NAME             =
                    if available(ORDER)
                    then ORDER.NAME
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.CUSTOMER
                         else if available(CUSTOMER)
                         then CUSTOMER.NAME
                         else ""
                W_PICKUP.W_PO               =
                    if available(ORDER)
                    then ORDER.CUST_ORNBR
                    else ""
                W_PICKUP.W_SHIP_STR         = 
                    (substr(tt-LTP-Lines.PickupByDate,5,2) + "/" +
                     substr(tt-LTP-Lines.PickupByDate,7,2) + "/" +
                     substr(tt-LTP-Lines.PickupByDate,1,4))
                W_PICKUP.W_SHIP_DT          =
                    if available(ORDER)
                    then ORDER.SHIP_DT
                    else ?
                W_PICKUP.W_PICKUP_INSTR     = 
                    if tt-LTP-Lines.SpecialInstr1 > ""
                    then tt-LTP-Lines.SpecialInstr1
                    else if tt-LTP-Lines.SpecialInstr2 > ""
                         then tt-LTP-Lines.SpecialInstr2
                         else ""
                W_PICKUP.W_SHIPTO_NO        =
                    if available(ORDER)
                    then ORDER.SHIPTO
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.SHIPTO
                         else ""
                W_PICKUP.W_NAME             =
                    if available(ORDER)
                    then ORDER.NAME
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.NAME
                         else if available(CUSTOMER)
                         then CUSTOMER.NAME
                         else ""
                W_PICKUP.W_PICKUPATTN       =
                    if available(ORDER)
                    then ORDER.SH_ATTN
                    else if available(CUSTOMER)
                    then CUSTOMER.ATTN
                    else ""
                W_PICKUP.W_PICKUPADDR[1]    =
                    if available(ORDER)
                    then ORDER.SH_ADDRESS[1]
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.ADDRESS[1]
                         else if available(CUSTOMER)
                              then CUSTOMER.ADDRESS[1]
                              else ""
                W_PICKUP.W_PICKUPADDR[2]    =
                    if available(ORDER)
                    then ORDER.SH_ADDRESS[2]
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.ADDRESS[2]
                         else if available(CUSTOMER)
                              then CUSTOMER.ADDRESS[2]
                              else ""
                W_PICKUP.W_PICKUPADDR[3]    =
                    if available(ORDER)
                    then ORDER.SH_ADDRESS[3]
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.ADDRESS[3]
                         else if available(CUSTOMER)
                              then CUSTOMER.ADDRESS[3]
                              else ""
                W_PICKUP.W_PICKUPCITY         =
                    if available(ORDER)
                    then ORDER.SH_CITY
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.CITY
                         else if available(CUSTOMER)
                              then CUSTOMER.CITY
                              else ""
                W_PICKUP.W_PICKUPSTATE        =
                    if available(ORDER)
                    then ORDER.SH_STATE
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.STATE
                         else if available(CUSTOMER)
                              then CUSTOMER.STATE
                              else "" 
                W_PICKUP.W_PICKUPJUR      =
                    if available(ORDER)
                    then ORDER.JUR
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.JUR
                         else if available(CUSTOMER)
                              then CUSTOMER.JUR
                              else ""
                W_PICKUP.W_PICKUPPHONE    =
                    if available(ORDER)
                    then ORDER.SH_PHONE
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.PHONE
                         else if available(CUSTOMER)
                              then CUSTOMER.PHONE[1]
                              else ""
                W_PICKUP.W_PICKUPFAX      =
                   if available(ORDER)
                    then ORDER.SH_FAX
                    else if available(CUST_SHIPTO)
                         then CUST_SHIPTO.FAX
                         else if available(CUSTOMER)
                              then CUSTOMER.FAX
                              else ""
                W_PICKUP.W_LNE_CNT       = 0
                W_PICKUP.W_LOG_NAME      = messages-dsn
                wpu-recid                = recid(W_PICKUP).
                 
            assign w-temp = "".
            do i = 1 to length(W_PICKUP.W_PICKUPPHONE):
                if lookup(substr(W_PICKUP.W_PICKUPPHONE,i,1)," ,(,),-") = 0
                then assign w-temp = w-temp +
                        substr(W_PICKUP.W_PICKUPPHONE,i,1).
            end.
            assign W_PICKUP.W_PICKUPPHONE = w-temp.
      
            w-temp = "".
            do i = 1 to length(W_PICKUP.W_PICKUPFAX):
                if lookup(substr(W_PICKUP.W_PICKUPFAX,i,1)," ,(,),-") = 0
                then assign w-temp = w-temp + substr(W_PICKUP.W_PICKUPFAX,i,1).
            end.
            assign W_PICKUP.W_PICKUPFAX = w-temp.
        
            run u/u_date.p 
                (input W_PICKUP.W_SHIP_STR, output W_PICKUP.W_SHIP_DT).
      
            create W_MESS.
            assign
                W_MESS.W_SEED = W_PICKUP.W_SEED
                W_MESS.W_TXT  = "Loading Pickup: " + W_PICKUP.W_SEED.
            assign messages-line = W_MESS.W_TXT.
            run Messages.
            {we_debug.i "'Messages:' messages-dsn"}.
            if debug&
            then display W_PICKUP with 2 columns.
        end. /* if first-of(tt-LTP-Lines) */
        {we_run.i Create-W_PUITEM}.
        if last-of(tt-LTP-Lines.Seed)
        then do:
            find W_PICKUP where recid(W_PICKUP) = wpu-recid.
            assign
                W_PICKUP.W_LNE_CNT = linecnt
                linecnt = 0.
        end. /* if last-of(tt-LTP-Lines) */
    end. /* LTP-Lines: */
    {we_dbgproc.i Create-W_PICKUP Ends}.
end procedure. /* Create-W_PICKUP: */

Procedure Create-W_PUITEM:
    {we_dbgproc.i Create-W_PUITEM Begins}.
    find ITEM
        where ITEM.CO   = tt-LTP-Lines.Company
          and ITEM.ITEM = tt-LTP-Lines.ITEM
        no-lock no-error.
    find ORDER_ITEM use-index ORDER_LINE
        where ORDER_ITEM.CO    = tt-LTP-Lines.Company
          and ORDER_ITEM.ORDER = tt-LTP-Lines.InvoiceNum
          and ORDER_ITEM.LINE  = int(tt-LTP-Lines.LineNum)
        no-lock no-error.
    if not available(ORDER_ITEM)
    then find ORDER_ITEM use-index ORDER_ITEM
            where ORDER_ITEM.CO    = tt-LTP-Lines.Company
              and ORDER_ITEM.ORDER = tt-LTP-Lines.InvoiceNum
              and ORDER_ITEM.ITEM  = tt-LTP-Lines.Item
              and ORDER_ITEM.UNIT  = tt-LTP-Lines.Unit
        no-lock no-error.
    do i = 1 to 3 by 1:
        if ITEM.UNIT[1] = tt-LTP-Lines.Unit then leave.
    end. /* do i = 1 to 3 by 1: */
    {we_debug.i "'create W_PUTITEM Messages:' messages-dsn"}.
    create W_PUITEM.
    assign
        linecnt             = linecnt + 1
        W_PUITEM.W_SEED     = W_PICKUP.W_SEED 
        W_PUITEM.W_ITEM     = tt-LTP-Lines.ITEM
        W_PUITEM.W_UNIT     = tt-LTP-Lines.Unit
        W_PUITEM.W_QTY      = int(tt-LTP-Lines.CreditQty)
        W_PUITEM.W_WEIGHT   = (dec(tt-LTP-Lines.CreditWgt) / 10000)
        W_PUITEM.W_LINE     = linecnt
        W_PUITEM.W_REASON   = tt-LTP-Lines.CreditCode
        W_PUITEM.W_COMMENT  = if tt-LTP-Lines.SpecialInstr2 > ""
                              then tt-LTP-Lines.SpecialInstr2
                              else if tt-LTP-Lines.SpecialInstr1 > ""
                              then tt-LTP-Lines.SpecialInstr1
                              else ""
        W_PUITEM.W_UNITNUM  = i
        W_PUITEM.W_INV      = tt-LTP-Lines.InvoiceNum
        W_PUITEM.W_INV_LNE  = int(tt-LTP-Lines.LineNum)
        W_PUITEM.W_PART&    = if tt-LTP-Lines.BrkCaseCode = "Y"
                              then yes else no
        W_PUITEM.W_NO_INV&  = if W_PUITEM.W_INV > ""
                              then yes else no.
    create W_MESS.
    assign
        W_MESS.W_SEED = W_PUITEM.W_SEED
        W_MESS.W_TXT  = "PickupItem:" +
            "Item: " + W_PUITEM.W_ITEM +
            "Unit: " + W_PUITEM.W_UNIT +
            "Qty: "  + string(W_PUITEM.W_QTY,"9999").
    assign messages-line = W_MESS.W_TXT.
    run Messages.
    {we_dbgproc.i Create-W_PUITEM Ends}.
end procedure. /* Create-W_PUITEM */

Procedure Load-tt-Controls:
    {we_dbgproc.i Load-tt-Controls "Begins"}
    if not os-getenv("PSCTL") = ?
    then assign ftp-ctl-dsn = os-getenv("PSCTL").
    input stream s-ftpctl from value(ftp-ctl-dsn).
    {we_dbgproc.i Create-tt-Controls "Begins"}.
    create tt-Controls.
    import stream s-ftpctl delimiter "," tt-Controls.
    {we_dbgproc.i Create-tt-Controls "Ends"}.
    input stream s-ftpctl close.
    if debug&
    then do:
        display tt-Controls 
            with frame frm-ftpctl 1 column title "tt-Controls".
        pause message "DEBUG tt-Controls".
    end. /* if debug& */
    {we_dbgproc.i Load-tt-Controls "Ends"}
end procedure. /* Load-tt-Controls: */

Procedure Clear-W-Tables:
    Clear-W_ORDER  : for each W_ORDER  : delete W_ORDER.   end.
    Clear-W_ITEM   : for each W_ITEM   : delete W_ITEM.    end.
    Clear-W_Mess   : for each W_MESS   : delete W_MESS.    end.
    Clear-W_PICKUP : for each W_PICKUP : delete W_PICKUP.  end.
    Clear-W_PUITEM : for each W_PUITEM : delete W_PUITEM.  end.
    Clear-W_SAVEREL: for each W_SAVEREL: delete W_SAVEREL. end.
end procedure. /* Clear-W-Tables: */

Procedure Fax-Back:
define var cnffile as char no-undo.
define var w-co as char no-undo.
define var WarnTxt as char no-undo.
define var txt as char no-undo.

    /* XML CODE
    if laptop-ver >= 777
    then do:   /* 771 = 0x0303, Version 3.03 */
        find first SYS_CONTROL no-error.
        assign cnffile = infile + ".cnf.xml".
        output stream s-outstr to value(cnffile).
        assign txt = string(today,"99/99/9999").
        put stream s-outstr unformatted
            "<?xml version =" chr(34) "1.0" chr(34)
            " encoding=" chr(34) "UTF-8" chr(34) "?>"  SKIP.
        if laptop-ver >= 1280
        then do:
            put stream s-outstr unformatted
                "<ConfirmationFile  xmlns=" chr(34)
                "http://tempuri.org/Confirmations.xsd" chr(34) ">"
            SKIP.
        end.
        put stream s-outstr unformatted        
            "<Confirmation" SKIP
            " softwareVersion=" chr(34) laptop-ver      chr(34)
            " numOrders="       chr(34) o-ordr-cnt      chr(34)
            " numPickups="      chr(34) o-pu-cnt        chr(34)
            " laptopID="        chr(34) o-id            chr(34)
            " file="            chr(34) cnffile         chr(34)
            " date="            chr(34) substr(txt,7,4) + "-" +
                     substr(txt,1,2) + "-" + substr(txt,4,2) + "T" +
                     string(time,"HH:MM:SS")            chr(34)
            ">" SKIP.
        
        for each W_MESS
            where not can-find(first W_ORDER
                        where W_ORDER.W_SEED = W_MESS.W_SEED)
            no-lock:
            {we_run.i Process-Str (input W_MESS.W_TXT, output txt).
            put stream s-outstr unformatted space(2)
                "<Warning text="    chr(34) txt             chr(34) 
                " seed="            chr(34) W_MESS.W_SEED   chr(34)
                "/>"
                SKIP.
        end. /* for each W_MESS: */
    
        for each W_ORDER
            break by W_ORDER.W_ORDER:
            {we_run.i Process-Str(input W_ORDER.W_SEED, output w-temp).
            assign w-co = if W_ORDER.W_CO > "" then W_ORDER.W_CO else C[1].
            find first ORDER_REMOTE
                where ORDER_REMOTE.CO = w-co
                  and ORDER_REMOTE.SEED = W_ORDER.W_SEED
                no-lock no-error.
            if available(ORDER_REMOTE)
            then find ORDER
                    where ORDER.CO = ORDER_REMOTE.CO
                      and ORDER.ORDER = ORDER_REMOTE.ORDER
                    no-lock no-error.
            if not available(ORDER)
            then find ORDER
                    where ORDER.CO = w-co
                      and ORDER.ORDER = W_ORDER.W_ORDER
                    no-lock no-error.
            if available(ORDER)
            then assign W_ORDER.W_SHIP_DT = ORDER.SHIP_DT.
            assign txt = string(if available(ORDER)
                         then ORDER.STAMP_DT else today,"99/99/9999").
            put stream s-outstr unformatted 
                space(4) "<Order"
                " totalLines=" chr(34) 
                    (if avail ORDER then ORDER.TTL_LN else 0) chr(34)
                " totalPcs=" chr(34) 
                    (if avail ORDER then ORDER.TTL_PCS else 0) chr(34)
                " totalWT=" chr(34) 
                    (if avail ORDER then ORDER.TTL_WT else 0) chr(34)
                " totalTax=" chr(34)
                    (if avail ORDER then ORDER.TTL_TAX else 0) chr(34)
                " subTotal=" chr(34)
                    (if avail ORDER then ORDER.TTL_EXT else 0) chr(34)
                " freight=" chr(34)
                    (if avail ORDER then ORDER.FREIGHT else 0) chr(34)
                " dateCreated=" chr(34) substr(txt,7,4) + "-" +
                                    substr(txt,1,2) + "-" +
                                    substr(txt,4,2) + "T" +
                                    (if available(ORDER)
                                     then ORDER.STAMP_TM
                                     else string(time,"HH:MM:SS")) chr(34).
                                    
            if W_ORDER.W_SHIP_DT <> ?
            then do:
                assign txt = string(W_ORDER.W_SHIP_DT,"99/99/9999").
                put stream s-outstr unformatted
                    " shipDate=" chr(34) substr(txt,7,4) + "-" +
                         substr(txt,1,2) + "-" + substr(txt,4,2) chr(34).
            end.        
            put stream s-outstr unformatted                            
                " customer="    chr(34) W_ORDER.W_CUSTOMER      chr(34)
                " salesrep="    chr(34) (if available(ORDER)
                                         then ORDER.SALESREP
                                         else salesrep)         chr(34)
                " seed="        chr(34) W_ORDER.W_SEED          chr(34)
                " type="        chr(34) (if available(ORDER)
                                         then ORDER.TYPE
                                         else "T")              chr(34)
                " orderNumber=" chr(34) string(W_ORDER.W_ORDER,"XXXXXX-XX")
                                                                chr(34)
                ">"
                SKIP.
        
            for each W_ITEM
                where W_ITEM.W_SEED = W_ORDER.W_SEED
                  and W_ITEM.W_LINE > 0:
                find ORDER_ITEM
                    where ORDER_ITEM.CO = w-co
                      and ORDER_ITEM.ORDER = W_ORDER.W_ORDER
                      and ORDER_ITEM.LINE = W_ITEM.W_LINE
                      and ORDER_ITEM.ITEM = W_ITEM.W_ITEM
                    no-lock no-error.
                if not available(ORDER_ITEM)
                then assign W_ITEM.W_LINE = 0.
            end. /* for each W_ITEM: */
        
            for each W_ITEM
                where W_ITEM.W_SEED = W_ORDER.W_SEED:
                if W_ITEM.W_LINE = 0
                and W_ORDER.W_ORDER > ""
                then do:
                    LINE: for each ORDER_ITEM
                            where ORDER_ITEM.CO = w-co
                              and ORDER_ITEM.ORDER = W_ORDER.W_ORDER
                              and ORDER_ITEM.LINE > 0
                              and ORDER_ITEM.ITEM = W_ITEM.W_ITEM
                            no-lock:
                            find first W_ITEM1
                                where W_ITEM1.W_SEED = W_ITEM.W_SEED
                                  and W_ITEM1.W_LINE = ORDER_ITEM.LINE
                                no-lock no-error.
                            if not available(W_ITEM1)
                            then do:
                                assign W_ITEM.W_LINE = ORDER_ITEM.LINE.
                                leave LINE.
                            end. /* if not available(W_ITEM1) */
                    end. /* LINE: */
                end. /* if W_ITEM.W_LINE = 0 */
                find ORDER_ITEM
                    where ORDER_ITEM.CO = w-co
                      and ORDER_ITEM.ORDER = W_ORDER.W_ORDER
                      and ORDER_ITEM.LINE = W_ITEM.W_LINE
                      and ORDER_ITEM.ITEM = W_ITEM.W_ITEM
                      and ORDER_ITEM.LINE > 0
                    no-lock no-error.
                find ITEM
                    where ITEM.CO = w-co
                      and ITEM.ITEM = W_ITEM.W_ITEM
                    no-lock no-error.
                {we_run.i Process-Str(input W_ITEM.W_ITEM, output w-temp).
                put stream s-outstr unformatted space(8)
                    "<Item itemNum="    chr(34) w-temp          chr(34)
                    " seed="            chr(34) W_ITEM.W_SEED   chr(34)
                    " unit="            chr(34) W_ITEM.W_UNIT   chr(34)
                    " qtyShip="         chr(34) (if available(ORDER_ITEM)
                                                 then ORDER_ITEM.QTY_SHIP
                                                 else 0)        chr(34)
                    " qtyOrder="        chr(34) W_ITEM.W_QTY    chr(34)
                    " price="           chr(34) (if available(ORDER_ITEM)
                                                 then ORDER_ITEM.PRICE
                                                 else 0)        chr(34) 
                    " extendedPrice="   chr(34) (if avail ORDER_ITEM
                                                 then ORDER_ITEM.EXTEND
                                                 else 0)        chr(34)
                    ">"
                    SKIP.
            
                for each ORDER_COMM
                    where ORDER_COMM.CO = w-co
                      and ORDER_COMM.ORDER = W_ORDER.W_ORDER
                      and ORDER_COMM.LINE = W_ITEM.W_LINE
                    no-lock:
                    {we_run.i Process-Str
                        (input ORDER_COMM.COMMENT, output txt).
                    put stream s-outstr unformatted space(12)
                        "<Comment type="    chr(34) ORDER_COMM.TYPE   chr(34)
                        " seed="            chr(34) ORDER_REMOTE.SEED chr(34)
                        " text="            chr(34) txt               chr(34)
                        "/>"
                        SKIP.
                end. /* for each ORDER_COMM */
                put stream s-outstr unformatted space(8) "</Item>" SKIP.
            end. /* for each W_ITEM */
        
            for each ORDER_ITEM
                where ORDER_ITEm.CO = w-co
                  and ORDER_ITEM.ORDER = W_ORDER.W_ORDER
                  and not can-find(first W_ITEM
                            where W_ITEM.W_LINE = ORDER_ITEM.LINE)
                no-lock:
                find ITEM
                    where ITEM.CO = w-co
                      and ITEM.ITEM = ORDER_ITEM.ITEM
                    no-lock no-error.
                {we_run.i Process-Str(input ORDER_ITEM.ITEM, output w-temp).
                put stream s-outstr unformatted space(8)
                    "<Item itemNum="    chr(34) w-temp              chr(34)
                    " seed="            chr(34) ORDER_REMOTE.SEED   chr(34)
                    " unit="            chr(34) ORDER_ITEM.UNIT     chr(34)
                    " qtyShip="         chr(34) ORDER_ITEM.QTY_SHIP chr(34)
                    " qtyOrder="        chr(34) 0                   chr(34)
                    " price="           chr(34) ORDER_ITEM.PRICE    chr(34)
                    " pricecode="       chr(34) ORDER_ITEM.PRICING  chr(34)
                    " extendedPrice="   chr(34) ORDER_ITEM.EXTEND   chr(34)
                    ">"
                    SKIP.
            
                for each ORDER_COMM
                    where ORDER_COMM.CO = w-co
                      and ORDER_COMM.ORDER = W_ORDER.W_ORDER
                      and ORDER_COMM.LINE = ORDER_ITEM.LINE
                    no-lock:
                    {we_run.i Process-Str (input ORDER_COMM.COMMENT,
                                           output txt).
                    put stream s-outstr unformatted space(12)
                        "<Comment type="    chr(34) ORDER_COMM.TYPE     chr(34)
                        " seed="            chr(34) ORDER_REMOTE.SEED   chr(34)
                        " text="            chr(34) txt                 chr(34)
                        "/>"
                        SKIP.
                end. /* for each ORDER_COMM */
                put stream s-outstr unformatted space(8) "</Item>" SKIP.
            end. /* for each ORDER_ITEM */
                
            for each W_MESS
                where W_MESS.W_SEED = W_ORDER.W_SEED:
                {we_run.i Process-Str (input W_MESS.W_TXT, output txt).
                put stream s-outstr unformatted space(4)
                    "<Warning text="    chr(34) txt             chr(34) 
                    " seed="            chr(34) W_ORDER.W_SEED  chr(34)
                    "/>"
              A      SKIP.
            end. /* for each W_MESS */
            put stream s-outstr unformatted space(4) "</Order>" SKIP.
        end. /* for each W_ORDER */
    end. /* if laptop-ver >= 777 */
    put stream s-outstr unformatted "</Confirmation>" SKIP.

    if laptop-ver >= 1280
    then put stream s-outstr unformatted "</ConfirmationFile>" SKIP.
    output stream s-outstr close.

    {we_run.i u/u_clolk.p (input nc-file-handle).
    XML CODE */

define var hdrdesc2 as char format "X(80)" no-undo.
define var termsdesc like TERMS.DESCRIPTION no-undo.
define var comm like CUST_COMM.COMMENT extent 3 no-undo.
define var codelist AS CHAR FORMAT "X(3)"  EXTENT 3 INITIAL ["A/R","BIL","DEL"].

    FORM HEADER
        gb-coname                   AT 1
        "Faxback Order Summary"     AT 32
        gb-dt                       AT 73
        SKIP(1)
        FILL("-",80) FORMAT "X(80)"
        SKIP(1)
        hdrdesc2                    AT 1
        SKIP(1)
        WITH FRAME hdr PAGE-TOP CENTERED NO-BOX NO-ATTR-SPACE WIDTH 80.
    assign
        hdrdesc2 = "LINE   ITEM   UNIT  DESCRIPTION                 ORD SHIP" +
                   "   PRICE    EXT     TAX"
        cnt      = 0.

    for each W_ORDER
        where W_ORDER.W_FAXBACK > ""
        by W_ORDER:
        assign 
            cnt  = cnt + 1
            w-co = if W_ORDER.W_CO > "" then W_ORDER.W_CO else C[1].
        find ORDER
            where ORDER.CO = w-co
              and ORDER.ORDER = W_ORDER.W_ORDER
            no-lock.
    
        output stream s-print to value(infile + ".fax." + string(cnt)).
        view stream s-print frame hdr.
        find TERMS
            where TERMS.CO = w-co
              and TERMS.TERMS = ORDER.TERMS
            no-lock no-error.
        assign termsdesc = if available(TERMS) then TERMS.DESCRIPTION else "".
        find CUSTOMER
            where CUSTOMER.CO = w-co
              and CUSTOMER.CUSTOMER = ORDER.CUSTOMER
            no-lock no-error.
        find SALESREP
            where SALESREP.CO = w-co
              and SALESREP.SALESREP = ORDER.SALESREP
            no-lock no-error.
        assign comm = "".
        do i = 1 TO 3:
            find CUST_COMM
                where CUST_COMM.CO = w-co
                  and CUST_COMM.CUSTOMER = CUSTOMER.CUSTOMER
                  and CUST_COMM.CODE = codelist[i]
                no-lock no-error.
            if available(CUST_COMM) then assign comm[i] = CUST_COMM.COMMENT.
        end. /* do i = 1 TO 3: */
        put stream s-print
            "SOLD TO: "                 at 1
            ORDER.CUSTOMER              at 10
            ORDER.NAME                  at 17
            "SHIP TO: "                 at 46
            ORDER.SH_NAME               at 53
            SKIP
            CUSTOMER.ADDRESS[1]         at 17
            ORDER.SH_ADDRESS[1]         at 53
            CUSTOMER.ADDRESS[2]         at 17
            ORDER.SH_ADDRESS[2]         at 53
            SKIP
            CUSTOMER.CITY               at 17
            CUSTOMER.STATE              at 33
            CUSTOMER.ZIP                at 36
            ORDER.SH_CITY               at 53
            ORDER.SH_STATE              at 71
            ORDER.SH_ZIP                at 74
            SKIP(1)
            "SALESREP: "                at 1
            ORDER.SALESREP              at 11
            SALESREP.NAME               at 15
            "ORDER DATE:"               at 50
            ORDER.ORDER_DT              at 63
            "TERMS:"                    at 1
            termsdesc                   at 11
            "SHIP DATE:"                at 51
            ORDER.SHIP_DT               at 63
            SKIP(1).

        if ORDER.INSTRUCTION > ""
        then put stream s-print
                "SPECIAL INSTRUCTIONS: " at 1 
                ORDER.INSTRUCTION        at 24
                SKIP.
        if comm[3] > ""
        then put stream s-print
                "SHIPPING INSTRUCTIONS: " at 1
                comm[3]                   at 24
                SKIP.
        if comm[2] > ""
        then put stream s-print
                "BILLING INSTRUCTIONS: "  at 1
                comm[2]                   at 24
                SKIP.
        put stream s-print skip(1).

        for each ORDER_ITEM use-index ORDER_LINE 
            where ORDER_ITEM.CO = w-co
              and ORDER_ITEM.ORDER = ORDER.ORDER
              and ORDER_ITEM.LINE > 0
            no-lock:
            find ITEM_UNIT
                where ITEM_UNIT.CO = w-co
                  and ITEM_UNIT.ITEM = ORDER_ITEM.ITEM
                  and ITEM_UNIT.UNIT = ORDER_ITEM.UNIT
                no-lock no-error.
            find ITEM
                where ITEM.CO = w-co
                  and ITEM.ITEM = ORDER_ITEM.ITEM
                no-lock no-error.
            put stream s-print
                ORDER_ITEM.LINE         format "ZZ9"        at 1
                ORDER_ITEM.ITEM         format "X(10)"      at 5
                ORDER_ITEM.UNIT                             at 16
                ORDER_ITEM.DESCRIPTION                      at 20
                ORDER_ITEM.QTY_ORD      format "ZZ9-"       at 51
                ORDER_ITEM.QTY_SHIP     format "ZZ9-"       at 55
                ORDER_ITEM.PRICE        format "Z,ZZ9.99"   at 59
                ORDER_ITEM.EXTEND       format "ZZ,ZZ9.99-" at 67
                ORDER_ITEM.TAX&         format "Y/N"        at 77
                ORDER_ITEM.RW&          format "R/"         at 79
                skip.
        end. /* for each ORDER_ITEM */
        put stream s-print SKIP(1)
            "SUB-TOTAL"                                     at 10
            ORDER.TTL_EXT                                   at 23
            SKIP
            "TYP:"                                          at 2
            ORDER.TYPE                                      at 6
            "SALES TAX"                                     at 10
            ORDER.TTL_TAX           format "ZZ,ZZZ.99-"     at 24
            SKIP
            "** TOTAL"                                      at 10
            (ORDER.TTL_EXT + ORDER.TTL_TAX)                 at 23
            SKIP(1).
        output stream s-print close.

        assign
            fax             = W_ORDER.W_FAXBACK
            faxls           = ""
            fax-attn        = CUSTOMER.ATTN
            fax-name        = CUSTOMER.NAME
            fax-comment     = ""
            fax-comment[2]  = " ORDER CONFIRMATION GENERATED ON " +
                              string(today) + string(time,"HH:MM:SS")
            print-also&     = no
            fax-from        = "FAXBACK CONFIRMATION FROM: " + trim(gb-coname)
            h-page          = 1
            spoolfile       = infile + ".fax." + string(cnt).
        /*fax-from*/

        assign gb-realid = trim(gb-realid).
        {we_run.i u/u_faxcov.p}.
        {we_run.i u/u_faxq.p}.
    end. /* each W_ORDER */
    assign gb-realid = h-gbrealid.
end procedure. /* Fax-Back: */

Procedure Wait-Time:

    {we_run.i Check-Trace}

    assign messages-line = "Waiting " + string(wait-secs,">>9") + " seconds".
    run Set-Dbg-DTTM.
    message dbg-dttm + " " + prog-name + ": " + messages-line.
    pause wait-secs.
    
    if search(shuts[1]) = shuts[1]
    or search(shuts[2]) = shuts[2]
    or string(time,"HH:MM:SS") > "23:30:00"
    then do:
        run Set-Dbg-DTTM.
        messages-line =
            dbg-dttm + " " + prog-name + ": Shutdown token detected - " +
            if search(shuts[1]) = shuts[1] 
            then shuts[1] 
            else if search(shuts[2]) = shuts[2]
            then shuts[2]
            else if string(time,"HH:MM:SS") > "23:30:00"
            then ("time-of-day expired " +
                  string(time,"HH:MM:SS") + " > 23:30:00")
            else "UNKNOWN".
        message messages-line.
        assign shut& = yes.
        return.
    end. /* if not search(shuts[1]) = shuts[1] */
    else assign
            shut&          = no
            messages-line  = ""
            messages-lines = "".
end procedure. /* Wait-Time: */

Procedure Initialization:
    {we_dbgproc.i Initialization "Begins"}
    if not available(SYS_CONTROL)
    then find first SYS_CONTROL no-lock no-error.
    assign
        batch-dir   = SYS_CONTROL.BATCH_DIR
        temp-dir    = SYS_CONTROL.TEMP_DIR
        ftp-ctl-dsn = replace(ftp-ctl-dsn,"[BATCHDIR]",batch-dir).
    {we_run.i Load-tt-Controls}.
    assign
        submit-dir  = trim(tt-Controls.Local-Submit-Dir,"/")
        submit-dir  = trim(substr(submit-dir,r-index(submit-dir,"/")),"/")
        confirm-dir = trim(tt-Controls.Local-Confirm-Dir,"/")
        confirm-dir = trim(substr(confirm-dir,r-index(confirm-dir,"/")),"/")
        subproc-dir = trim(tt-Controls.Local-Sub-Proc-Dir)
        cnfproc-dir = trim(tt-Controls.Local-Cnf-Proc-Dir)
        wait-secs   = tt-Controls.Wait-Seconds.
    {ps_batchdir.i subproc-dir}
    {ps_batchdir.i cnfproc-dir}
        {we_debug.i 
            "'wait-secs: ' wait-secs
             'Wait-Seconds: ' tt-Controls.Wait-Seconds"}.
         
    find first tt-Controls
        where tt-CONTROLS.Pgm-Name = "ps_order.p"
        no-lock no-error.
    assign
        local-base-dir     = tt-Controls.Local-Base-Dir
        remote-submit-dir  = tt-Controls.Remote-Submit-Dir
        remote-confirm-dir = tt-Controls.Remote-Confirm-Dir
        local-submit-dir   = tt-Controls.Local-Submit-Dir
        local-confirm-dir  = tt-Controls.Local-Confirm-Dir
        ftp-cmd-dsn[1] = replace(ftp-cmd-dsn[2],"[TMP]",temp-dir)
        ftp-cmd-dsn[1] = 
            replace(ftp-cmd-dsn[1],"[PGMNAME]",tt-Controls.Pgm-Name)
        ftp-cmd-dsn[1] = replace(ftp-cmd-dsn[1],"[FTPDTTM]",ftp-dttm)
        ftp-cmd-ini[1] = replace(ftp-cmd-ini[2],"[TMP]",temp-dir)
        ftp-cmd-ini[1] =
            replace(ftp-cmd-ini[1],"[PGMNAME]",tt-Controls.Pgm-Name)
        ftp-cmd-ini[1] = replace(ftp-cmd-ini[1],"[FTPDTTM]",ftp-dttm)
        ftp-cmd-ini[1] = trim(ftp-cmd-ini[1])
        ftp-cmd-log[1] = replace(ftp-cmd-log[2],"[TMP]",temp-dir)
        ftp-cmd-log[1] =
            replace(ftp-cmd-log[1],"[PGMNAME]",tt-Controls.Pgm-Name)
        ftp-cmd-log[1] = replace(ftp-cmd-log[1],"[FTPDTTM]",ftp-dttm)
        rm-cmds[1]     = replace(rm-cmds[2],"[TMP]",temp-dir)
        trace-log[1]   = replace(trace-log[2],"[TRACEDIR]",batch-dir).
    {ps_batchdir.i local-base-dir}
    {ps_batchdir.i local-submit-dir}
    {ps_batchdir.i local-confirm-dir}
    
    run Set-Dbg-DTTM.
    message dbg-dttm + " " + prog-name + ": "
            'Initialization'                                        skip
            'BTCH:' batch-dir         'TEMP: ' temp-dir             skip
            'LSD:'  local-submit-dir  'LCD:  ' local-confirm-dir    skip
            'RSD:'  remote-submit-dir 'RCD:  ' remote-confirm-dir   skip
            'DataBase:' gb-coname.
    {we_dbgproc.i Initialization "Ends"}
end procedure. /* Initialization: */

Procedure Check-Trace:
    assign debug& = no dbgproc& = no runi& = no ftp-verb = "".
    Check-Traces: do i = 1 to extent(trace-dsns) by 1:
        assign trace-dsn = trace-dsns[i].
        if search(trace-dsn) = trace-dsn
        then do:
            assign trace& = yes.
            if index(trace-dsn,"all") > 0
            then do:
                assign
                    debug&      = yes
                    dbgproc&    = yes
                    runi&       = yes
                    ftp-verb  = " -d ". 
                leave Check-Traces.
            end. /* if index(trace-dsn,"all") > 0 */
            if index(trace-dsn,"debug") > 0
            then do:
                assign debug& = yes.
                leave Check-Traces.
            end. /* if index(trace-dsn,"debug") > 0 */
            if index(trace-dsn,"dbgproc") > 0
            then do:
                assign dbgproc& = yes.
                leave Check-Traces.
            end. /* if index(trace-dsn,"dbgproc") > 0 */
            if index(trace-dsn,"run") > 0
            then do:
                assign runi& = yes.
                leave Check-Traces.
            end. /* if index(trace-dsn,"run") > 0 */
            if index(trace-dsn,"ftp") > 0
            then do:
                assign ftp-verb = " -d ".
                leave Check-Traces.
            end. /* if index(trace-dsn,"ftp") > 0 */
        end. /* if search(trace-dsn) = trace-dsn */
        else assign trace& = no.
    end. /* Check-Traces: */
    if trace& = no
    then assign messages-line = "Traces Turned Off".
    else assign
            messages-lines[1] = "Trace/s Set:"
            messages-lines[2] = "    Debug[" + string(debug&,"YES/NO")   + "]"
            messages-lines[3] = "  Dbgproc[" + string(dbgproc&,"YES/NO") + "]"
            messages-lines[4] = "     Runi[" + string(runi&,"YES/NO")    + "]"
            messages-lines[5] = "      FTP[" + string(ftp-verb,"x(4)")   + "]".
    run Set-Dbg-DTTM.
    message dbg-dttm + " " + prog-name + ": " + messages-line.
end procedure. /* Check-Trace: */

Procedure Clear-Temp-Tables:
    {we_dbgproc.i Clear-Temp-Tables "Begins"}
    for each tt-Controls:       delete tt-Controls.         end.
    for each tt-FTP-Files:      delete tt-FTP-Files.        end.
    for each tt-LTO-Lines:      delete tt-LTO-Lines.        end.
    for each tt-LTP-Lines:      delete tt-LTP-Lines.        end.
    for each tt-Rem-Header:     delete tt-Rem-Header.       end.
    for each tt-Rem-Order:      delete tt-Rem-Order.        end.
    for each tt-Rem-Item:       delete tt-Rem-Item.         end.
    for each tt-Rem-Quote:      delete tt-Rem-Quote.        end.
    for each tt-Pickup-Header:  delete tt-Pickup-Header.    end.
    for each tt-Pickup-Order:   delete tt-Pickup-Order.     end.
    for each tt-Pickup-Item:    delete tt-Pickup-Item.      end.
    for each tt-Confirm-Header: delete tt-Confirm-Header.   end.
    for each tt-Confirm-Order:  delete tt-Confirm-Order.    end.
    for each tt-Confirm-Item:   delete tt-Confirm-Item.     end.
    for each W_ORDER:           delete W_ORDER.             end.
    for each W_ITEM:            delete W_ITEM.              end.
    for each W_MESS:            delete W_Mess.              end.
    for each W_PICKUP:          delete W_PICKUP.            end.
    for each W_PUITEM:          delete W_PUITEM.            end.
    {we_dbgproc.i Clear-Temp-Tables "Ends"}
end procedure. /* Clear-Temp-Tables: */

Procedure Process-Str:  /* Replaces special chars for use in XML exporting */
    def input param in-str as char.
    def output param out-str as char.
    
    def var i as int no-undo.
    
    out-str = "".
    do i = 1 to length(in-str).
        if substr(in-str,i,1) = '&' then
            out-str = out-str + "&amp;".
        else if substr(in-str,i,1) = "'" then
            out-str = out-str + "&apos;".
        else if substr(in-str,i,1) = '"' then
            out-str = out-str + "&quot;".
        else out-str = out-str + substr(in-str,i,1).
    end.
end procedure. /* Process-Str: */

Procedure Debug-Temp-Tables:
    for each tt-Rem-Header by tt-Rem-Header.Seed by tt-Rem-Header.Seed:
        display tt-Rem-Header.Seed length(tt-Rem-Header.Seed) format "zz9"
            with frame frm-remhdrdup no-labels title "Rem-Header".
        for each tt-Rem-Order
            where tt-Rem-Order.Seed begins tt-Rem-Header.Seed
            by tt-Rem-Order.Seed:
            display
                tt-Rem-Order.Seed length(tt-Rem-Order.Seed) format "zz9"
                with frame frm-remorddup no-labels title "Rem-Order".
            for each tt-Rem-Item
                where tt-Rem-Item.Seed begins tt-Rem-Order.Seed
                by tt-Rem-Item.Seed:
                display tt-Rem-Item.Item tt-Rem-Item.Unit
                    tt-Rem-Item.Price tt-Rem-Item.Pricing
                    tt-Rem-Item.Seed
                    with frame frm-remitmdup down title "Rem-Item".
            end.
        end.
    end.
    hide frame frm-remhdrdup.
    hide frame frm-remorddup.
    hide frame frm-remitmdup.
    for each W_ORDER by W_ORDER.W_SEED:
        display W_ORDER.W_SEED format "x(50)" label "OrderSeed"
            with frame frm-worddup title "W_ORDER".
        for each W_ITEM
            where W_ITEM.W_SEED = W_ORDER.W_SEED
            by W_ITEM.W_SEED by W_ITEM.W_LINE:
        display
            W_ITEM.W_SEED  format "x(50)" label "ItemSeed"
            W_ITEM.W_LINE format "9999" W_ITEM.W_ITEM  W_ITEM.W_UNIT
            with frame frm-witmdup down title "W Files".
        end.
    end.
    hide frame frm-worddup.
    hide frame frm-witmdup.
    for each tt-Rem-Quote:
        display tt-Rem-Quote
            with frame frm-remquote down title "tt-Rem-Quote".
    end.
    /*
    pause message "DEBUG Quiting Seed".
    quit.
    */
end procedure. /* Debug-Temp-Tables: */

{we_messages.i ": "}
{we_setdbgdttm.i}
