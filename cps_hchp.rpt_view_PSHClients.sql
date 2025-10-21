go
use CpsWarehouse
go
drop view if exists cps_hchp.rpt_view_PSHClients;
go
create view cps_hchp.rpt_view_PSHClients
as
	SELECT [PID]
		  ,[PSH]
		  ,[Last_PSH_Enroll_Date]
		  ,[Valid_PSH_Discharge_Date]
		   ,[Last_PSH_Intake_Date]
		  ,[Sec_Last_PSH_Intake_Date]
		  ,[Last_PSH_Assessment_Date]
		  ,[Sec_Last_PSH_Assessment_Date]
		  ,[Last_PSH_Treatment_Date]
		  ,[Sec_Last_PSH_Treatment_Date]
		  ,[Last_PSH_ProgressNote_Date]
		  ,[Sec_Last_PSH_ProgressNote_Date]
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
	  where PSH is not null
		and PatientID not in (12127552, 12106651, 12111213, 12111324, 12079885, 12071738, 12127911,
								12112782, 12093208, 12103829, 12092459, 12073863, 12119647, 12091707,
								12090370, 12110239, 10060200, 12109334, 12109708, 7804600, 12097776,
								12099223, 12090234, 12088717, 12098468, 12090066
							)

go
