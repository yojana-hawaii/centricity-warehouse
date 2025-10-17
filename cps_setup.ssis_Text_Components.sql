
use [CpsWarehouse]
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO



drop table if exists [CpsWarehouse].[cps_setup].[Text_Components];
go
create table [CpsWarehouse].[cps_setup].[Text_Components](
	TextComponentID numeric(19,0) not null primary key,
	TextComponentName nvarchar(100) not null,
	TextComponentContent nvarchar(max) not null,
	TextComponentLocation nvarchar(100) not null
)

go


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_setup].ssis_Text_Components 
 
go
create procedure [cps_setup].ssis_Text_Components
as begin

truncate table [cps_setup].[Text_Components];

;with u as (
	select 
		o.NAME TextComponentName, o.OBJECTID TextComponentID, 
		o.Text TextComponentContent, 
		case 
				when h5.GROUPNAME = 'Top level' then '\\'
				when h5.GROUPNAME is null then ''
				when h5.GROUPNAME = 'Enterprise' then h5.GROUPNAME
				else '\' + h5.GroupName
			end 
			+ 
			case 
				when h4.GROUPNAME = 'Top level' then '\\'
				when h4.GROUPNAME is null then ''
				when h4.GROUPNAME = 'Enterprise' then h4.GROUPNAME
				else '\' + h4.GroupName
			end 
			+ 
			case 
				when h3.GROUPNAME = 'Top level' then '\\'
				when h3.GROUPNAME is null then ''
				when h3.GROUPNAME = 'Enterprise' then h3.GROUPNAME
				else '\' + h3.GroupName
			end 
			+ 
			case 
				when h2.GROUPNAME = 'Top level' then '\\'
				when h2.GROUPNAME is null then ''
				when h2.GROUPNAME = 'Enterprise' then h2.GROUPNAME
				else '\' + h2.GroupName
			end 
			+ 
			case 
				when h1.GROUPNAME = 'Top level' then '\\'
				when h1.GROUPNAME is null then ''
				when h1.GROUPNAME = 'Enterprise' then h1.GROUPNAME
				else '\' + h1.GroupName
			end 
			TextComponentLocation
	from cpssql.CentricityPS.dbo.HIEROBJS o
		left join cpssql.CentricityPS.dbo.HIERGRPS g on g.GROUPID = o.GROUPID
		left join cpssql.CentricityPS.dbo.Hiergrps h1 on h1.GROUPID = o.GROUPID
		left join cpssql.CentricityPS.dbo.Hiergrps h2 on h2.GROUPID = h1.PARENTID
		left join cpssql.CentricityPS.dbo.Hiergrps h3 on h3.GROUPID = h2.PARENTID
		left join cpssql.CentricityPS.dbo.Hiergrps h4 on h4.GROUPID = h3.PARENTID
		left join cpssql.CentricityPS.dbo.Hiergrps h5 on h5.GROUPID = h4.PARENTID
	where g.GROUPTYPE = 1
) 
insert into [cps_setup].[Text_Components] (TextComponentID,TextComponentName,TextComponentContent,TextComponentLocation)
select TextComponentID,TextComponentName,TextComponentContent,TextComponentLocation from u;

end 
go
