go
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_Timeliness_Outreach;

go

create proc cps_hchp.rpt_Timeliness_Outreach
as
begin

	select 
		h.Outreach,h.Last, h.First, Name, PatientID, h.DoB, h.Last_Outreach_Enroll_Date, h.Valid_Outreach_Discharge_Date,
		h.Last_Outreach_Assessment_Date, h.Sec_Last_Outreach_Assessment_Date,
		h.Last_Outreach_Treatment_Date, h.Sec_Last_Outreach_Treatment_Date,
		h.Last_Outreach_Intake_date,  h.Sec_Last_Outreach_Intake_date, h.Last_VISPDAT_Submitted, h.Last_Path_Enrollment_Date, 
		h.Last_Outreach_HMIS_Assessment_Completed_Date, h.Last_Outreach_HMIS_Consent_Signed_Date, h.Last_Cps_Consent
	from cps_hchp.rpt_view_OutreachClients h

end
go
