go
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_Timeliness_HFSpecialist;

go

create proc cps_hchp.rpt_Timeliness_HFSpecialist
as
begin

	select 
		h.HF_Housing_Specialist,h.Last, h.First, Name, PatientID, h.DoB, h.Last_HF_Enroll_Date, h.Valid_HF_Discharge_Date,
		h.Last_HF_Intake_Date,h.Sec_Last_HF_Intake_Date,
		h.Last_HF_Assessment_Date, h.Sec_Last_HF_Assessment_Date,
		h.Last_HF_Treatment_Date, h.Sec_Last_HF_Treatment_Date,
		h.Last_HF_Locus_Date, h.Sec_Last_HF_Locus_Date,
		h.Last_HF_Locus_Level, h.Last_Housed_date
	from cps_hchp.rpt_view_HFClients h
	where h.HF_Housing_Specialist is not null

end
go
