
use CpsWarehouse
go

drop table if exists [cps_all].[Location]
go
CREATE TABLE [cps_all].[Location] (
    [locID]            NUMERIC (19)   NOT NULL,
    [LoCName]          VARCHAR (70)   NOT NULL,
    [LocAbbrevName]    VARCHAR (20)   NOT NULL,
	[LocAddress]	   varchar(50)	  null,
    [LocInactive]      BIT            NOT NULL,
    [FacilityID]       INT            NOT NULL,
    [Facility]         NVARCHAR (100) NOT NULL,
    [MainFacility]     SMALLINT       NULL,
    [FacilityInactive] BIT            NOT NULL,
    [PrimaryPhone]     BIGINT         NOT NULL,
    [SecondaryPhone]   BIGINT         NOT NULL,
    [Fax]              BIGINT         NOT NULL,
    [LocParentID]      NUMERIC (19)   NOT NULL,
    [FacilityAddress]          NVARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([locID] ASC)
);


go
drop proc if exists [cps_all].[ssis_Location];
go
create procedure [cps_all].[ssis_Location]
as begin

truncate table [cps_all].[Location];

with u as (
  select 
	loc.locid LocID,
	loc.name LocName,
	case when loc.Status = 'A' then 0 else 1 end [LocInactive],
	loc.abbrevname [LocAbbrevName],
	loc.Address1 [LocAddress],

	df.DoctorFacilityId FacilityID, 
	case ListName 
		when 'building A' then 'A'
		when 'building B' then 'B'
		else ListName
		end Facility, 
	df.Inactive FacilityInactive, 
	convert(bigint,primphone) PrimaryPhone,
	convert(bigint,secphone) SecondaryPhone,
	convert(bigint,faxphone) fax,
	case 
		when abbrevName = 'ABC' then 1533735808001260 
		when abbrevName = 'DFG' then 1533735268001260 
		else parentid end LocParentID,
	df.Address1 [FacilityAddress],

	case when parentid = 0 and LocID not in (0, 1533735808001260,1730369680280220)  then 1 else 0 end MainFacility 

 from [cpssql].centricityps.dbo.locreg loc
	left join [cpssql].CentricityPS.dbo.DoctorFacility df on df.DoctorFacilityId = loc.facilityid and df.type = 2
)

 
insert into [cps_all].[Location]  (
	locID,LocName,[LocAbbrevName],[LocInactive],[LocAddress],FacilityID,facility,
	[FacilityInactive],PrimaryPhone,SecondaryPhone,Fax,
	LocParentID,[FacilityAddress],[MainFacility]
)
select 
	locID,LocName,[LocAbbrevName],[LocInactive],[LocAddress],FacilityID,facility,
	[FacilityInactive],PrimaryPhone,SecondaryPhone,Fax,
	LocParentID,[FacilityAddress],[MainFacility]
from u

end

go



