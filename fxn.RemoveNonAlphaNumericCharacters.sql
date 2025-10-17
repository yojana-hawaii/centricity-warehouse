
Go
use CpsWarehouse
GO

drop function if exists fxn.[RemoveNonAlphaNumericCharacters];
go
Create Function fxn.[RemoveNonAlphaNumericCharacters](@Temp VarChar(1000))
Returns VarChar(1000)
AS
Begin

    Declare @KeepValues as varchar(50)
    Set @KeepValues = '%[^a-zA-Z0-9]%'
    While PatIndex(@KeepValues, @Temp) > 0
        Set @Temp = Stuff(@Temp, PatIndex(@KeepValues, @Temp), 1, '')

    Return @Temp
End
Go