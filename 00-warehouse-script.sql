
USE master
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_WARNINGS ON
GO

/*

mklink /d c:\CpsWarehouse \\fileserver\it\apps\sql\centricity-warehouse

linked server separate

Turn on sqlCmd Mode --> Query --> sqlCmd Mode
--create user report
--Job Separately
*/

/******************dbo path******************/
:setvar path_main c:\CpsWarehouse


GO
/*create database - 4*/
:r $(path_main)\01_create_database.sql
:r $(path_main)\02_create_schema.sql
:r $(path_main)\dbo.dimDates.sql
exec cpswarehouse.dbo.ssis_dimDate
-- no stored proc
--:r $(path_main)\dbo.Numbers.sql
print('Message: Database Created, schema added, dates and number dimension added')

/*functions > 2 + 6 + 3 + 5 + 2 = 18*/
:r $(path_main)\fxn.ClinicalDateToDate.sql
:r $(path_main)\fxn.ClinicalDateToDateTime.sql

:r $(path_main)\fxn.ConvertFlowsheetIntoColumnNameForInsert.sql
:r $(path_main)\fxn.ConvertFlowsheetIntoColumnNameForTable.sql
:r $(path_main)\fxn.ConvertFlowsheetIntoDynamicPivot.sql
:r $(path_main)\fxn.ConvertNdc10ToNdc11.sql
:r $(path_main)\fxn.ConvertObsHdidIntoDynamicPivot.sql
:r $(path_main)\fxn.ConvertRtfToText.sql

:r $(path_main)\fxn.GetSubstringCount.sql
:r $(path_main)\fxn.ProtocolNextDueDate.sql
:r $(path_main)\fxn.ProtocolPastDue.sql


:r $(path_main)\fxn.RemoveAlphaCharacters.sql
:r $(path_main)\fxn.RemoveNonAlphaCharacters.sql
:r $(path_main)\fxn.RemoveNonAlphaNumericCharacters.sql
:r $(path_main)\fxn.RemoveSpecialCharacters.sql
:r $(path_main)\fxn.RemoveWeirdWhiteSpaces.sql

:r $(path_main)\fxn.SplitStrings.sql
:r $(path_main)\fxn.StripMultipleSpaces.sql
print('Message: 18 functions created')




go
print('Message: Schema End')
go

