

use CpsWarehouse
go

drop table if exists cps_imm.ImmunizationWithCombo;
go
create table cps_imm.ImmunizationWithCombo
(
	ImmunizationId numeric(19,0) not null,
	PID numeric(19,0) not null,
	PatientId int not null,
	DoB date not null,
	VaccineGroup varchar(50) not null,
	VaccineGroupCvx int not null,
	Brand varchar(100)  null,
	brandCvx int not null,
	AdministeredDate date not null,
	Series smallint not null,
	EventAge decimal(10,2) not null,
	primary key ( PID, VaccineGroup, Series)
)

go

drop proc if exists cps_imm.ssis_ImmunizationWithCombo;

go

create proc cps_imm.ssis_ImmunizationWithCombo
as
begin

	truncate table cps_imm.ImmunizationWithCombo

	;with get_combo as (
		select  distinct
			imm.ImmunizationId,imm.PID, pp.PatientID, pp.DoB,
			isnull(g.VaccineGroupName,'Unspecified') VaccineGroup, imm.Brand, g.VaccineFamilyCvxCode VaccineGroupCvx, 
			g.cvxCode BrandCvx, imm.AdministeredDate,
			imm.Series
		from cps_imm.ImmunizationGiven imm
			left join cpssql.CentricityPS.dbo.Imm_VaccineGroupName g on g.CVXCode = imm.CVXCode
			left join cps_all.PatientProfile pp on pp.PID = imm.PID
		where imm.wasGiven = 'Y' and VaccineFamilyCvxCode is not null
	)
	, u as (

			select 
				ImmunizationId, PID, PatientID, DoB,  VaccineGroup, VaccineGroupCvx, Brand, BrandCvx, AdministeredDate,
				Series = ROW_NUMBER() over(partition by PID, VaccineGroup order by AdministeredDate asc),
				EventAge = cast(DATEDIFF(day, DoB, AdministeredDate) / 365.25 as decimal(10,2) )
			from get_combo
	) --select * from u
	insert into cps_imm.ImmunizationWithCombo(
		ImmunizationId, PID, PatientId, DoB, VaccineGroup, VaccineGroupCvx, Brand, BrandCvx, AdministeredDate, Series, EventAge
	)
	select 
		ImmunizationId,u.PID, PatientID, DoB, VaccineGroup, VaccineGroupCvx, Brand, BrandCvx, AdministeredDate, Series, EventAge
		
	from u



end 

go
