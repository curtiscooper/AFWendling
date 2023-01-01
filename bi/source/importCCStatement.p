/*******************************************************************************
bi/source/importCCStatement.p   

12/31/2022   clc Created

Imports Credit Card Statement to AP

*******************************************************************************/

define temp-table ttCCStatement
  field name as character 
  field employeeID as character 
  field lastFourCard as integer 
  field amount  as decimal 
  field merhcant as character 
  field date as date
  field costCenter as character 
  field expenseType as character 
  field glCode as integer 
  field transactionID as character 
  field id as character 
  field personal as logical
  field transStatus as character
  field reimbursable as character 
  field source as character 
  field businessPurpose as character 
  field notes as character
  .

message "Befor Input"
view-as alert-box.  
  
input from CreditCardImportFile.csv.
repeat:
  create ttCCStatement.
  import delimiter "," ttCCStatement.
end.
input close.

for each ttCCStatement:
  
  display ttCCStatement.
  
end.
