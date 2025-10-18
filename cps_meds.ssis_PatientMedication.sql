
use CpsWarehouse
go

drop table if exists [cps_meds].[PatientMedication];
go

CREATE TABLE [cps_meds].[PatientMedication] (
    [PTID]         NUMERIC (19)  NOT NULL,
    [MID]          NUMERIC (19)   NULL,
    [PID]          NUMERIC (19)  NOT NULL,
    [PVID]         NUMERIC (19)  NOT NULL,
    [UserID]       NUMERIC (19)  NOT NULL,
    [PubUser]      NUMERIC (19)  NOT NULL,
    [SDID]         NUMERIC (19)  NOT NULL,
    [Pharmacy]     VARCHAR (400)  NULL,
    [PharmacyID]   NUMERIC (19)   NULL,
    [MyPharmacy] TINYINT      NOT NULL,
    [ClinicalDate] DATETIME       NULL,
    [GPI]          VARCHAR (14)  NULL,
    [DDID]         NUMERIC (19)  NULL,
    [Description]  VARCHAR (255)  NULL,
    [GenericMed]   VARCHAR (80)  NULL,
	[Instructions] varchar (max) null,
    [Quantity]     VARCHAR (60)  NULL,
    [Unit]         VARCHAR (30)  NULL,
    [Refills]      VARCHAR (12)  NULL,
    [RxType]       VARCHAR (40)  NULL,
    [StartDate]    DATE          NULL,
    [StopDate]     DATE          NULL,
    [StopReason]   VARCHAR (25)  NULL,
    [Inactive]     SMALLINT      NOT NULL,
    PRIMARY KEY CLUSTERED ([PTID] ASC)
);

go
drop proc if exists [cps_meds].[ssis_PatientMedication];
go

CREATE procedure [cps_meds].[ssis_PatientMedication]
as begin

truncate table [cps_meds].[PatientMedication];

drop table if exists #meds
select
	p.PTID,p.MID, p.PID, 
	p.PVID, p.USRID UserID, p.PUBUSER, p.SDID, 
	p.PHARMACY, p.PHARMBUSID PharmacyID, 
	p.CLINICALDATE,
	m.GPI, m.DDID,
	
	lower(m.DESCRIPTION) Description, 
	lower(m.GENERICMED) GenericMed, 
	lower(m.instructions) Instructions,
	p.QUANTITY, p.REFILLS, 
	p.RXType,
	convert(date,m.STARTDATE) StartDate, convert(date,m.STOPDATE) StopDate,
	m.stopReason,
	q.DisplayUnit Unit,
	case 
		when m.xid = 1000000000000000000 then 0
		when m.stopreason is null and m.STOPDATE > getdate() then 0 
		else 1 end Inactive
into #meds
from cpssql.CentricityPS.dbo.PRESCRIB p
	left join cpssql.CentricityPS.dbo.MEDICATE m on m.MID = p.MID
	left join cpssql.CentricityPS.dbo.ERX_UNITOFMEASURE q on q.NCPDP_RxQtyQualifier = p.NCPDP_RxQtyQualifier;

--	exec tempdb.dbo.sp_help '#meds'


;with u as (
	select *, 
		case RXTYPE
			when 'W' then 'Handwritten'
			when 'H' then 'Historical'
			when 'F' then 'Fax to pharmacy'
			when 'A' then 'Re-fax'
			when 'D' then 'Pharmacy''s prescribing method'
			when 'Q' then 'Print then fax to pharmacy'
			when 'P' then 'Print then give to patient'
			when 'R' then 'Reprint'
			when 'M' then 'Print then mail to patient'
			when 'L' then 'Print then mail to pharmacy'
			when 'S' then 'Samples given to patient'
			when 'T' then 'Telephone'
			when 'E' then 'Electronic'
		end RxType1,
		case STOPREASON 
			when 'A' then 'Adverse Reaction'
			when 'C' then 'Changed'
			when 'D' then 'Removed'
			when 'E' then 'Error'
			when 'N' then 'Not effective'
			when 'O' then 'Other'
			when 'P' then 'Patient preference'
			when 'R' then 'Regimen completed'
			when 'S' then 'Side effects'
			when 'T' then 'Cost'
			end StopReason1,
		case when Pharmacy like 'my pharm%' then 1 else 0 end MyPharmacy
	from #meds
)
 insert into [cps_meds].[PatientMedication] 
	(
		PTID,MID,PID,PVID,UserID,PubUser,SDID,Pharmacy,PharmacyID,MyPharmacy,ClinicalDate,GPI,DDID,
		Description,GenericMed,Quantity,Unit,Refills,RxType,StartDate,StopDate,StopReason,Inactive,[Instructions]
	)
select 
	PTID,MID,PID,PVID,UserID,PubUser,SDID,Pharmacy,PharmacyID,MyPharmacy,ClinicalDate,GPI,DDID,
	Description,GenericMed,Quantity,Unit,Refills,RxType,StartDate,StopDate,StopReason,Inactive,[Instructions]
from u;
end

go  

