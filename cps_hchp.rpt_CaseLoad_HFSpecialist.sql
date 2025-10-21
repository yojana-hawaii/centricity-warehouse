go
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_CaseLoad_HFSpecialist;

go


create proc cps_hchp.rpt_CaseLoad_HFSpecialist
as
begin
	select 
		c.HF_Housing_Specialist,c.Last, c.First, c.Name, c.PatientID, c.DoB, c.Last_HF_Enroll_date, c.Valid_HF_Discharge_Date,
		c.Last_Housing_Status,Last_Housed_date,Last_KPHC_Consent,
		c.Address1, c.Address2, c.City, c.Zip, c.Phone1, c.Phone2, c.Phone3, c.PrimaryInsurance, c.SecondaryInsurance,
		c.Last_HF_Intake_Date, c.Last_HF_Assessment_Date, c.Last_HF_Treatment_Date, c.Last_HF_ProgressNote_Date,
		c.Last_HF_Locus_Date, c.Last_HF_Locus_Level, c.Last_HF_Locus_Recommendation, c.Last_HF_Locus_Score
	from cps_hchp.rpt_view_HFClients c
	where c.HF_Housing_Specialist is not null

end
go
