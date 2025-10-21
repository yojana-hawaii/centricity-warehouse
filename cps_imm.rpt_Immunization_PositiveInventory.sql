go
use CpsWarehouse

go


drop proc if exists cps_imm.rpt_Immunization_PositiveInventory;
go

create proc cps_imm.rpt_Immunization_PositiveInventory
as
begin

	SELECT 
		i.netQty, i.location, 
		rx.DrugName, rx.NDCCode NDC10, fxn.ConvertNdc10ToNdc11(rx.NDCCode) NDC11, 
		rx.Mfr, rx.LotNo, convert(date, rx.ExpDate) ExpDate, rx.SourceRcv, rx.Active
	FROM cpssql.[SRX_Cps].[dbo].[InventoryMaster] i
	left join cpssql.[SRX_Cps].[dbo].[Rx] on rx.RxSRXID = i.RxSRXID
	where i.netQty > 0.00
	order by NdcCode, location

end 
go
