go
use CpsWarehouse
go

drop function if exists fxn.ConvertFlowsheetIntoColumnNameForInsert;
go
create function fxn.ConvertFlowsheetIntoColumnNameForInsert ( 
	@FlowsheetId numeric(19,0)
)
returns nvarchar(max) 
as
begin
	/*Get Labelfrom flowsheet ID*/
	declare @FlowsheetLabel table (FlowsheetCustomLabel nvarchar(max), FlowsheetObsOrder int);
	insert into @FlowsheetLabel (FlowsheetCustomLabel, FlowsheetObsOrder)
	select 
		FlowsheetCustomLabel, FlowsheetObsOrder
	from cps_setup.Flowsheet_Recussive f 
	where  f.FlowsheetID = @FlowsheetId

	/*Convert hdid in comma separated list*/
	declare @column_names nvarchar(max);
	select @column_names = left(hdid, len(hdid) -1)
	from (
		select QUOTENAME( FlowsheetCustomLabel ) + ', '
		from @FlowsheetLabel
		order by FlowsheetObsOrder
		for xml path('')
	) c (hdid)


	return 'PID, SDID, XID, PatientID,ObsDate,' +  @column_names

end 

go

