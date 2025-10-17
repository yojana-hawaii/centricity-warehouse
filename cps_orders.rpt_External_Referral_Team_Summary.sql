use CpsWarehouse
go

drop proc if exists cps_orders.rpt_External_Referral_Team_Summary
go

create proc cps_orders.rpt_External_Referral_Team_Summary
(
	@StartDate date,
	@EndDate date
)
as
begin

	--declare @startDate date = '2021-01-01', 
	--	@endDate date = '2021-02-25';


;with referral_Followup as ( 
	select 
		'Referral' Tpye, PID, 
		d.Month, d.MonthName, d.Year, d.Quarter,
		r.ReferralSpecialist Specialist, r.CurrentStatus, ReferralDate
	from cps_orders.rpt_view_ExternalReferral r
		inner join dbo.dimDate d on d.date = r.ReferralDate
	where 
		r.ReferralDate >= @Startdate
		and r.ReferralDate <= @EndDate
		and ReferralSpecialist is not null

	union 
	select 
		'Follow up' Tpye, PID,
		d.Month, d.MonthName, d.Year, d.Quarter,
		r.FollowupSpecialist, '' CurrentStatus, FollowupDate
	from cps_orders.ReferralFollowup_ByStaff r
		inner join dbo.dimDate d on d.date = r.FollowupDate
	where 
		r.FollowupDate >= @Startdate
		and r.FollowupDate <= @EndDate
		and FollowupSpecialist is not null
)
, monthly as (
	select *
	from (
		select Tpye, PID, Specialist, CurrentStatus , MonthName,  Year
		from referral_Followup
	) q
	pivot (
		count(PID)
		for monthName in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
), quarterly as (
	select *
	from 
	(
		select  Year, quarter, PID, Specialist, Tpye, CurrentStatus
		from referral_Followup
	) q
	pivot
	(
		count(PID)
		for quarter in ([1],[2],[3],[4])
	) pvt
)
, yearly as (
	select Year,  Specialist, Tpye, CurrentStatus, count(*) Total
	from referral_Followup
	group by Year,  Specialist, Tpye, CurrentStatus
)
	select m.*, q.[1] Q1,q.[2] Q2,q.[3] Q3,q.[4] Q4,y.Total
	from monthly m
		left join quarterly q on m.Specialist = q.Specialist and m.Tpye = q.Tpye and m.Year = q.Year and m.CurrentStatus = q.CurrentStatus
		left join yearly y on m.Specialist = y.Specialist and m.Tpye = y.Tpye and m.Year = y.Year and m.CurrentStatus = y.CurrentStatus
	--order by  Specialist, year, tpye, CurrentStatus

end

go
