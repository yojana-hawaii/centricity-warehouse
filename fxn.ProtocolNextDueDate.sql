
Go
use CpsWarehouse
go

drop function if exists fxn.ProtocolNextDueDate
go
create function fxn.ProtocolNextDueDate(@LastDate date, @numOfDays int)
returns date
as begin
	declare 
		@nextDate date, 
		@today date = convert(date, getdate() ) ;
	set @nextDate = case when @LastDate is null then @today else DATEADD(day,  @numOfDays, @LastDate) end
	return @nextDate
end
go