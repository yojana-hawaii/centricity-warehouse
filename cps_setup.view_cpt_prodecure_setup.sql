

use CpsWarehouse
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

drop view if exists cps_setup.view_cpt_prodecure_setup
go
create view cps_setup.view_cpt_prodecure_setup
as

select 
	isnull(typ.Description,'') TypeOfService, isnull(plc.Description,'') PlaceOfService, 
	isnull(mo.Code,'') AutomaticModifier,
	isnull(p.RevenueCode,'') RevenueCode, p.code, p.CPTCode, p.Description,
	isnull(dep.Description,'') Department,
	case 
		when qua.Description like 'Health Care Financing %' then 'HCPCS'
		when qua.Description like 'HCPC - BH' then 'BH'
		when qua.Description like 'HCPC - VIS' then 'OPT'
		when qua.Description like 'HCPC - OP' then 'Other'
		when qua.Description like 'HCPC - EN' then 'Enabling'
		when qua.Description like 'HCPC - MED' then 'Medical'
		 else isnull(qua.Description,'') end VisitType,
	
	case when isnull(p.Inactive, 0) = 0 then 0 else 1 end Inactive,
	p.RVU, p.fee FlatFee, p.Cost
	
from cpssql.CentricityPS.dbo.[Procedures] p 
	left join cpssql.CentricityPS.dbo.MedLists typ on typ.MedListsId = p.TypeOfServiceMId	
	left join cpssql.CentricityPS.dbo.MedLists plc on plc.MedListsId = p.PlaceOfServiceMId
	left join cpssql.CentricityPS.dbo.MedLists mo on mo.MedListsId = p.Modifier1MId
	left join cpssql.CentricityPS.dbo.MedLists dep on dep.MedListsId = p.DepartmentMId
	left join cpssql.CentricityPS.dbo.MedLists qua on qua.MedListsId = p.CPTProcedureCodeQualifierMId


--where isnull(p.Inactive, 0) = 0


go