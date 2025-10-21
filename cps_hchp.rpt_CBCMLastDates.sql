
go
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_CBCMLastDates;
go
create proc cps_hchp.rpt_CBCMLastDates
as
begin
	;with lastenc as (
		select PID, LastEncounter
		from (
				select d.PID,
					isnull(convert(varchar(10),d.ObsDate),'')  + ' (' +  isnull(d.CBCM_Encounter_Type,'') + ' - ' + isnull(d.CBCM_Success,'') + ')' lastEncounter,
					rowNum = ROW_NUMBER() over(partition by d.PID order by d.obsdate desc)
				from cps_hchp.rpt_view_CBCMClients c
				left join cps_hchp.HCHP_Dashboard d on c.pid = d.PID and CBCM_Encounter_Type is not null
			) x
		where rowNum = 1
	), f2f as (
		select PID, Last_F2F
		from (
				select 
					c.PID, 
					isnull(convert(varchar(10),d.ObsDate),'')  + ' (' + isnull(d.CBCM_Success,'') + ')' Last_F2F,
					rowNum = ROW_NUMBER() over(partition by d.PID order by d.obsdate desc)
				from cps_hchp.rpt_view_CBCMClients c
					left join cps_hchp.HCHP_Dashboard d on c.pid = d.PID and CBCM_Encounter_Type is not null
				where d.CBCM_Method = 'face to face'
			) x
			where rowNum = 1
	)
	
		select 
			c.CBCM, c.PID, 
			c.Name, c.PatientID, 
			c.Last_Cbcm_1157Eval_Date, 
			c.Last_Cbcm_Assessment_Date, 
			c.Last_BHA_signed_by_Q,
			c.Last_Cbcm_Treatment_Date, 
			c.Last_ITP_signed_by_Q,
			c.Last_Cbcm_Locus_Date, 
			c.Last_LOCUS_signed_by_Q,
			d.LastEncounter, f2f.Last_F2F
		from cps_hchp.rpt_view_CBCMClients c
			left join lastenc d on d.pid = c.pid 
			left join f2f on f2f.PID = c.PID
		where Valid_CBCM_Discharge_Date is null

end
go