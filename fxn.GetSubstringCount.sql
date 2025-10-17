Go
use CpsWarehouse
go

 drop function if exists fxn.GetSubstringCount
 go
 CREATE FUNCTION fxn.GetSubstringCount
    (
      @InputString TEXT, 
      @SubString VARCHAR(200),
      @NoisePattern VARCHAR(20)
    )
    RETURNS INT
    WITH SCHEMABINDING
    AS
    BEGIN
      RETURN 
      (
        SELECT COUNT(*)
        FROM dbo.Numbers N
        WHERE
          SUBSTRING(@InputString, N.Number, LEN(@SubString)) = @SubString
          AND PATINDEX(@NoisePattern, SUBSTRING(@InputString, N.Number + LEN(@SubString), 1)) = 0
          AND 0 = 
            CASE 
              WHEN @NoisePattern = '' THEN 0
              ELSE PATINDEX(@NoisePattern, SUBSTRING(@InputString, N.Number - 1, 1))
            END
      )
    END
go