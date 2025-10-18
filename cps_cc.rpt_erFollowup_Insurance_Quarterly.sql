use CpsWarehouse
go

drop proc if exists [cps_cc].[rpt_erFollowup_Insurance_Quarterly];
go

create proc [cps_cc].[rpt_erFollowup_Insurance_Quarterly]
(
	@years varchar(4) = null,
	@insurances varchar(20) = null
)
as
begin
--	declare @years varchar(4) = 2019, @insurances varchar(20) = 'Alohacare';

declare 
	@year int = case when isnumeric(@years) = 1 then convert(int, @years) end,
	@Insurance varchar(30) = case when @Insurances = 'All' then null else @Insurances end;

with summ as (
	select e.ER_Followup_GUID,
	 e.Actual_Qualified_Appt_Range, ER, d.year, d.quarter, ic.Classify_Major_Insurance
	from cps_cc.ER_Followup e 
		left join dimDate d on d.date = e.DischargeDate
		left join cps_all.PatientInsurance ins on ins.PID = e.PID
		left join cps_all.InsuranceCarriers ic on ins.PrimCarrierID = ic.InsuranceCarriersID
	where year >= 2017
) 
, pvt_on_quarters as (
	select Insurance, [Year], [Actual_Qualified_Appt_Range], ER, p.[1] [Q1], p.[2] [Q2], p.[3] [Q3], p.[4] [Q4]
	from
	(
		select 
			ER_Followup_GUID,Classify_Major_Insurance Insurance, ER, Actual_Qualified_Appt_Range,Year, Quarter
		from summ
	) s
	pivot
	(
		count(ER_Followup_GUID)
		for Quarter in ([1], [2], [3], [4])
	) p
)
, total as (
	select 
		Insurance, Year, 'Total' [Appointment Time (days)], ER, sum(Q1) Q1, sum(Q2) Q2, sum(q3) Q3, sum(q4) Q4,
		Total = sum(Q1) + sum(Q2) + sum(Q3) + sum(Q4)
	from pvt_on_quarters
	group by Insurance, Year, ER
), breakdown as 
(
	select 
		Insurance, year, Actual_Qualified_Appt_Range, ER, Q1, Q2, Q3, Q4,
		Total = Q1 + Q2 + Q3 + Q4
	from pvt_on_quarters
)
	select 
		b.Insurance, b.year, b.Actual_Qualified_Appt_Range [Appointment Time (days)], 
		case b.ER when 0 then 'Hospital' when 1 then 'ER' end ER_Hosp, 
		b.Q1, t.Q1 TotalQ1, 
		b.Q2, t.Q2 TotalQ2, 
		b.Q3, t.Q3 TotalQ3, 
		b.Q4, t.Q4 TotalQ4, 
		b.Total, t.Total TotalYear

	from breakdown B
		left join total t on t.Insurance = b.Insurance and t.year = b.year and t.er = b.er
	where b.Insurance = isnull(@Insurance, b.Insurance)
		and b.year = @year
end

go
