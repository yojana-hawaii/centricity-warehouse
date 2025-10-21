
use CpsWarehouse
go
drop table if exists cps_imm.SrxCurrentInventory;
go
create table cps_imm.SrxCurrentInventory
(
	Barcode varchar(50) not null,
	Location varchar(20) not null,
	CreatedDate datetime2 not null,
	Brand varchar(100) not null,
	NDC_SRX varchar(20) not null,
	NDC11Converted varchar(15) not null,
	LotNo varchar(20) not null,
	SourceRcv varchar(20) not null,
	Received decimal(12,2)  null,
	
	PositiveAdj_Duplicate decimal(12,2)  null,
	PositiveAdj_Other decimal(12,2)  null,
	PositiveAdj_Total decimal(12,2)  null,

	NegativeAdj_Wasted decimal(12,2) null,
	NegativeAdj_Destroyed decimal(12,2) null,
	NegativeAdj_Expired decimal(12,2) null,
	NegativeAdj_Returned decimal(12,2) null,
	NegativeAdj_Subtract decimal(12,2) null,
	NegativeAdj_Total decimal(12,2) null,

	TotalAdjustment decimal(12,2) null,

	TransferIn decimal(12,2) null,
	TransferOut decimal(12,2) null,
	TransferTotal decimal(12,2) null,

	TotalAdministered_InvTable decimal(12,2) null,
	TotalAdministeredDose_ShotTable decimal(12,2) null,
	TotalAdministeredCount_ShotTable int null,

	SRX_Remaining_netQty decimal(12,2) not null,

);
go
drop proc if exists cps_imm.ssis_SrxCurrentInventory;
go
create proc cps_imm.ssis_SrxCurrentInventory
as 
begin

	truncate table cps_imm.SrxCurrentInventory;

	drop table if exists #Srx_Count;
	select 
		pvt.RxSRXID Barcode, pvt.[Location] [Location], 
		i.CreatedDate [CreatedDate], 
		rx.NDCCode NDC_Srx,
		rx.RxName [Brand], fxn.ConvertNdc10ToNdc11(rx.NDCCode) [NDC11Converted],rx.LotNo LotNo,rx.SourceRcv,
		[1] Received,
		Case when [2] like 'dup%' then [2] end DuplicatePositiveAdj,
		Case when [2] not like 'dup%' then [2] end OtherPositiveAdj,
		[2] TotalPosAdj, 
		[4] * -1 WastedAdj,
		[5] * -1 DestroyedAdj,
		[6] * -1 ExpiredAdj,
		[9] * -1 ReturnedAdj,
		[3] * -1 SubtractAdj,
		((isnull([3],0) + isnull([4],0) + isnull([5],0) + isnull([6],0) ) * -1) TotalNegAdj,
		isnull([2],0) + ((isnull([3],0) + isnull([4],0) + isnull([5],0) + isnull([6],0) ) * -1) TotalAdj,
		[7] TransferIn,
		([8] * -1) TransferOut,
		isnull([7],0) + (isnull([8],0) * -1) TotalTransfer,
		
		[10] *-1 TotalUsed,
		i.netQty SRX_Remaining_netQty, 
		s.TotalDoseAdministered_ShotTable, s.TotalCount_ShotTable
		
	into #Srx_Count
	from 
		(
			select  [RxSRXID] [RxSRXID],[qty],[tran_typeid] [tran_typeid],[location] [Location]
			from cpssql.[SRX_Cps].[dbo].[Inventory_transection]
			where RxSRXID not in ('TESTMED','TESTVAC')
		) q
		pivot (
			sum(qty)
			for [tran_typeid] in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
		) pvt
			left join cpssql.[SRX_Cps].[dbo].InventoryMaster i on i.RxSRXID = pvt.RxSRXID and i.location = pvt.location
			--left join cpssql.[SRX_Cps].[dbo].[RxHistory] rx on rx.RxSRXID = pvt.RxSRXID
			left join (
				select * from
				(
					select rowNum = ROW_NUMBER() over(partition by RxSRXID order by EditedDate desc), 
					RXSRXID RXSRXID, NDCCode NDCCode,lotNo lotNo, rxName RxName, SourceRcv SourceRcv
					from cpssql.[SRX_Cps].[dbo].[RxHistory]
				) lastChaged
				where rowNum = 1
			) rx on rx.RxSRXID = pvt.RxSRXID
			left join (
				select  
					[RxSRXID],LocationID,-- RxName, NDCCode, LotNo,   
					round(sum(convert(float, dose)),2)*-1 TotalDoseAdministered_ShotTable,
					count(*)*-1 TotalCount_ShotTable
				from cpssql.[SRX_Cps].[dbo].shot
				group by [RxSRXID], LocationID--, RxName, NDCCode, LotNo
			) s on s.RxSRXID = pvt.RxSRXID and s.LocationID = pvt.location

	--exec tempdb.dbo.sp_help @objname = N'#Srx_Count'
	insert into cps_imm.SrxCurrentInventory (
		Barcode,Location,CreatedDate,Brand,NDC_SRX,NDC11Converted,LotNo,SourceRcv,
		Received,
		PositiveAdj_Duplicate,PositiveAdj_Other,PositiveAdj_Total,
		NegativeAdj_Wasted,NegativeAdj_Destroyed,NegativeAdj_Expired, NegativeAdj_Returned,NegativeAdj_Subtract,NegativeAdj_Total,
		TotalAdjustment,

		TransferIn,TransferOut,TransferTotal,

		TotalAdministered_InvTable,TotalAdministeredDose_ShotTable,TotalAdministeredCount_ShotTable,
		SRX_Remaining_netQty
	)
	select  
		Barcode,Location,CreatedDate,Brand,NDC_Srx,NDC11Converted,LotNo,SourceRcv,
		Received,
		DuplicatePositiveAdj,OtherPositiveAdj,TotalPosAdj,
		WastedAdj,DestroyedAdj,ExpiredAdj,ReturnedAdj,SubtractAdj,TotalNegAdj,
		TotalAdj,
		TransferIn,TransferOut,TotalTransfer,
		TotalUsed,TotalDoseAdministered_ShotTable,TotalCount_ShotTable,
		SRX_Remaining_netQty
	from #Srx_Count c

end
go
