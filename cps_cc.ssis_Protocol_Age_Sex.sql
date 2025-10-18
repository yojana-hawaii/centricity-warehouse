

use CpsWarehouse
go
drop table if exists [cps_cc].[Protocol_Age_Sex]
go
CREATE TABLE [cps_cc].[Protocol_Age_Sex] (
    [PID]                    NUMERIC (19) NOT NULL,
    [OsteoporosisM80]        INT          NOT NULL,
    [Female16_24]            INT          NOT NULL,
    [Female21_64]            INT          NOT NULL,
    [Female50_75]            INT          NOT NULL,
    [All50_75]               INT          NOT NULL,
    [All65Plus]              INT          NOT NULL,
    [LastChlamydia]          DATE         NULL,
    [Chlamydia_DueIn]        INT          NOT NULL,
    [LastPapSmear]           DATE         NULL,
    [PapSmear_DueIn]         INT          NOT NULL,
    [LastMammogram]          DATE         NULL,
    [Mammogram_DueIn]        INT          NOT NULL,
    [ColorectalType]         VARCHAR (20) NULL,
    [LastColorectal]         DATE         NULL,
    [Colorectal_DueIn]       INT          NOT NULL,
    [LastFunctionalAssess]   DATE         NULL,
    [FunctionalAssess_DueIn] INT          NOT NULL,
    [LastDirective]          DATE         NULL,
    [Directive_DueIn]        INT          NOT NULL,
    [LastFractureQuestion]   DATE         NULL,
    [FractureQuestion_DueIn] INT          NULL,
    [LastBoneDensity]        DATE         NULL,
    [BoneDensity_DueIn]      INT          NULL,
    PRIMARY KEY CLUSTERED ([PID] ASC)
);
go
drop proc if exists [cps_cc].[ssis_Protocol_Age_Sex]
go
CREATE procedure [cps_cc].[ssis_Protocol_Age_Sex]
as begin

