use CpsWarehouse

--select * from cps_all.DoctorFacility where lastname = 'vega'
declare @startdate date = '2022-01-01', @enddate date = '2022-12-31'
drop table if exists #countPerWeek
select *,
	case 
		when LastName in ('young-ajose','delcarmen', 'vega','inada') then 'Family Medicine'
		when LastName in ('Fernandes','rediger') then 'Internal Medicine'
		when LastName in ('nishi') then 'OB/Gyn'
		when LastName in ('ricardo','walter','raymundo','hokari') then 'Peds'
		when LastName in ('tammens','sims','ono','linhares') then 'Midwife'
		when LastName in ('adachi','ho','gelb','kuklok','ramos-yoshida','mamaclay') then 'Aprn'

	end Specialty
into #countPerWeek
from (
	select 

		ap.ListName,  d.WeekOfYear,
		df.LastName, count(*) Total
	
	from cps_visits.Appointments ap
		left join dbo.dimDate d on ap.ApptDate = d.Date
		left join cps_all.DoctorFacility df on df.PVID = ap.PVID
	where ApptDate >= @startdate 
		and ApptDate <= @enddate
		and ApptStatus not in ('data entry error','cancel/facility error')
		and df.LastName in ('young-ajose','delcarmen', 'vega','inada',
							'Fernandes','rediger',
							'nishi',
							'ricardo','walter','raymundo','hokari',
							'tammens','sims','ono','linhares',
							'adachi','ho','gelb','kuklok','ramos-yoshida','mamaclay',
							'mimms')
	group by ap.ListName, df.LastName,   d.WeekOfYear
) x


select ListName Providers, Specialty Jobtitle, AVG(Total) AveragePerWeek
from #countPerWeek
group by ListName, Specialty
order by Specialty, ListName


select  Specialty Jobtitle, AVG(Total) AveragePerWeek
from #countPerWeek
group by  Specialty
order by Specialty