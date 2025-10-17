
use CpsWarehouse
go
drop table if exists [cps_orders].[Fact_all_orders];
go

CREATE TABLE [cps_orders].[Fact_all_orders] (
	[OrderLinkID]        NUMERIC (19)   NOT NULL,
	[PID]                NUMERIC (19)   NOT NULL,
	[PatientId]			 int			not null,
	[Name]				 varchar(100)	not null,
	[SDID]               NUMERIC (19)   NOT NULL,
	[OrderType]          VARCHAR (1)    NOT NULL,
	[OrderCodeID]        NUMERIC (19)   NOT NULL,
	[OrderDesc]			 varchar(255)	not null,
	[OrderCode]			 varchar(20)	not null,
	[OrderProviderID]    NUMERIC (19)   NOT NULL,
	[OrderProvider]		 varchar(160)	not null,
	[DispensedStatus]    VARCHAR (1)	NOT NULL,
	[CurrentStatus]      VARCHAR (1)    NOT NULL,
	[VisitDate]          DATE           NOT NULL,
	[OrderDate]          DATE           NOT NULL,
	EndDate				 date null,
	[AdminHoldDate]      DATE           NULL,
	[InProcessDate]      DATE           NULL,
	[InProcessBy]		 varchar(160)  null,
	[ReportSource]			varchar(30) null,
	[ReportReceivedDate] DATE           NULL,
	[CompletedDate]		 DATE           NULL,
	[CompleteBy]		 varchar(160)  null,
	[CancelDate]		 DATE           NULL,
	[CancelBy]			varchar(160) null,
	[Canceled]          smallint       NOT NULL,
	[FacilityID] 		int not null,
	[Facility] 			varchar(200) not null,
	[LocID]              NUMERIC (19)   NOT NULL,
	[LoC]				varchar(20) not null,
	[ServProvID]         NUMERIC (19)   NULL,
	[PrimInsuranceId]	int		not null,
	[LetterToInsurance] varchar(1) null,
	[LetterToPatient]	varchar(1) null,
	[LetterToSpecialist] varchar(1) null,
	[ReferralReason]     VARCHAR (2000) NULL,
	[ClinicalComment]    VARCHAR (2000) NULL,
	[AdminComment]       VARCHAR (2000) NULL,
	[CancelReason]       VARCHAR (2000) NULL,
	[AuthNum]            VARCHAR (20)   NULL,
	[OrderNum]           VARCHAR (16)   NOT NULL,
	[Units]		     int  null,
	[DXGroupID]          NUMERIC (19)   NOT NULL,
	[ResultSDIDList1]    NUMERIC (19)   NULL,
	[ResultSDIDList2]    NUMERIC (19)   NULL,
	[DocumentAssociated] smallint NOT NULL,
	[InternalServProvId] numeric(19) not null,
	[OrderClassification]   VARCHAR (10)    NOT NULL,

	PRIMARY KEY CLUSTERED ([OrderLinkID] ASC),
	CONSTRAINT [fk_OrderCompletedDated] FOREIGN KEY ([CompletedDate]) REFERENCES [dbo].[dimDate] ([date]),
	CONSTRAINT [fk_orderDate] FOREIGN KEY ([OrderDate]) REFERENCES [dbo].[dimDate] ([date]),
	CONSTRAINT [fk_reportReceivedDate] FOREIGN KEY ([ReportReceivedDate]) REFERENCES [dbo].[dimDate] ([date]),
	CONSTRAINT [fk_VisitDate] FOREIGN KEY ([VisitDate]) REFERENCES [dbo].[dimDate] ([date])
);
go


drop proc if exists [cps_orders].[ssis_Fact_all_orders];
go

