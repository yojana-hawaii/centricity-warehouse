
use CpsWarehouse
go

drop table if exists [cps_orders].[ReferralSetup];
go
CREATE TABLE [cps_orders].[ReferralSetup] (
	[SDID]                  NUMERIC (19)   NOT NULL,
	[XID]					numeric(19)	not null,

	[PID]                   NUMERIC (19)   NOT NULL,
	[PatientId]				int				not null,
	[Name]					varchar(100)	not null,
    
	[ReferralDate]               DATE           NOT NULL,
	[ReferralSpecialistid]    NUMERIC (19)   NOT NULL,
	[ReferralSpecialist]    varchar(100)   NOT NULL,
	[Facility]				varchar(50) not null,

	[OrderLinkID]           NUMERIC (19)    NULL,
	[OrderCodeID]           NUMERIC (19)   NULL,
	[OrderNum]				varchar(20)		null,
	[OrderingProviderID]           NUMERIC (19)   NULL,
	[ReferralDesc]          VARCHAR (100)  NULL,
	[ReferralCode]          VARCHAR (50)   NULL,
	[OrderDiag]                 VARCHAR (500)  NULL,
	[OrderAuthNum]              VARCHAR (20)   NULL,
	[OrderStartDate]         VARCHAR (15)   NULL,
	[OrderEndDate]           VARCHAR (15)   NULL,
	[OrderAdminComment]      VARCHAR (max)  NULL,
	
	TotalReferralAttempt			smallint not null,
	[ExternalvInternalvFollowup]	varchar(20) null,
	[ReferralApptDate]              VARCHAR (20)   NULL,
	[ReferralApptTBS]              VARCHAR (20)   NULL,
	[ReferralApptTime]              VARCHAR (20)   NULL,
	[ReferralPtInstruction]     VARCHAR (100)  NULL,
	[ReferralRetro]                 VARCHAR (3)    NULL,
	[ReferralStat]                  VARCHAR (3)    NULL,
	[ReferralSummaryOfCare]         VARCHAR (3)    NULL,

	[SpecialistCCDA]					smallint		not null,
	[SpecialistDirectAddress]			varchar(200)	null,
	[SpecialistContact]     VARCHAR (max) NULL,
	[Specialty]             VARCHAR (50)   NULL,

    PRIMARY KEY CLUSTERED ([SDID] ASC),
);

GO

drop table if exists [cps_orders].[ReferralFollowup];
go
CREATE TABLE [cps_orders].[ReferralFollowup] (
	[SDID]                  NUMERIC (19)   NOT NULL,
	[XID]					numeric(19)	not null,

	[PID]                   NUMERIC (19)   NOT NULL,
	[PatientId]				int				not null,
	[Name]					varchar(100)	not null,
    
	TotalFollowup			smallint		not null,
	[FollowupDate]               DATE           NOT NULL,
	[FollowupSpecialistid]    NUMERIC (19)   NOT NULL,
	[FollowupSpecialist]    varchar(100)   NOT NULL,
	[Facility]				varchar(50) not null,

	[OrderLinkID]           NUMERIC (19)    NULL,
	[OrderCodeID]           NUMERIC (19)   NULL,
	[OrderNum]				varchar(20)		null,
	[OrderingProviderID]           NUMERIC (19)   NULL,
	[ReferralDesc]          VARCHAR (100)  NULL,
	[ReferralCode]          VARCHAR (50)   NULL,
	[OrderDiag]                 VARCHAR (500)  NULL,
	[OrderAuthNum]              VARCHAR (20)   NULL,
	[OrderStartDate]         VARCHAR (15)   NULL,
	[OrderEndDate]           VARCHAR (15)   NULL,
	[OrderAdminComment]      VARCHAR (max)  NULL,
	
	[ExternalvInternalvFollowup]	varchar(20) null,
	[FollowupComment]              VARCHAR (50)   NULL,
	[FollowupOverdue]              VARCHAR (20)   NULL,
	[FollowupReport]              VARCHAR (20)   NULL,


	[SpecialistCCDA]					smallint		not null,
	[SpecialistDirectAddress]			varchar(200)	null,
	[SpecialistContact]     VARCHAR (max) NULL,
	[Specialty]             VARCHAR (50)   NULL,

    PRIMARY KEY CLUSTERED ([SDID] ASC),
);

GO

drop table if exists [cps_orders].[ReferralScanned];
go
CREATE TABLE [cps_orders].[ReferralScanned] (
	[SDID]                  NUMERIC (19)   NOT NULL,
	[PID]                   NUMERIC (19)   NOT NULL,
	[OrderLinkID]           NUMERIC (19)   not NULL,
	[OrderCodeID]           NUMERIC (19)   NULL,
	[ReferralDesc]          VARCHAR (100)  NULL,
	[ReferralCode]          VARCHAR (50)   NULL,
	[ScanDate]               DATE           NOT NULL,
	[ScannedReport]			varchar(50) null,
	[Scanned]				tinyint not null,
	OrderDate				date null, 
	MedicalRecordsMatching	tinyint not null

    PRIMARY KEY CLUSTERED ([SDID] ASC, OrderlinkId asc),

);

GO

drop table if exists cps_orders.ReferralFollowup_ByStaff
go
create table cps_orders.ReferralFollowup_ByStaff(
	[SDID]                  NUMERIC (19)   NOT NULL,
	[XID]					numeric(19)	not null,

	[PID]                   NUMERIC (19)   NOT NULL,
	[PatientId]				int				not null,
	[Name]					varchar(100)	not null,
    
	[FollowupDate]               DATE           NOT NULL,
	[FollowupSpecialistid]    NUMERIC (19)   NOT NULL,
	[FollowupSpecialist]    varchar(100)   NOT NULL,
	[Facility]				varchar(50) not null,

	[OrderLinkID]           NUMERIC (19)    NULL,
	[OrderCodeID]           NUMERIC (19)   NULL,
	[OrderNum]				varchar(20)		null,
	[OrderingProviderID]           NUMERIC (19)   NULL,
	[ReferralDesc]          VARCHAR (100)  NULL,
	[ReferralCode]          VARCHAR (50)   NULL,
	
	[FollowupComment]              VARCHAR (50)   NULL,
	[FollowupOverdue]              VARCHAR (20)   NULL,
	[FollowupReport]              VARCHAR (20)   NULL,

    PRIMARY KEY CLUSTERED ([SDID] ASC),
)
go



