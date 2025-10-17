
Go
use CpsWarehouse
go

drop function if exists fxn.[SplitStrings];
go
create FUNCTION fxn.[SplitStrings]
(
    @List       NVARCHAR(MAX),
    @Delimiter  NVARCHAR(255)
)
RETURNS TABLE
AS
    RETURN (SELECT Number = ROW_NUMBER() OVER (ORDER BY Number),
        Item FROM (SELECT Number, Item = LTRIM(RTRIM(SUBSTRING(@List, Number, 
        CHARINDEX(@Delimiter, @List + @Delimiter, Number) - Number)))
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY s1.[object_id])
        FROM sys.all_objects AS s1 CROSS APPLY sys.all_objects) AS n(Number)
    WHERE Number <= CONVERT(INT, LEN(@List))
        AND SUBSTRING(@Delimiter + @List, Number, 1) = @Delimiter
    ) AS y);
go