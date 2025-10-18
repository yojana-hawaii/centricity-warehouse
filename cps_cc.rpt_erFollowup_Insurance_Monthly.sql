use CpsWarehouse
go

drop proc if exists cps_cc.rpt_erFollowup_Insurance_Monthly;
go

create proc [cps_cc].[rpt_erFollowup_Insurance_Monthly]
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
	 e.Actual_Qualified_Appt_Range, ER, year, month, MonthName, e.PrimaryInsuranceGroup
	from cps_cc.rpt_view_er_followup e 
	where year >= 2017
	--where year = @year
	--and Classify_for_Reports_to_Major_Insurance = @insurance	
) 
, pvt_on_month as (
	select 
		Insurance, [Year], month, MonthName, ER,
		isnull(pvt.[0_7], 0) [0_7], isnull(pvt.[8_14], 0) [8_14], isnull(pvt.[15_30], 0) [15_30],
		isnull(pvt.[31+], 0) [31+], isnull(pvt.[Not Yet], 0) [Not Yet]
	from
	(
		select 
			ER_Followup_GUID,PrimaryInsuranceGroup Insurance, ER, Actual_Qualified_Appt_Range,Year, month,  MonthName
		from summ
	) s
	pivot
	(
		count(ER_Followup_GUID)
		for [Actual_Qualified_Appt_Range] in ([0_7], [8_14], [15_30], [31+], [Not Yet])
	) pvt
) --select * from pvt_on_month
, total as (
	select 
		Insurance, Year, month, MonthName, ER, 
		([0_7] + [8_14] + [15_30] + [31+] + [Not Yet]) [Total 0_7] ,
		([0_7] + [8_14] + [15_30] + [31+] + [Not Yet]) [Total 8_14] ,
		([0_7] + [8_14] + [15_30] + [31+] + [Not Yet]) [Total 15_30] ,
		([0_7] + [8_14] + [15_30] + [31+] + [Not Yet]) [Total 31+] ,
		([0_7] + [8_14] + [15_30] + [31+] + [Not Yet]) [Total Not Yet]


		--Total = sum([0_7]) + sum([8_14]) + sum([15_31]) + sum([31+]) +
		--	sum([Not Yet]) 
	from pvt_on_month
	--group by Insurance, Year, month, MonthName, ER
) --select * from total

, breakdown as 
(
	select 
		Insurance, Year, month, MonthName, ER, 
		[0_7], [8_14], [15_30], [31+], [Not Yet],
		Total = [0_7] + [8_14] + [15_30] + [31+] + [Not Yet]
	from pvt_on_month
)
	select 
		b.Insurance, b.year, b.month, b.MonthName, 
		case b.ER when 0 then 'Hospital' when 1 then 'ER' end ER_Hosp, 
		b.[0_7], t.[Total 0_7],
		b.[8_14], t.[Total 8_14],
		b.[15_30], t.[Total 15_30],
		b.[31+], t.[Total 31+],
		b.[Not Yet], t.[Total Not Yet]
	from breakdown B
		left join total t on t.Insurance = b.Insurance and t.year = b.year and t.er = b.er and t.month = b.month
	where b.Insurance = isnull(@Insurance, b.Insurance)
		and b.year = @year
	order by Insurance, year, ER_Hosp, month
end

go
