
use CpsWarehouse
go

drop table if exists cps_obs.ObsHead;
go
create table cps_obs.ObsHead
(
	HDID int primary key, 
	ObsTerm varchar(20) not null, 
	MyName varchar(200) null,
	MLCode varchar(20) not null, 
	[Description] varchar(max) not null, 
	Keyword varchar(max) null, 
	GroupName varchar(50) not null, 
	GroupID int not null, 
	Unit varchar(20) null, 
	Active varchar(2) null, 
	TotalUsed int not null, 
	LastUsedDate date null, 
	ObsAddedDate date  null
)

go

drop proc if exists cps_obs.ssis_ObsHead;
go

create proc cps_obs.ssis_ObsHead
as 
begin

	truncate table cps_obs.ObsHead;

	;with cnt as (
		select oh.HDID HDID, COUNT(obs.HDID) AS TotalUsed, convert(date, MAX(obs.DB_CREATE_DATE)) AS 'LastUsedDate'
		from cpssql.centricityps.dbo.OBSHEAD AS OH
			LEFT JOIN cpssql.centricityps.dbo.OBS	ON obs.HDID = oh.HDID
		group by oh.Hdid
	), u as (
		SELECT 
			oh.HDID HDID, oh.[NAME] ObsTerm, oh.MLCODE MlCode, oh.[DESCRIPTION] [Description]
	
			,hj.GROUPNAME GroupName,hj.GROUPID GroupId, oh.UNIT Unit ,oh.ACTIVE	Active,oh.KEYWORD Keyword,
			cnt.TotalUsed, cnt.LastUsedDate,

			convert(date, oh.db_create_date) ObsAddedDate
		FROM cpssql.centricityps.dbo.OBSHEAD AS OH
			LEFT JOIN cpssql.centricityps.dbo.HIERGRPS AS hj	ON hj.GROUPID = oh.GROUPID
			left join cnt on cnt.HDID = oh.hdid
	)

	insert into cps_obs.ObsHead (HDID, ObsTerm, MLCode, [Description], Keyword, GroupName, GroupID, Unit, Active, TotalUsed, LastUsedDate, ObsAddedDate)
	select HDID, ObsTerm, MLCode, [Description], Keyword, GroupName, GroupID, Unit, Active, TotalUsed, LastUsedDate, ObsAddedDate  from u
end

go 
