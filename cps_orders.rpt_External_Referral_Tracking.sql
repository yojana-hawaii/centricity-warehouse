
USE CpsWarehouse
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


drop PROCEDURE if exists [cps_orders].[rpt_External_Referral_Tracking] 

go

create procedure [cps_orders].rpt_External_Referral_Tracking 
(
	@StartDate date,
	@EndDate date,
	@Facility nvarchar(10) = null
)
as 
begin

	--declare @startDate date = '12-15-2019', 
	--	@endDate date = '1-2-2020', 
	--	@facility nvarchar(10) = 'All';



select 
	@Facility = case when @Facility = 'All' then null  else @Facility end



 
select r.* 
from cps_orders.rpt_view_ExternalReferral r
where 
	r.OrderDate >= @Startdate
	and r.OrderDate <= @EndDate
	and r.facilityID = isnull(@facility, r.facilityID)
	and r.CurrentStatus in ('S', 'H')


end 
go
