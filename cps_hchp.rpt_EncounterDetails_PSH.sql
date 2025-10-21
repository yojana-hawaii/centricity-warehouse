


go
use CpsWarehouse
go


drop proc if exists cps_hchp.rpt_EncounterDetails_PSH;
go
create proc cps_hchp.rpt_EncounterDetails_PSH
as
begin
	;with u as (
		select 
			c.PSH,c.Last, c.First,c.Name, c.PatientID, c.Last_PSH_Enroll_Date, c.Valid_PSH_Discharge_Date, d.ObsDate EncounterDate,
			d.PSH_Encounter_Type, d.[PSH_Method], d.PSH_Success, d.PSH_Duration, f.OrderCode, d.sdid,DocSigner
		from cps_hchp.rpt_view_PSHClients c
			left join cps_hchp.HCHP_Dashboard d on c.pid = d.PID and PSH_Encounter_Type is not null
			left join cps_orders.Fact_all_orders f on f.SDID = d.SDID
	)
		select 
			distinct PSH,Last, First,Name, PatientID, Last_PSH_Enroll_Date, Valid_PSH_Discharge_Date, EncounterDate,
			PSH_Encounter_Type, PSH_Method, PSH_Success, PSH_Duration, DocSigner,
			stuff((select distinct ', ' + OrderCode 
					from u ux
					where u.sdid = ux.SDID
						for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'') EnablingCodes
		from u
end
go
