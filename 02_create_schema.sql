go
use CpsWarehouse
go
--create schema
if not exists (select * from sys.schemas where name=N'fxn') 
begin
exec('create schema fxn authorization dbo')
end
if not exists (select * from sys.schemas where name=N'cps_all') 
begin
exec('create schema cps_all authorization dbo')
end

go
print('Message: Schema End')
go
