

use [CpsWarehouse]
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

drop table if exists [CpsWarehouse].[cps_setup].[Encounters_DocumentTemplates];
go
create table [CpsWarehouse].[cps_setup].[Encounters_DocumentTemplates](
	[EncounterID] [numeric](19, 0) NOT NULL,
	[EncounterName] nvarchar(50) not null,
	[DocType] nvarchar(40) null,
	[Summary]  nvarchar(100) null,
	[WhoSuppliedTemplate]  [numeric](19, 0) NULL,
	[DocumentTemplateID]  [numeric](19, 0) not NULL,
	[DocumentTemplateLocation]  nvarchar(100) not null,
	[DocumentTemplateName]  nvarchar(50) not null,
	[FormID] [numeric](19, 0) NOT NULL,
	[FormOrder] [smallint] not null,
	[FormName] nvarchar(50) not null,
	[Ready_To_Copy] nvarchar(30) not null
)
GO

--exec tempdb.dbo.sp_help N'#temp'



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_setup].[ssis_Encounters_DocumentTemplates] 

go
create procedure [cps_setup].[ssis_Encounters_DocumentTemplates]
as begin

truncate table cps_setup.[Encounters_DocumentTemplates];

;with get_encounter as (
	select 
		--top 100 
		isnull(en.ETID, 0) EncounterID, 
		isnull(tm.DTID,0) DocumentTemplateID,
		dt.DESCRIPTION DocType, 
		Summary Summary,
		isnull(en.NAME, 'Unused Document Template') EncounterName, 
		isnull(tm.NAME, 'Empty Encounter') DocumentTemplateName, 
	
		h1.FACTORID WhoSuppliedTemplate,
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
		DocumentTemplateLocation,

			--replace( 
				replace(
							fxn.[ConvertRtfToText](tm.TEXT), /* function to convert RTF into plain text*/
							'[M', '~[M'
						--), ']', ''
					)  Forms

		
					
	
	from cpssql.CentricityPS.dbo.ENCTYPE en
		left join cpssql.CentricityPS.dbo.DOCTYPES dt on dt.DTID = en.DOCTYPEID
		full outer join cpssql.CentricityPS.dbo.DocTemplate tm on tm.DTID = en.DOCTEMPID
		left join cpssql.CentricityPS.dbo.Hiergrps h1 on h1.GROUPID = tm.GROUPID
		left join cpssql.CentricityPS.dbo.Hiergrps h2 on h2.GROUPID = h1.PARENTID
		left join cpssql.CentricityPS.dbo.Hiergrps h3 on h3.GROUPID = h2.PARENTID
		left join cpssql.CentricityPS.dbo.Hiergrps h4 on h4.GROUPID = h3.PARENTID
		left join cpssql.CentricityPS.dbo.Hiergrps h5 on h5.GROUPID = h4.PARENTID
)
, form_name_clean_up as (
	select 
		u.EncounterID, u.EncounterName, u.DocType, u.Summary,  u.WhoSuppliedTemplate,
		u.DocumentTemplateID, u.DocumentTemplateName, u.DocumentTemplateLocation, 
		case when u.Forms like '~%' then stuff(Forms, 1,1,'') /*remove first charater if it is comma*/
		else u.Forms
		end Forms
	from get_encounter u
), separate_forms as (
	select 
		u.EncounterID, u.EncounterName, u.DocType, u.Summary,  u.WhoSuppliedTemplate,
		u.DocumentTemplateID, u.DocumentTemplateName, u.DocumentTemplateLocation, 
		replace(replace(trim(t.Item),'[',''),']','') Ready_To_Copy,
		try_convert(numeric(19,0) , 
			replace(
				substring(t.Item, 
							charindex(':', t.Item) +1, 
							len(t.Item) 
					), ']',''
			)
		) FormID,
		t.Number FormOrder
	from form_name_clean_up u
		cross apply  fxn.SplitStrings(Forms, '~') t
)
--select * from separate_forms
, u as (
	select 
		EncounterID, EncounterName, DocType, Summary,  WhoSuppliedTemplate,
		DocumentTemplateID, DocumentTemplateLocation, DocumentTemplateName,  
		FormID, FormOrder, 
		case 
			when f.Name is not null then f.Name
			else ho.Name
		end FormName,
		Ready_To_Copy
	from separate_forms s
		left join cpssql.CentricityPS.dbo.FORMSET f on f.fsid = case 
																	when Ready_To_Copy like 'MLI_FORM%' then s.FormID
																	end
	left join cpssql.CentricityPS.dbo.HIEROBJS ho on ho.OBJECTID = case 
																	when Ready_To_Copy like 'MLI_TEXT%' then s.FormID
																	end
) --select * from u
 insert into [cps_setup].[Encounters_DocumentTemplates]([EncounterID],[EncounterName],[DocType],[Summary],[WhoSuppliedTemplate],[DocumentTemplateID],
		[DocumentTemplateLocation],[DocumentTemplateName],[FormID],[FormOrder],[FormName],[Ready_To_Copy])
select [EncounterID],[EncounterName],[DocType],[Summary],[WhoSuppliedTemplate],[DocumentTemplateID],
		[DocumentTemplateLocation],[DocumentTemplateName],[FormID],[FormOrder],[FormName],[Ready_To_Copy] from u
end
go
