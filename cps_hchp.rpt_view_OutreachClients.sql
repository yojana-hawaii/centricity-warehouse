
go
use CpsWarehouse
go
drop view if exists cps_hchp.rpt_view_OutreachClients;
go
create view cps_hchp.rpt_view_OutreachClients
as
	SELECT [PID]
		  ,[Outreach]
		  ,[Last_Outreach_Enroll_date]
		  ,[Valid_Outreach_Discharge_Date]
		   ,[Last_Outreach_Intake_Date]
		  ,[Sec_Last_Outreach_Intake_Date]
		  ,[Last_Outreach_Assessment_Date]
		  ,[Sec_Last_Outreach_Assessment_Date]
		  ,[Last_Outreach_Treatment_Date]
		  ,[Sec_Last_Outreach_Treatment_Date]
		  ,[Last_Outreach_ProgressNote_Date]
		  ,[Sec_Last_Outreach_ProgressNote_Date]
		  ,[Last_VISPDAT_Submitted]
		  ,[Last_Path_Enrollment_Date]
		  ,[Last_Housed_date]
		  ,[Last_housing_location]
		  ,[Last_Housing_Program]
		  ,[Last_Housing_Status]
		  ,Last_Outreach_HMIS_Assessment_Completed_Date
		  ,Last_Outreach_HMIS_Consent_Signed_Date
		  ,Last_Cps_Consent
		  ,[PatientID]
		  ,[Last]
		  ,[First]
		  ,name
		  ,[DoB]
		  ,[Address1]
		  ,[Address2]
		  ,[City]
		  ,[Zip]
		  ,[Phone1]
		  ,[Phone2]
		  ,[Phone3]
		  ,[Therapist]
		  ,[Psych]
		  ,[ExternalProvider]
		  ,[PrimaryInsurance]
		  ,[SecondaryInsurance]
	  FROM [CpsWarehouse].[cps_hchp].[rpt_view_hchpDemographics]
	  where Outreach is not null

go
