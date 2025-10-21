USE CpsWarehouse
GO

drop proc if exists [cps_orders].[rpt_EnablingCodeCount_HCHP] ;
go
create procedure [cps_orders].[rpt_EnablingCodeCount_HCHP] 
	@StartDate date,
	@EndDate date
as 
begin
--	declare @date date = '2022-06-01';

--Declare 
--	@month varchar(20),
--	@year int;


--set @date = dateadd( day, -15, @date )
--set	@month = datename(month, @date)
--set	@year = year(@date)


select --distinct OrderCode
	df.ListName, df.UserName,df.JobTitle, df.PVID, 
	--o.OrderCode,
	case 
		when o.OrderCode like '%CM001' then 'Assess'
		when o.OrderCode like '%CM002' then 'Tx Plan'
		when o.OrderCode like '%CM003' then 'Referral'
		when o.OrderCode like '%FC001' then 'Financial'
		when o.OrderCode like '%HE001' then 'Health Ed'
		when o.OrderCode like '%IN001' then 'Interpret'
		when o.OrderCode like '%OR001' then 'OR Svc'
		when o.OrderCode like '%OT001' then 'Other ES'
		when o.OrderCode like '%TR001' then 'Transit'

		when o.OrderCode like '%OT002.1' then 'S-F2F'
		when o.OrderCode like '%OT002.2' then 'U-F2F'
		when o.OrderCode like '%OT002.3' then 'SL10-F2F'
		when o.OrderCode like '%OT002.4' then 'S-TC'
		when o.OrderCode like '%OT002.5' then 'U-TC'
		when o.OrderCode like '%OT002.6' then 'SL10-TC'
		when o.OrderCode like '%OT002.7' then 'S-Collat'
		when o.OrderCode like '%OT002.8' then 'U-Collat'
		when o.OrderCode like '%OT002.9' then 'SL10-Collat'
		when o.OrderCode like '%OT002.10' then 'S-OR'
		when o.OrderCode like '%OT002.11' then 'U-OR'
		when o.OrderCode like '%OT002.12' then 'SL10-OR'


	else o.OrderCode
	end OrderCode, 
	o.OrderDate--, count(*) Total /*pivot in ssrs*/
from CpsWarehouse.cps_orders.rpt_view_EnablingCodes o
	left join CpsWarehouse.cps_all.DoctorFacility df on df.PVID = o.OrderProviderID
	--left join dbo.dimDate d on d.date  = o.OrderDate
where 
	(JobTitle in ('CBCM Case Manager', 'Permanent Supportive Housing', 'HF Case Manager', 'HF Housing Specialist', 'Outreach') or df.UserName = 'ldavis')
	--and d.MonthName = @month
	--and d.year = @year
	and o.OrderDate >= @StartDate
	and o.OrderDate <= @EndDate

end
go
