
use CpsWarehouse
go


drop view if exists cps_all.tmp_view_PatientEthnicity;
go
create view cps_all.tmp_view_PatientEthnicity
as
with eth as (
	select 
		eth.pid,
		ethnicity.Description,
		rowNum = ROW_NUMBER() over( partition by PID order by eth.LastModified)
	from [cpssql].CentricityPS.dbo.patientethnicity eth
		left join [cpssql].CentricityPS.dbo.MedLists  ethnicity 
						on eth.PatientEthnicityMid = ethnicity.MedlistsID
							and ethnicity.TableName = 'Ethnicity'
)
,eth1 as (
	select *
	from eth 
	where eth.rowNum = 1
)
, eth2 as (
	select *
	from eth 
	where eth.rowNum = 2
)
	select eth1.PID, eth1.Description Ethnicity1, eth2.Description Ethnicity2
	from eth1 
		left join eth2 on eth1.pid = eth2.PID

go
