
use CpsWarehouse
go

drop table if exists [cps_orders].[OrderSpecialist];
go

CREATE TABLE [cps_orders].[OrderSpecialist] (
    [ServProvID]              NUMERIC (19)  NOT NULL,
    [ServProvOrgID]           NUMERIC (19)  NOT NULL,
    [FirstName]               VARCHAR (25)  NULL,
    [LastName]                VARCHAR (25)  NULL,
    [Organization]            VARCHAR (50)  NULL,
    [Org_Short]               VARCHAR (50)  NULL,
    [Specialty]               VARCHAR (32)  NULL,
    [Phone]                   VARCHAR (15)  NULL,
    [Fax]                     VARCHAR (15)  NULL,
    [Address1]                VARCHAR (50)  NULL,
    [Address2]                VARCHAR (50)  NULL,
    [City]                    VARCHAR (30)  NULL,
    [State]                   VARCHAR (10)  NULL,
    [Zip]                     VARCHAR (10)  NULL,
    [SecureElectronicAddress] VARCHAR (255) NULL,
    CONSTRAINT [pk_provID_orgID] PRIMARY KEY CLUSTERED ([ServProvID] ASC, [ServProvOrgID] ASC)
);

go

drop proc if exists [cps_orders].[ssis_OrderSpecialist]
go

create procedure [cps_orders].[ssis_OrderSpecialist]
as begin

truncate table [cps_orders].[OrderSpecialist];

select 
	isnull(sp.ServProvID,0) ServProvID, org.ServProvOrgID, sp.ProvLastName LastName, sp.ProvFirstName FirstName, sp.Specialty, 
	case when sp.SecureElectronicAddress = '' then null else sp.SecureElectronicAddress end SecureElectronicAddress, 
	org.ListName Organization, org.Phone1 Phone, org.Phone3 Fax, org.Address1, org.Address2, org.City, org.State, org.Zip,
	case 
		when org.listname = 'Department of Health (DOH)' then 'DOH'
		when org.listname = 'Hawaii Pathologists Laboratory (HPL)' then 'HPL'
		when sp.ProvLastName = 'Default' then 'Default'
		when 
			(org.ListName like '%queen%' or org.listname like '%qmc%' or org.Address1 like '%Queen%') 
			and (org.ListName like '%west%' or org.Address1 like '%west%') 
		then 'Queens West' 
		when 
			org.ListName like '%queen%' or org.listname like '%qmc%' or org.Address1 like '%Queen%' or org.Address1 like '%QMC%'
		then 'Queens' 
		when 
			org.ListName like '%straub%' or org.Address1 like '%straub%' 
		then 'Straub' 
		when 
			org.ListName like '%kapiolani%' or org.ListName like '%kmc%' or org.Address1 like '%kapiolani%' or org.Address1 like '%kmc%' 
		then 'Kapiolani'
		when 
			org.ListName like '%pali momi%' or org.Address1 like '%pali momi%'
		then 'Pali'
		when 
			org.ListName like '%Kuakini%' or org.Address1 like '%Kuakini%'
		then 'Kuakini'
		when 
			org.ListName like '%Workstar%' or org.Address1 like '%Workstar%'
		then 'Workstar'
		when 
			org.ListName like '%DLS%' or org.Address1 like '%DLS%'
		then 'DLS'
		when 
			org.ListName like '%CLH%'
		then 'CLH'
		when 
			org.ListName like 'HDRS Electronic'
		then 'eHDRS'
		when 
			org.ListName like '%Aiea Medical%' or org.Address1 like '%Aiea Medical%'
		then 'Aiea Medical'
		when 
			org.ListName = 'Endoscopy Institute of Hawaii'
		then 'Endoscopy Institute'
		when 
			org.ListName like 'Hawaii Medical Center%' 
		then 'Hawaii Medical Center'
		when 
			org.ListName like 'Hale Pawa''a%'
		then 'Hale Pawa''a'
		when 
			org.ListName like 'Aloha Laser Vision'
		then 'Aloha Laser Vision'
		when 
			org.ListName like 'All Access Ortho, LLC'
		then 'All Access Ortho'
		when 
			org.ListName like 'Cataract & Vision Center'
		then 'Cataract & Vision'
		when 
			org.ListName like 'Fetal Diagnostic%'
		then 'Fetal Diagnostic'
		
	end [Org_Short]
into #temp
from [cpssql].centricityps.dbo.SERVPROV sp
	full outer join [cpssql].centricityps.dbo.SERVPROVORG org on org.SERVPROVORGID = sp.BUSID




insert into [cps_orders].[OrderSpecialist] (ServProvID,ServProvOrgID,FirstName,LastName,Organization,Specialty,Phone,Fax,Address1,Address2,city,state,Zip,SecureElectronicAddress,[Org_Short])
select ServProvID,ServProvOrgID,FirstName,LastName,Organization,Specialty,Phone,Fax,Address1,Address2,city,state,Zip,SecureElectronicAddress,[Org_Short]
from #temp;


drop table #temp

end

go
