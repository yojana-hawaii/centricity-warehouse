use CpsWarehouse;
go

drop table if exists [cps_cc].[ER_Count];
go

CREATE TABLE [cps_cc].[ER_Count] (
    [ER_Count_GUID]  UNIQUEIDENTIFIER DEFAULT (newsequentialid()) NOT NULL primary key,
    [PID]            NUMERIC (19)     NOT NULL,
    [ER/Hospital]    VARCHAR (10)     NOT NULL,
    [ER]             INT              NOT NULL,
    [Years]          VARCHAR (8)      NOT NULL,
    [January]        INT              NULL,
    [February]       INT              NULL,
    [March]          INT              NULL,
    [April]          INT              NULL,
    [May]            INT              NULL,
    [June]           INT              NULL,
    [July]           INT              NULL,
    [August]         INT              NULL,
    [September]      INT              NULL,
    [October]        INT              NULL,
    [November]       INT              NULL,
    [December]       INT              NULL,
    [Total for Year] AS               (((((((((((isnull([January],(0))+isnull([February],(0)))+isnull([March],(0)))+isnull([April],(0)))+isnull([May],(0)))+isnull([June],(0)))+isnull([July],(0)))+isnull([August],(0)))+isnull([September],(0)))+isnull([October],(0)))+isnull([November],(0)))+isnull([December],(0)))
);

go

drop proc if exists [cps_cc].[ssis_ER_Count];
go

create proc [cps_cc].[ssis_ER_Count]
as 
begin
	truncate table CpsWarehouse.[cps_cc].[ER_Count];

	drop table if exists #pvt;
	select 
		pvt.PID, pvt.[ER/Hospital], ER, convert(varchar(4), pvt.Year) years, 
		case when pvt.January >= 1 then pvt.January else null end January, 
		case when pvt.February >= 1 then pvt.February else null end February, 
		case when pvt.March >= 1 then pvt.March else null end March, 
		case when pvt.April >= 1 then pvt.April else null end April, 
		case when pvt.May >= 1 then pvt.May else null end May, 
		case when pvt.June >= 1 then pvt.June else null end June, 
		case when pvt.July >= 1 then pvt.July else null end July, 
		case when pvt.August >= 1 then pvt.August else null end August, 
		case when pvt.September >= 1 then pvt.September else null end September, 
		case when pvt.October >= 1 then pvt.October else null end October, 
		case when pvt.November >= 1 then pvt.November else null end November, 
		case when pvt.December >= 1 then pvt.December else null end December
	into #pvt
	from 
	(
		select 
			PID, patientID, 
			case 
				when ER = 1 then 'ER'
				when ER = 0 then 'Hospital'
				else 'NotSure'
			end [ER/Hospital], 
			ER,
			d.year, d.MonthName
		from  CpsWarehouse.cps_cc.ER_Followup er
			left join CpsWarehouse.dbo.dimDate d on d.date = er.DischargeDate
	) q	
	pivot 
	(
		count(PatientID)
		for monthName in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
	where year is not null;

	drop table if exists #pvt_past_year;
	select 
		pvt.PID, pvt.[ER/Hospital], ER, 'PastYear' Years, 
		case when pvt.January >= 1 then pvt.January else null end January, 
		case when pvt.February >= 1 then pvt.February else null end February, 
		case when pvt.March >= 1 then pvt.March else null end March, 
		case when pvt.April >= 1 then pvt.April else null end April, 
		case when pvt.May >= 1 then pvt.May else null end May, 
		case when pvt.June >= 1 then pvt.June else null end June, 
		case when pvt.July >= 1 then pvt.July else null end July, 
		case when pvt.August >= 1 then pvt.August else null end August, 
		case when pvt.September >= 1 then pvt.September else null end September, 
		case when pvt.October >= 1 then pvt.October else null end October, 
		case when pvt.November >= 1 then pvt.November else null end November, 
		case when pvt.December >= 1 then pvt.December else null end December
	into #pvt_past_year
	from 
	(
		select 
			PID, patientID, 
			case 
				when ER = 1 then 'ER'
				when ER = 0 then 'Hospital'
				else 'NotSure'
			end [ER/Hospital], 
			ER,
			d.MonthName
			
		from  CpsWarehouse.cps_cc.ER_Followup er
			left join CpsWarehouse.dbo.dimDate d on d.date = er.DischargeDate
		where datediff(day, er.DischargeDate,  getdate()) <= 365
		) q	
	pivot 
	(
		count(PatientID)
		for monthName in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
	;

	--	select * from #pvt union select * from #pvt_past_year
	
	insert into [CpsWarehouse].[cps_cc].[ER_Count] (PID, [ER/Hospital],ER, Years, January, February, March, April, May, June, July, August, September,  October, November, December)
	select 
		PID, [ER/Hospital],ER,  Years,
		January, February, March, April, May, June, 
		July, August, September,  October, November, December
	from #pvt
	union 
	select 
		PID, [ER/Hospital],ER,  Years,
		January, February, March, April, May, June, 
		July, August, September,  October, November, December
	from #pvt_past_year

	drop table if exists #pvt;
	drop table if exists #pvt_past_year;
	end
go
