

use CpsWarehouse
go

drop function if exists fxn.ClinicalDateToDate;
go
create function fxn.ClinicalDateToDate(@Temp numeric(19,0) )
returns date
as
begin
	declare @temp_datetime datetime = dateadd(day,convert(int,(@Temp/1000000/3600/24)),'01/01/1960')
	declare @return_date as date
	set @return_date = convert(date, @temp_datetime)
	return @return_date
end
Go
