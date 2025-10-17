
Go
use CpsWarehouse
go

drop function if exists fxn.ConvertFlowsheetIntoDynamicPivot ;
go
create function fxn.ConvertFlowsheetIntoDynamicPivot ( 
	@FlowsheetId numeric(19,0),
	@StartDate date = null
)
returns nvarchar(max) 
as
begin

--declare @FlowsheetId numeric(19,0) = 1969702579437570
--	declare @StartDate date = '2020-01-01'

	/*Get HDID, Label, ObsTerm and Order from flowsheet ID*/
	declare @FlowsheetData table (HDID int, obsterm nvarchar(max), FlowsheetCustomLabel nvarchar(max), FlowsheetObsOrder int);
	insert into @FlowsheetData (FlowsheetObsOrder, HDID, Obsterm, FlowsheetCustomLabel)
	select 
		FlowsheetObsOrder, HDID,  ObsTerm,  FlowsheetCustomLabel
	from cps_obs.Flowsheet_Recussive f 
	where  f.FlowsheetID = @FlowsheetId
	--select * from @FlowsheetData

	/*Convert hdid in comma separated list*/
	declare @comma_separated_hdid nvarchar(max);
	select @comma_separated_hdid = left(hdid, len(hdid) -1)
	from (
		select convert(varchar(10), hdid) + ','
		from @FlowsheetData
		--order by FlowsheetObsOrder
		for xml path('')
	) c (hdid)
	--select @comma_separated_hdid


	/*Define column names with hdid as Label*/
	declare @column_names nvarchar(max);
	select @column_names = X
	from (
		select ',' +QUOTENAME(HDID) + ' as ' + QUOTENAME( isnull(FlowsheetCustomLabel,ObsTerm) ) 
		from @FlowsheetData
		order by FlowsheetObsOrder
		for xml path('')
	) c (X)



	/*remove first 1 characters, comma and space*/
	select @column_names = right(@column_names, len(@column_names) - 1);
	--select @column_names;
	
	
	
	/*define pivot columns with just hdid for pviot aggregate*/
	declare @pivot_columns nvarchar(max) = N'';
	select @pivot_columns += N',' + QUOTENAME(HDID)
		from
		(
			select p.HDID, p.Obsterm from @FlowsheetData as p
		) as x;

	/*remove leading comma*/
	select @pivot_columns = right(@pivot_columns, len(@pivot_columns) - 1);

	--select @pivot_columns

	
	/*convert date to varchar for dynamic sql*/
	declare @CutoffDate nvarchar(10) = convert(nvarchar(10), @StartDate );

	/*Build Dynamic sql*/
	declare @sql nvarchar(max);
	set @sql = N'
select PID, SDID, XID, PatientID, ObsDate, ListName,  ' + @column_names + '
into ##dynamic_temp_table
from
(
	select hdid,obs.PID,PatientID,obs.SDID, obs.XID, obs.OBSVALUE, convert(date,obs.ObsDate) ObsDate, df.ListName
	from cpssql.CentricityPS.dbo.obs
		inner join cps_all.PatientProfile pp on pp.pid = obs.pid and pp.TestPatient = 0
		inner join cpssql.Centricityps.dbo.Document doc on doc.sdid = obs.sdid 
		inner join cpssql.Centricityps.dbo.doctorfacility df on doc.pubuser = df.pvid
	where 
		obs.xid = 1000000000000000000 /*active row*/
		and obs.change not in (10,11,12) /*file in error*/
		and doc.doctype not in (30,24) /*replaced doc and filed in error*/
		and doc.pubuser is not null
		and doc.status = ''S''
		and obs.hdid in ('+@comma_separated_hdid +')
		and convert(date,obs.obsdate) >= ''' +  @CutoffDate + '''

)
as q
pivot
(
	max(obsvalue)
	for hdid in (' + @pivot_columns + ')
)
as p
'
	--print @sql

	-- exec sP_executesql @sql;

	 
	 return @sql

end

go
