use CpsWarehouse
go

drop function if exists fxn.StripMultipleSpaces;
go
create function fxn.StripMultipleSpaces
(
	@str varchar(max)
)
returns varchar(max) 
as
begin
	while CHARINDEX('  ', @str) > 0
		set @str = replace(@str, '  ', ' ')
	return @str
end

go
