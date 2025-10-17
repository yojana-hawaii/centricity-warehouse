
use CpsWarehouse
go

SET ANSI_PADDING ON
drop table if exists [cps_visits].[PatientVisitType]
go
CREATE TABLE [cps_visits].[PatientVisitType] (
    [PID]                    NUMERIC (19)   NOT NULL,
    [PatientVisitID]         INT            NOT NULL,
    [TicketNumber]           VARCHAR (20)   NOT NULL,

    [VoidedTicket]           bit			NOT NULL,
	OrigInsAllocation		 MONEY			NOT NULL,
	OrigPatAllocation		 MONEY			NOT NULL,

    [DoS]                    DATETIME       NOT NULL,
    [BillerEntry]            DATETIME       NOT NULL,

    [FacilityID]             INT            NOT NULL,
	[Facility]				 varchar(50)	not null,
    [BilledProviderID]       INT            not null,
	[BilledProvider]		 varchar(100)	not null,

    [InsuranceCarrierUsed]   INT            NULL,
    [InsuranceIDUSed]        VARCHAR (50)   NULL,

    [Resource1]              INT            NULL,
    [Resource2]              INT            NULL,
    [Resource3]              INT            NULL,
    [ApptProviderID]         INT            NULL,
    [ApptProviderConfidence] SMALLINT       NULL,

    [ICD10]                  VARCHAR (MAX) NULL,
    [PrimaryICD]             VARCHAR (25)  NULL,
    [CPTCode]                VARCHAR (MAX) NULL,
    [PrimaryCPT]             VARCHAR (25)  NULL,


    [MedicalVisit]           SMALLINT       NOT NULL,
    [BHVisit]                SMALLINT       NOT NULL,
    [OptVisit]               SMALLINT       NOT NULL,
    [EnablingVisit]          SMALLINT       NOT NULL,
    [Telehealth]	         SMALLINT       NOT NULL,

    [HCPCS]                  SMALLINT       NOT NULL,
    [HCPCS_Type]             VARCHAR (50)  NULL,
    [Outlier_NotSure]        SMALLINT       NOT NULL,
    [NDC_NotSure]            SMALLINT       NOT NULL,
    [NoQualifier]            SMALLINT       NOT NULL,

    [BillingStatus]          VARCHAR (30)  NULL,
    [ClaimStatus]            VARCHAR (20)  NULL,
    [FilingMethod]           VARCHAR (30)  NULL,
    [FilingType]             VARCHAR (15)  NULL,
    [BillingDescription]     VARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([PatientVisitID] ASC)
);





go

SET ANSI_PADDING ON
drop proc if exists [cps_visits].[ssis_PatientVisitType]
go

create procedure [cps_visits].[ssis_PatientVisitType]
as begin

truncate table cps_visits.[PatientVisitType];

	declare @startdate date = '2019-01-01';

/*find patient Visits starting 2019. 
	* Change from 2016 to 2019 on 10-7-2021 -> 3 years should be enough data
remove voided visits
*/
drop table if exists #patVisits
select distinct
	pp.PID PID, pp.PatientID, pp.PatientProfileID,
	pv.PatientVisitID PatientVisitID,  pv.visit DoS, pv.entered BillerEntry, 
	pv.TicketNumber TicketNumber, 
	pv.DoctorID BilledProviderID, 
	df.ListName BilledProvider,
	pv.FacilityID FacilityID,
	fac.Facility,
	ins.InsuranceCarriersID InsuranceCarrierUsed, 
	pv.primaryInsuranceCarriersID,

	case 
		when ins.InsuranceCarriersid = 212 then '0' /*self pay*/
		when ins.InsuranceCarriersID = 1 then '0' /*sliding fee*/
	else  ins.InsuredId end InsuranceIDUsed,

	--pvp.voided,pv.Description,
	case when  isnull(pv.Description,'')  like '%void%' then 1 else 0 end [VoidedTicket], 
	--isnull(pvp.voided,0) voided, 
	vt.OrigInsAllocation, vt.OrigPatAllocation,

	bill.Description BillingStatus, claim.Description ClaimStatus, fil.Description FilingMethod, 
	case pv.FilingType when 0 then 'None' when 1 then 'Paper' when 2 then 'Electronic' end FilingType, 
	pv.Description BillingDescription
