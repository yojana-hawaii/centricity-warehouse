

go
use CpsWarehouse
go


drop proc if exists cps_hchp.rpt_EncounterDetails_Outreach;
go
create proc cps_hchp.rpt_EncounterDetails_Outreach
as
begin
	;with u as (
		select 
			c.Outreach,c.Last, c.First,c.name, c.PatientID, c.Last_Outreach_Enroll_Date, c.Valid_Outreach_Discharge_Date, d.ObsDate EncounterDate,
			d.Outreach_Encounter_Type, d.Outreach_Method, d.Outreach_Success, d.Outreach_Duration, f.OrderCode, d.sdid,DocSigner
		from cps_hchp.rpt_view_OutreachClients c
			left join cps_hchp.HCHP_Dashboard d on c.pid = d.PID and Outreach_Encounter_Type is not null
			left join cps_orders.Fact_all_orders f on f.SDID = d.SDID
	)
		select 
			distinct Outreach,Last, First,Name, PatientID, Last_Outreach_Enroll_Date, Valid_Outreach_Discharge_Date, EncounterDate,
			Outreach_Encounter_Type, Outreach_Method, Outreach_Success, Outreach_Duration, DocSigner,
			stuff((select distinct ', ' + OrderCode 
					from u ux
					where u.sdid = ux.SDID
						for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'') EnablingCodes
		from u
end
go

