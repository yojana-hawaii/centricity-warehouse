
use CpsWarehouse
go

drop table if exists cps_obs.Flowsheet_Recussive;
go
create table cps_obs.Flowsheet_Recussive
(
	FlowsheetPath varchar(100) not null,
	FlowsheetID numeric(19,0) not null,
	FlowsheetName varchar(100)  null,
	HDID int  null,
	ObsTerm varchar(2000)  null,
	FlowsheetCustomLabel varchar(2000) null,
	FlowsheetObsOrder int  null
)
go

drop proc if exists cps_obs.ssis_Flowsheet_Recussive;
go
create proc cps_obs.ssis_Flowsheet_Recussive
as 
begin
	truncate table cps_obs.Flowsheet_Recussive

	--recusrively get parent group
	drop table if exists #flowsheet;
	;with hierarical_flowhseet_Folder as (

		select ParentID ParentID, GroupID GroupID,  convert(nvarchar(100), hg.GroupName) FlowsheetPath
		from cpssql.Centricityps.dbo.[HIERGRPS] hg
		where groupType = 2
			and  hg.parentid = 0

		union all

		select hg.ParentID, hg.GroupID,convert(nvarchar(100), f.FlowsheetPath + '\' + hg.GroupName) FlowsheetPath
		from cpssql.Centricityps.dbo.[HIERGRPS] hg
			inner join hierarical_flowhseet_Folder f on f.GroupId = hg.ParentID
		where hg.grouptype = 2
	) --select * from hierarical_flowhseet_Folder
		select 
			hf.ParentID, hf.GroupID, hf.FlowsheetPath, 
			ho.objectid FlowsheetID, 
			ho.Name FlowSheetName, 
			llogic.hdid HDID, oh.ObsTerm ObsTerm,
			f.Name FlowsheetCustomLabel,
			llogic.exportorder FlowsheetObsOrder,
			f.hdid hdid2,
			ho.text
		into #flowsheet
		from hierarical_flowhseet_Folder hf
			LEFT JOIN cpssql.Centricityps.dbo.HIEROBJS ho ON ho.GROUPID = hf.GROUPID
			left join cpssql.Centricityps.dbo.LinkLogic_Export_Flowsheet llogic on llogic.ObjectId = ho.ObjectId
			left join cps_obs.ObsHead oh on oh.hdid = llogic.hdid
			left join cpssql.Centricityps.dbo.FlowsheetLabels f on f.ObjectId = ho.ObjectId and f.hdid = llogic.hdid
		where ho.name is not null


	declare @count int;
	select @count = count(*) 
	from #flowsheet u
	where u.hdid is null

	

	if @count > 0
	begin
		declare @missing_hdid varchar(max) = '' 
		select  @missing_hdid = @missing_hdid + convert(varchar(100),  u.FlowsheetPath + ' --> ' + isnull(u.FlowSheetName,'')) + '; '
		from #flowsheet u
		where u.hdid is null 

		set @missing_hdid = replace(@missing_hdid, ';', CHAR(13) + char(10))

		--select @missing_hdid

		declare @body varchar(max) = '
Hello me,

Add one obs to this flow sheet and remove.

Table Centricityps.dbo.LinkLogic_Export_Flowsheet is not populating for 
' +
@missing_hdid

		print @body


		--exec msdb.dbo.sp_send_dbmail
		--	@profile_name = 'sql-profile',
		--	@recipients = 'user@domain.com',

		--	@body = @body,
		--	@subject = 'Auto-generated email: Flowsheet issue in ssrs';
	end




	insert into cps_obs.Flowsheet_Recussive (
		FlowsheetPath, FlowsheetName, HDID, ObsTerm, FlowsheetCustomLabel, FlowsheetObsOrder,FlowsheetID
	)
	select
		FlowsheetPath, FlowsheetName, HDID, ObsTerm, FlowsheetCustomLabel, FlowsheetObsOrder,FlowsheetID
	from #flowsheet 
	where hdid is not null



end

go
