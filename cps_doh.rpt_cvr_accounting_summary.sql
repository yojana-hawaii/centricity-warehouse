use CpsWarehouse
go

drop proc if exists cps_doh.rpt_cvr_accounting_summary;

go

create proc cps_doh.rpt_cvr_accounting_summary
(
		@years int
	)
as 
begin

--declare @startdate date = '2021-05-01', @enddate date = '2021-05-31'
select cvr.Provider,count(*) Total, d.Year, d.MonthName, d.Month

from [CpsWarehouse].[cps_doh].rpt_view_FindCVRPatients cvr
	left join [cpssql].[CentricityPS].dbo.PatientVisit pv on pv.PatientVisitId = cvr.PatientVisitID
	left join CpsWarehouse.dbo.dimDate d on d.date = convert(date, (CASE WHEN pv.visit IS NOT NULL THEN CONVERT(DATE,pv.Visit) Else cvr.DB_CREATE_DATE END ))
where year (convert(date, (CASE WHEN pv.visit IS NOT NULL THEN CONVERT(DATE,pv.Visit) Else cvr.DB_CREATE_DATE END ))) >= @years
 group by Provider, year, MonthName, Month
end

go
