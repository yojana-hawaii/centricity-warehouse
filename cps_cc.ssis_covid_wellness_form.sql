
use CpsWarehouse
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

drop table if exists CpsWarehouse.cps_cc.Covid_Wellness_Form;
go

create table cps_cc.Covid_Wellness_Form (
	[PID] numeric(19, 0) not null,
	[PatientID] int not null,
	[SDID] numeric(19, 0) not null,
	[XID] numeric(19, 0) not null,
	[covid_result] varchar(2000) null,
	[Test_Location] varchar(2000) null,
	[Household_under19] varchar(2000) null,
	[Household_adult] varchar(2000) null,
	[Household_positive] varchar(2000) null,
	[Household_sick] varchar(2000) null,
	[Household_hospital] varchar(2000) null,
	[Household_Restroom] varchar(2000) null,
	[Household_Bedroom] varchar(2000) null,
	[Household_tested_Count] varchar(2000) null,
	[household_positive_count] varchar(2000) null,
	[household_quarantine] varchar(2000) null,
	[Patient_Quarantine] varchar(2000) null,
	[CDR] varchar(2000) null,
	[PCR] varchar(2000) null,
	[PUI] varchar(2000) null,
	[Contact_DOH] varchar(2000) null,
	[lab_discussed] varchar(2000) null,
	[Pregnant] varchar(2000) null,
	[BH_Referral] varchar(2000) null,
	[Employed] varchar(2000) null,
	[Pregnant_Months] varchar(2000) null,
	[Employer] varchar(2000) null,
	[Understand_when_to_seek_medical_attention] varchar(2000) null,
	[Telehealth_Followup_48hours] varchar(2000) null,
	[Telehealth_Followup_10-14Days] varchar(2000) null,
	[Covid_Education] nvarchar(2000) null,
	[Resources] varchar(2000) null,
	[Food_refer_CARES] varchar(2000) null,
	[Food_Phone] varchar(2000) null,
	[Food_Delivery] varchar(2000) null,
	[Medical_Charge] varchar(2000) null,
	[Medical_delivery] varchar(2000) null,
	[PPE_Delivery] varchar(2000) null,
	[PPD_Supplier] varchar(2000) null,
	[PPE_basic_supply] varchar(2000) null,
	[Correspondence] varchar(2000) null,
	[Legal] varchar(2000) null,
	[Childcare] varchar(2000) null,
	[Financial] varchar(2000) null,
	[Hygiene_Delivery] varchar(2000) null,
	[Hygiene_Supplier] varchar(2000) null,
	[Temp_relocation] varchar(2000) null,
	[Housing] varchar(2000) null,
	[Transportation] varchar(2000) null,
	[Coordination] varchar(2000) null,
	[Disability] varchar(2000) null,
	[MH Referral] varchar(2000) null,
	[Mental Health Support] varchar(2000) null,
	[Subst referral] varchar(2000) null,
	[Employer_Contact_Phone] varchar(2000) null,
	[Employer_Contact_Name] varchar(2000) null,
	[TDI] varchar(2000) null,
	[ROI] varchar(2000) null
)
 
