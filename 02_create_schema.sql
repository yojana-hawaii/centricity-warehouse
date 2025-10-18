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
if not exists (select * from sys.schemas where name=N'cps_visits') 
begin
exec('create schema cps_visits authorization dbo')
end
if not exists (select * from sys.schemas where name=N'cps_orders') 
begin
exec('create schema cps_orders authorization dbo')
end
if not exists (select * from sys.schemas where name=N'cps_setup') 
begin
exec('create schema cps_setup authorization dbo')
end
go
if not exists (select * from sys.schemas where name=N'cps_hl7') 
begin
exec('create schema cps_hl7 authorization dbo')
end
if not exists (select * from sys.schemas where name=N'cps_obs') 
begin
exec('create schema cps_obs authorization dbo')
end
if not exists (select * from sys.schemas where name=N'cps_bh') 
begin
exec('create schema cps_bh authorization dbo')
end
if not exists (select * from sys.schemas where name=N'cps_meds') 
begin
exec('create schema cps_meds authorization dbo')
end
if not exists (select * from sys.schemas where name=N'cps_diag') 
begin
exec('create schema cps_diag authorization dbo')
end
if not exists (select * from sys.schemas where name=N'cps_imm') 
begin
exec('create schema cps_imm authorization dbo')
end
if not exists (select * from sys.schemas where name=N'cps_cc') 
begin
exec('create schema cps_cc authorization dbo')
end

print('Message: Schema End')
go
