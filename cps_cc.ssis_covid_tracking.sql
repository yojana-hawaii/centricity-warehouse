
USE [CpsWarehouse]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

drop table if exists [cps_cc].[covid_Tracking];
go

create table [cps_cc].[covid_Tracking]
(
	PID numeric(19,0) not null,
	PatientID int not null,
	OrderCode varchar(30) null,
	--OrderDate date null,
	TestDate date null,
	ReceivedDate date null,
	Provider varchar(100) null,
	Loc varchar(20) null,
	Facility varchar(30) null,

	PCR_SDID numeric(19,0) null,
	PCR_Result varchar(100) null,
	PCR_Duplicate smallint null,

	Rapid_SDID numeric(19,0) null,
	Rapid_Result varchar(100) null,
	Rapid_Duplicate smallint null,
	
	Comment varchar(30) null	
)


go


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop proc if exists [cps_cc].[ssis_covid_Tracking]
go

create proc [cps_cc].[ssis_covid_Tracking]
as
begin

	truncate table [cps_cc].[covid_Tracking];

	--select * from #orders order by ordercode where pid = 1499090231550010 order by OrderDate desc
	drop table if exists #orders;
	select 
		f.PId, f.OrderLinkID,
		o.OrderCode, o.CategoryName,
		f.OrderDate, f.ReportReceivedDate, o.OrderClassification,
		f.ResultSDIDList1, f.ResultSDIDList2,
		f.OrderProvider, loc.LocAbbrevName LoC, loc.Facility, 1 Unmatched
	into #orders
	from CpsWarehouse.cps_orders.OrderCodesAndCategories o 
		inner join CpsWarehouse.cps_orders.Fact_all_orders f on f.OrderCodeID = o.OrderCodeID		
		left join CpsWarehouse.cps_all.Location loc on loc.locID = f.LocID								
	where 
		(o.OrderDesc like '%covid%' or o.OrderCode = 'CPT-87636')
		--and o.OrderCode  not in ('CPT-91301', 'CPT-91300','CPT-0011A', 'CPT-0012A', 'CPT-0013A','CPT-0071A', 'CPT-0001A', 'CPT-0002A','CPT-0003A','CPT-0004A','CPT-0064A','COVIGG')
		and o.CategoryName not in ('Immunization Administration','GEImmunizations','Immunizations')
		and f.CurrentStatus != 'X';
	


	-- select * from #covid_obs_PCR
	drop table if exists #covid_obs_PCR; 
	select distinct
		obs.PID Pid, obs.SDID Sdid, convert(date,ObsDate) TestDate, convert(date,obs.db_Create_Date) ReceivedDate, ObsValue ObsValue,
		df.ListName, doc.LoC, doc.Facility, doc.ClinicalDateConverted
	into #covid_obs_PCR
	from cpssql.CentricityPS.dbo.Obs
		left join CpsWarehouse.cps_all.DoctorFacility df on obs.pubuser = df.PVID
		left join CpsWarehouse.cps_visits.Document doc on doc.SDID = obs.sdid
	where obs.hdid = 665997  /*obs covid-19*/
		and obs.xid = 1000000000000000000;

	

	-- select * from #covid_obs_Rapid 
	drop table if exists #covid_obs_Rapid; 
	select distinct
		obs.PID Pid, obs.SDID Sdid, convert(date,ObsDate) TestDate, convert(date,obs.db_Create_Date) ReceivedDate, ObsValue ObsValue,
		df.ListName, doc.LoC, doc.Facility, doc.ClinicalDateConverted
	into #covid_obs_Rapid
	from cpssql.CentricityPS.dbo.Obs
		left join CpsWarehouse.cps_all.DoctorFacility df on obs.pubuser = df.PVID
		left join CpsWarehouse.cps_visits.Document doc on doc.SDID = obs.sdid
	where obs.hdid = 667230  /*obs COVAGRSRAPID - in-house rapid test*/
		and obs.xid = 1000000000000000000;
	



	 --	select * from #covid_pcr_rapid  /*combine on test date - has duplicates*/
	drop table if exists #covid_pcr_rapid_dups;
	select distinct
		case when pcr.pid is null then rap.pid else pcr.Pid end PID,
		case when pcr.TestDate is null then rap.TestDate else pcr.TestDate end TestDate,
		case when pcr.ReceivedDate is null then rap.ReceivedDate else pcr.ReceivedDate end ReceivedDate,
		pcr.ObsValue PCRResult, rap.ObsValue RapidResult,
		case when pcr.ListName is null then rap.ListName else pcr.ListName end ListName,
		case when pcr.LoC is null then rap.LoC else pcr.LoC end LoC,
		case when pcr.Facility is null then rap.Facility else pcr.Facility end Facility,
		pcr.sdid PCR_SDID, 
		pcr.ClinicalDateConverted pcr_ClinicalDateConverted, 
		rap.sdid rapid_sdid,
		rap.ClinicalDateConverted Rapid_ClinicalDateConverted
	into #covid_pcr_rapid_dups
	from #covid_obs_PCR pcr
		full outer join  #covid_obs_Rapid rap on rap.pid = pcr.Pid and pcr.TestDate = rap.TestDate;
	


	--cannot remove duplicate - so mark it
	-- select * from #covid_pcr_rapid_dups_marked
	drop table if exists #covid_pcr_rapid_dups_marked;
	;with rapid_dup as (
		select PID, rapid_sdid, count(*) Rapid_duplicates
		from #covid_pcr_rapid_dups
		where rapid_sdid is not null
		group by pid, rapid_sdid
		having count(*) > 1
	)
	, pcr_dup as (
		select PID, pcr_sdid, count(*) pcr_duplicates
		from #covid_pcr_rapid_dups
		where PCR_SDID is not null
		group by pid, pcr_sdid
		having count(*) > 1
	)
		select 
			d.*, r.Rapid_duplicates, pcr_duplicates, 1 UnmatchedResults
		into #covid_pcr_rapid_dups_marked
		from #covid_pcr_rapid_dups d
			left join rapid_dup r on r.rapid_sdid = d.rapid_sdid
			left join pcr_dup p on p.PCR_SDID = d.PCR_SDID


	 --	select * from #covid_pcr_rapid_dups_marked --where RapidResult is  null and PCRResult is  null /*should always be 0*/

	 -- select * from #lab_report_matches
	drop table if exists #lab_report_matches;
	select distinct
		case when o.PID is null then ob.pid else o.pid end PID, 
		o.OrderLinkID, o.OrderCode, 
	
		case when ob.TestDate is null then o.OrderDate else ob.TestDate end TestDate,
		case when ob.ReceivedDate is null then o.ReportReceivedDate else ob.ReceivedDate end ReceivedDate ,
		
		case when o.OrderProvider is null then ob.ListName else o.OrderProvider end OrderProvider,
		case when o.loc is null then ob.LoC else o.LoC end LoC,
		case when o.Facility is null then ob.Facility else o.Facility end Facility, 

		ob.PCR_SDID,ob.PCRResult ,ob.pcr_ClinicalDateConverted, ob.pcr_duplicates,
		ob.rapid_sdid, ob.RapidResult, ob.Rapid_ClinicalDateConverted, ob.Rapid_duplicates,

		comment = case when ob.PCR_SDID in (o.ResultSDIDList1, o.ResultSDIDList2) then 'lab report match' end
	into #lab_report_matches
	from  #orders o
		full outer join #covid_pcr_rapid_dups_marked ob on ob.pid = o.pid and  ob.PCR_SDID in (o.ResultSDIDList1, o.ResultSDIDList2)

	-- change unmatched bit for matched orders
	update #orders
	set Unmatched = 0
	where OrderLinkID in (
		select distinct OrderLinkID 
		from #lab_report_matches
		where comment is not null
	)

	update #covid_pcr_rapid_dups_marked
	set UnmatchedResults = 0
	where PCR_SDID in (
		select distinct PCR_SDID 
		from #lab_report_matches
		where comment is not null
	)

	update #covid_pcr_rapid_dups_marked
	set UnmatchedResults = 0
	where rapid_sdid in (
		select distinct rapid_sdid 
		from #lab_report_matches
		where comment is not null
	)




	/*match with orders placed in last 14 days*/
	drop table if exists #fourteen_day_match;
	;with orders as (
		select * 
		from #orders o
		where Unmatched = 1
	) --select * from orders
	, obs as (
		select * 
		from #covid_pcr_rapid_dups_marked o
		where UnmatchedResults = 1
	)
	, fourteen_day_match as (
		select 
			case when o.PID is null then ob.pid else o.pid end PID, 
		o.OrderLinkID, o.OrderCode, 
	
		case when ob.TestDate is null then o.OrderDate else ob.TestDate end TestDate,
		case when ob.ReceivedDate is null then o.ReportReceivedDate else ob.ReceivedDate end ReceivedDate ,
		
		case when o.OrderProvider is null then ob.ListName else o.OrderProvider end OrderProvider,
		case when o.loc is null then ob.LoC else o.LoC end LoC,
		case when o.Facility is null then ob.Facility else o.Facility end Facility, 

		ob.PCR_SDID,ob.PCRResult ,ob.pcr_ClinicalDateConverted, ob.pcr_duplicates,
		ob.rapid_sdid, ob.RapidResult, ob.Rapid_ClinicalDateConverted, ob.Rapid_duplicates,

			rowNum = ROW_NUMBER() over(partition by o.pid, o.orderlinkid order by ReceivedDate),
			comment = case when datediff(day, o.OrderDate, ob.ReceivedDate ) < 14
								and  datediff(day, o.OrderDate, ob.ReceivedDate ) >= 0 
							then '14 day match' else null end
		from orders o
			left join obs ob on ob.pid = o.pid --and OrderDate = TestDate
								and  datediff(day, o.OrderDate, ob.ReceivedDate ) < 14
								and  datediff(day, o.OrderDate, ob.ReceivedDate ) >= 0
	)
		select *
		into #fourteen_day_match
		from fourteen_day_match
		where rowNum = 1;

	-- change unmatched bit for matched orders
	update #orders
	set Unmatched = 0
	where OrderLinkID in (
		select distinct OrderLinkID 
		from #fourteen_day_match
		where comment is not null
	)

	update #covid_pcr_rapid_dups_marked
	set UnmatchedResults = 0
	where PCR_SDID in (
		select distinct PCR_SDID 
		from #fourteen_day_match
		where comment is not null
	)

	update #covid_pcr_rapid_dups_marked
	set UnmatchedResults = 0
	where rapid_sdid in (
		select distinct rapid_sdid 
		from #fourteen_day_match
		where comment is not null
	)
	




		
	
	--select * from #lab_report_matches where pid = 1505820816850010
	
	;with u as
	(
		
		select
			pid, 
			orderlinkid, ordercode, TestDate, ReceivedDate,  
			OrderProvider, Loc, Facility,
			PCR_SDID, PCRResult, pcr_ClinicalDateConverted, pcr_duplicates,
			rapid_sdid, RapidResult, Rapid_ClinicalDateConverted, Rapid_duplicates,
			comment
		from #lab_report_matches /*lab result match*/
		where comment is not null
		
		union

		select 
			pid, 
			orderlinkid, ordercode, TestDate, ReceivedDate,  
			OrderProvider, Loc, Facility,
			PCR_SDID, PCRResult, pcr_ClinicalDateConverted, pcr_duplicates,
			rapid_sdid, RapidResult, Rapid_ClinicalDateConverted, Rapid_duplicates,
			comment
		from #fourteen_day_match /**14 day match*/
		where comment is not null

		union
		select 
			pid, 
			null orderlinkid, null ordercode, TestDate, ReceivedDate,  
			ListName, Loc, Facility,
			PCR_SDID, PCRResult, pcr_ClinicalDateConverted, pcr_duplicates,
			rapid_sdid, RapidResult, Rapid_ClinicalDateConverted, Rapid_duplicates,
			'Result without orders' comment
		from #covid_pcr_rapid_dups_marked
		where UnmatchedResults = 1

		union

		--order without result
		select 
			pid, 
			orderlinkid, ordercode, OrderDate, ReportReceivedDate,  
			OrderProvider, Loc, Facility,
			null PCR_SDID, null PCRResult, null pcr_ClinicalDateConverted, null pcr_duplicates,
			null rapid_sdid, null RapidResult, null Rapid_ClinicalDateConverted, null Rapid_duplicates,
			Comment = 'order without result'
		from #orders o
		where o.Unmatched = 1
	)
	--select * from u order by orderdate 
		insert into CpsWarehouse.cps_cc.covid_Tracking(
			pid, PatientID, 
			ordercode, TestDate, ReceivedDate,  
			Provider, Loc, Facility,
			PCR_SDID, PCR_Result, PCR_Duplicate,
			rapid_sdid, Rapid_Result, Rapid_Duplicate,
			comment
		)
		select 	
			u.pid, pp.PatientID,
			ordercode, TestDate, ReceivedDate,  
			OrderProvider, Loc, u.Facility,
			PCR_SDID, PCRResult, pcr_duplicates,
			rapid_sdid, RapidResult, Rapid_duplicates,
			comment
		from u
			inner join CpsWarehouse.cps_all.PatientProfile pp on pp.pid = u.pid

end
go
