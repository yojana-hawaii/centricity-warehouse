
use CpsWarehouse


declare @startdate date = '2022-01-01', @EndDate date  = '2022-12-31'


drop table if exists #resultCount;
select
	obs.PID PID, hd.HDID, hd.ObsTerm, obs.obsvalue
into #resultCount
from cpssql.CentricityPS.dbo.obs
	inner join cps_obs.OBSHEAD hd on hd.HDID = obs.HDID
where 
	OBSDATE >= @startdate
	and obsdate <= @EndDate
	and obs.xid = 1000000000000000000
	and ObsTerm in ('elisa hiv','hiv ab','hiv 1 ab','hiv2 ab wb')

-- total number of results and uniue patients
select
	count(*) TotalResults, count(Distinct PID) UniquePatient
from #resultCount

--total number of orders
select  oc.OrderClassification,oc.OrderDesc, count(*) TotalOrdersIn2022
from cps_orders.OrderCodesAndCategories oc
	inner join cps_orders.Fact_all_orders f on f.OrderCodeID = oc.OrderCodeID
where oc.OrderDesc like '%HIV%' and Inactive  = 0
	and f.OrderDate >= @startdate
	and f.OrderDate <= @EndDate
	and f.Canceled = 0
group by oc.OrderClassification,oc.OrderDesc


-- total appointments for patients with results
select count(*) [Total Visits From Productivity Report - may or may not have HIV test done in that visit]
from #resultCount r
	left join cps_visits.PatientVisitType pvt on pvt.pid = r.PID
where pvt.DoS >= @startdate
	and pvt.DoS <= @EndDate