CREATE procedure [cps_orders].[ssis_Fact_all_orders]
as 
begin
	truncate table [cps_orders].[Fact_all_orders];

	Declare @StartDate date = dateadd(year, -5, convert(date, getdate() ) ), 
		@EndDate date = dateadd(year, 2, convert(date, getdate() ) );

	drop table if exists #all_orders;
	select --top 1000
		o.ordlinkid OrderLinkID, /*ordlinkid- order audit trail**/
		DispWhenSigned DispensedStatus,
		o.status RowStatus,

		LatestStatus = ROW_NUMBER() over (partition by ordlinkid order by  o.DB_CREATE_DATE desc),
		OrderPlacedDate = ROW_NUMBER() over (partition by ordlinkid order by  o.DB_CREATE_DATE asc),

		o.pid PID, 
		o.sdid SDID,
		o.xid XID, 
	
		o.ordcodeid OrderCodeID,
		o.OrderType OrderType,
		o.Description OrderDesc,
		o.Code OrderCode,
		o.OrderNum OrderNum,

		convert(date,orderdate) OrderDate,
		convert(date,EndDate) EndDate,
		o.DB_UPDATED_DATE db_upate_date,
		o.DB_CREATE_DATE DB_CREATE_DATE, 
		o.SENTPROVORDERINFO SENTPROVORDERINFO,

		o.LOCOFSERVICE LocId,

		o.PUBTIME PubTime,
		o.LUPD LastUpdate,
		o.DXUPDATE LastDiagUpdate,
	
		o.AuthByUsrID [AuthUserID],
		o.USRID SignUserID,
		o.PUBUSER LastModifiedByID,
		
		o.servprovid ServProvID,
		o.PRIMCOV PrimInsuranceId, 

		o.SENDINSLETTER LetterToInsurance,
		o.SENDPROVLETTER LetterToSpecialist,
		o.SENDPTLETTER LetterToPatient,

		isnull(o.referralreason,'') referralreason,
		o.clinComments ClinicalComment, 
		o.adminComments AdminComment,
		o.CANCELREASON CancelReason,

		o.authnum AuthNum,
		o.[NumVisits] [NumVisits],
		o.dxgroupid DXGroupID,
		o.resultsdidlist ResultSdidList,
		isnull(o.internalservprovid,0) InternalServProvId,

		auth.ListName AuthUser,
		auth.Billable AuthBillable,
		sig.ListName SignUser,
		sig.Billable SignBillable,
		loc.Facility Facility, 
		loc.FacilityID FacilityID,
		loc.LocAbbrevName LoC,
		las.ListName LastModifiedBy,

		doc.clinicalDateConverted VisitDate
	into #all_orders
	from [cpssql].centricityps.dbo.orders o
		inner join CpsWarehouse.cps_visits.Document doc on doc.SDID = o.sdid  /*remove replaced and file in error doc, only 2016 and newer*/
		left join CpsWarehouse.cps_all.doctorfacility auth on auth.PVId = o.AuthByUsrID
		left join CpsWarehouse.cps_all.doctorfacility sig on sig.PVId = o.USRID
		left join CpsWarehouse.cps_all.doctorfacility las on las.PVId = o.pubuser
		left join CpsWarehouse.cps_all.location loc on loc.locId = o.locofservice
	where o.status != 'U' /*no orderlinkid for unsigned*/
		and o.ordCodeID != 1584958852100950 /*no desc or code*/
		and orderdate >= @StartDate
		and OrderDate <= @EndDate;  


	/*******split result SDID - comma separated
	result sdid are documents containing results of this order

	select top 100 * from #all_orders
	****************/
	drop table if exists #split_resultSDID;
	;with split_result_sdid as (
		select OrderLinkID, ResultSDIDList x,
			convert(numeric(19,0), 
				case 
					when charindex(',',c.ResultSDIDList,1) > 0 
						then substring(c.RESULTSDIDLIST,1,charindex(',',c.ResultSDIDList,1)-1) 
					else c.RESULTSDIDLIST
				end ) ResultSDIDList1,
			case 
				when charindex(',',c.ResultSDIDList,1) > 0 
					then substring(c.RESULTSDIDLIST, charindex(',', c.ResultSDIDList,1)+1 , len(c.RESULTSDIDLIST) - CHARINDEX(',',c.RESULTSDIDLIST,1) ) 
			end  ResultSDIDList
		from #all_orders c
		where ResultSDIDList is not null
	) 
		select 
			distinct
			OrderLinkID,x, ResultSDIDList1,
			convert(numeric(19,0), 
				case 
					when charindex(',',c.ResultSDIDList,1) > 0 
						then substring(c.RESULTSDIDLIST,1,charindex(',',c.ResultSDIDList,1)-1) 
					else c.RESULTSDIDLIST
				end ) ResultSDIDList2
		into #split_resultSDID
		from split_result_sdid c;


	/** pivot & get dates for each status

	select top 100 * from #all_orders
	select top 100 * from #split_resultSDID
	*/
	drop table if exists #dates;
	select
		o.OrderLinkID, 
		max(case when RowStatus = 'H' then convert(date,DB_CREATE_DATE) end) AdminHoldDate,

		max(case when RowStatus = 'S' then convert(date,DB_CREATE_DATE) end) InProcessDate,
		max(case when RowStatus = 'S' and DispensedStatus != RowStatus then LastModifiedBy end) InProcessBy,
			

		max(case when RowStatus = 'C' then convert(date,DB_CREATE_DATE) end) CompletedDate,
		max(case when RowStatus = 'C' and DispensedStatus != RowStatus then LastModifiedBy end) CompleteBy,

		max(case when RowStatus = 'X' then convert(date,DB_CREATE_DATE) end) CancelDate,
		max(case when RowStatus = 'X' then LastModifiedBy end) CancelBy,
		max(case when RowStatus = 'X' then 1 else 0 end) Canceled

	into #dates
	from #all_orders o 
	group by o.OrderLinkID;
		

	/** get source of report from link logic - scanned vs electronic

	select top 100 * from #all_orders
	select top 100 * from #split_resultSDID
	select top 100 * from #dates
	*/


	select 
		distinct
		o.OrderLinkID, 
		o.PID, pp.PatientID, pp.Name, 
		o.sdid, 
			
		o.OrderType, 
		o.OrderCodeID, o.OrderDesc, o.OrderCode,

		case 
			when o.AuthUserID = o.SignUserID then o.AuthUserID
			when o.AuthUserID = 1560859855000010 then o.SignUserID
			when o.AuthBillable = 1 then o.AuthUserID
			when o.SignUserID is not null then o.SignUserID
			else o.AuthUserID
		end OrderProviderID,

		case 
			when o.AuthUserID = o.SignUserID then o.AuthUser 
			when o.AuthUserID = 1560859855000010 then o.SignUser
			when o.AuthBillable = 1 then o.AuthUser
			when o.SignUserID is not null then o.SignUser
			else o.AuthUser
		end OrderProvider,

		o.DispensedStatus,
		o.rowStatus CurrentStatus,

		o.VisitDate, o.OrderDate, o.EndDate, d.AdminHoldDate, 
			
		d.InProcessDate, d.InProcessBy, 

		rpt.LinkLogicSource ReportSource,
		convert(date, rpt.DB_CREATE_DATE) [ReportReceivedDate],
		d.CompletedDate, d.CompleteBy, 

		d.CancelDate, d.CancelBy, d.Canceled,  

		o.LocId,o.Facility, FacilityID, o.LoC,

		o.ServProvID, PrimInsuranceId,

		LetterToInsurance, LetterToPatient, LetterToSpecialist,

		case when trim(ReferralReason) = '' then null else trim(ReferralReason) end ReferralReason, 
		case when trim(ClinicalComment) = '' then null else trim(ClinicalComment) end ClinicalComment, 
		case when trim(AdminComment) = '' then null else trim(AdminComment) end AdminComment, 
		case when trim(CancelReason) = '' then null else trim(CancelReason) end CancelReason, 
		case when trim(AuthNum) = '' then null else trim(AuthNum) end AuthNum, 
			

		o.OrderNum, 
		[NumVisits],

		o.DXGroupID, 
			
		--o.ResultSdidList,
		spli.ResultSDIDList1, spli.ResultSDIDList2,
		case when spli.ResultSDIDList1 is not null then 1 else 0 end DocumentAssociated,
		o.InternalServProvId,od.[OrderClassification]
			
	into #u	
	from #all_orders o
		left join #dates d on o.OrderLinkID = d.OrderLinkID
		left join CpsWarehouse.cps_all.PatientProfile pp on pp.pid = o.pid
		left join #split_resultSDID spli on spli.OrderLinkID = o.OrderLinkID
		left join CpsWarehouse.cps_visits.Document rpt on rpt.sdid = spli.ResultSDIDList1
		left join CpsWarehouse.cps_orders.OrderCodesAndCategories od on o.OrderCodeID = od.OrderCodeID
	where o.LatestStatus = 1
		and pp.TestPatient = 0

	--select top 100 * from #u where OrderLinkID = 1767341240179450
	--exec tempdb.dbo.sp_help #u

	insert into [cps_orders].[Fact_all_orders] (
		[OrderLinkID],[PID],[PatientId],[Name],[SDID],[OrderType],[OrderCodeID],
		[OrderDesc],[OrderCode],[OrderProviderID],[OrderProvider],[DispensedStatus],
		[CurrentStatus],[VisitDate],[OrderDate], EndDate,[AdminHoldDate],[OrderClassification],
		[InProcessDate],[InProcessBy],[ReportReceivedDate],ReportSource,[CompletedDate],[CompleteBy],
		[CancelDate],[CancelBy],[Canceled],[LocID],[LoC],[Facility],FacilityID,[ServProvID],
		[PrimInsuranceId],[LetterToInsurance],[LetterToPatient],[LetterToSpecialist],
		[ReferralReason],[ClinicalComment],[AdminComment],[CancelReason],[AuthNum],[OrderNum],
		[DXGroupID],[ResultSDIDList1],[ResultSDIDList2],[DocumentAssociated],[InternalServProvId]
		)
	select
		[OrderLinkID],[PID],[PatientId],[Name],[SDID],[OrderType],[OrderCodeID],
		[OrderDesc],[OrderCode],[OrderProviderID],[OrderProvider],[DispensedStatus],
		[CurrentStatus],[VisitDate],[OrderDate], EndDate,[AdminHoldDate],[OrderClassification],
		[InProcessDate],[InProcessBy],[ReportReceivedDate],ReportSource,[CompletedDate],[CompleteBy],
		[CancelDate],[CancelBy],[Canceled],[LocID],[LoC],[Facility],FacilityID,[ServProvID],
		[PrimInsuranceId],[LetterToInsurance],[LetterToPatient],[LetterToSpecialist],
		[ReferralReason],[ClinicalComment],[AdminComment],[CancelReason],[AuthNum],[OrderNum],
		[DXGroupID],[ResultSDIDList1],[ResultSDIDList2],[DocumentAssociated],[InternalServProvId]
	from #u

	drop table if exists #all_orders;
	drop table if exists #split_resultSDID;

end
go