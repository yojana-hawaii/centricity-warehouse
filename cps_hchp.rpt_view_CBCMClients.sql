
use CpsWarehouse
go
drop view if exists cps_hchp.rpt_view_CBCMClients;
go
create view cps_hchp.rpt_view_CBCMClients
as
	SELECT [PID]
		  ,[cbcm]
		  ,[Last_CBCM_Enroll_Date]
		  ,[Valid_CBCM_Discharge_Date]
		  ,[Last_Cbcm_Assessment_Date]
		  ,[Sec_Last_Cbcm_Assessment_Date]
		  ,[Last_Cbcm_Treatment_Date]
		  ,[Sec_Last_Cbcm_Treatment_Date]
		  ,[Last_Cbcm_ProgressNote_Date]
		  ,[Sec_Last_Cbcm_ProgressNote_Date]
		  ,[Last_Cbcm_1157Eval_Date]
		  ,[Sec_Last_Cbcm_1157Eval_Date]
		  ,[Last_Cbcm_Locus_Date]
		  ,[Sec_Last_Cbcm_Locus_Date]
		  ,[Last_CBCM_Locus_Score]
		  ,[Last_CBCM_Locus_Level]
		  ,[Last_CBCM_Locus_Recommendation]
		  ,[Last_Housed_date]
		  ,[Last_housing_location]
		  ,[Last_Housing_Program]
		  ,[Last_Housing_Status]
		  , Last_Cps_Consent
		  ,Last_BHA_signed_by_Q
		  ,Last_ITP_signed_by_Q
		  ,Last_LOCUS_signed_by_Q
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
	  where cbcm is not null

go
