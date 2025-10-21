
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_CaseLoad_CBCM;
go
create proc cps_hchp.rpt_CaseLoad_CBCM
as
begin

	select 
		c.CBCM,c.Last, c.First, c.Name, c.PatientID, c.DoB, c.Last_CBCM_Enroll_Date, c.Valid_CBCM_Discharge_Date,
		c.Last_Housing_Status, Last_Housed_date,Last_KPHC_Consent,
		c.Address1, c.Address2, c.City, c.Zip, c.Phone1, c.Phone2, c.Phone3, c.PrimaryInsurance, c.SecondaryInsurance,
		c.Last_Cbcm_1157Eval_Date, c.Sec_Last_Cbcm_1157Eval_Date,
		c.Last_Cbcm_Assessment_Date, c.Sec_Last_Cbcm_Assessment_Date, 
		c.Last_Cbcm_Treatment_Date, c.Sec_Last_Cbcm_Treatment_Date,
		c.Last_Cbcm_ProgressNote_Date,c.Sec_Last_Cbcm_ProgressNote_Date,
		c.Last_Cbcm_Locus_Date, c.Sec_Last_Cbcm_Locus_Date, 
		c.Last_CBCM_Locus_Level, c.Last_CBCM_Locus_Recommendation, c.Last_CBCM_Locus_Score
	from cps_hchp.rpt_view_CBCMClients c

end
go
