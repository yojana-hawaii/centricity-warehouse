

USE CpsWarehouse
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_insurance].[rpt_Well_Child_30_Months] 

go
create procedure [cps_insurance].[rpt_Well_Child_30_Months] 
	(
		@StartDate DATE,
		@EndDate DATE,
		@Insurance nvarchar(20)
	)
AS
BEGIN

--declare @Startdate date = '2021-01-01', @Enddate date = '2021-6-30', @Insurance varchar(20) = 'HMSA';

declare @dob_start date = dateadd(day, -910, @StartDate), 
	@dob_end date = dateadd(day, -910, @EndDate);

--select @StartDate, @EndDate, @dob_start Start_Dob, @dob_end End_Dob,@Insurance



drop table if exists #well_child30;
select distinct
	pp.PatientID, ic.InsuranceName, pp.DoB,  
	pvt.PID
into #well_child30
from cps_visits.PatientVisitType pvt
	left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pvt.InsuranceCarrierUsed
	left join cps_all.PatientProfile pp on pp.pid = pvt.PID
where 
	--DoS >= @dos_start  (/*being seen in that period is not a requirement*/)
	--and DoS <= @dos_end
	 ic.Classify_Major_Insurance = @Insurance
	and pp.DoB >= @dob_start
	and pp.DoB <= @dob_end

;with visits as (
	select 
		w30.PatientID, w30.InsuranceName, w30.DoB, 
		convert(varchar(10),dateadd(day, 456, Dob) ) + ' and ' + convert(varchar(10), dateadd(day, 910, Dob)) VisitBetween, 
		convert(date,DoS) DoS,
		RowNum = ROW_NUMBER() over(partition by patientId order by Dos Desc)
	from #well_child30 w30
		left join cps_visits.PatientVisitType pvt on pvt.PID = w30.PID 
													and pvt.DoS >= dateadd(day, 456, Dob)
													and pvt.DoS <= dateadd(day, 910, Dob)
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
		v.PatientID, v.DoB, v.InsuranceName Insurance, c.TotalVisit, v.VisitBetween,
		pvt.[1], pvt.[2], pvt.[3],pvt.[4], pvt.[5], pvt.[6],pvt.[7], pvt.[8],pvt.[9],pvt.[10]
	from pivoted pvt
		left join total_cnt c on c.PatientID = pvt.PatientID
		left join visits v on v.PatientID = pvt.PatientID;

end

go
