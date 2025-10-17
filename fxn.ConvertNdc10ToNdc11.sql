
go
use cpswarehouse
go

drop function if exists fxn.ConvertNdc10ToNdc11
go
create function fxn.ConvertNdc10ToNdc11 (
	@ndc10 varchar(20)
)
returns varchar(50)
as
begin
	
	declare @ndc11 varchar(50) = '';
	
	select @ndc11 = case 
					when charindex('-',@ndc10 , 1) = 5 then '0' + @ndc10
					when charindex('-',@ndc10 , 5) = 6 and charindex('-',@ndc10 , 7) = 10 then  stuff(@ndc10, charindex('-',@ndc10 , 5) + 1, 0, '0')
					when charindex('-',@ndc10 , 5) = 6 and charindex('-',@ndc10 , 7) = 11  and len(@ndc10)<13 then  stuff(@ndc10, charindex('-',@ndc10 , 11) + 1, 0, '0')
					else @ndc10
					end

	select @ndc11 = replace(@ndc11, '-', '')

	select @ndc11 = case when len(@ndc11) = 11 then @ndc11 else @ndc10 + ' Conversion issue' end 
	return @ndc11

end
go
