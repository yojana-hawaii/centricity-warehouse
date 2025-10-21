
go
use CpsWarehouse
go


drop proc if exists cps_hchp.rpt_EncounterDetails_CBCM;
go
create proc cps_hchp.rpt_EncounterDetails_CBCM
as
begin
	;with u as (
		select 
			c.CBCM,c.Last, c.First, c.Name, c.PatientID, c.Last_CBCM_Enroll_Date, c.Valid_CBCM_Discharge_Date, d.ObsDate EncounterDate,
			d.CBCM_Encounter_Type, d.CBCM_Method, d.CBCM_Success, d.CBCM_Duration, f.OrderCode, d.sdid, d.DocSigner, c.Last_CBCM_Locus_Level
		from cps_hchp.rpt_view_CBCMClients c
			left join cps_hchp.HCHP_Dashboard d on c.pid = d.PID and CBCM_Encounter_Type is not null
			left join cps_orders.Fact_all_orders f on f.SDID = d.SDID
	)
		select 
			distinct CBCM,Last, First, Name, PatientID, Last_CBCM_Enroll_Date, Valid_CBCM_Discharge_Date,  EncounterDate,
			CBCM_Encounter_Type, CBCM_Method, CBCM_Success, CBCM_Duration, DocSigner, Last_CBCM_Locus_Level,
			stuff((select distinct ', ' + OrderCode 
					from u ux
					where u.sdid = ux.SDID
						for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'') EnablingCodes
		from u
end
go
