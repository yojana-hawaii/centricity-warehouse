
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
:r $(path_main)\dbo.Numbers.sql
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

/*cps all > 3 + 4 + 4 + 1 + 2 + 9 = 23*/
--before temp views
:r $(path_main)\cps_all.ssis_Location.sql
:r $(path_main)\cps_all.ssis_Location-x.sql
:r $(path_main)\cps_all.ssis_DoctorFacility.sql
-- before patient Profile
:r $(path_main)\cps_all.tmp_view_PatientProvider.sql
:r $(path_main)\cps_all.tmp_view_PatientEthnicity.sql
:r $(path_main)\cps_all.tmp_view_PatientEducation.sql
:r $(path_main)\cps_all.tmp_view_PatientCountry.sql
--SSIS
:r $(path_main)\cps_all.ssis_PatientProfile.sql
:r $(path_main)\cps_all.ssis_PatientRace.sql
:r $(path_main)\cps_all.ssis_InsuranceCarriers.sql
:r $(path_main)\cps_all.ssis_PatientInsurance.sql

:r $(path_main)\cps_all.view_DoctorFacility_Active_30days.sql

:r $(path_main)\cps_all.rpt_view_ActiveProviders.sql
:r $(path_main)\cps_all.rpt_view_major_Insurances.sql

:r $(path_main)\cps_all.rpt_active_facility.sql
:r $(path_main)\cps_all.rpt_active_insurance.sql
:r $(path_main)\cps_all.rpt_ActiveProviders.sql
:r $(path_main)\cps_all.rpt_doctorfacility.sql
:r $(path_main)\cps_all.rpt_facility.sql
:r $(path_main)\cps_all.rpt_identify_patient_insurance.sql
:r $(path_main)\cps_all.rpt_identify_patient_with_InsuranceID.sql
:r $(path_main)\cps_all.rpt_InsuranceCarrier_Classify.sql
:r $(path_main)\cps_all.rpt_quest_patient_income.sql

print('Message: 23 cps_all created')



/*ssis job*/
:r $(path_main)\dbo.ssis_job_cps_all.sql
:r $(path_main)\dbo.ssis_job_cps_visit.sql
:r $(path_main)\dbo.ssis_job_cps_orders.sql
:r $(path_main)\dbo.ssis_job_cps_setup.sql
print('Message: jobs created')



/*run ssis*/
go
exec cpswarehouse.dbo.ssis_job_cps_all
print('Message: cps_all ssis complete')
go
exec cpswarehouse.dbo.ssis_job_cps_visit
print('Message: cps_visit ssis complete')
go
exec cpswarehouse.dbo.ssis_job_cps_orders
print('Message: cps_orders ssis complete')
go
exec cpswarehouse.dbo.ssis_job_cps_setup
print('Message: cps_setup ssis complete')




print('Message: Schema End')
go

