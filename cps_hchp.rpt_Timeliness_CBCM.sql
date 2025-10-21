go
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_Timeliness_cbcm;

go

create proc cps_hchp.rpt_Timeliness_cbcm
as
begin

	select 
		h.cbcm,h.Last, h.First, Name, PatientID, h.DoB, h.Last_CBCM_Enroll_Date, h.Valid_CBCM_Discharge_Date,
		h.Last_Cbcm_Assessment_Date, h.Sec_Last_Cbcm_Assessment_Date,
		h.Last_Cbcm_Treatment_Date, h.Sec_Last_Cbcm_Treatment_Date,
		h.Last_Cbcm_Locus_Date, h.Sec_Last_Cbcm_Locus_Date,
		h.Last_CBCM_Locus_Level
	from cps_hchp.rpt_view_CBCMClients h

end
go
