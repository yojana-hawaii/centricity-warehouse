

use CpsWarehouse
go
drop table if exists cps_imm.SrxDuplicateInventory;
go
create table cps_imm.SrxDuplicateInventory
(
	Barcode varchar(50) not null,
	Brand varchar(100) not null,
	LotNo varchar(20) not null,
	SourceRcv varchar(20) not null,
	[Location] varchar(50) not null,
	DuplicatesByDay_Add decimal(12,2)  null,
	TestPatients_Add decimal(12,2)  null,
	ManualIntoCPS decimal(12,2)  null,
	NotInCentricity_MatchOn_Patient_Lot_AdminDate decimal(12,2)  null,
	
)
go
drop proc if exists cps_imm.ssis_SrxDuplicateInventory;
go
create proc cps_imm.ssis_SrxDuplicateInventory
as
begin

	truncate table cps_imm.SrxDuplicateInventory;


	--select * from cps_imm.SrxCurrentInventory
	declare @CutoffDate date = '2022-11-01';
	drop table if exists #allVaccines;
	select 
		s.patientid PatientID, lotno LotNo, rxname Brand, RxSRXID Barcode, LocationId LocationId, 
		shotdate ShotDate, Dose Dose, SourceRcv SourceRcv, 
		RowNumLastEntry = ROW_NUMBER() over(partition by patientid, RxSRXID,LocationId order by shotdate desc),
		RowNumFirstEntry = ROW_NUMBER() over(partition by patientid, RxSRXID,LocationId order by shotdate desc)

	into #allVaccines-- select top 10 *
	FROM cpssql.[SRX_KPHC].[dbo].[Shot] s
	where RxSRXID not in ('TESTMED','TESTVAC')
		and convert(date, s.shotdate) >= @CutoffDate;

	drop table if exists #dupsPerPatient;
	with dupsPerDay as (
		select 
			PatientID , Brand, LotNo,Barcode,SourceRcv,LocationId, 
			--[2],[3],[4],[5],[6],[7],[8],[9],[10],
			isnull(convert(decimal(12,2),[2]),0.0) + isnull(convert(decimal(12,2),[3]),0.0) + isnull(convert(decimal(12,2),[4]),0.0) 
				+ isnull(convert(decimal(12,2),[5]),0.0) + isnull(convert(decimal(12,2),[6]),0.0) + isnull(convert(decimal(12,2),[7]),0.0) 
				+ isnull(convert(decimal(12,2),[8]),0.0) + isnull(convert(decimal(12,2),[9]),0.0) + isnull(convert(decimal(12,2),[10]),0.0) DuplicatesByDay
		--into #dupsPerPatient
		from (
			select PatientID , Brand, LotNo,Barcode,SourceRcv,LocationId, convert(varchar(5), Dose) Dose,RowNumLastEntry
			from #allVaccines
			where RowNumLastEntry >1
		) q
		pivot (
			max(Dose)
			for RowNumLastEntry in ([2],[3],[4],[5],[6],[7],[8],[9],[10])
		) pvt
	)
	select Brand, LotNo,Barcode,SourceRcv,LocationId, sum(DuplicatesByday) DuplicatesByDay
	into #dupsPerPatient
	from dupsPerDay
	--where LotNo = 'U7373AB'-- and PatientID = '10111202'
	group by Brand, LotNo,Barcode,SourceRcv,LocationId


	drop table if exists #testPatients;
	select Brand, LotNo,Barcode,SourceRcv,LocationId, Sum(convert(decimal(12,2), Dose) ) TestPatients
	into #testPatients
	from #allVaccines v
		inner join cps_all.PatientProfile pp on pp.PatientID = v.PatientID and pp.TestPatient = 1
	group by Brand, LotNo,Barcode,SourceRcv,LocationId

	--	declare @CutoffDate date = '2022-11-01';
	drop table if exists #cps_data;
	select 
		ImmunizationId, i.PID, i.SDID, pp.PatientID, VaccineGroup, Manufacturer, LotNumber, NDC, AdministeredDate, Dose, replace(i.Facility,' ','') Facility
	into #cps_data
	from cps_imm.ImmunizationGiven i
		inner join cps_all.PatientProfile pp on pp.PID = i.PID and pp.TestPatient = 0 /*remove test patient-> already tracked above*/
		inner join cps_visits.Document doc on i.SDID = doc.SDID /*remove unsigned document*/
	where i.wasGiven = 'y' and i.Historical ='n'
		and i.AdministeredDate >= @CutoffDate

	drop table if exists #manualEntryInCps;
	select  
		s.Barcode,s.Brand,m.VaccineGroup,Manufacturer, m.NDC, m.LotNumber, m.Facility, sum(Dose) ManualIntoCPS
	into #manualEntryInCps
	from
		(
			select distinct 
				c.VaccineGroup, Manufacturer,c.NDC, c.LotNumber, c.Facility,c.AdministeredDate, c.Dose
			from #cps_data c
				left join #allVaccines v on c.PatientID = v.PatientID and c.LotNumber = v.LotNo and c.AdministeredDate = convert(date, v.ShotDate) 
			where v.PatientID is null --and RowNumFirstEntry = 1 /*no need coz duplicate in srx will not affect centricity only data*/
			--order by AdministeredDate
			--group by c.VaccineGroup,c.NDC, c.LotNumber, c.Facility,Manufacturer
		) m
			left join cps_imm.SrxCurrentInventory s on m.NDC = s.NDC11Converted and m.LotNumber = s.LotNo and m.Facility = s.Location
	group by s.Barcode,m.VaccineGroup,s.Brand, m.NDC, m.LotNumber, m.Facility,Manufacturer



	drop table if exists #notInCPS;
	select Brand, LotNo,Barcode,SourceRcv,LocationId, Sum(convert(decimal(12,2), v.Dose) ) NotInCentricity_MatchOn_Patient_Lot_AdminDate
	into #notInCPS
	from #allVaccines v
		left join #cps_data c on c.PatientID = v.PatientID and c.LotNumber = v.LotNo and c.AdministeredDate = convert(date, v.ShotDate)
	where c.PatientID is null and RowNumLastEntry = 1
	group by Brand, LotNo,Barcode,SourceRcv,LocationId



	insert into cps_imm.SrxDuplicateInventory(
		Barcode,Brand,LotNo,SourceRcv,Location,
		DuplicatesByDay_Add, 
		TestPatients_Add,
		ManualIntoCPS, 
		NotInCentricity_MatchOn_Patient_Lot_AdminDate
	)
	select 
		i.Barcode, i.Brand,i.LotNo,i.SourceRcv,i.Location, 
		d.DuplicatesByDay, /*SRX will have less so add -> centricity only has one*/
		t.TestPatients,/*SRX will have less so add -> vaccine not really used*/
		m.ManualIntoCPS, /*SRX will have less so add -> manually entered in CPS*/
		n.NotInCentricity_MatchOn_Patient_Lot_AdminDate * -1  /*SRX will have more so subtract -> probably discarded??*/
	from cps_imm.SrxCurrentInventory i
		left join #dupsPerPatient d on d.Barcode = i.Barcode and i.Location = d.LocationId
		left join #testPatients t on t.Barcode = i.Barcode and i.Location = t.LocationId
		left join #notInCPS n on n.Barcode = i.Barcode and i.Location = n.LocationId
		left join #manualEntryInCps m on m.NDC = i.NDC11Converted and m.LotNumber = i.LotNo and m.Facility = i.Location
	where d.DuplicatesByDay is not null or t.TestPatients is not null or m.ManualIntoCPS is not null
	union
	select VaccineGroup + ' - no barcode match', Manufacturer, LotNumber, NDC + ' -  NDC', Facility, null, null, ManualIntoCPS, null
	from #manualEntryInCps m
	where barcode is null


end
go


