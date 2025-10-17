

use [CpsWarehouse]
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO


drop table if exists [CpsWarehouse].[cps_setup].[Form_Components];
go
create table [CpsWarehouse].[cps_setup].[Form_Components](
	FormID numeric(19,0) not null primary key,
	FormName nvarchar(30) not null,
	InactiveForms smallint not null,
	TextTranslation nvarchar(max) null,
	PrintedForm nvarchar(max) null,
	FunctionSection nvarchar(max) null,
	WhoSuppliedForm numeric(19,0)  null,
	FormDescription nvarchar(255)  null,
	Version smallint not null,
	FormLocation nvarchar(100) not null,
	Form_created_date date not null,
	Tab1 nvarchar(100) null,
	Tab2 nvarchar(100) null,
	Tab3 nvarchar(100) null,
	Tab4 nvarchar(100) null,
	Tab5 nvarchar(100) null,
	Tab6 nvarchar(100) null,
	Tab7 nvarchar(100) null,
	Tab8 nvarchar(100) null,
	Tab9 nvarchar(100) null,
	Tab10 nvarchar(100) null,
	Tab11 nvarchar(100) null,
	Tab12 nvarchar(100) null,
	Tab13 nvarchar(100) null
) 

go
--	exec tempdb.dbo.sp_help N'#temp'



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_setup].[ssis_Form_Components] ;

go
create procedure [cps_setup].[ssis_Form_Components]
as begin

truncate table [cps_setup].[Form_Components];


drop table if exists #form_info
select 
	[Name] FormName, FSID FormID, FIDS FormPages,
	case active when 'D' then 0 else 1 end InactiveForms,
	FORMXLATEDEF TextTranslation, 
	PefData PrintedForm,
	WATCHERS FunctionSection,

	f.FACTORID WhoSuppliedForm,
	DESCRIPTION FormDescription, Version,
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
		FormLocation,
		f.DB_Create_Date,f.DB_Updated_Date
into #form_info
from cpssql.CentricityPS.dbo.formset f
	left join cpssql.CentricityPS.dbo.Hiergrps h1 on h1.GROUPID = f.GROUPID
	left join cpssql.CentricityPS.dbo.Hiergrps h2 on h2.GROUPID = h1.PARENTID
	left join cpssql.CentricityPS.dbo.Hiergrps h3 on h3.GROUPID = h2.PARENTID
	left join cpssql.CentricityPS.dbo.Hiergrps h4 on h4.GROUPID = h3.PARENTID
	left join cpssql.CentricityPS.dbo.Hiergrps h5 on h5.GROUPID = h4.PARENTID


--select * from #form_info


drop table if exists #form_tabs;
select  f.FormID, f.FormName, f.InactiveForms,  t.Number,
	f1.Title  + case when f1.PageChangeWatcher is null then '' else ' (PageWatcher: ' +  f1.PageChangeWatcher + ')' end FormTab
into #form_tabs
from #form_info f
	cross apply fxn.SplitStrings(FormPages, ',') t
	left join cpssql.CentricityPS.dbo.Form f1 on f1.fid = t.Item ;

--select * from #form_tabs


drop table if exists #tab_pivot;
select 
	pvt.FormID, 
	left(isnull(pvt.[1],''),100) Tab1,left(isnull(pvt.[2],''),100) Tab2,left(isnull(pvt.[3],''),100) Tab3,
	left(isnull(pvt.[4],''),100) Tab4,left(isnull(pvt.[5],''),100) Tab5,
	left(isnull(pvt.[6],''),100) Tab6,left(isnull(pvt.[7],''),100) Tab7,left(isnull(pvt.[8],''),100) Tab8,
	left(isnull(pvt.[9],''),100) Tab9,left(isnull(pvt.[10],''),100) Tab10,
	left(isnull(pvt.[11],''),100) Tab11,left(isnull(pvt.[12],''),100) Tab12,left(isnull(pvt.[13],''),100) Tab13
into #tab_pivot
from
(
	select FormID, FormTab, Number
	from #form_tabs
) q
pivot
(
	max(FormTab)
	for number in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13])
) pvt;

--select * from #tab_pivot

drop table if exists #temp;
select 
	f.FormName, f.FormID, f.InactiveForms, 
	f.TextTranslation, f.PrintedForm, f.FunctionSection,
	f.WhoSuppliedForm, f.FormDescription, 
	case 
		when f.version = '' or f.version is null then 0 
		else Version end Version, 
	f.FormLocation,
	convert(date,f.db_create_date) Form_created_date,
	t.Tab1, t.tab2, t.tab3, t.tab4, t.tab5, t.tab6, t.tab7, t.tab8,
	t.tab9, t.tab10, t.tab11, t.tab12, t.tab13
into #temp
from #form_info f
	left join #tab_pivot t on f.FormID = t.FormID
	
--select * from #temp where version is null

insert into [cps_setup].[Form_Components] (
	FormID,FormName,InactiveForms,TextTranslation,PrintedForm,FunctionSection,WhoSuppliedForm,
	FormDescription,Version,FormLocation,Form_created_date,
	Tab1,Tab2,Tab3,Tab4,Tab5,Tab6,Tab7,Tab8,
	Tab9,Tab10,Tab11,Tab12,Tab13
	)
select 
	FormID,FormName,InactiveForms,TextTranslation,PrintedForm,FunctionSection,WhoSuppliedForm,
	FormDescription,Version,FormLocation,Form_created_date,
	Tab1,Tab2,Tab3,Tab4,Tab5,Tab6,Tab7,Tab8,
	Tab9,Tab10,Tab11,Tab12,Tab13
from #temp;

end 

go
