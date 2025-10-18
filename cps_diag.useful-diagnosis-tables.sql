
/*most used diagnosis by providers*/
select top 100 df.ListName, m.*
from cpssql.CentricityPS.dbo.MostUsedProblem m
left join cps_all.DoctorFacility df on df.PVId = m.PVID
order by UsageCount desc


/*diagnosis master list*/
select top 100 * from cpssql.CentricityPS.dbo.diagnosis

/*inactive diagnosis*/
select * from cpssql.CentricityPS.dbo.SPR68501_MUP_Codes_Inactvtd