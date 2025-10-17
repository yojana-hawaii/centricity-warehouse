go
use CpsWarehouse
go

drop function if exists fxn.ConvertFlowsheetIntoColumnNameForTable;
go
create function fxn.ConvertFlowsheetIntoColumnNameForTable ( 
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
		select QUOTENAME( FlowsheetCustomLabel ) + ' varchar(2000) null, '
		from @FlowsheetLabel
		order by FlowsheetObsOrder
		for xml path('')
	) c (hdid)

	declare @additional_columns nvarchar(max) = 'PID numeric(19) not null, SDID numeric(19) not null, XID numeric(19) not null, PatientID int not null,ObsDate date not null,'
	return @additional_columns + @column_names
end

go
