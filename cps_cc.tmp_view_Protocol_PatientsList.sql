
use CpsWarehouse
go
drop view if exists [cps_cc].[tmp_view_Protocol_PatientsList]
go
create view [cps_cc].[tmp_view_Protocol_PatientsList]
as

with problems as (
	select p1.PID,	
		(
			select count(sprid)
			from [CpsWarehouse].[cps_diag].[Problem_First_Last_Assessment] p2
			where p1.PID = p2.PID and p2.Inactive = 0
		) ActiveProblemCount,
		stuff((
			select ',' + p3.ICD10Code
			from [CpsWarehouse].[cps_diag].[Problem_First_Last_Assessment] p3
			where p1.PID = p3.PID
			order by p3.OnsetDate
			for xml path('')
		),1,1,'') ICD10Codes
	from [CpsWarehouse].[cps_diag].[Problem_First_Last_Assessment] p1
		inner join cps_visits.Appointments ap on ap.pid = p1.PID and ap.ApptDate > '2019-01-01'
	where p1.Inactive = 0
	group by p1.PID
)
	select 
		p.PID, pp.PatientID, ActiveProblemCount, ICD10Codes,
		case 
			when ICD10Codes like '%E11%' and ICD10Codes like '%E10%' then 12 
			when ICD10Codes like '%E11%' then 2 
			when ICD10Codes like '%E10%' then 1
			else 0 
			end DiabE10_E11,
		case when ICD10Codes like '%I10%' then 1 else 0 end HypertensionI10,
		case when ICD10Codes like '%M80%' then 1 else 0 end OsteoporosisM80,
		case when pp.sex = 'F' and pp.AgeDecimal >= 16 and pp.AgeDecimal <= 24 then 1 else 0 end Female16_24,
	case when pp.sex = 'F' and pp.AgeDecimal >= 21 and pp.AgeDecimal <= 64 then 1 else 0 end Female21_64,
	case when pp.sex = 'F' and pp.AgeDecimal >= 50 and pp.AgeDecimal <= 74 then 1 else 0 end Female50_75,
	case when pp.AgeDecimal >= 50 and pp.AgeDecimal <= 75 then 1 else 0 end All50_75,
	case when pp.AgeDecimal >= 65 then 1 else 0 end All65Plus
	from problems p
		left join cps_all.PatientProfile pp on pp.pid = p.pid

go
