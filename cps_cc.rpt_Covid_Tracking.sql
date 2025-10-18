
use CpsWarehouse
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
drop proc if exists cps_cc.rpt_covid_tracking

go

create proc cps_cc.rpt_covid_tracking
(
	@StartDate date,
	@EndDate date, 
	@result varchar(10) = null,
	@age varchar(10) = null,
	@order varchar(10),
	@insurance varchar(5)
)
with recompile
as 
begin

/*
Name				Orders	Age		Result		EndDate		StartDate
All Time			all		all		All			tomorrow	jan 1, 2020
No Result			all		all		None		tomorrow	jan 1, 2020
Positive			all		all		Positive	tomorrow	jan 1, 2020
Daily Orders		all		all		all			tomorrow	-1 day
Rolling 7days		all		all		all			tomorrow	-7 days
Under 19			all		19		all			tomorrow	jan 1, 2020		done

No Orders			none	all		all			tomorrow	jan 1, 2020		done
*/

--declare 
--		@startdate date = '2020-01-01', 
--		--@startdate date = convert(date, dateadd(day,-1,getdate()) ),
--		--@startdate date = convert(date, dateadd(day,-7,getdate()) ),

--	@enddate date = convert(date, dateadd(day,1,getdate()) ),
	
--	@result varchar(10) = 'all',
--	--@result varchar(10) = 'None',
	
--	@order varchar(10) = 'all',
--	--@order varchar(10) = 'None',

--	@age varchar(5) = '19',
--	--@age varchar(5) = 'all',

--	@insurance varchar(5) = 'all'
--	--@insurance varchar(5) = 'city'
--	;

	set @result = case when @result = 'all' then null else @result end
	set @age = case when @age = 'all' then null else @age end
	set @order = case when @order = 'all' then null else @order end
	set @insurance = case when @insurance = 'all' then null else @insurance end
	--select @result, @age, @startdate, @enddate

	select 	
		u.pid, u.OrderCode, 
		u.ReceivedDate, u.TestDate,
		PCR_Result,Rapid_Result,
		PCR_Duplicate, Rapid_Duplicate,

		pp.PatientID, 
		pp.Name, pp.Sex, pp.Phone1, pp.Phone2, pp.Phone3, 
		pp.DoB, pp.AgeRounded, pp.Language, 
		race.Race1, race.Race2, race.SubRace1, race.SubRace2, 
		race.Ethnicity1, race.Ethnicity2,
		ic.InsuranceName PrimaryInsurance, ic1.InsuranceName SecondaryInsurance,
		u.Provider, 
		u.Loc, 
		u.Facility, 
		pp.Zip
	from CpsWarehouse.cps_cc.covid_Tracking u
		left join CpsWarehouse.cps_all.PatientProfile pp on pp.PID = u.PID
		left join CpsWarehouse.cps_all.PatientRace race on race.pid = pp.pid
		left join CpsWarehouse.cps_all.PatientInsurance pin on pin.pid = pp.pid
		left join CpsWarehouse.cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pin.PrimCarrierID
		left join CpsWarehouse.cps_all.InsuranceCarriers ic1 on ic1.InsuranceCarriersID = pin.SecCarrierID
	where 
		isnull(pcr_Result,'None') = isnull(@result, isnull(pcr_Result,'None') )
		and isnull(OrderCode,'None') = isnull(@order, isnull(OrderCode,'None') )
		and isnull(AgeRounded,1) <= isnull(@age, isnull(AgeRounded,1))
		and isnull(TestDate, getdate()) <= @EndDate 

		and 
			case 
				when @StartDate = '2020-01-01'
					then isnull(case when TestDate < '2020-01-01' then null else TestDate end, getdate()) 
				else TestDate
				end 
				>= @StartDate
		
		and (@insurance is null or
				(ic.InsuranceCarriersID in (1, 212) /*sliding and self pay*/
					and TestDate is not null
				)
			)
--	order by TestDate



end

go
