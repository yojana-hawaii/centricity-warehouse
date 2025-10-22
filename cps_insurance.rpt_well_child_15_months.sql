

USE CpsWarehouse
go


drop PROCEDURE if exists [cps_insurance].[rpt_Well_Child_15_Months] 

go
create procedure [cps_insurance].[rpt_Well_Child_15_Months] 
	(
		@StartDate DATE,
		@EndDate DATE,
		@Insurance nvarchar(20)
	)
AS
BEGIN

--declare @reporting_start date = '2021-01-01', @reporting_end date = '2021-6-30';

declare @dob_start date = dateadd(day, -455, @StartDate), 
	@dob_end date = dateadd(day, -455, @EndDate);

--select @dob_start Start_Dob, @dob_end End_Dob



drop table if exists #well_child15;
select distinct
	pp.PatientID, ic.InsuranceName, pp.DoB,  
	pvt.PID
into #well_child15
from cps_visits.PatientVisitType pvt
	left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pvt.InsuranceCarrierUsed
	left join cps_all.PatientProfile pp on pp.pid = pvt.PID
where 
	--DoS >= @dos_start  (/*being seen in that period is not a requirement*/)
	--and DoS <= @dos_end
	 ic.Classify_Major_Insurance = @Insurance
	and pp.DoB >= @dob_start
	and pp.DoB <= @dob_end

--select * from #well_child15

;with visits as (
	select 
		w15.PatientID, w15.InsuranceName, w15.DoB, 
		dateadd(day, 455, w15.Dob) Cutoff_Date, convert(date,DoS) DoS,
		RowNum = ROW_NUMBER() over(partition by patientId order by Dos Desc)
	from #well_child15 w15
		left join cps_visits.PatientVisitType pvt on pvt.PID = w15.PID 
													and pvt.DoS <= dateadd(day, 455, Dob)
	where cptcode like '%99381%'
		or cptcode like '%99382%'
		or cptcode like '%99383%'
		or cptcode like '%99384%'
		or cptcode like '%99385%'
		or cptcode like '%99391%'
		or cptcode like '%99392%'
		or cptcode like '%99393%'
		or cptcode like '%99394%'
		or cptcode like '%99395%'
		or cptcode like '%99461%'
)
,total_cnt as (
	select v.PatientID, Count(*) TotalVisit
	from visits v
	group by v.PatientID
)
, pivoted as (
	select pvt.PatientID, pvt.[1], pvt.[2], pvt.[3],pvt.[4], pvt.[5], pvt.[6],pvt.[7], pvt.[8],pvt.[9],pvt.[10]
	from (
		select  PatientID, DoS, RowNum
		from visits
	) q
	pivot (
		max(DoS)
		for RowNum in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
	) pvt
)
	select distinct
		v.PatientID, v.DoB, v.InsuranceName Insurance, c.TotalVisit, v.Cutoff_Date,
		pvt.[1], pvt.[2], pvt.[3],pvt.[4], pvt.[5], pvt.[6],pvt.[7], pvt.[8],pvt.[9],pvt.[10]
	from pivoted pvt
		left join total_cnt c on c.PatientID = pvt.PatientID
		left join visits v on v.PatientID = pvt.PatientID;
end

go
