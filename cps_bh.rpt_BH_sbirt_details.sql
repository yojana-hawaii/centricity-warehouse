


use CpsWarehouse
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


drop proc if exists cps_bh.rpt_BH_sbirt_details;
go
create procedure cps_bh.rpt_BH_sbirt_details
(
	@years int = 2021,
	@month int = 1
)
as
begin
	select * 
	from cps_bh.rpt_view_BHSbirt_Code_Obs
	where Year = @years
		and Month = @month
	
end

go