into #patVisits
from cpssql.CentricityPS.dbo.PatientVisit pv
	inner join cpssql.CentricityPS.dbo.PatientProfile pp  ON pv.PatientProfileId = pp.PatientProfileId
	left join cpssql.CentricityPS.dbo.PatientInsurance ins on  ins.PatientInsuranceId = case when pv.PrimaryPICarrierID  is not null then pv.PrimaryPICarrierID
																								else pv.CurrentPICarrierID
																							end
	left join cpssql.CentricityPS.dbo.PatientVisitProcs pvp ON pvp.PatientVisitId = pv.PatientVisitId 
	left join cpssql.CentricityPS.dbo.MedLists bill on bill.Code = pv.BillStatus and bill.TableName = 'BillStatus'
	left join cpssql.CentricityPS.dbo.MedLists claim on claim.Code = pv.ClaimStatus and claim.TableName = 'SIClaimStatus'
	left join cpssql.CentricityPS.dbo.MedLists fil on fil.MedListsId = pv.FilingMethodMId and fil.TableName = 'FilingMethods'
	left join cpssql.CentricityPS.dbo.DoctorFacility df on df.doctorFacilityID = pv.DoctorID
	left join cps_all.Location fac on fac.FacilityID = pv.FacilityID
	left join cpssql.CentricityPS.dbo.PatientVisitAgg vt on vt.PatientVisitid = pv.PatientVisitId
																					
where  pv.Visit  >= @startdate



/**************
add resources for the visit
up to 3 resource per visit

select top 100 * from #patVisits

select patientvisitID,count(*) t from #patVisits group by patientvisitID having count(*) > 1
select * from #patVisits where insuranceIDUsed is null order by dos	
****************/

drop table if exists #resource
select 
	PatientVisitID, [1] Resource1, [2] Resource2, [3] Resource3
into #resource
from (
	select 
		pv.PatientVisitID, pv.TicketNumber,
		convert(nvarchar(20), pvr.resourceid) resourceID,
		RowNum = ROW_NUMBER() over (partition by pv.patientVisitID order by resourceID)
	from #patVisits pv
		left join cpssql.CentricityPS.dbo.PatientVisitResource pvr on pv.PatientVisitId =  pvr.PatientVisitId
) q
pivot
(
	max(resourceid)
	for rowNum in ([1], [2], [3])
) p

/****#icd110******************
include diagnosis, 
comma separate them
if no diagnosis then not included in #icd110
cannot do inner join
also get prim diag

select * from #patVisits
select * from #resource
****************/
	
drop table if exists #diag
select  u.patientVisitID patientVisitID, d.listOrder, d.Code Code, 
	rowNum = ROW_NUMBER() over (partition by u.patientVisitID order by listorder)
into #diag
from #patVisits u
	left join cpssql.centricityps.dbo.patientvisitdiags d  on u.patientVisitID= d.patientVisitID

drop table if exists #prim
select * 
into #prim
from #diag 
where rowNum = 1 and listOrder is not null

