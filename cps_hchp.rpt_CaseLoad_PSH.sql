
go
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_CaseLoad_PSH;

go


create proc cps_hchp.rpt_CaseLoad_PSH
as
begin
	select 
		c.PSH,c.Last, c.First, c.Name, c.PatientID, c.DoB, c.Last_PSH_Enroll_Date, c.Valid_PSH_Discharge_Date,
		c.Last_Housing_Status,Last_Housed_date,Last_Cps_Consent,
		c.Address1, c.Address2, c.City, c.Zip, c.Phone1, c.Phone2, c.Phone3, c.PrimaryInsurance, c.SecondaryInsurance,
		c.Last_PSH_Intake_Date, c.Last_PSH_Assessment_Date, c.Last_PSH_Treatment_Date, c.Last_PSH_ProgressNote_Date
	from cps_hchp.rpt_view_PSHClients c

end
go
