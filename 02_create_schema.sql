go
use CpsWarehouse
go
--create schema
if not exists (select * from sys.schemas where name=N'fxn') 
begin
exec('create schema fxn authorization dbo')
end


go
print('Message: Schema End')
go