go


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop proc if exists  cps_cc.ssis_Covid_Wellness_Form;
go
create procedure cps_cc.ssis_Covid_Wellness_Form
as begin
	truncate table CpsWarehouse.cps_cc.Covid_Wellness_Form;
	drop table if exists ##dynamic_temp_table
	drop table if exists #pivot_table


	declare @comma_separated_hdid nvarchar(max), @StartDate date = '2020-01-01', @EndDate date = convert(date, getdate() );


	set @comma_separated_hdid = '665997,671185,12562,43461,1341,1342,1343,1344,1345,1347,1349,1350,1353,1354,1355,664316,
				1356,674103,21505,1316,95303,21818,8595,534528,666598,666599,674104,643674,532647,532630,532633,532628,
				532629,532632,532631,532627,532637,532638,532634,414466,532635,532636,414489,414492,414491,414488,414487,
				194995,414482,218443,414481,414467,399108,414476'

	declare @pivoted_sql nvarchar(max) = fxn.ConvertObsHdidIntoDynamicPivot( @comma_separated_hdid, @StartDate, @EndDate)


	--print @pivoted_sql
	exec sp_executesql @pivoted_sql

	select * 
	into #pivot_table
	from  ##dynamic_temp_table

	drop table ##dynamic_temp_table

	--select * from #pivot_table

	--Select name ColumnNames From Tempdb.Sys.Columns Where Object_ID = Object_ID('tempdb..#pivot_table')


	;with u as (
		select p.PID, pp.PatientID, p.SDID, p.XID, 
			isnull ( p.[covid-19], '') as [covid_result],
			isnull ( p.[ncovcontloc], '') as [Test_Location],
			isnull ( p.[#child<18 in], '') as [Household_under19],
			isnull ( p.[adults#hshld], '') as [Household_adult],
			isnull ( p.[hoffmanrflxr], '') as [Household_positive],
			isnull ( p.[hoffmanrflxl], '') as [Household_sick],
			isnull ( p.[rflxsepigr], '') as [Household_hospital],
			isnull ( p.[rflxshypgasr], '') as [Household_Restroom],
			isnull ( p.[rflxscremr], '') as [Household_Bedroom],
			isnull ( p.[rflxsquadr], '') as [Household_tested_Count],
			isnull ( p.[rflxsgassolr], '') as [household_positive_count],
			isnull ( p.[rflxsgassoll], '') as [household_quarantine],
			isnull ( p.[rflxshamintr], '') as [Patient_Quarantine],
			isnull ( p.[rflxshamintl], '') as [CDR],
			isnull ( p.[rflxshamextr], '') as [PCR],
			isnull ( p.[ptidentpui], '') as [PUI],
			isnull ( p.[rflxshamextl], '') as [Contact_DOH],
			isnull ( p.[covid19cnsts], '') as [lab_discussed],
			isnull ( p.[preg/imprgnt], '') as [Pregnant],
			isnull ( p.[rflxshypgasl], '') as [BH_Referral],
			isnull ( p.[employed], '') as [Employed],
			isnull ( p.[gestatnmonth], '') as [Pregnant_Months],
			isnull ( p.[currjobemplr], '') as [Employer],
			isnull ( p.[sdhhcamedcre], '') as [Understand_when_to_seek_medical_attention],
			isnull ( p.[covid19fudd1], '') as [Telehealth_Followup_48hours],
			isnull ( p.[covid19fudd2], '') as [Telehealth_Followup_10-14Days],
			isnull ( lower(p.[covid19edcns]), '') as [Covid_Education],
			isnull ( p.[sdoh assess], '') as [Resources],
			isnull ( p.[tcm1phonecom], '') as [Food_refer_CARES],
			isnull ( p.[tcmcomcaret], '') as [Food_Phone],
			isnull ( p.[tcmcomcmser], '') as [Food_Delivery],
			isnull ( p.[tcmcomfmly], '') as [Medical_Charge],
			isnull ( p.[tcmcomguard], '') as [Medical_delivery],
			isnull ( p.[tcmcomhha], '') as [PPE_Delivery],
			isnull ( p.[tcmcomoprof], '') as [PPD_Supplier],
			isnull ( p.[tcmcompt], '') as [PPE_basic_supply],
			isnull ( p.[tcmmdsp3], '') as [Correspondence],
			isnull ( p.[tcmmdsp4], '') as [Legal],
			isnull ( p.[tcmresource], '') as [Childcare],
			isnull ( p.[dateofinte], '') as [Financial],
			isnull ( p.[tcmmdsp1], '') as [Hygiene_Delivery],
			isnull ( p.[tcmmdsp2], '') as [Hygiene_Supplier],
			isnull ( p.[tcmappcoodte], '') as [Temp_relocation],
			isnull ( p.[tcmapcorvby], '') as [Housing],
			isnull ( p.[tcmapcorwit], '') as [Transportation],
			isnull ( p.[tcmasuprevby], '') as [Coordination],
			isnull ( p.[tcmasssupnte], '') as [Disability],
			isnull ( p.[bh cm ref], '') as [MH Referral],
			isnull ( p.[tcmcomnterev], '') as [Mental Health Support],
			isnull ( p.[pactrefbh], '') as [Subst referral],
			isnull ( p.[tcmcomresnte], '') as [Employer_Contact_Phone],
			isnull ( p.[tcmconmthd], '') as [Employer_Contact_Name],
			isnull ( p.[tcmdcphys], '') as [TDI],
			isnull ( p.[tcmdedrvby], '') as [ROI]
		from #pivot_table p
			left join cps_all.PatientProfile pp on pp.pid = p.pid
		where 
			p.[ncovcontloc] is not null
			or p.[#child<18 in] is not null
			or p.[adults#hshld] is not null
			or p.[hoffmanrflxr] is not null
			or p.[hoffmanrflxl] is not null
			or p.[rflxsepigr] is not null
			or p.[rflxshypgasr] is not null
			or p.[rflxscremr] is not null
			or p.[rflxsquadr] is not null
			or p.[rflxsgassolr] is not null
			or p.[rflxsgassoll] is not null
			or p.[rflxshamintr] is not null
			or p.[rflxshamintl] is not null
			or p.[rflxshamextr] is not null
			or p.[ptidentpui] is not null
			or p.[rflxshamextl] is not null
			or p.[covid19cnsts] is not null
			or p.[preg/imprgnt] is not null
			or p.[rflxshypgasl] is not null
			or p.[employed] is not null
			or p.[gestatnmonth] is not null
			or p.[currjobemplr] is not null
			or p.[sdhhcamedcre] is not null
			or p.[covid19fudd1] is not null
			or p.[covid19fudd2] is not null
			or p.[covid19edcns] is not null
			or p.[sdoh assess] is not null
			or p.[tcm1phonecom] is not null
			or p.[tcmcomcaret] is not null
			or p.[tcmcomcmser] is not null
			or p.[tcmcomfmly] is not null
			or p.[tcmcomguard] is not null
			or p.[tcmcomhha] is not null
			or p.[tcmcomoprof] is not null
			or p.[tcmcompt] is not null
			or p.[tcmmdsp3] is not null
			or p.[tcmmdsp4] is not null
			or p.[tcmresource] is not null
			or p.[dateofinte] is not null
			or p.[tcmmdsp1] is not null
			or p.[tcmmdsp2] is not null
			or p.[tcmappcoodte] is not null
			or p.[tcmapcorvby] is not null
			or p.[tcmapcorwit] is not null
			or p.[tcmasuprevby] is not null
			or p.[tcmasssupnte] is not null
			or p.[bh cm ref] is not null
			or p.[tcmcomnterev] is not null
			or p.[pactrefbh] is not null
			or p.[tcmcomresnte] is not null
			or p.[tcmconmthd] is not null
			or p.[tcmdcphys] is not null
			or p.[tcmdedrvby] is not null
	)
	insert into CpsWarehouse.cps_cc.Covid_Wellness_Form([PID],[PatientID],[SDID],[XID],[covid_result],[Test_Location],
			[Household_under19],[Household_adult],[Household_positive],[Household_sick],[Household_hospital],[Household_Restroom],
			[Household_Bedroom],[Household_tested_Count],[household_positive_count],[household_quarantine],
			[Patient_Quarantine],[CDR],[PCR],[PUI],[Contact_DOH],[lab_discussed],[Pregnant],[BH_Referral],[Employed],
			[Pregnant_Months],[Employer],[Understand_when_to_seek_medical_attention],[Telehealth_Followup_48hours],
			[Telehealth_Followup_10-14Days],[Covid_Education],[Resources],[Food_refer_CARES],[Food_Phone],[Food_Delivery],
			[Medical_Charge],[Medical_delivery],[PPE_Delivery],[PPD_Supplier],[PPE_basic_supply],[Correspondence],[Legal],
			[Childcare],[Financial],[Hygiene_Delivery],[Hygiene_Supplier],[Temp_relocation],[Housing],[Transportation],
			[Coordination],[Disability],[MH Referral],[Mental Health Support],[Subst referral],[Employer_Contact_Phone],
			[Employer_Contact_Name],[TDI],[ROI]
			)
	select [PID],[PatientID],[SDID],[XID],[covid_result],[Test_Location],
			[Household_under19],[Household_adult],[Household_positive],[Household_sick],[Household_hospital],[Household_Restroom],
			[Household_Bedroom],[Household_tested_Count],[household_positive_count],[household_quarantine],
			[Patient_Quarantine],[CDR],[PCR],[PUI],[Contact_DOH],[lab_discussed],[Pregnant],[BH_Referral],[Employed],
			[Pregnant_Months],[Employer],[Understand_when_to_seek_medical_attention],[Telehealth_Followup_48hours],
			[Telehealth_Followup_10-14Days],[Covid_Education],[Resources],[Food_refer_CARES],[Food_Phone],[Food_Delivery],
			[Medical_Charge],[Medical_delivery],[PPE_Delivery],[PPD_Supplier],[PPE_basic_supply],[Correspondence],[Legal],
			[Childcare],[Financial],[Hygiene_Delivery],[Hygiene_Supplier],[Temp_relocation],[Housing],[Transportation],
			[Coordination],[Disability],[MH Referral],[Mental Health Support],[Subst referral],[Employer_Contact_Phone],
			[Employer_Contact_Name],[TDI],[ROI]
	from u;

	drop table if exists #pivot_table;

end
go
