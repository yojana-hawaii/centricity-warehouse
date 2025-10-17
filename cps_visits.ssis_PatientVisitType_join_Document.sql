
USE CpsWarehouse
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
drop table if exists [CpsWarehouse].[cps_visits].[PatientVisitType_Join_Document];
create table [CpsWarehouse].cps_visits.[PatientVisitType_Join_Document] (
	[PID] [numeric](19, 0) NOT NULL,
	[SDID] [numeric](19, 0)  NULL,
	[PatientVisitID] int not null,
	[DoS] date not null,
)

go


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists cps_visits.[ssis_PatientVisitType_Join_Document] 
 
go
CREATE procedure cps_visits.[ssis_PatientVisitType_Join_Document]
as begin

truncate table cps_visits.[PatientVisitType_Join_Document];

drop table if exists #match_on_patientVisitID;
drop table if exists #match_without_patientVisitID;
drop table if exists #billable_remaining;
drop table if exists #late_doc;
drop table if exists #final_billable;
drop table if exists #non_bill;
drop table if exists #final;



/**************************

19573	original visits

select distinct patientVisitID from #match_on_patientVisitID where SDID is not null 
11399	perfect match, some days 2 visit, same patient, billers combine them to create one ticket
11359 unique visit
8214 not matched

select distinct patientVisitID from #match_without_patientVisitID where sdid is not null
1834 matched, 1817 unique
6397 not matched

select * from #billable_remaining
select * from #late_doc	
select * from  #final_billable
*******************************/

/***************
perfect match on patientVisitID, PID, Provider (billing or resource), VisitType, could be different date
*******************/

drop table if exists #match_on_patientVisitID;
select 
	pv.PID, pv.DoS, pv.FacilityID,
	----VisitID, VisitType, 
	pv.BilledProviderID, bill.ListName BilledProv, 
	pv.ApptProviderID, apt.ListName ApptProv, 
	pv.Resource1, res.ListName ResourceProv,
	pv.PatientVisitID, 
	pv.MedicalVisit, pv.OptVisit, pv.BHVisit, pv.EnablingVisit,pv.[HCPCS],
	doc.SDID, doc.XID, doc.DocType, doc.DocAbbr, db_Create_Date, PubUser, 
	AppointmentsID
into #match_on_patientVisitID
from cps_visits.PatientVisitType pv
	left join cps_all.DoctorFacility res on res.DoctorFacilityID = pv.Resource1
	left join cps_all.DoctorFacility bill on bill.DoctorFacilityID = pv.BilledProviderID
	left join cps_all.DoctorFacility apt on apt.DoctorFacilityID = pv.ApptProviderID
	left join cps_visits.Document doc on doc.PatientVisitID = pv.PatientVisitID 
										and pv.pid = doc.pid 
										and DocType = case 
														when pv.MedicalVisit = 1 or pv.BHVisit = 1 or pv.OptVisit = 1 then 1 
														when EnablingVisit = 1 then 1607946462900870 
													end
										and apt.PVID = doc.PubUser
										--and (res.pvid = doc.PubUser or bill.pvid = doc.PubUser)
										and convert(date,pv.DoS) = doc.db_Create_Date


/***********
select top 100 * from #match_on_patientVisitID where dos > '2021-01-01' and sdid is not null

remove patientVisitID but added DoS should match doc_create_date, continue match on PID, provider (bill and resource) and visit type
*********************/
select 
	pv.*,
	doc.SDID, doc.db_Create_Date, doc.PubUser
