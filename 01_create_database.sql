USE [master]
GO

if exists ( select * from sys.databases where name=N'CpsWarehouse')
begin
	alter database [CpsWarehouse] set single_user with rollback immediate
	drop database if exists [CpsWarehouse];
end

GO
/*Create database --> change owner*/
if not exists ( select * from sys.databases where name=N'CpsWarehouse')
begin
	CREATE DATABASE [CpsWarehouse]
	 ON   
		( NAME = N'CpsWarehouse', 
			FILENAME = N'E:\Data\CpsWarehouse.mdf' , 
			SIZE = 10, 
			MAXSIZE = UNLIMITED, 
			FILEGROWTH = 256 )
	 LOG ON 
		( NAME = N'cpswarehouseLog', 
			FILENAME = N'F:\Logs\cpswarehouseLog.ldf' , 
			SIZE = 5 , 
			MAXSIZE = UNLIMITED , 
			FILEGROWTH = 128)
end
GO

ALTER AUTHORIZATION ON DATABASE::CpsWarehouse to sa;
GO

USE [master]
GO
ALTER DATABASE CpsWarehouse SET  READ_WRITE 
GO