drop proc if exists [cps_orders].[ssis_referral_Setup_followup_scan];
go

CREATE procedure [cps_orders].[ssis_referral_Setup_followup_scan]
as begin

truncate table [cps_orders].[ReferralSetup];
truncate table [cps_orders].[ReferralFollowup];
truncate table [cps_orders].[ReferralScanned];
truncate table [cps_orders].[ReferralFollowup_ByStaff];

	/********* obs used in form
	obs -->				 HDID -->     Form Description
	LANGTRNSLTN -->      241906 -->     CHC translator (this obs used in CHC to obs documents)
	ADDREF -->			 110176 -->     external vs internal vs followup
	SWREFCOM -->		 26516 -->     followup comment
	REF STATUS -->		 2200014 -->     followup report status
	REFER STATUS -->     13400016 -->     followup  overdue
	PT REF TO 10 -->     108918 -->     not visible in form - note to insurance
	PT REF PR #5 -->     15805 -->     not visible in form - referral date
	PT REF TO 9 -->      108917 -->     not visible in form - test tab --> other
	PT REF TO 8 -->      108916 -->     not visible in form - test tab --> type of service
	REF COMMENTS -->     26375 -->     order admin comment
	# REF APPRVL -->     18898 -->     order auth #
	REF AUTH BEG -->     10104 -->     order date
	CONSULT REFE -->     2542 -->     order desc and code
	PT REF PR #6 -->     15806 -->     order diag 1
	PT REF TO 7 -->      108915 -->     order diag2 --> old form only
	REF AUTH END -->     10105 -->     order end date
	REFORDERNUM -->      354822 -->     order number
	PT REF PR #4 -->     15804 -->     ordering provider
	REF APPTDT -->       86957 -->     referral setup appt date
	GPRAAPPTSCH -->      129611 -->     referral setup appt TBS
	REFAPPTTIME -->      26374 -->     referral setup appt time
	addrefcom -->        110177 -->     referral setup patient instruction
	OTHERCOMMENT -->     131080 -->     referral setup retro
	PT REF TO 3 -->      200220 -->     referral setup stat
	RFIPROVIDER -->      354793 -->     referral setup summary of care
	PT REF TO 2 -->      200219 -->     specialist contact
	SecMsgOpt -->		 79780 -->     specialist send secure message
	PT REF TO 1 -->      200218 -->     specialty

	*/

	drop table if exists #pivot_referral_and_followup_data;
	select 
		p.PID PID,
		p.SDID SDID, XID [Appended],
		convert(date,p.OBSDATE) ObsDate, 
		p.pubuser ReferralSpecialistID, p.ListName ReferralSpecialist,

		substring(ltrim(rtrim(p.[110176])),1,15) ExternalvInternalvFollowup, 

		substring(ltrim(rtrim(p.[26516])),1,50) FollowupComment, 
		substring(ltrim(rtrim(p.[2200014])),1,20) FollowupReport, 
		substring(ltrim(rtrim(p.[13400016])),1,20) FollowupOverdue, 
		
		substring(ltrim(rtrim(p.[108916])),1,15) HiddenTypeOfService, 
		substring(ltrim(rtrim(p.[108917])),1,15) HiddenOther, 
		substring(ltrim(rtrim(p.[15805])),1,15) NotUsedReferringDate, 
		substring(ltrim(rtrim(p.[108918])),1,2000) NotUsedInsuranceComment,

		substring(ltrim(rtrim(p.[2542])),1,200) OrderDescCode, 
		substring(ltrim(rtrim(p.[15804])),1,100) OrderingProvider, 
		substring(ltrim(rtrim(p.[354822])),1,20) OrderNum, 
		substring(ltrim(rtrim(p.[18898])),1,20) OrderAuthNum, 
		substring(ltrim(rtrim(p.[10104])),1,15) OrderStartDate, 
		substring(ltrim(rtrim(p.[10105])),1,15) OrderEndDate,
		substring(ltrim(rtrim(p.[15806])),1,200) OrderDiag1,
		substring(ltrim(rtrim(p.[108915])),1,200) OrderDiag2, 
		substring(ltrim(rtrim(p.[26375])),1,2000) OrderAdminComment,

		substring(ltrim(rtrim(p.[86957])),1,20) ReferralApptDate,
		substring(ltrim(rtrim(p.[129611])),1,20) ReferralApptTBS,
		substring(ltrim(rtrim(p.[26374])),1,20) ReferralApptTime,
		substring(ltrim(rtrim(p.[110177])),1,20) ReferraPtInstruction,
		substring(ltrim(rtrim(p.[131080])),1,3) ReferralRetro,
		substring(ltrim(rtrim(p.[200220])),1,3) ReferralStat,
		substring(ltrim(rtrim(p.[354793])),1,3) ReferralSummaryOfCare,

		substring(ltrim(rtrim(p.[200219])),1,2000) SpecialistContact,
		substring(ltrim(rtrim(p.[79780])),1,2000) SpecialistSecureMessage,
		substring(ltrim(rtrim(p.[200218])),1,50) Specialty
	into #pivot_referral_and_followup_data
	from (
		select 
			obs.pid PID ,obs.SDID sdid,doc.xid ,obs.HDID,obs.OBSDATE OBSDATE,obs.OBSVALUE,obs.pubuser pubuser, 
			df.ListName
		from [cpssql].[CentricityPS].[dbo].OBS
			inner join CpsWarehouse.cps_visits.Document doc on doc.sdid = obs.sdid	
			inner join CpsWarehouse.cps_all.PatientProfile pp on pp.pid = obs.pid and pp.TestPatient = 0 /*remove test patient*/
			left join CpsWarehouse.cps_all.DoctorFacility df on df.PVID = obs.pubuser
		where obs.HDID IN (
				'2542', '10104', '10105', '15804', '15805', '15806', '18898', '26374', 
				'26375', '26516', '79780', '86957', '108916', '108917', '108918', 
				'110176', '110177', '129611', '131080', '200218', '200219', '200220', 
				'354793', '354822', '2200014', '13400016','108915' 
				/*'241906' --> translator*/
			)
			and obs.change not in (10,11,12) /*file in error --> should be take care by inner join document*/
			and obs.pubuser != 0 /*unsigned obs*/
		) q
		pivot (
			max(obsvalue)
			for hdid IN (
				[2542], [10104], [10105], [15804], [15805], [15806], [18898], [26374], 
				[26375], [26516], [79780], [86957], [108916], [108917], [108918], 
				[110176], [110177], [129611], [131080], [200218], [200219], [200220], 
				[354793], [354822], [2200014], [13400016], [108915]
			)
		) p;
	--order by SDID /*to find which row is causing problem when separating*/

	
	--	select * from #pivot_referral_and_followup_data
	



	begin/*referral code and desc breakdown*/
	drop table if exists #separate_desc_code;
	select
		SDID, PID, 
		Specialty, OrderNum,
		OrderDescCode,

		substring(
				case 
				when charindex('[', OrderDescCode, 1) > 1
					then ltrim(rtrim(substring( OrderDescCode ,1, (charindex('[', OrderDescCode, 1) - 2 ) )  ))
				else ltrim(rtrim(OrderDescCode))
				end,
			1,
			100) ReferralDesc,

		case 
			when charindex('[', OrderDescCode, 1) > 0 and charindex(']', OrderDescCode, 1) > 0 /**both bracket in there*/
				then substring( 
							substring(
								OrderDescCode,    
								(charindex('[', OrderDescCode, 1) + 1 ),  
								len(OrderDescCode) - (charindex('[', OrderDescCode, 1) )  
							)
							,1
						,CHARINDEX(']', substring(
											OrderDescCode,    
											(charindex('[', OrderDescCode, 1) + 1 ),  
											len(OrderDescCode) - (charindex('[', OrderDescCode, 1) )  
										) 
									) - 1 
					)
			when charindex('[', OrderDescCode, 1) = len(OrderDescCode) /*one bracket - nothing after first bracket */
				then null 

			when charindex('[', OrderDescCode, 1) > 0 /*one bracket - something after first bracket */
				then substring( 
						OrderDescCode , 
						charindex('[', OrderDescCode, 1) + 1 , 
						len(OrderDescCode) - (charindex('[', OrderDescCode, 1) )   /*20 - 19*/
					) 
		end ReferralCode
	into #separate_desc_code 
	from  #pivot_referral_and_followup_data s
	-- select * from #separate_desc_code

	drop table if exists #match_by_OrderNum; /*OrderNum to obs on 6-19-2020*/
	select 
		f.OrderLinkID, f.OrderCodeID, s.PID, s.SDID, Specialty, s.ReferralCode, s.ReferralDesc, f.OrderProviderID
	into #match_by_OrderNum
	from #separate_desc_code s
		left join CpsWarehouse.cps_orders.Fact_all_orders f on f.OrderNum = s.OrderNum
	where s.OrderNum is not null
		and f.OrderType = 'R'
	--	select * from #match_by_OrderNum

	drop table if exists #match_Desc_Code
	select	
		OrderCodeID, SDID, pid, Specialty, ReferralCode, ReferralDesc
	into #match_Desc_Code
	from
		(
		select 
			o.OrderCodeID,s.sdid, s.pid, s.Specialty, s.ReferralCode, s.ReferralDesc,
				RowNum = row_number() over(partition by s.sdid order by  o.ordertype asc,o.inactive asc, o.common desc, o.orderDesc)
		from #separate_desc_code s
			left join CpsWarehouse.cps_orders.OrderCodesAndCategories o 
							on ltrim(rtrim(lower(o.OrderCode))) = trim(lower(s.ReferralCode)) 
								and CpsWarehouse.fxn.RemoveSpecialCharacters(o.OrderDesc) = CpsWarehouse.fxn.RemoveSpecialCharacters(s.ReferralDesc)
								--and o.Inactive = 0 /*did not make any difference*/
								and o.OrderType != 'S'
		where s.orderNum is null
		) a
	where a.RowNum = 1
	
	drop table if exists #match_just_desc;
	select 
		OrderCodeID, SDID, pid, Specialty, ReferralCode, ReferralDesc
	into #match_just_desc
	from
		(
		select 
			case when s.OrderCodeID is not null then s.OrderCodeID else o.OrderCodeID end OrderCodeId,
			s.sdid, s.pid, s.Specialty, s.ReferralCode, s.ReferralDesc,
			RowNum = row_number() over(partition by s.sdid order by  o.inactive asc, o.common desc, o.orderDesc)
		
		from #match_Desc_Code s
			left join CpsWarehouse.cps_orders.OrderCodesAndCategories o 
				on  CpsWarehouse.fxn.RemoveSpecialCharacters(o.OrderDesc) = CpsWarehouse.fxn.RemoveSpecialCharacters(s.ReferralDesc)
					and OrderCode != 'Referral'
					and o.OrderType = 'R' 
					--and o.Inactive = 0
					and orderDesc not like 'HDRS%'
					and  s.OrderCodeID is null
		) a
	where a.RowNum = 1

	drop table if exists #match_just_code;
	select	
		OrderCodeID, SDID, pid, Specialty, ReferralCode, ReferralDesc
	into #match_just_code
	from
		(
		select 
			case when s.OrderCodeID is not null then s.OrderCodeID else o.OrderCodeID end OrderCodeId,
			s.sdid, s.pid, s.Specialty, s.ReferralCode, s.ReferralDesc,
			RowNum = row_number() over(partition by s.sdid order by  o.inactive asc, o.common desc, o.orderDesc)
		from #match_just_desc s
			left join CpsWarehouse.cps_orders.OrderCodesAndCategories o 
									on  ltrim(rtrim(lower(o.OrderCode))) = ltrim(rtrim(lower(s.ReferralCode)))
										and s.OrderCodeID is null
		) a
	where a.RowNum = 1

	drop table if exists #manual_matching
	select 
		case 
			when OrderCodeId is not null then OrderCodeId
			when  OrderCodeId is null and ReferralDesc in (
							'Screening Mammogram', 'Screening MMG','HDRS-screening mammogram',
							'Mammogram screening','SCRN MMG','Screening Mammogram Referral',
							'HDRS-screening mmg','bilateral screening mammogram','Mammogram, Screening',
							'screening  mmg','kapiolani artesian-screening mammogram',
							'Mammogram, screening, bilateral','Referral Request: Screening Mammogram',
							'Screening mammogram, bilateral','kapiolani artesian-screening mmg',
							'Screening Mammogram Bilat','sceening mmg','SCREENIG MAMMOGRAM',
							'Mammogram, screening, bilat (CPT-77057)','Mammogram,Screening, Bilat',
							'Mammogram Screening Bilateral','Kapiolani Breast center-screening mammogram',
							'Mammogram Screening Referral','screening mmmg','kapiolani artesian plaza-screening mammogram',
							'Mammogram,Screening,Bilat','screeninh mmg','Screening Mammogram Bilateral','Mammogram, Screening Bilateral',
							'Screening Mammo','Screenin Mammogram','Screening Mammgram','HDRS mammogram screening bilateral',
							'hdrs ala moana-screening mammogram','Mammogram, Screening Referral','Pali Momi-screening mammogram',
							'hdrs-ala moana-screening mmg','HDRS - Mammogram screening, bilateral','screeening mammogram',
							'Digital screening mammogram bilateral','screeniing mmg','hdrs-sceening mammogram',
							'kapiolani Breast Center-screening mmg','screeningmmg','-Screening MMG',
							'Mammogram, screening , bilat ( CPT - 77057 ),','Mammogram Screening Bilat Referral','screning  mmg',
							'kapiolani-artesian plaza-screening mmg,screening mmg/ dx mmg bilat'
						)
				then 1541953294050570
			when OrderCodeId is null and ReferralDesc like '%mammo%'or ReferralDesc like '%mmg%' then 1541530156150780
			when OrderCodeId is null and ReferralDesc in ('Cardiology','Cardiology Referral') then 1541150145000670
			when OrderCodeId is null and ReferralDesc = 'ENT' then 1541150145150670
			when OrderCodeId is null and ReferralDesc in ('OB US','OB Ultrasound') then 1541530157650780
			when OrderCodeId is null and ReferralDesc in ('ORTHOPEDIC','Orthopedics') then 1541150146000670
			when OrderCodeId is null and ReferralDesc = 'Gastroenterology' then 1541150145300670
			when OrderCodeId is null and ReferralDesc in ('NEUROLOGY','Neurology Referral') then 1541150145750670
			when OrderCodeId is null and ReferralDesc in ('Ophthalmology','Opthalmology','Opthalmology Referral') then 1542192791101020
			when OrderCodeId is null and ReferralDesc = 'PHYSICAL THERAPY' then 1541150146350670
			when OrderCodeId is null and ReferralDesc = 'UROLOGY' then 1541150146900670
			when OrderCodeId is null and ReferralDesc in ('DERMATOLOGY','Referral - Dermatology') then 1541150145100670
			when OrderCodeId is null and ReferralDesc in ('Pelvis Ultrasound', 'pelvic US')  then 1541530157750780
			when OrderCodeId is null and ReferralDesc in ('Breast Ultrasound','US, Breast','Breast US','US Breast') then 1541530157300780
			when OrderCodeId is null and ReferralDesc = 'Nephrology' then 1541150145650670
			when OrderCodeId is null and ReferralDesc = 'Endocrinology' then 1541150145250670
			when OrderCodeId is null and ReferralDesc = 'Podiatry' then 1541150146500670
			
			
			when OrderCodeId is null and ReferralDesc in ('US-Abdomen','Abdomen Ultrasound','US Abdomen','US Abdomen Referral','US Abdomen Liver') then 1541150146500670
			when OrderCodeId is null and ReferralDesc = 'Audiology' then 1541150142650670
			when OrderCodeId is null and ReferralDesc = 'Pulmonology' then 1541150146600670
			when OrderCodeId is null and ReferralDesc = 'Genetics' then 1700143766910430
			when OrderCodeId is null and ReferralDesc = 'RHEUMATOLOGY' then 1541150146700670

		end OrderCodeId,
		SDID, PID, Specialty, ReferralCode, ReferralDesc
	into #manual_matching
	from #match_just_code
	
	end

	--	select * from #manual_matching
	
	begin /*clean up order section and ordering provider and specialist*/

	drop table if exists #order_prov_cleaup
	select 
		p.pid, p.SDID, p.ObsDate,
		p.ReferralSpecialist, p.ReferralSpecialistID,
		x.OrderCodeID, x.ReferralCode, x.ReferralDesc,

		p.OrderNum,
		case 
			when CpsWarehouse.fxn.RemoveSpecialCharacters(p.OrderAuthNum)  = '' then null 
			else OrderAuthNum 
		end OrderAuthNum,
		case 
			when isdate(p.OrderStartDate) = 1 then convert(varchar(10),convert(datetime, p.OrderStartDate), 101)
			when CpsWarehouse.fxn.RemoveSpecialCharacters(p.OrderStartDate) = '' then null
			else p.OrderStartDate
		end OrderStartDate,
		case 
			when isdate(p.OrderEndDate) = 1 then convert(varchar(10),convert(datetime, p.OrderEndDate), 101)
			when CpsWarehouse.fxn.RemoveSpecialCharacters(p.OrderEndDate) = '' then null
			else p.OrderEndDate
		end OrderEndDate,
		case 
			when CpsWarehouse.fxn.RemoveSpecialCharacters(p.OrderAdminComment)  = '' then null 
			else OrderAdminComment 
		end OrderAdminComment,
		
		trim(concat(
			isnull(
				case 
					when CpsWarehouse.fxn.RemoveSpecialCharacters(OrderDiag1)  = '' then null 
					else OrderDiag1 
				end
			, '')
			
			, ' ', 
		
		
			isnull(
				case 
					when CpsWarehouse.fxn.RemoveSpecialCharacters(OrderDiag2)  = '' then null 
					else OrderDiag2 
				end 
			, '')
		)) OrderDiag,
		
		
		case 
			
			when CpsWarehouse.fxn.RemoveNonAlphaCharacters(OrderingProvider)= '' then null
			when OrderingProvider like '%custodio%' then 1700123470016600
			when OrderingProvider like '%mamaclay%' or OrderingProvider like '%blandina%' then 1536150409000010
			when OrderingProvider like '%yoshida%' then 1537388810000010
			when OrderingProvider like '%ricardo%' then 1537388709000010
			when OrderingProvider like '%suzuki%' then 1537388735000010
			when OrderingProvider like '%walter%' or OrderingProvider like '%michael%' then 1537388759000010

			when OrderingProvider like '%bragi%' or OrderingProvider like '%nafa%' then 1537435867000010
			when OrderingProvider like '%fern%' then 1537387568000010
			when OrderingProvider like '%jackie%' or OrderingProvider like '%hui%' then 1536149186000010
			when OrderingProvider like '%koff%' then 1535297385000010
			when OrderingProvider like '%rediger%' or OrderingProvider like '%reiger%' or OrderingProvider like '%glen%' then 1536148802000010
			when OrderingProvider like '%chen%' then 1536150557000010
			when OrderingProvider like '%yamada%' then 1523351563000010

			when OrderingProvider like '%Pua%' or OrderingProvider like '%gandall%' then 1730972454359000
			when OrderingProvider like '%coll%' then 1686496786016000


			when (OrderingProvider like '%ab%' and OrderingProvider like '%lisa%') or OrderingProvider like '%abb%' then 1701168504012300
			when OrderingProvider like '%gelb%' then 1788181625121160
			when OrderingProvider like '%ellen%' then 1840434653454420
			when OrderingProvider like '%christina%' and OrderingProvider like '%ho%' then 1802871452620130
			when OrderingProvider like '%yongseok%' then 1788337261347500
			when OrderingProvider like '%kuk%' then 1699252556012400
			when OrderingProvider like '%mck%' then 1808895806988400
			when OrderingProvider like '%niheu%' or OrderingProvider like '%kala%' then 1539945390000010
			when OrderingProvider like '%kayla%' then 1831105199265140
			when OrderingProvider like '%sch%' or OrderingProvider like '%clare%' then 1798697185994670
			when OrderingProvider like '%tamoria%' then 1665987353406120
			when OrderingProvider like '%walcott%' or OrderingProvider like '%wol%' then 1786874164202630
			when OrderingProvider like '%young%' or OrderingProvider like '%ajose%' then 1695652376015600
			
			when OrderingProvider like '%gaspar%' or OrderingProvider like '%gasper%' then 1657443395011800
			when OrderingProvider like '%linhares%' then 1652390813013080
			when OrderingProvider like '%nishi%' then 1537385723000010
			when OrderingProvider like '%resor%' then 1721129635011500
			when OrderingProvider like '%lynn%' then 1687077359016200
			when OrderingProvider like '%seitz%' then 1769434444982510
			when OrderingProvider like '%sims%' then 1585564812000010
			when OrderingProvider like '%tamm%' or OrderingProvider like '%holl%' then 1742480117285590
			when OrderingProvider like '%brittney%' then 1838450633088600

			when OrderingProvider like '%anderson%' then 1637074620000010
			when OrderingProvider like '%seabolt%' then 1536149359000010
			when OrderingProvider like '%tsai%' then 1749112259599830
			when (OrderingProvider like '%eco%' and OrderingProvider like '%chri%') or OrderingProvider like '%econ%' then 1773564926173850
			when OrderingProvider like '%uchida%' then 1657719986357200
			when OrderingProvider like '%oyama%' then 1713264459019200
			when OrderingProvider like '%suzanne%' then 1716789316016100
			when OrderingProvider like '%jewell%' then 1539944159000010
			when OrderingProvider like '%hamilton%' then 1700568733012500
			when OrderingProvider like '%hobin%' then 1629054580000010

			when OrderingProvider like '%ann%' or OrderingProvider like '%chang%' then 1721129635011500

			when OrderingProvider like '%lila%' then 1888217228377160
			when OrderingProvider like '%king%' then 1851327681111960
			when OrderingProvider like '%java%' then 1885466810104050
			when OrderingProvider like '%ray%' then 1874660293159040
			when OrderingProvider like '%pepe%' then 1880185675887230
			when OrderingProvider like '%vict%' then 1854005201728930
			when OrderingProvider like '%pangi%' then 1612346249000010
			when OrderingProvider like '%nami%' then 1873527391290470
			when OrderingProvider like '%bolan%' then 1801127465281010
			when OrderingProvider like '%brit%' or OrderingProvider like '%will%' then 1838450633088600
			when OrderingProvider like '%yon%' or OrderingProvider like '%ki%' then 1788337261347500
			when OrderingProvider like '%hei%' or OrderingProvider like '%lee%' then 1887896137568430
			when OrderingProvider like '%jeff%' or OrderingProvider like '%lin%' then 1770554566886320
			when OrderingProvider like '%chr%' or OrderingProvider like '%ho%' then 1802871452620130
			when OrderingProvider like '%tr%' or OrderingProvider like '%yama%' then 1537388602000010
			when OrderingProvider like '%miriam%' then 1769434444982510
			when OrderingProvider like '%marin%' then 1888217471405300
			when OrderingProvider like '%klei%' then 1888216854337800

		else NULL 
		end OrderingProviderID

		--,OrderingProvider
	into #order_prov_cleaup
	from #manual_matching x
		left join #pivot_referral_and_followup_data p on x.SDID = p.SDID
		inner join #separate_desc_code s on s.sdid = x.SDID;

	--	select * from #order_prov_cleaup

	drop table if exists #header_order_combine;
	;with header_order_combine as (
		select 
			PID, SDID, ObsDate, ReferralSpecialist, ReferralSpecialistID,
			OrderCodeId, OrderLinkId,ReferralCode, ReferralDesc, OrderNum,
			OrderAuthNum, OrderStartDate, OrderEndDate, OrderDiag, OrderAdminComment,
			OrderingProviderID
		from
			(
			select		
				o.PID, o.SDID, ObsDate,
				ReferralSpecialist, ReferralSpecialistID,

				o.OrderCodeID, 
				case 
					when f.OrderLinkID is not null then f.OrderLinkID
				end OrderLinkId, 
				OrderingProviderID, 
				ReferralCode, ReferralDesc,
				case when f.OrderNum is not null then f.OrderNum else o.OrderNum end OrderNum, 
				OrderAuthNum, OrderStartDate, OrderEndDate, 
				case when OrderDiag = '' then null else OrderDiag end OrderDiag, 
				OrderAdminComment,
				DATEDIFF(day,  f.orderdate, o.ObsDate) numDays,
				RowNum = ROW_NUMBER() over(partition by o.SDID order by DATEDIFF(day,  orderdate, ObsDate) )
			from #order_prov_cleaup o
				left join CpsWarehouse.cps_orders.Fact_all_orders f 
							on f.OrderCodeID = o.OrderCodeID 
								and f.pid  = o.PID
								and DATEDIFF(day,  f.orderdate, o.ObsDate) <= 365
								and DATEDIFF(day,  f.orderdate, o.ObsDate) > -7
			
		) x
		where x.RowNum = 1

		union

		select 
			o.PID, o.SDID, ObsDate, ReferralSpecialist, ReferralSpecialistID,
			OrderCodeId, OrderLinkId,ReferralCode, ReferralDesc, OrderNum,
			OrderAuthNum, OrderStartDate, OrderEndDate, p.OrderDiag1, OrderAdminComment,OrderProviderID
		from #match_by_OrderNum o
			left join #pivot_referral_and_followup_data p on p.sdid = o.SDID

	)

		select *
		into #header_order_combine
		from header_order_combine p

	/*specialist*/
	drop table if exists #clean_specialty;
	select 
		PID, SDID,
		SpecialistContact,

		case when SpecialistSecureMessage is not null then 1 else 0 end CCDA, 
		case when CHARINDEX('|TO=', SpecialistSecureMessage, 1) > 0 and CHARINDEX('|CC=', SpecialistSecureMessage, 1) > 0
			then substring(
						SpecialistSecureMessage
						,CHARINDEX('|To=', SpecialistSecureMessage, 1) + 4
						,CHARINDEX('|CC=', SpecialistSecureMessage, 1) - CHARINDEX('|To=', SpecialistSecureMessage, 1) - 4
					)
			end DirectAddress, 
		Specialty
	into #clean_specialty
	from #pivot_referral_and_followup_data
	where SpecialistContact is not null 
		or SpecialistSecureMessage is not null 
		or Specialty is not null;
				
	end


	--	select * from #header_order_combine

	begin /*break down scanned, setup and followup*/

	/*scanned*/
	
	
	drop table if exists #scanned_report;
	;with all_scanned as (
		select 
			p.PID,  p.SDID, p.ObsDate ScanDate, p.FollowupReport ScannedReport, 
			doc.HasAttachment Scanned,
			isnull(f.OrderLinkID, 0) OrderLinkID, f.OrderCodeID, f.OrderCode, f.OrderDesc, f.OrderDate
		from #pivot_referral_and_followup_data p
			inner join CpsWarehouse.cps_visits.Document doc on doc.SDID = p.SDID
			left join CpsWarehouse.cps_orders.Fact_all_orders f on (f.ResultSDIDList1 = doc.SDID  )
		where ( doc.HasAttachment = 1 
					or p.ReferralSpecialistID = -3) 
				and FollowupReport is not null
	)
	, medical_records_matching as (
		select * , 1 MedicalRecordsMatching
		from all_scanned
		where OrderLinkID != 0
	)
	, random_matching as (
		select 
			s.PID,  s.SDID, 
			s.ScanDate, s.ScannedReport, 
			s.Scanned,
			isnull(f.OrderLinkID, 0) OrderLinkID, f.OrderCodeID, f.OrderCode, f.OrderDesc,f.OrderDate,
			0 MedicalRecordsMatching
		from all_scanned  s
			left join CpsWarehouse.cps_orders.Fact_all_orders f on f.PID = s.PID   
																and f.OrderDesc like '%' + s.ScannedReport + '%' 
																and DATEDIFF(day, f.OrderDate,ScanDate) >= -30
																and DATEDIFF(day, f.OrderDate,ScanDate) <= 365
																
		where s.OrderLinkID = 0
			and s.OrderLinkID not in (select OrderLinkID from medical_records_matching)
			and s.SDID not in (select SDID from medical_records_matching)
	)
	,combine as (
		select 
			PID, SDID,ScanDate, ScannedReport, Scanned, 
			OrderLinkID, OrderCodeID, OrderCode, OrderDesc,Orderdate,
			MedicalRecordsMatching,
			 rowNum = ROW_NUMBER() over(partition by OrderlinkId Order by MedicalRecordsMatching desc, ScanDate Desc)
		from (
			select
				PID, SDID,ScanDate, ScannedReport, Scanned, 
				OrderLinkID, OrderCodeID, OrderCode, OrderDesc,Orderdate,
				MedicalRecordsMatching
			from random_matching

			union 

			select 
				PID, SDID,ScanDate, ScannedReport, Scanned, 
				OrderLinkID, OrderCodeID, OrderCode, OrderDesc,Orderdate,
				MedicalRecordsMatching
			from medical_records_matching
		) cm
	)
		select * 
		into #scanned_report
		from combine
		where rowNum = 1



				

	/*followup*/
	
	drop table if exists #tempFollowup;
	;with followup as (
	select 
		p.pid, p.SDID, p.OrderStartDate,
		case when p.ExternalvInternalvFollowup is null then 'Follow Up' else ExternalvInternalvFollowup end ExternalvInternalvFollowup, 

		case when CpsWarehouse.fxn.RemoveSpecialCharacters(p.FollowupComment) = '' then null
			else lower(p.FollowupComment)
		end FollowupComment,

		case when CpsWarehouse.fxn.RemoveSpecialCharacters(p.FollowupOverdue) = '' then null
			else lower(p.FollowupOverdue)
		end FollowupOverdue,

		case when CpsWarehouse.fxn.RemoveSpecialCharacters(p.FollowupReport) = '' then null
			else lower(p.FollowupReport)
		end FollowupReport
	
	from #pivot_referral_and_followup_data p
	where sdid not in (select sdid from #scanned_report)
			and 
				(
					FollowupOverdue is not null
					or FollowupComment is not  null 
					or FollowupReport is not null
				)
	
	
	)--, followUp_mapping as (
		select 
			h.PID, pp.patientid, pp.name, 
			h.ObsDate, h.SDID, p.Appended XID,
			h.ReferralSpecialist FollowupSpecialist, h.ReferralSpecialistID FollowupSpecialistId,

			h.OrderLinkId, h.OrderCodeId, h.OrderNum, h.OrderingProviderID, 
			h.ReferralCode, h.ReferralDesc,
			h.OrderDiag, h.OrderAuthNum, h.OrderStartDate, h.OrderEndDate,
			h.OrderAdminComment,

			r.ExternalvInternalvFollowup,
			r.FollowupComment, r.FollowupOverdue, r.FollowupReport,

			isnull(c.CCDA,0) CCDA, c.DirectAddress, c.SpecialistContact, c.Specialty, doc.Facility,
			rowNum = ROW_NUMBER() over(partition by OrderlinkId Order by h.ObsDate Desc)
		into #tempFollowup
		from followup r
			inner join #header_order_combine h on h.SDID = r.SDID
			left join #clean_specialty c on c.SDID = r.SDID
			left join CpsWarehouse.cps_all.PatientProfile pp on pp.pid = r.PID
			left join #pivot_referral_and_followup_data p on r.SDID = p.SDID
			left join CpsWarehouse.cps_visits.Document doc on doc.SDID = r.SDID;
	
	-- overall followup
	drop table if exists #followup;
	with cnt as(
		select OrderLinkId, count(*) TotalFollowup 
		from #tempFollowup
		group by OrderLinkId
	)
		select f.*, isnull(cnt.TotalFollowup,1) TotalFollowup
		into #followup
		from #tempFollowup f
			left join cnt on f.OrderLinkId = cnt.OrderLinkId
		where f.rowNum = 1;
	
	--folow up by staff
	drop table if exists #FollowByStaff;
	select 
		SDID,  XID,
		PID, PatientID, Name, ObsDate FollowUpDate,  
		FollowupSpecialist, FollowupSpecialistId, OrderLinkId, OrderCodeId, OrderNum, OrderingProviderID, ReferralDesc, ReferralCode,
		FollowupComment, FollowupOverdue, FollowupReport, Facility
	into #FollowByStaff
	from #tempFollowup


	/*referral setup*/
	drop table if exists #referral_setup;
	;with setup as (
		select 
			p.pid,p.SDID, 

			p.ExternalvInternalvFollowup, 

			case when CpsWarehouse.fxn.RemoveSpecialCharacters(p.ReferralApptDate) = '' then null
				else lower(p.ReferralApptDate)
			end ReferralApptDate,

			case when CpsWarehouse.fxn.RemoveSpecialCharacters(p.ReferralApptTBS) = '' then null
				else lower(p.ReferralApptTBS)
			end ReferralApptTBS,

			case when CpsWarehouse.fxn.RemoveSpecialCharacters(p.ReferralApptTime) = '' then null
				else lower(p.ReferralApptTime)
			end ReferralApptTime,		
					case when CpsWarehouse.fxn.RemoveSpecialCharacters(p.ReferraPtInstruction) = '' then null
				else lower(p.ReferraPtInstruction)
			end ReferraPtInstruction,

			p.ReferralRetro, p.ReferralStat, p.ReferralSummaryOfCare
		from #pivot_referral_and_followup_data p
		where sdid not in (
					select sdid from #scanned_report 
					union 
					select sdid from #followup
					)
		)
		, referral_setup_mapping as (
			select  
				h.PID, pp.patientid, pp.name, 
				h.ObsDate, h.SDID,h.ReferralSpecialist, h.ReferralSpecialistID,

				h.OrderLinkId, h.OrderCodeId, h.OrderNum, h.OrderingProviderID, 
				h.ReferralCode, h.ReferralDesc, p.Appended XID,
				h.OrderDiag, h.OrderAuthNum, h.OrderStartDate, h.OrderEndDate,
				h.OrderAdminComment,

				r.ExternalvInternalvFollowup,
				r.ReferralApptDate, r.ReferralApptTBS, r.ReferralApptTime, r.ReferraPtInstruction,
				r.ReferralRetro, r.ReferralStat, r.ReferralSummaryOfCare,

				isnull(c.CCDA,0) CCDA, c.DirectAddress, c.SpecialistContact, c.Specialty,

				doc.Facility,
				rowNum = ROW_NUMBER() over(partition by OrderlinkId Order by h.ObsDate Desc)
			--into #referral_setup
			from setup r
				inner join #header_order_combine h on h.SDID = r.SDID
				left join #clean_specialty c on c.SDID = r.SDID
				left join CpsWarehouse.cps_all.PatientProfile pp on pp.pid = r.PID
				left join #pivot_referral_and_followup_data p on r.SDID = p.SDID --and p.Appended = 1000000000000000000
				left join CpsWarehouse.cps_visits.Document doc on doc.SDID = r.SDID
		)
		, cnt as (
			select OrderLinkId, count(*) total
			from  referral_setup_mapping
			group by OrderLinkId
		)
			select r.*, isnull(cnt.total,1) TotalReferralAttempt
			into #referral_setup
			from referral_setup_mapping r
				left join cnt on r.orderlinkid = cnt.OrderLinkId
			where rowNum = 1;




	end

	/*
	select * from #referral_setup where sdid = 1840971200167760
	select * from #followup
	select * from #FollowByStaff where sdid = 1911814840042520
	select * from #scanned_report
	*/

	

	/*referral setup SSIS*/

		insert into CpsWarehouse.[cps_orders].[ReferralSetup] (
			[SDID], [XID], [PID], [PatientId], [Name], ReferralDate	, [ReferralSpecialistid], 
			[ReferralSpecialist], [OrderLinkID], [OrderCodeID], [OrderNum], 
			[OrderingProviderID], [ReferralDesc], [ReferralCode], [OrderDiag], 
			[OrderAuthNum], [OrderStartDate], [OrderEndDate], [OrderAdminComment], 
			[ExternalvInternalvFollowup], [ReferralApptDate], [ReferralApptTBS], 
			[ReferralApptTime], [ReferralPtInstruction], [ReferralRetro], [ReferralStat], 
			[ReferralSummaryOfCare], [SpecialistCCDA], [SpecialistDirectAddress], 
			[SpecialistContact], [Specialty] , Facility, TotalReferralAttempt
		)
		select 
			[SDID], [XID], [PID], [PatientId], [Name], [ObsDate], [ReferralSpecialistid], 
			[ReferralSpecialist], [OrderLinkID], [OrderCodeID], [OrderNum], 
			[OrderingProviderID], [ReferralDesc], [ReferralCode], [OrderDiag], 
			[OrderAuthNum], [OrderStartDate], [OrderEndDate], [OrderAdminComment], 
			[ExternalvInternalvFollowup], [ReferralApptDate], [ReferralApptTBS], 
			[ReferralApptTime], [ReferraPtInstruction], [ReferralRetro], [ReferralStat], 
			[ReferralSummaryOfCare], [CCDA], [DirectAddress], 
			[SpecialistContact], [Specialty] , Facility, TotalReferralAttempt
		from #referral_setup;

		
	/**referral followup SSIS*/

		insert into CpsWarehouse.cps_orders.ReferralFollowup(
			[SDID], [XID], [PID], [PatientId], [Name], FollowupDate, [FollowupSpecialistid], 
			[FollowupSpecialist], [OrderLinkID], [OrderCodeID], [OrderNum], 
			[OrderingProviderID], [ReferralDesc], [ReferralCode], [OrderDiag], 
			[OrderAuthNum], [OrderStartDate], [OrderEndDate], [OrderAdminComment], 
			[ExternalvInternalvFollowup], [FollowupComment], [FollowupOverdue], [FollowupReport], 
			[SpecialistCCDA], [SpecialistDirectAddress], 
			[SpecialistContact], [Specialty] , Facility,TotalFollowup
		)
		select 
			[SDID], [XID], [PID], [PatientId], [Name], [ObsDate], [FollowupSpecialistid], 
			[FollowupSpecialist], [OrderLinkID], [OrderCodeID], [OrderNum], 
			[OrderingProviderID], [ReferralDesc], [ReferralCode], [OrderDiag], 
			[OrderAuthNum], [OrderStartDate], [OrderEndDate], [OrderAdminComment], 
			[ExternalvInternalvFollowup], [FollowupComment], [FollowupOverdue], [FollowupReport], 
			[CCDA], [DirectAddress], 
			[SpecialistContact], [Specialty] , Facility,TotalFollowup
		from #followup;


		/*follow up by staff*/
		insert into CpsWarehouse.cps_orders.ReferralFollowup_ByStaff(
			[SDID], [XID], [PID], [PatientId], [Name], FollowupDate, [FollowupSpecialistid], 
			[FollowupSpecialist], [OrderLinkID], [OrderCodeID], [OrderNum], 
			[OrderingProviderID], [ReferralDesc], [ReferralCode], 
			[FollowupComment], [FollowupOverdue], [FollowupReport],
			Facility
		)
		select 
			[SDID], [XID], [PID], [PatientId], [Name], FollowUpDate, [FollowupSpecialistid], 
			[FollowupSpecialist], [OrderLinkID], [OrderCodeID], [OrderNum], 
			[OrderingProviderID], [ReferralDesc], [ReferralCode],  
			[FollowupComment], [FollowupOverdue], [FollowupReport]
			, Facility
		from #FollowByStaff;

	/*scanned - primary key composite (sdid and orderlinkid) - coz one scanned doc was used to close multiple orders*/

	insert into CpsWarehouse.cps_orders.ReferralScanned(
		PID, SDID, ScanDate, ScannedReport, Scanned, OrderLinkID, OrderCodeID, ReferralCode, ReferralDesc, OrderDate, MedicalRecordsMatching
	)
	select 
		PID, SDID, ScanDate,  ScannedReport, Scanned, OrderLinkID, OrderCodeID, OrderCode, OrderDesc, OrderDate, MedicalRecordsMatching
	from #scanned_report



end

go
