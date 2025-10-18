
use CpsWarehouse
go


drop table if exists cps_obs.DirectMessaging_Sent;
go

create table cps_obs.DirectMessaging_Sent
(
	PID numeric(19,0) not null,
	SDID numeric(19,0) not null,
	ObsDate datetime not null,
	ObsValue varchar(2000) not null,
	Sender numeric(19,0) not null,
	UHC_DM tinyint not null,
	Referral tinyint not null,
	CVS tinyint not null,
	Recipient varchar(100) not null,
	Subjects varchar(500) not null
)

go

drop proc if exists cps_obs.ssis_DirectMessaging_Sent;

go

create proc cps_obs.ssis_DirectMessaging_Sent
as 
begin
	truncate table cps_obs.DirectMessaging_Sent;

	insert into cps_obs.DirectMessaging_Sent 
		(PID, SDID, ObsDate, Sender, UHC_DM, Referral, CVS, Recipient, Subjects, ObsValue)
	
	select 
		PID PID, SDID SDID, ObsDate ObsDate, PubUser Sender,
		case when obsvalue like '%TO=UHGODXI-Prod@optumhiedirect.com%' then 1 else 0 end UHC_DM,
		case when obsvalue like '%CDA-TOC=true%' then 1 else 0 end TOC_Referral,
		case when obsvalue like '%CDA-CVS=true%' then 1 else 0 end CVS,
		substring(Obsvalue, charindex('|TO=', Obsvalue) + 4,  charindex('|CC=', Obsvalue) - charindex('|TO=', Obsvalue) -4 ) Recipient,
		substring(Obsvalue, charindex('|SUBJECT=', Obsvalue) + 9,  charindex('|REPLYTOCHART=', Obsvalue) - charindex('|SUBJECT=', Obsvalue) -9 ) Subjects,
		obsvalue ObsValue
	from cpssql.centricityps.dbo.obs
	where hdid = 79780;


end
go