truncate table [cps_cc].[Protocol_Age_Sex]
	drop table if exists #lastProtocol;
	select 
		p.PID, p.Female16_24, p.Female21_64, p.Female50_75, p.All50_75, p.All65Plus, p.OsteoporosisM80,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.Chlamydia is not null
				and p.Female16_24 = 1
		) LastChlamydia,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.PapSmear is not null
				and p.Female21_64 = 1
		) LastPapSmear,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.Mammogram is not null
				and p.Female50_75 = 1
		) LastMammogram,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.Colonoscopy is not null
				and p.All50_75 = 1
		) LastColonoscopy,

		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.IFobt is not null
				and p.All50_75 = 1
		) LastIFobt,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.IFobt_Decline is not null
				and p.All50_75 = 1
		) LastIFobtDecline,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.Sigmoidscopy is not null
				and p.All50_75 = 1
		) LastSigmoidscopy,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.FitDNA is not null
				and p.All50_75 = 1
		) LastFitDNA,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.Tomography is not null
				and p.All50_75 = 1
		) LastTomography,

		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.Functional_ADL is not null
				and p.All65Plus = 1
		) LastFunctionalADL,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.Functional_IADL is not null
				and p.All65Plus = 1
		) LastFunctionalIADL,
		(
			select max(convert(date, d.db_updated_date) )
			from cpssql.CentricityPS.dbo.directiv d
			where d.pid = p.PID
				and p.All65Plus = 1
		) LastDirective,

		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.Osteo_fracture is not null
				and p.OsteoporosisM80 = 1
		) LastOsteo_fracture,

		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.BoneDensity is not null
				and p.OsteoporosisM80 = 1
		) LastBoneDensity,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.BoneDensitySpine is not null
				and p.OsteoporosisM80 = 1
		) LastBoneDensitySpine,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.BoneDensityLeft is not null
				and p.OsteoporosisM80 = 1
		) LastBoneDensityLeft,
		(
			select max(obsdate)
			from cps_obs.Age_Sex_Protocol_obs s
			where s.pid = p.pid
				and s.BoneDensityRight is not null
				and p.OsteoporosisM80 = 1
		) LastBoneDensityRight


	into #lastProtocol
	from cps_cc.tmp_view_Protocol_PatientsList p
	where Female16_24 = 1
		or Female21_64 = 1
		or Female50_75 = 1
		or All50_75 = 1
		or All65Plus = 1
		or OsteoporosisM80 = 1

	declare @OneYear int = 365,
		@TwoYear int = 730,
		@ThreeYear int = 1095,
		@FourYear int = 1460,
		@TenYear int = 3650;

	drop table if exists #protocol_next_due;
	select 
		p.PID, p.Female16_24, p.Female21_64, p.Female50_75, p.All50_75, p.All65Plus, p.OsteoporosisM80,
		p.LastChlamydia, fxn.ProtocolNextDueDate(p.LastChlamydia, @OneYear) NextChlamydia,
		p.LastPapSmear, fxn.ProtocolNextDueDate(p.LastPapSmear, @ThreeYear) NextPapSmear,
		p.LastMammogram, fxn.ProtocolNextDueDate(p.LastMammogram, @TwoYear) NextMammogram,

		p.LastColonoscopy, fxn.ProtocolNextDueDate(p.LastColonoscopy, @TenYear) NextColonoscopy,
		p.LastIFobt, fxn.ProtocolNextDueDate(p.LastIFobt, @OneYear) NextIFobt,
		p.LastIFobtDecline, 
		p.LastFitDNA, fxn.ProtocolNextDueDate(p.LastFitDNA, @TwoYear) NextFitDNA,
		p.LastSigmoidscopy, fxn.ProtocolNextDueDate(p.LastSigmoidscopy, @FourYear) NextSigmoidscopy,
		p.LastTomography, fxn.ProtocolNextDueDate(p.LastTomography, @FourYear) NextTomography,

		p.LastDirective, fxn.ProtocolNextDueDate(p.LastDirective, @OneYear) NextDirective,

		p.LastFunctionalADL, fxn.ProtocolNextDueDate(p.LastFunctionalADL, @OneYear) NextFunctionalADL,
		p.LastFunctionalIADL, fxn.ProtocolNextDueDate(p.LastFunctionalIADL, @OneYear) NextFunctionalIADL,

		p.LastOsteo_fracture, fxn.ProtocolNextDueDate(p.LastOsteo_fracture, @OneYear) NextOsteoFracture,
		
		p.LastBoneDensity,  fxn.ProtocolNextDueDate(p.LastBoneDensity, @OneYear) NextBoneDensity,
		p.LastBoneDensityLeft,  fxn.ProtocolNextDueDate(p.LastBoneDensityLeft, @OneYear) NextBoneDensitLeft,
		p.LastBoneDensityRight, fxn.ProtocolNextDueDate(p.LastBoneDensityRight, @OneYear) NextBoneDensitRight,
		p.LastBoneDensitySpine, fxn.ProtocolNextDueDate(p.LastBoneDensitySpine, @OneYear) NextBoneDensitSpine
	into #protocol_next_due
	from #lastProtocol p;



	with u1 as (
		select 
			p.PID, p.Female16_24, p.Female21_64, p.Female50_75, p.All50_75, p.All65Plus, p.OsteoporosisM80,
			p.LastChlamydia, fxn.ProtocolPastDue(p.NextChlamydia) Chlamydia_DueIn,
			p.LastPapSmear, fxn.ProtocolPastDue(p.NextPapSmear) PapSmear_DueIn,
			p.LastMammogram, fxn.ProtocolPastDue(p.NextMammogram) Mammogram_DueIn,

			p.LastColonoscopy,
			p.LastIFobt,
			p.LastIFobtDecline, 
			p.LastFitDNA, 
			p.LastSigmoidscopy,
			p.LastTomography,

			case
				when isnull(p.LastColonoscopy,'') >= isnull(p.LastIFobt,'')
					and isnull(p.LastColonoscopy,'') >= isnull(p.LastFitDNA,'')
					and isnull(p.LastColonoscopy,'') >= isnull(p.LastSigmoidscopy,'')
					and isnull(p.LastColonoscopy,'') >= isnull(p.LastTomography,'')
				then p.LastColonoscopy
				when isnull(p.LastIFobt,'') >= isnull(p.LastColonoscopy,'')
					and isnull(p.LastIFobt,'') >= isnull(p.LastFitDNA,'')
					and isnull(p.LastIFobt,'') >= isnull(p.LastSigmoidscopy,'')
					and isnull(p.LastIFobt,'') >= isnull(p.LastTomography,'')
				then p.LastIFobt
				when isnull(p.LastSigmoidscopy,'') >= isnull(p.LastIFobt,'')
					and isnull(p.LastSigmoidscopy,'') >= isnull(p.LastFitDNA,'')
					and isnull(p.LastSigmoidscopy,'') >= isnull(p.LastColonoscopy,'')
					and isnull(p.LastSigmoidscopy,'') >= isnull(p.LastTomography,'')
				then p.LastSigmoidscopy
				when isnull(p.LastTomography,'') >= isnull(p.LastIFobt,'')
					and isnull(p.LastTomography,'') >= isnull(p.LastFitDNA,'')
					and isnull(p.LastTomography,'') >= isnull(p.LastSigmoidscopy,'')
					and isnull(p.LastTomography,'') >= isnull(p.LastColonoscopy,'')
				then p.LastTomography
			end LastColorectal,
			case
				when isnull(p.LastColonoscopy,'') >= isnull(p.LastIFobt,'')
					and isnull(p.LastColonoscopy,'') >= isnull(p.LastFitDNA,'')
					and isnull(p.LastColonoscopy,'') >= isnull(p.LastSigmoidscopy,'')
					and isnull(p.LastColonoscopy,'') >= isnull(p.LastTomography,'')
				then 'Colonoscopy'
				when isnull(p.LastIFobt,'') >= isnull(p.LastColonoscopy,'')
					and isnull(p.LastIFobt,'') >= isnull(p.LastFitDNA,'')
					and isnull(p.LastIFobt,'') >= isnull(p.LastSigmoidscopy,'')
					and isnull(p.LastIFobt,'') >= isnull(p.LastTomography,'')
				then 'IFobt'
				when isnull(p.LastSigmoidscopy,'') >= isnull(p.LastIFobt,'')
					and isnull(p.LastSigmoidscopy,'') >= isnull(p.LastFitDNA,'')
					and isnull(p.LastSigmoidscopy,'') >= isnull(p.LastColonoscopy,'')
					and isnull(p.LastSigmoidscopy,'') >= isnull(p.LastTomography,'')
				then 'Sigmoidscopy'
				when isnull(p.LastTomography,'') >= isnull(p.LastIFobt,'')
					and isnull(p.LastTomography,'') >= isnull(p.LastFitDNA,'')
					and isnull(p.LastTomography,'') >= isnull(p.LastSigmoidscopy,'')
					and isnull(p.LastTomography,'') >= isnull(p.LastColonoscopy,'')
				then 'Tomography'
			end ColorectalType,

			case
				when p.NextColonoscopy >= p.NextIFobt
					and p.NextColonoscopy >= p.NextFitDNA
					and p.NextColonoscopy >= p.NextSigmoidscopy
					and p.NextColonoscopy >= p.NextTomography
				then p.NextColonoscopy
				when p.NextIFobt >= p.NextColonoscopy
					and p.NextIFobt >= p.NextFitDNA
					and p.NextIFobt >= p.NextSigmoidscopy
					and p.NextIFobt >= p.NextTomography
				then p.NextIFobt
				when p.NextSigmoidscopy >= p.NextIFobt
					and p.NextSigmoidscopy >= p.NextFitDNA
					and p.NextSigmoidscopy >= p.NextColonoscopy
					and p.NextSigmoidscopy >= p.NextTomography
				then p.NextSigmoidscopy
				when p.NextTomography >= p.NextIFobt
					and p.NextTomography >= p.NextFitDNA
					and p.NextTomography >= p.NextSigmoidscopy
					and p.NextTomography >= p.NextColonoscopy
				then p.NextTomography
			end NextColorectalScreening,

			p.LastFunctionalADL, 
			p.LastFunctionalIADL,
			case 
				when isnull(LastFunctionalADL,'') >= isnull(LastFunctionalIADL,'')
				then LastFunctionalIADL
				else LastFunctionalADL
			end LastFunctionalAssess,
			case 
				when p.NextFunctionalADL <= p.NextFunctionalIADL
				then p.NextFunctionalADL
				else p.NextFunctionalIADL
			end NextFunctionalAssessment,

			p.LastDirective, fxn.ProtocolPastDue(p.NextDirective) Directive_DueIn,

			p.LastOsteo_fracture LastFractureQuestion, fxn.ProtocolPastDue(p.NextOsteoFracture) FractureQuestion_DueIn,
			case 
				when isnull(LastBoneDensity,'') >= isnull(LastBoneDensityLeft,'')
					and isnull(LastBoneDensity,'') >= isnull(LastBoneDensityRight,'')
					and isnull(LastBoneDensity,'') >= isnull(LastBoneDensitySpine,'')
				then LastBoneDensity

				when isnull(LastBoneDensityLeft,'') >= isnull(LastBoneDensity,'')
					and isnull(LastBoneDensityLeft,'') >= isnull(NextBoneDensitRight,'')
					and isnull(LastBoneDensityLeft,'') >= isnull(NextBoneDensitSpine,'')
				then LastBoneDensityLeft

				when isnull(LastBoneDensityRight,'') >= isnull(NextBoneDensitLeft,'')
					and isnull(LastBoneDensityRight,'') >= isnull(LastBoneDensity,'')
					and isnull(LastBoneDensityRight,'') >= isnull(NextBoneDensitSpine,'')
				then LastBoneDensityRight

				when isnull(LastBoneDensitySpine,'') >= isnull(NextBoneDensitLeft,'')
					and isnull(LastBoneDensitySpine,'') >= isnull(NextBoneDensitRight,'')
					and isnull(LastBoneDensitySpine,'') >= isnull(LastBoneDensity,'')
				then LastBoneDensitySpine
			end LastBoneDensity,
			
			case 
				when NextBoneDensity >= NextBoneDensitLeft
					and NextBoneDensity >= NextBoneDensitRight
					and NextBoneDensity >= NextBoneDensitSpine
				then NextBoneDensity

				when NextBoneDensitLeft >= NextBoneDensity
					and NextBoneDensitLeft >= NextBoneDensitRight
					and NextBoneDensitLeft >= NextBoneDensitSpine
				then NextBoneDensitLeft

				when NextBoneDensitRight >= NextBoneDensitLeft
					and NextBoneDensitRight >= NextBoneDensity
					and NextBoneDensitRight >= NextBoneDensitSpine
				then NextBoneDensitRight

				when NextBoneDensitSpine >= NextBoneDensitLeft
					and NextBoneDensitSpine >= NextBoneDensitRight
					and NextBoneDensitSpine >= NextBoneDensity
				then NextBoneDensitSpine
			end NextBoneDensity

		from #protocol_next_due p
	)
	, u as (
		select 
			PID, Female16_24, Female21_64, Female50_75, All50_75, All65Plus, OsteoporosisM80,
			LastChlamydia, Chlamydia_DueIn,
			LastPapSmear, PapSmear_DueIn,
			LastMammogram, Mammogram_DueIn,

			LastColorectal, ColorectalType,
			fxn.ProtocolPastDue(NextColorectalScreening) Colorectal_DueIn,

			LastFunctionalAssess,
			fxn.ProtocolPastDue(NextFunctionalAssessment) FunctionalAssess_DueIn,

			LastDirective, Directive_DueIn,
			LastFractureQuestion, FractureQuestion_DueIn,
			LastBoneDensity,
			fxn.ProtocolPastDue(NextBoneDensity) BoneDensity_DueIn
		from u1
	) --select * from u
	insert into [cps_cc].[Protocol_Age_Sex](
		PID, OsteoporosisM80, Female16_24, Female21_64, Female50_75, All50_75, All65Plus,
		LastChlamydia, Chlamydia_DueIn, LastPapSmear, PapSmear_DueIn, 
		LastMammogram, Mammogram_DueIn, ColorectalType,LastColorectal, Colorectal_DueIn, LastFunctionalAssess, 
		FunctionalAssess_DueIn, LastDirective, Directive_DueIn,
		LastFractureQuestion, FractureQuestion_DueIn, LastBoneDensity, BoneDensity_DueIn
	)
	select
		PID, OsteoporosisM80, Female16_24, Female21_64, Female50_75, All50_75, All65Plus,
		LastChlamydia, Chlamydia_DueIn, LastPapSmear, PapSmear_DueIn, 
		LastMammogram, Mammogram_DueIn, ColorectalType,LastColorectal, Colorectal_DueIn, LastFunctionalAssess, 
		FunctionalAssess_DueIn, LastDirective, Directive_DueIn,
		LastFractureQuestion, FractureQuestion_DueIn, LastBoneDensity, BoneDensity_DueIn
	from u;
	end

go
