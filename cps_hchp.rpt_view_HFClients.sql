
use CpsWarehouse
go
drop view if exists cps_hchp.rpt_view_HFClients;
go
create view cps_hchp.rpt_view_HFClients
as
	SELECT [PID]
		  ,[HF_Case_Manager]
		  ,[HF_Housing_Specialist]
		  ,[Last_HF_Enroll_date]
		  ,[Valid_HF_Discharge_Date]
		  ,[Last_HF_Intake_Date]
		  ,[Sec_Last_HF_Intake_Date]
		  ,[Last_HF_Assessment_Date]
		  ,[Sec_Last_HF_Assessment_Date]
		  ,[Last_HF_Treatment_Date]
		  ,[Sec_Last_HF_Treatment_Date]
		  ,[Last_HF_ProgressNote_Date]
		  ,[Sec_Last_HF_ProgressNote_Date]
		  ,[Last_HF_Locus_Date]
		  ,[Sec_Last_HF_Locus_Date]
		  ,[Last_HF_Locus_Level]
		  ,[Last_HF_Locus_Recommendation]
		  ,[Last_HF_Locus_Score]
		  ,[Last_Housed_date]
		  ,[Last_housing_location]
		  ,[Last_Housing_Program]
		  ,[Last_Housing_Status]
		  , Last_Cps_Consent
		  ,[PatientID]
		  ,[Last]
		  ,[First]
		  ,Name
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
	  where  HF_Case_Manager is not null
		or HF_Housing_Specialist is not null

go
