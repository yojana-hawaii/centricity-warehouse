
go
use CpsWarehouse
go
drop function if exists  fxn.RemoveWeirdWhiteSpaces
go
create function fxn.RemoveWeirdWhiteSpaces (@temp varchar(max))
returns varchar(max)
as
begin

	set @temp = replace(@temp, char(0),' '); --null
	set @temp = replace(@temp, char(9),' '); --horizontal tab
	set @temp = replace(@temp, char(10),' '); --line feed
	set @temp = replace(@temp, char(11),' '); --vertical tab
	set @temp = replace(@temp, char(12),' '); --form feed
	set @temp = replace(@temp, char(13),' '); --carriage return
	set @temp = replace(@temp, char(14),' '); --column break
	set @temp = replace(@temp, char(160),' '); --non-breaking spac
	set @temp = ltrim(rtrim(@temp));

	return @temp

end
go