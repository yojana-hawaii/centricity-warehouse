
go
use CpsWarehouse
go
drop proc if exists cps_all.rpt_doctorfacility
go
create proc cps_all.rpt_doctorfacility
(
	@Selection nvarchar(30) = NULL,
	@JobTitle nvarchar(30) = NULL,
	@Specialty nvarchar(30) = NULL
)
as begin



--declare 
--	@Selection varchar(30) = 'Has NPI',
--	@JobTitle nvarchar(30) = 'All',
--	@Specialty nvarchar(30) = 'All'
/*
Billable
Has Schedule
Chart Access
No Chart

Provider
Has NPI
Has SPI
Has DEA
Has State License
Has Specialty License

Active
Inactive

Login One Month
Login Two Month
*/
/*
select distinct JobTitle
from cps_all.DoctorFacility df
where df.inactive = 0
	and df.JobTitle is not null
union 
select 'All'

select distinct Specialty
from cps_all.DoctorFacility df
where df.inactive = 0
	and df.specialty is not null
union 
select 'All'
*/
set
	@JobTitle = case when @JobTitle = 'All' then null else @JobTitle end;
set
	@Specialty = case when @Specialty = 'All' then null else @Specialty end;

declare
	@Billable smallint = case when @Selection <> 'Billable' then null else 1 end,
	@Inactive smallint = case when @Selection <> 'Inactive' then 0 else 1 end,

	@NPI smallint = case when @Selection = 'Has NPI' then 1 else null end,
	@SPI smallint = case when @Selection = 'Has SPI' then 1 else null end,
	@DEA smallint = case when @Selection = 'Has DEA' then 1 else null end,
	@StateLicense smallint = case when @Selection = 'Has State License' then 1 else null end,
	@SpecialtyLicense smallint = case when @Selection = 'Has Specialty License' then 1 else null end,

	@Type nvarchar(30) = case when @Selection = 'Provider' then 'Provider' else null end,
	
	@LoginDate date = case 
						when @Selection = 'Login One Month' then dateadd(day,-30, convert(date,getdate() ) )  
						when @Selection = 'Login Two Month' then dateadd(day,-60, convert(date,getdate() ) )  
						else null end,

	@HasSchedule smallint = case when @selection = 'Has Schedule' then 1 else null end,
	@ChartAccess smallint = case 
								when @selection = 'Chart Access' then 1
								when @selection = 'No Chart' then 0 
								else null end
;




	select 
		df.ListName Name, df.UserName, 
		case when df.Suffix = '' then 'None' else df.suffix end Suffix, 
		df.NPI, df.StateLicenseNo, df.SpecialtyLicenseNo, df.DEA, df.SPI,
		df.AccountCreated, df.LastLogIn, 
		df.Billable, df.HasSchedule, df.ChartAccess, 
		df.Type, df.Inactive,
		case when df.JobTitle = '' then 'None' else df.JobTitle end JobTitle, 
		case when df.Specialty = '' then 'None' else df.Specialty end Specialty, 
		case when df.PreferenceGroup = '' then 'None' else df.PreferenceGroup end PreferenceGroup, 
		case when df.Role = '' then 'None' else df.Role end Role, 
		
		df.Notes, 
		df.HomeLocation MainLOC, df.CurrentLocation LastLOC

	from cps_all.DoctorFacility df
	where pvid > 0 and CentricityUser = 1 and df.DoctorFacilityID <> df.PVID
		and df.Inactive = isnull(@Inactive, df.Inactive)
		and df.Billable = isnull(@Billable, df.Billable)
		and df.LastLogIn > isnull(@LoginDate, '2000-01-01')
		and df.HasSchedule = isnull(@HasSchedule, df.HasSchedule)

		and df.JobTitle = isnull(@JobTitle, df.JobTitle)
		and df.Specialty = isnull(@Specialty, df.Specialty)

		and df.Type = isnull(@Type, df.Type)
		and case when df.NPI is not null then 1 else 0 end = isnull(@NPI, case when df.NPI is not null then 1 else 0 end)
		and case when df.SPI is not null then 1 else 0 end = isnull(@SPI, case when df.SPI is not null then 1 else 0 end)
		and case when df.DEA is not null then 1 else 0 end = isnull(@DEA, case when df.DEA is not null then 1 else 0 end)
		and case when df.StateLicenseNo is not null then 1 else 0 end = isnull(@StateLicense, case when df.StateLicenseNo is not null then 1 else 0 end )
		and case when df.SpecialtyLicenseNo is not null then 1 else 0 end = isnull(@SpecialtyLicense, case when df.SpecialtyLicenseNo is not null then 1 else 0 end)

		and df.ChartAccess = isnull(@ChartAccess, df.ChartAccess)


	
end

go