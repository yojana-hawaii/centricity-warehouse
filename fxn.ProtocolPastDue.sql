
Go
use CpsWarehouse
go
drop function if exists fxn.ProtocolPastDue
go
create function fxn.ProtocolPastDue(@NextDueDate date)
returns int
as begin
	declare 
		@today date = convert(date, getdate() ),
		@nextDue int;

		set @nextDue = DATEDIFF(day, @today, @NextDueDate)
		return @nextDue
end
go