


go
use CpsWarehouse
go


drop proc if exists cps_hchp.rpt_EncounterDetails_HFSpecialist;
go
create proc cps_hchp.rpt_EncounterDetails_HFSpecialist
as
begin
	;with u as (
		select 
			c.HF_Housing_Specialist,c.Last, c.First,c.Name, c.PatientID, c.Last_HF_Enroll_Date, c.Valid_HF_Discharge_Date, d.ObsDate EncounterDate,
			d.HF_Encounter_Type, d.HF_Method, d.HF_Success, d.HF_Duration, f.OrderCode, d.sdid,DocSigner
		from cps_hchp.rpt_view_HFClients c
			left join cps_hchp.HCHP_Dashboard d on c.pid = d.PID and HF_Encounter_Type is not null
			left join cps_orders.Fact_all_orders f on f.SDID = d.SDID
		where c.HF_Housing_Specialist is not null
	)
		select 
			distinct HF_Housing_Specialist,Last, First,Name, PatientID, Last_HF_Enroll_Date, Valid_HF_Discharge_Date, EncounterDate,
			HF_Encounter_Type, HF_Method, HF_Success, HF_Duration, DocSigner,
			stuff((select distinct ', ' + OrderCode 
					from u ux
					where u.sdid = ux.SDID
						for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'') EnablingCodes
		from u
end
go

