go
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_Timeliness_PSH;

go

create proc cps_hchp.rpt_Timeliness_PSH
as
begin

	select 
		h.PSH,h.Last, h.First, Name, PatientID, h.DoB, h.Last_PSH_Enroll_Date, h.Valid_PSH_Discharge_Date,
		h.Last_PSH_Assessment_Date, h.Sec_Last_PSH_Assessment_Date,
		h.Last_PSH_Treatment_Date, h.Sec_Last_PSH_Treatment_Date,
		h.Last_PSH_Intake_Date, h.Sec_Last_PSH_Intake_Date, h.Last_Housed_date

	from cps_hchp.rpt_view_PSHClients h

end
go
