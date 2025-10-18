

use CpsWarehouse
go

drop view if exists cps_bh.rpt_view_BH_GAD_PHQ;
go
create view cps_bh.rpt_view_BH_GAD_PHQ
as 
	select m.*, pp.PatientID,
		d.Month, d.MonthName, d.Year, d.Quarter
	from cps_bh.BH_phq_Gad m
		left join dbo.dimDate d on d.date = m.ObsDate
		inner join cps_all.PatientProfile pp on pp.pid = m.pid
	where pp.TestPatient = 0
		and m.ObsValue is not null
 

go
