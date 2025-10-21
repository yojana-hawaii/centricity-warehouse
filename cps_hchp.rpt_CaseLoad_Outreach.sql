go
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_CaseLoad_Outreach;
go


create proc cps_hchp.rpt_CaseLoad_Outreach
as
begin
	select 
		c.Outreach,c.Last, c.First, c.Name, c.PatientID, c.DoB, c.Last_Outreach_Enroll_date, c.Valid_Outreach_Discharge_Date,
		c.Last_Housing_Status,Last_Housed_date,Last_KPHC_Consent,
		c.Address1, c.Address2, c.City, c.Zip, c.Phone1, c.Phone2, c.Phone3, c.PrimaryInsurance, c.SecondaryInsurance,
		c.Last_Outreach_Intake_Date, c.Last_Outreach_Assessment_Date, c.Last_Outreach_Treatment_Date, c.Last_Outreach_ProgressNote_Date
	from cps_hchp.rpt_view_OutreachClients c

end

go