drop table if exists #comma_separated_icd;
select distinct d.PatientVisitID, 
	stuff((select distinct ', ' + d1.Code
		from #diag d1
		where d1.PatientVisitID = d.PatientVisitID
			for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'') ICD10
into #comma_separated_icd
from #diag d

drop table if exists #icd10
select distinct d.patientVisitID, d.ICD10 ,p.code PrimaryICD
into #icd10
from #comma_separated_icd d
	left join #prim p on d.patientVisitID = p.patientVisitID
where d.patientVisitID is not null


/**#cptCode********************
add cpt code and proceduresID
comma separate CPT codes
get primary cpt code: has duplicates coz more than one listorder = 1

select * from #patVisits
select * from #resource

select top 100 * from #diag
select top 100 * from #prim
select top 100 * from #comma_separated_icd
select top 100 * from #icd10
****************/
drop table if exists #procedures_and_cpt
select
	pv.PatientVisitID, pvp.listOrder listOrder, pvp.Code Code, pvp.ProceduresId ProceduresId, 
	serv.Description PlaceOfService
into #procedures_and_cpt
from #patVisits pv
	left join cpssql.CentricityPS.dbo.PatientVisitProcs pvp ON pvp.PatientVisitId = pv.PatientVisitId 
	left join cpssql.CentricityPS.dbo.Medlists serv on serv.MedListsID = pvp.PlaceOfServiceMid and serv.TableName = 'placeofservicecodes'

drop table if exists #primaryCPT_duplicates_comma_separated
;with prim_cpt_duplicates as (
	select * 
	from #procedures_and_cpt 
	where listOrder = 1 
)
select distinct PatientVisitID,
	stuff((select distinct ', ' + d1.Code
		from prim_cpt_duplicates d1
		where d1.PatientVisitID = d.PatientVisitID
			for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'') CPTCode
into #primaryCPT_duplicates_comma_separated
from prim_cpt_duplicates d

drop table if exists #cptCode
select 
	distinct d.PatientVisitID, p.CPTCode PrimaryCPT, 
	case when d.PlaceOfService = 'telehealth' then 1 else 0 end Telehealth,
	stuff((select distinct ', ' + d1.Code
		from #procedures_and_cpt d1
		where d1.PatientVisitID = d.PatientVisitID
			for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'') CPTCode
into #cptCode
from #procedures_and_cpt d
	left join #primaryCPT_duplicates_comma_separated p on d.PatientVisitID = p.PatientVisitID

/**#wrong_place_of_service********************
exclude telehealth visit with different sites
	* one cpt code is office visit & the other is telehealth
	* will show duolication patientVisitID in #cptCode

email billing with duplicats to fix telehealth

select top 100 * from #patVisits where patientvisitid = 1705946
select top 100 * from #resource

select top 100 * from #diag
select top 100 * from #prim
select top 100 * from #comma_separated_icd
select top 100 * from #icd10

select top 100 * from #procedures_and_cpt where PatientVisitID = 1705946
select top 100 * from #primaryCPT_duplicates_comma_separated
select top 100 * from #cptCode where patientvisitid = 1705946
****************/


drop table if exists #wrong_place_of_service;
;with dups as (
	select PatientVisitID, count(*) c 
	from #cptCode
	group by PatientVisitID
	having count(*) > 1

)
	select p.TicketNumber, p.PatientVisitID
	into #wrong_place_of_service
	from dups d
		left join #patVisits p on p.PatientVisitID = d.PatientVisitID

/*email Rhanna if wrong visit type - telehealth vs in person*/

declare @wrong_pos_count int 
select @wrong_pos_count = count(*)
from #wrong_place_of_service;
print @wrong_pos_count

if @wrong_pos_count > 0 and 1 = 2
	begin

	DECLARE @comma_separated_tickets NVARCHAR(MAX) = 'Hello, 

	This is auto-generated email. Below is list of ticket number that have different place of service.
	
	'
		select @comma_separated_tickets = @comma_separated_tickets +  convert(varchar(20), TicketNumber) + ', '
		from #wrong_place_of_service

	set @comma_separated_tickets = @comma_separated_tickets + '
	
	Thank you
	Me
	'
		-- exec msdb.dbo.sp_send_dbmail
			-- @profile_name = 'sql-profile',
			-- @recipients = 'a@b.com;c@d.com',
			-- @copy_recipients = 'e@f.com',

			-- @body = @comma_separated_tickets,
			-- @subject = 'Auto-generated email: Tickets with different place of service';
end


/**#visitType********************
define visit type: medical vs BH vs opt etc
HCFA visits sparated by department
from cpssql.CentricityPS.dbo.MedLists ml ON ml.MedListsId = p.CPTProcedureCodeQualifierMId


select top 100 * from #patVisits where patientvisitid = 1705946
select top 100 * from #resource

select top 100 * from #diag
select top 100 * from #prim
select top 100 * from #comma_separated_icd
select top 100 * from #icd10

select top 100 * from #procedures_and_cpt where PatientVisitID = 1705946
select top 100 * from #primaryCPT_duplicates_comma_separated
select top 100 * from #cptCode where patientvisitid = 1705946

select * from #wrong_place_of_service
****************/
drop table if exists #visitType
select distinct
	c.PatientVisitID, --p.CPTProcedureCodeQualifierMId,
	/*from cpssql.CentricityPS.dbo.MedLists ml ON ml.MedListsId = p.CPTProcedureCodeQualifierMId*/
	max(case p.CPTProcedureCodeQualifierMId	when 4724 then 1 else 0 end) MedicalVisit,
	max(case p.CPTProcedureCodeQualifierMId	when 4725 then 1 else 0 end) EnablingVisit,
	max(case when p.CPTProcedureCodeQualifierMId in (4726,184251) then 1 else 0 end) OptVisit,
	max(case p.CPTProcedureCodeQualifierMId	when 4727 then 1 else 0 end) BHVisit,

	max(case p.CPTProcedureCodeQualifierMId	when 156 then 1 else 0 end) HCPCS,
	--warning: null value is eliminated by an aggregate or other set operation.
	max(case 
		when p.CPTProcedureCodeQualifierMId = 156 
		then 
			case p.DepartmentMID
				when 1944 then 'BH'

				when 1945 then 'Enabling'
				when 1946 then 'Family Planning'
				when 1947 then 'Home Visit'
				when 1948 then 'Hospital Visit'
				when 1949 then 'Immunization'
				when 1950 then 'Internal Lab'
				when 49967 then 'Medicare FQHC'
				when 5144 then 'Nursing Facility'
				when 1951 then 'Office Visits'
				when 1952 then 'Optometry'
				when 1953 then 'Outside Lab'
				when 1954 then 'Pharmaceuticals'
				when 1955 then 'Procedures'
				when 4518 then 'Radiology'

				else 'Unclassified'
			end
		
		end
	) HCPCS_Type,

	max(case p.CPTProcedureCodeQualifierMId	when 758 then 1 else 0 end) [Outlier_NotSure],
	max(case when p.CPTProcedureCodeQualifierMId in (160, 162) then 1 else 0 end) [NDC_NotSure],
	max(case when p.CPTProcedureCodeQualifierMId is null then 1 else 0 end) NoQualifier
into #visitType
from #procedures_and_cpt c
	left join cpssql.CentricityPS.dbo.[Procedures] p ON p.ProceduresId = c.ProceduresId 
	left join cpssql.CentricityPS.dbo.MedLists dpt on dpt.MedListsId = p.DepartmentMID
group by c.PatientVisitID

/**********************
combine all

select count(*) from #patVisits
select count(distinct patientVisitID ) from #patVisits

select count(*) from #resource
select count(distinct patientVisitID ) from #resource

select count(*) from #icd10
select count(distinct patientVisitID ) from #icd10

select count(*) from #procedures_and_cpt
select count(distinct patientVisitID ) from #procedures_and_cpt

select count(*) from #primaryCPT
select count(distinct patientVisitID ) from #primaryCPT

select count(*) from #cptCode
select count(distinct patientVisitID ) from #cptCode

select count(*) from #visitType
select count(distinct patientVisitID ) from #visitType
****************/



;with u as (	
	select 
		pv.PID, pv.PatientVisitID, pv.TicketNumber, pv.DoS, pv.BillerEntry, 
		pv.FacilityID, pv.Facility, 
		pv.VoidedTicket, pv.OrigInsAllocation, pv.OrigPatAllocation,
		pv.InsuranceCarrierUsed, pv.InsuranceIDUsed,
		pv.BilledProviderID, pv.BilledProvider,
		r.Resource1, r.Resource2, r.Resource3,
		case 
			when MedicalVisit = 1 or BHVisit = 1 or OptVisit = 1 or HCPCS = 1 or NoQualifier = 1
			then 
				case
					when r.Resource1 = pv.BilledProviderID 
						or r.Resource1 is null 
						or res.JobTitle in ('Schedule Resource', 'Community Health Worker', 'Proxy users', 'Medical Assistant','Receptionist','','Educator','Registered Nurse','Care Manager')
						or res.ListName = 'Residents, OBGYN'
					then pv.BilledProviderID
					when r.Resource1 != pv.BilledProviderID 
						and res.JobTitle in ('Physician','Nurse Practitioner','Therapist','Psychiatrist','Certified Nurse Midwife', 'Medical Doctor') 
					then r.Resource1
				end
			when EnablingVisit = 1 or HCPCS = 1 or NoQualifier = 1
			then
				case
					when pv.BilledProviderID in  (1114,535) or pv.BilledProviderID = r.Resource1 
					then r.Resource1
					when r.Resource1 in (1114,535) or res.JobTitle in ('Schedule Resource') or r.Resource1 is null
					then pv.BilledProviderID
				end  
		end [ApptProviderID],
		case 
			when MedicalVisit = 1 or BHVisit = 1 or OptVisit = 1 or HCPCS = 1 or NoQualifier = 1
			then 
				case
					when r.Resource1 = pv.BilledProviderID 
						or r.Resource1 is null 
						or res.JobTitle in ('Schedule Resource', 'Community Health Worker', 'Proxy users', 'Medical Assistant','Receptionist','','Educator','Registered Nurse','Care Manager')
						or res.ListName = 'Residents, OBGYN'
					then 1
					when r.Resource1 != pv.BilledProviderID 
						and res.JobTitle in ('Physician','Nurse Practitioner','Therapist','Psychiatrist','Certified Nurse Midwife', 'Medical Doctor') 
					then 0
					else -1
				end
			when EnablingVisit = 1 or HCPCS = 1 or NoQualifier = 1
			then
				case
					when pv.BilledProviderID in  (1114,535) or pv.BilledProviderID = r.Resource1
					then 1
					when r.Resource1 in (1114,535) or res.JobTitle in ('Schedule Resource') or r.Resource1 is null
					then 1
					else -1
				end  
			else -1
		end [ApptProviderConfidence],
		i.ICD10, i.PrimaryICD, 
		c.CPTCode, c.PrimaryCPT,
		c.Telehealth,
		v.MedicalVisit, v.BHVisit, v.OptVisit, v.EnablingVisit, v.HCPCS, v.HCPCS_Type, v.[Outlier_NotSure], v.[NDC_NotSure], v.NoQualifier,
		pv.BillingStatus, pv.ClaimStatus, pv.FilingMethod, pv.FilingType, pv.BillingDescription
	from #patVisits pv
		left join #resource r on pv.PatientVisitID = r.PatientVisitID
		left join #icd10 i on pv.PatientVisitID = i.PatientVisitID
		left join #cptCode c on c.PatientVisitID = pv.PatientVisitID
		left join #visitType v on v.PatientVisitID = c.PatientVisitID
		left join cps_all.DoctorFacility bill on bill.DoctorFacilityID = pv.BilledProviderID
		left join cps_all.DoctorFacility res on res.DoctorFacilityID = r.Resource1
	where c.PatientVisitID not in (select PatientVisitID from #wrong_place_of_service)
) 
--select * from #patVisits  where PatientVisitID = '1367878'

--exec tempdb.dbo.sp_help N'#patientVisitCombined'
 insert into cps_visits.PatientVisitType
	(
	[PID],[PatientVisitID],[DoS],BillerEntry,[TicketNumber],[FacilityID],
	[BillingStatus],[ClaimStatus],[FilingMethod],[FilingType],
	facility, BilledProvider, 
	[BillingDescription],
	[InsuranceCarrierUsed],[InsuranceIDUSed],
	[BilledProviderID],
	[Resource1],[Resource2],[Resource3],[ApptProviderID],[ApptProviderConfidence],
	[ICD10],[CPTCode], [PrimaryICD], [PrimaryCPT],
	[MedicalVisit], [BHVisit], [OptVisit], [EnablingVisit],[HCPCS_Type],
	[HCPCS],[Outlier_NotSure],[NDC_NotSure],[NoQualifier],
	 Telehealth,VoidedTicket,OrigInsAllocation,OrigPatAllocation
	)
select 
	[PID],[PatientVisitID],[DoS],BillerEntry,[TicketNumber],[FacilityID],
	[BillingStatus],[ClaimStatus],[FilingMethod],[FilingType],
	facility, BilledProvider, 
	[BillingDescription],
	[InsuranceCarrierUsed],[InsuranceIDUSed],
	[BilledProviderID],
	[Resource1],[Resource2],[Resource3],[ApptProviderID],[ApptProviderConfidence],
	[ICD10],[CPTCode], [PrimaryICD], [PrimaryCPT],
	[MedicalVisit], [BHVisit], [OptVisit], [EnablingVisit],[HCPCS_Type],
	[HCPCS],[Outlier_NotSure],[NDC_NotSure],[NoQualifier],
	 Telehealth,VoidedTicket,OrigInsAllocation,OrigPatAllocation
from u;
end

go
