
use CpsWarehouse
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

drop table if exists CpsWarehouse.cps_imm.Immunization_Combo
go
create table CpsWarehouse.cps_imm.Immunization_Combo
(
	CVXCode nvarchar(5) not null,
	Combo1 nvarchar(50) not null,
	Combo2 nvarchar(50) not null,
	Combo3 nvarchar(50) not null,
	Combo4 nvarchar(50) not null,
	Combo5 nvarchar(50) not null,
	Combo6 nvarchar(50) not null,
)
go




SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

drop proc if exists cps_imm.ssis_Immunization_Combo
go
create proc cps_imm.ssis_Immunization_Combo
as begin

truncate table cps_imm.Immunization_Combo;

	;with u as (
		SELECT  
			lower(case when i.[VaccineName] is null or i.VaccineName = '' then i.VaccineGroupName else i.VaccineName end) vaccineName,
			g.VaccineGroupName, g.cvxCode, g.VACCINEFAMILYCVXCode, count(*) total
		FROM [cpssql].[CentricityPS].[dbo].[Immunization] i
			left join [cpssql].centricityps.dbo.Imm_VaccineGroupName g on g.CVXCode = i.CVXCode 
		group by g.VaccineGroupName, g.cvxCode, g.VACCINEFAMILYCVXCode, i.VaccineName, i.VaccineGroupName
	), v as (
		select VaccineName, VaccineGroupName, CVXCode, VACCINEFAMILYCVXCode, Sum(Total) Total
		--
		from u
		group by  VaccineName, VaccineGroupName, CVXCode, VACCINEFAMILYCVXCode
	) , w as (
		select *, rowNum = row_number() over (partition by  vaccineName, CVXCode order by VaccineGroupName) 
		from v
	)
	, y as (
		select distinct
			CVXCode CVXCode,
			isnull([1],'') as Combo1, isnull([2],'') as Combo2, isnull([3],'') as Combo3,
			isnull([4],'') as Combo4, isnull([5],'') as Combo5, isnull([6],'') as Combo6
		from (
			select VaccineName, CVXCode,  Total , VaccineGroupName, RowNum
			from w
			) s
			pivot
			(
			max(VaccineGroupName)
			for RowNum in ([1],[2],[3],[4],[5],[6])
			)
			pvt
		where cvxCode is not null
	) 

insert into cps_imm.Immunization_Combo(CVXCode, Combo1, Combo2, Combo3, Combo4, Combo5, Combo6)
select CVXCode, Combo1, Combo2, Combo3, Combo4, Combo5, Combo6 from y;
	

end

go
