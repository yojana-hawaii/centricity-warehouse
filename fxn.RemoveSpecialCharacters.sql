
Go
use CpsWarehouse
go
drop function if exists fxn.[RemoveSpecialCharacters];
go
Create Function fxn.[RemoveSpecialCharacters](@Temp VarChar(1000))
Returns VarChar(1000)
AS
Begin

    Declare @KeepValues as varchar(50)
    Set @KeepValues = '%[^a-zA-Z0-9 ]%'
    While PatIndex(@KeepValues, @Temp) > 0
        Set @Temp = Stuff(@Temp, PatIndex(@KeepValues, @Temp), 1, '')

    Return @Temp
End

go