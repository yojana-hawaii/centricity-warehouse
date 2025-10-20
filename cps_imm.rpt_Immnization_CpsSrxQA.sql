go

use CpsWarehouse
go

drop proc if exists cps_imm.rpt_Immnization_CpsSrxQA;
go

create proc cps_imm.rpt_Immnization_CpsSrxQA
(
	@StartDate date ,
	@EndDate date
)
as
begin

--	declare @StartDate date = '11-1-2022', @EndDate date = convert(date, getdate())
	/*
	drop table if exists #cps_data;
	drop table if exists #cps_data_Facility;
	drop table if exists #srx_data;
	drop table if exists #srx_data_facility;

	drop table if exists #cpsSRX;
	drop table if exists #cpsSRX_facility;
	*/
	if OBJECT_ID('tempdb..#cps_data') is  null
	select 
			VaccineGroup VaccineGroup_cps,   NDC NDC_CPS, LotNumber LotNumber_Cps,
			count(*) Total_cps
		into #cps_data
		from (
			select 
				i.PID, VaccineGroup, Brand,  NDC, LotNumber, isnull(i.Facility,loc.Facility) Facility
			from cps_imm.ImmunizationGiven i
				left join cpssql.Centricityps.dbo.document doc on doc.sdid = i.SDID and i.Providers is null
				left join cps_all.Location loc on loc.locID = doc.locofcare
			where AdministeredDate >= @StartDate
				and AdministeredDate < @EndDate
				and wasGiven = 'y'
				and Historical = 'n'
		) x
		group by VaccineGroup,  NDC, LotNumber;	

	if OBJECT_ID('tempdb..#cps_data_Facility') is  null
	select 
			VaccineGroup VaccineGroup_cps,   NDC NDC_CPS, LotNumber LotNumber_Cps,  Facility facility_cps,
			count(*) Total_cps
		into #cps_data_Facility
		from (
			select 
				i.PID, VaccineGroup, Brand,  NDC, LotNumber, isnull(i.Facility,loc.Facility) Facility
			from cps_imm.ImmunizationGiven i
				--left join dbo.dimDate d on d.date = i.AdministeredDate
				left join cpssql.Centricityps.dbo.document doc on doc.sdid = i.SDID and i.Providers is null
				left join cps_all.Location loc on loc.locID = doc.locofcare
			where AdministeredDate >= @StartDate
				and AdministeredDate < @EndDate
				and wasGiven = 'y'
				and Historical = 'n'
		) x
		group by VaccineGroup,  NDC, LotNumber, Facility;	
		
	if OBJECT_ID('tempdb..#srx_data') is  null
	select  
		s.NDCCode NDC10_Srx, fxn.ConvertNdc10ToNdc11(s.NDCCode) NDC11_Converted, s.RXName RXName_srx, s.LotNo LotNo_srx
		, count(*) Total_srx
	into #srx_data
	FROM cpssql.[SRX_KPHC].[dbo].[Shot] s
		left join dbo.dimDate d on d.date = convert(date,s.shotdate)
	where convert(date,s.shotDate) >= @StartDate
		and convert(date,s.shotDate) < @EndDate
		and rxsrxid != 'Testvac'
	group by  s.NDCCode,s.RXName, s.LotNo;
	
	if OBJECT_ID('tempdb..#srx_data_facility') is  null
	select  
		s.NDCCode NDC10_Srx, fxn.ConvertNdc10ToNdc11(s.NDCCode) NDC11_Converted, s.RXName RXName_srx, s.LotNo LotNo_srx, LocationID LocationID_srx
		, count(*) Total_srx
	into #srx_data_facility
	FROM cpssql.[SRX_KPHC].[dbo].[Shot] s
		left join dbo.dimDate d on d.date = convert(date,s.shotdate)
	where convert(date,s.shotDate) >= @StartDate
		and convert(date,s.shotDate) < @EndDate
		and rxsrxid != 'Testvac'
	group by  s.NDCCode,s.RXName, s.LotNo, LocationID;
	

	if OBJECT_ID('tempdb..#cpsSRX') is  null
	select 
		case 
			when VaccineGroup_cps is null then 'Not in CPS'
			when RXName_srx is null then 'Not in SRX'
			when isnull(Total_cps,0) = isnull(Total_srx,0) then 'match' 
			when isnull(Total_cps,0) > isnull(Total_srx,0)  then 'cps'
			when isnull(Total_cps,0) < isnull(Total_srx,0) then 'srx'--and facility_cps not like '%*'  
		else 'x' end Matching,
		
		isnull(VaccineGroup_cps,'')VaccineGroup_cps , 
		isnull(NDC_CPS,'')NDC_CPS, 
		isnull(LotNumber_Cps,'')LotNumber_Cps, 
		
		isnull(RXName_srx,'') RXName_srx, 
		--isnull(NDC10_Srx,'') NDC_srx, 
		--isnull(LotNo_srx,'') LotNo_srx,
		
		Total_cps, isnull(Total_srx,0)Total_srx

	into #cpsSRX
	from #cps_data cps
		full outer join #srx_data srx on 
				cps.LotNumber_Cps = srx.LotNo_srx 
				--and srx.LocationID_srx = replace(cps.facility_cps,' ','')
				and cps.NDC_CPS = srx.NDC11_Converted

				
	if OBJECT_ID('tempdb..#cpsSRX_Facility') is  null
	select 
		case 
			when VaccineGroup_cps is null then 'Not in CPS'
			when RXName_srx is null then 'Not in SRX'
			when isnull(Total_cps,0) = isnull(Total_srx,0) then 'match' 
			when isnull(Total_cps,0) > isnull(Total_srx,0)  then 'cps'
			when isnull(Total_cps,0) < isnull(Total_srx,0) then 'srx'--and facility_cps not like '%*'  
		else 'x' end Matching,
		
		isnull(VaccineGroup_cps,'')VaccineGroup_cps , 
		isnull(NDC_CPS,'')NDC_CPS, 
		isnull(LotNumber_Cps,'')LotNumber_Cps, 
		facility_cps,
		isnull(RXName_srx,'') RXName_srx, 
		isnull(NDC10_Srx,'') NDC_srx, 
		NDC11_Converted,
		isnull(LotNo_srx,'') LotNo_srx,
		LocationID_srx,
		Total_cps, isnull(Total_srx,0)Total_srx

	into #cpsSRX_Facility
	from #cps_data_Facility cps
		full outer join #srx_data_Facility srx on 
				cps.LotNumber_Cps = srx.LotNo_srx 
				and srx.LocationID_srx = replace(cps.facility_cps,' ','')
				and cps.NDC_CPS = srx.NDC11_Converted;

	
	select 
		case 
			when VaccineGroup_cps is null or VaccineGroup_cps = '' then 'Not in CPS'
			when RXName_srx is null or RXName_srx= '' then 'Not in SRX'
			when isnull(Total_cps,0) = isnull(Total_srx,0) then 'match' 
			when isnull(Total_cps,0) > isnull(Total_srx,0)  then 'cps'
			when isnull(Total_cps,0) < isnull(Total_srx,0) then 'srx'--and facility_cps not like '%*'  
		else 'x' end Matching,
		VaccineGroup_cps, lower(RXName_srx)RXName_srx,NDC_CPS,LotNumber_Cps, Total_cps,Total_srx,
		max(case when Facility = 'facA' then loc_Total_cps end) Total_CPS_A,
		max(case when Facility = 'facB' then loc_Total_srx end) Total_SRX_B
	from (
		select 
			--c.Matching, 
			c.VaccineGroup_cps, c.NDC_CPS, c.LotNumber_Cps, c.RXName_srx, c.Total_cps, c.Total_srx, 
			isnull(facility_cps, LocationID_srx) Facility, 
			f.Total_cps loc_Total_cps, f.Total_srx loc_Total_srx
		from #cpsSRX c
			left join #cpsSRX_Facility f on f.VaccineGroup_cps = c.VaccineGroup_cps and f.LotNo_srx = c.LotNumber_Cps
		--where c.LotNumber_Cps = 'KM72C'
	) x
	group by  VaccineGroup_cps, RXName_srx,NDC_CPS,LotNumber_Cps, Total_cps,Total_srx
	--order by VaccineGroup_cps, NDC_CPS, LotNumber_Cps, Matching
end
go