into #match_without_patientVisitID
from 
	(
		select 
			pv.DoS, pv.PID, pv.BilledProviderID, pv.BilledProv, pv.ResourceProv, pv.Resource1, pv.PatientVisitID, 
			pv.MedicalVisit, pv.BHVisit, pv.OptVisit, pv.EnablingVisit, pv.[HCPCS]
		from #match_on_patientVisitID pv
		where pv.SDID is null 
	) pv
	left join cps_visits.Document doc
	left join cps_all.DoctorFacility df on df.PVID = doc.PubUser 
				on  pv.pid = doc.pid 
					and doc.DocType = case 
										when pv.MedicalVisit = 1 or pv.BHVisit = 1 or pv.OptVisit = 1 then 1 
										when EnablingVisit = 1 then 1607946462900870 
									end
					and (pv.Resource1 = df.DoctorFacilityID or pv.BilledProviderID = df.DoctorFacilityID)
					and convert(date,pv.DoS)= doc.db_Create_Date
					and doc.sdid not in (select distinct x.sdid from #match_on_patientVisitID x where x.sdid is not null);


/***************
select top 100 * from #match_on_patientVisitID
select top 100 * from #match_without_patientVisitID

4 levels of match 
  1. internal other, not scanned doc, PID, provider (bill and resource) and DOS match
  2. patientVisitID match along with office visit document type
  3. patientVisitID match along with appends and find the main doc of append
  4. patientVisitID match for non-billable user and enabling doc type
************************************/

select 
	pv.*,
	case when int_oth.SDID is null and main.SDID is null and non_bill.SDID is null
				then off_vst.SDID 
		when int_oth.SDID is null and off_vst.SDID is null and non_bill.SDID is null
				then main.SDID 
		when int_oth.SDID is null and off_vst.SDID is null and main.SDID is null
				then non_bill.SDID
		else int_oth.SDID 
	end SDID, 

	case when int_oth.db_Create_Date is null and main.db_Create_Date is null and non_bill.db_Create_Date is null
				then off_vst.db_Create_Date 
		when int_oth.db_Create_Date is null and off_vst.db_Create_Date is null and non_bill.db_Create_Date is null
				then main.db_Create_Date 
		when int_oth.db_Create_Date is null and off_vst.db_Create_Date is null and main.db_Create_Date is null
				then non_bill.db_Create_Date
		else int_oth.db_Create_Date 
	end db_Create_Date,

	case when int_oth.PubUser is null and main.PubUser is null and non_bill.PubUser is null
				then off_vst.PubUser 
		when int_oth.PubUser is null and off_vst.PubUser is null and non_bill.PubUser is null
				then main.PubUser 
		when int_oth.PubUser is null and off_vst.PubUser is null and main.PubUser is null
				then non_bill.PubUser
		else int_oth.PubUser 
	end PubUser

into #billable_remaining
-- select top 100* 
from 
	(
		select pv.DoS, pv.PID, pv.BilledProviderID, pv.BilledProv, pv.ResourceProv, pv.Resource1, pv.PatientVisitID, 
			pv.MedicalVisit, pv.BHVisit, pv.OptVisit, pv.EnablingVisit, pv.[HCPCS]
		from #match_without_patientVisitID pv
		where sdid is null and (MedicalVisit = 1 or BHVisit = 1 or OptVisit = 1)
				
	) pv
	left join cps_visits.Document int_oth 
				on pv.pid = int_oth.pid 
					and int_oth.DocType = 6 and int_oth.LinkLogicSource is null /*not scanned*/ 
					and (Resource1 = int_oth.PubUser or BilledProviderID = int_oth.PubUser)
					and convert(date,pv.DoS) = int_oth.db_Create_Date
					and int_oth.sdid not in 
							(
								select distinct sdid from #match_without_patientVisitID x where x.sdid is not null
								union
								select distinct x.sdid from #match_on_patientVisitID x where x.sdid is not null
							)
					 
	left join cps_visits.Document off_vst 
				on pv.PatientVisitID = off_vst.PatientVisitID 
					and off_vst.DocType = 1
					and off_vst.sdid not in  
							(
								select distinct sdid from #match_without_patientVisitID x where x.sdid is not null
								union
								select distinct x.sdid from #match_on_patientVisitID x where x.sdid is not null
							)

	left join cps_visits.Document app 
				on pv.PatientVisitID = app.PatientVisitID 
					and app.DocType = 31
					and app.sdid not in  
							(
								select distinct sdid from #match_without_patientVisitID x where x.sdid is not null
								union
								select distinct x.sdid from #match_on_patientVisitID x where x.sdid is not null
							)

	left join cps_visits.Document main 
				on app.xid = main.SDID
					and main.sdid not in  
							(
								select distinct sdid from #match_without_patientVisitID x where x.sdid is not null
								union
								select distinct x.sdid from #match_on_patientVisitID x where x.sdid is not null
							)
	
	left join cps_visits.Document non_bill 
				on non_bill.PatientVisitID = pv.PatientVisitID
				and  pv.BilledProviderID = 1560859855000010 
				and non_bill.DocType = 1607946462900870
				and non_bill.sdid not in  
							(
								select distinct sdid from #match_without_patientVisitID x where x.sdid is not null
								union
								select distinct x.sdid from #match_on_patientVisitID x where x.sdid is not null
							)

	;

/***************
select * from #match_on_patientVisitID
select * from #match_without_patientVisitID
select * from #billable_remaining	

-- document created a day ahead or up to 10 days later, office visit or  append wthout scaned doc and not app cancel doc
************************************/
select 
	pv.*, 
	late.SDID, late.db_Create_Date, late.PubUser
into #late_doc
from
	(
		select 
			pv.DoS, pv.PID, pv.BilledProviderID, pv.BilledProv, pv.ResourceProv, pv.Resource1, pv.PatientVisitID, 
			pv.MedicalVisit, pv.BHVisit, pv.OptVisit, pv.EnablingVisit, pv.[HCPCS]
		from #billable_remaining pv
		where sdid is null
	) pv
	left join cps_visits.Document late 
	left join  cps_all.DoctorFacility df on late.PubUser = df.PVID
		on late.PID = pv.PID
			and (pv.Resource1 = df.DoctorFacilityID or pv.BilledProviderID = df.DoctorFacilityID)
			and late.db_Create_Date >= dateadd(day,-1,dos)
			and late.db_Create_Date <= dateadd(day,10,dos)
			and late.sdid not in  
							(
								select distinct sdid from #match_without_patientVisitID x where x.sdid is not null
								union
								select distinct x.sdid from #match_on_patientVisitID x where x.sdid is not null
								union
								select distinct sdid from #billable_remaining x where x.sdid is not null
							)
						
			and 
				(
					late.DocType = 1 
					or 
					(
					late.DocType = 6 and LinkLogicSource is null
					)
				)
			
			and (late.PatientVisitID != -1 or late.PatientVisitID is null)

/***************
select * from #match_on_patientVisitID
select * from #match_without_patientVisitID
select * from #billable_remaining
select * from #late_doc	

-- may include non-office visits and no match to doc at all
************************************/
select 	pv.*
	,doc.SDID, doc.db_Create_Date, doc.PubUser
into #final_billable
from
	(
		select 
			pv.DoS, pv.PID, pv.BilledProviderID, pv.BilledProv, pv.ResourceProv, pv.Resource1, pv.PatientVisitID, 
			pv.MedicalVisit, pv.BHVisit, pv.OptVisit, pv.EnablingVisit, pv.[HCPCS]
		from #late_doc pv
		where sdid is null
	) pv
	left join cps_visits.Document doc 
		on doc.PatientVisitID = pv.PatientVisitID


/***************
select * from #match_on_patientVisitID
select * from #match_without_patientVisitID
select * from #billable_remaining
select * from #late_doc	
select * from  #final_billable

-- all non-bill, not putting too much effort to clean up
************************************/
select 
	pv.*,
	non_bill.SDID, non_bill.db_Create_Date, non_bill.PubUser
into #non_bill
from
	(
		select pv.DoS, pv.PID, pv.BilledProviderID, pv.BilledProv, pv.ResourceProv, pv.Resource1, pv.PatientVisitID, 
			pv.MedicalVisit, pv.BHVisit, pv.OptVisit, pv.EnablingVisit, pv.[HCPCS]
		from #match_without_patientVisitID pv
		where sdid is null and EnablingVisit = 1
	) pv
	left join cps_visits.Document non_bill 
		on non_bill.PatientVisitID = pv.PatientVisitID

/***************
select * from #match_on_patientVisitID
select * from #match_without_patientVisitID
select * from #billable_remaining
select * from #late_doc	
select * from  #final_billable
select * from #non_bill

-- union remaining to get
select * from #final
************************************/

;with final_union as (
	--perfect match
	select DoS, PID, PatientVisitID, SDID, pv.MedicalVisit, pv.BHVisit, pv.OptVisit, pv.EnablingVisit, pv.[HCPCS] 
	from #match_on_patientVisitID pv
	where sdid is not null
	
	union

	--match without patientVisitID
	select DoS, PID, PatientVisitID, SDID, pv.MedicalVisit, pv.BHVisit, pv.OptVisit, pv.EnablingVisit, pv.[HCPCS]
	from #match_without_patientVisitID pv
	where pv.SDID is not null

	union

	--with internal other for medical, bh, or opt visits (non-billable) not included
	select DoS, PID, PatientVisitID, SDID, pv.MedicalVisit, pv.BHVisit, pv.OptVisit, pv.EnablingVisit, pv.[HCPCS] 
	from #billable_remaining pv
	where sdid is not null	

	union

	-- document not created on the same day as appt
	select DoS, PID, PatientVisitID, SDID, pv.MedicalVisit, pv.BHVisit, pv.OptVisit, pv.EnablingVisit, pv.[HCPCS] 
	from #late_doc pv
	where sdid is not null	

	union

	-- last ditch on billable. spent too much time of clean up already
	select DoS, PID, PatientVisitID, SDID, pv.MedicalVisit, pv.BHVisit, pv.OptVisit, pv.EnablingVisit, pv.[HCPCS] 
	from #final_billable pv
	
	union

	-- all non-billable. not much clean up
	select DoS, PID, PatientVisitID, SDID, pv.MedicalVisit, pv.BHVisit, pv.OptVisit, pv.EnablingVisit, pv.[HCPCS] 
	from #non_bill pv

)
select distinct * 
into #final
from final_union;

;with u as (
select distinct m.PID, m.PatientVisitID, f.SDID, m.DoS
from #match_on_patientVisitID m
left join #final f on f.PatientVisitID  = m.PatientVisitID
)

 insert into cps_visits.PatientVisitType_Join_Document (PID, PatientVisitID, SDID, DOS)
select PID, PatientVisitID, SDID, DOS from u;
END

GO
