USE CpsWarehouse
GO

drop proc if exists [cps_orders].[rpt_EnablingCodeCount] ;
go
create procedure [cps_orders].[rpt_EnablingCodeCount] 
	@date date
as 
begin
--	declare @date date = '2022-06-01';

Declare 
	@month varchar(20),
	@year int;


set @date = dateadd( day, -15, @date )
set	@month = datename(month, @date)
set	@year = year(@date)


select 
	df.ListName, df.UserName,df.JobTitle, df.PVID, o.OrderCode, o.OrderDate--, count(*) Total /*pivot in ssrs*/
from CpsWarehouse.cps_orders.rpt_view_EnablingCodes o
	left join CpsWarehouse.cps_all.DoctorFacility df on df.PVID = o.OrderProviderID
	left join dbo.dimDate d on d.date  = o.OrderDate
where d.MonthName = @month
	and d.year = @year

end

go
