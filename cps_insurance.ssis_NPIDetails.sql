USE CpsWarehouse
GO

drop table if exists cps_insurance.[NPIDetails];
go
CREATE TABLE cps_insurance.[NPIDetails](
	[DoctorFacilityID] [int] NOT NULL,
	[NPI] int NOT NULL,
	[OhanaSpecialty] [nvarchar](20) NOT NULL,
	[NPIEnumerationDate] [date]  NULL,
	[State]  [nvarchar](2)  NULL,
	[ActiveProviders] smallint null
 CONSTRAINT [PK_docFacNPIDetails] PRIMARY KEY CLUSTERED 
(
	[DoctorFacilityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO 

truncate table cps_insurance.[NPIDetails];
go

-- latest provider list 10-27-2021
drop table if exists #temp2;
create table #temp2 (
	Prov nvarchar(100) not null,
	NPI nvarchar(100) not null,
	OhanaSpecialty nvarchar(100) not null,
	NPIEnumerationDate nvarchar(100)  null,
	[State] nvarchar(100)  null
)

go

BULK
INSERT #temp2	
from '\\fileserver\it\apps\sql\centricity-warehouse\OhanaDetails.csv'
with 
(
	fieldterminator = ',',
	rowterminator = '\n', 
	firstrow = 2
);
go

insert into cps_insurance.NPIDetails(
	DoctorFacilityId, NPI, OhanaSpecialty, NPIEnumerationDate, State, ActiveProviders)
select 
	df.DoctorFacilityID, t.NPI, t.OhanaSpecialty, 
	convert(date, case when t.NPIEnumerationDate = 'null' then null else t.NPIEnumerationDate end) NPIEnumerationDate, 
	case when t.State != 'null' then t.state end state, 
	df.Inactive
from #temp2 t
	inner join cps_all.DoctorFacility df on df.ListName = t.Prov



go

