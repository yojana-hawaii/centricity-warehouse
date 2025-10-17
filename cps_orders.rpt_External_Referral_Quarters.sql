

USE CpsWarehouse
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


drop PROCEDURE if exists [cps_orders].[rpt_External_Referral_Quarters] 

go

create procedure [cps_orders].[rpt_External_Referral_Quarters] 
(
	@year int,
	@quarter int
)
as 
begin



--	declare @year int = 2021, @quarter int = 2

 
select d.Year, d.Quarter, r.* 
from cps_orders.rpt_view_ExternalReferral r
	left join dbo.dimDate d on r.OrderDate = d.Date
where 
	d.Year = @year
	and d.Quarter = @quarter


end 
go
