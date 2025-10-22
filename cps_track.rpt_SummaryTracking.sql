

go 
use CpsWarehouse
go

drop proc if exists cps_track.rpt_SummaryTracking;
go
create proc cps_track.rpt_SummaryTracking
(
	@StartDate date,
	@EndDate date
)
as
begin

--declare @startdate date = '2017-01-01', @enddate date = '2023-2-14';

with u as (
	select --top 1000
		pp.PatientID, pp.PID, pp.DoB, pp.Name, doc.Facility, pp.PCP, 
		lower(doc.Summary) Summary, doc.ClinicalDateConverted ClinicalDate, DocAbbr
	from cps_visits.Document doc
		left join cps_all.PatientProfile pp on pp.pid = doc.PID
		left join cpssql.CentricityPS.dbo.obs on obs.sdid = doc.SDID
	where doc.ClinicalDateConverted >= @startdate
		and doc.ClinicalDateConverted <= @enddate
		and doc.DocType = '1542266325850610'
		and doc.Summary like '%tracking%'
)
,removed as (
	select * 
	from u 
	where summary like '%end%' or summary like '%remove%'
)
, tracking as (
	select * 
	from u 
	where summary not like '%end%' and  summary not like '%remove%' 
)
	select distinct
		t.Name, t.PatientID, t.DoB, t.PCP, t.Facility, t.ClinicalDate as TrackingDate, t.Summary TrackingSummary, r.ClinicalDate as removeDate, r.Summary  RemoveSummary
	from tracking t
		left join removed r on t.PID = r.pid and t.ClinicalDate < r.ClinicalDate
	where r.Summary is null
	
end
go