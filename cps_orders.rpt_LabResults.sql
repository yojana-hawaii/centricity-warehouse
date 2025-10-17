go

USE [CpsWarehouse]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_orders].[rpt_LabResults] 

go
CREATE procedure [cps_orders].[rpt_LabResults] 
(
	@Facility nvarchar(20) = 'All',
	@StartDate date,
	@EndDate date
)
as begin

	--declare @servProv nvarchar(5) = 'CLH',@authProv nvarchar(20) = 'All',
	--@Facility nvarchar(20) = '66',@startDate date = '2018-08-01',	@endDate date = '2018-08-30',@orderID nvarchar(20) = '1849515752603090',@status nvarchar(5) = 'C';

declare 
	@Facility1 nvarchar(20) = @Facility,
	@StartDate1 date = @StartDate,
	@EndDate1 date = @EndDate;

select l.*
from cps_orders.rpt_view_LabResults l
where 
	convert(nvarchar,l.FacilityID) like case when @Facility1 = 'All' then '%' else @Facility1 end 
	and l.OrderDate >= @StartDate1
	and l.OrderDate <= @EndDate1
	and l.CurrentStatus in ('S', 'H')

end

go

