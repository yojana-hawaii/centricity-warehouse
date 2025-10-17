

Go
use CpsWarehouse
go

drop function if exists fxn.ClinicalDateToDateTime;
go
create function fxn.ClinicalDateToDateTime(@Temp numeric(19,0) )
returns datetime
as
begin
	declare @temp_datetime datetime = dateadd(SECOND,convert(int,(@Temp/1000000)),'01/01/1960')
	--declare @return_date as datetime
	--set @return_date = convert(datetime, @temp_datetime)
	return @temp_datetime
end
Go
