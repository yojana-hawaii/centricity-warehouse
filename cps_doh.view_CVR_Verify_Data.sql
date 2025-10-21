
use CpsWarehouse
go

drop view if exists [cps_doh].[view_CVR_Verify_Data];
go

create view [cps_doh].[view_CVR_Verify_Data]
AS



	select 
		pp.PID, f.PatientID, pp.PatientProfileID, f.SDID, cl.DoS, f.Provider, f.Summary , 
		case f.LoC 
			when 'CVR patient' then '1- 915'
			when '915/952' then '1- 915'
			when 'Dowtown' then '2- DT'
			when 'Kaaahi' then '3- KSC'
			when 'Living Well' then '5- LW'
			when '710' then '4- 710'
		end Clinic,
		case pp.Sex when 'M' then 'Male' when 'F' then 'Female' else 'U' end Sex,
		pp.DoB, 
		floor(datediff(day, pp.DoB, cl.DoS) / 365.25) AgeAtService,

		(select 
			case
			when floor(datediff(day, pp.DoB, cl.DoS) / 365.25) < 15 then 'Under 15'
			when floor(datediff(day, pp.DoB, cl.DoS) / 365.25) >= 15 and floor(datediff(day, pp.DoB, cl.DoS) / 365.25) <= 17 then '15-17'
			when floor(datediff(day, pp.DoB, cl.DoS) / 365.25) >= 18 and floor(datediff(day, pp.DoB, cl.DoS) / 365.25) <= 19 then '18-19'
			when floor(datediff(day, pp.DoB, cl.DoS) / 365.25) >= 20 and floor(datediff(day, pp.DoB, cl.DoS) / 365.25) <= 24 then '20-24'
			when floor(datediff(day, pp.DoB, cl.DoS) / 365.25) >= 25 and floor(datediff(day, pp.DoB, cl.DoS) / 365.25) <= 29 then '25-29'
			when floor(datediff(day, pp.DoB, cl.DoS) / 365.25) >= 30 and floor(datediff(day, pp.DoB, cl.DoS) / 365.25) <= 34 then '30-34'
			when floor(datediff(day, pp.DoB, cl.DoS) / 365.25) >= 35 and floor(datediff(day, pp.DoB, cl.DoS) / 365.25) <= 39 then '35-39'
			when floor(datediff(day, pp.DoB, cl.DoS) / 365.25) >= 40 and floor(datediff(day, pp.DoB, cl.DoS) / 365.25) <= 44 then '40-44'
			when floor(datediff(day, pp.DoB, cl.DoS) / 365.25) > 44  then 'Over 44'
		end
		from CpsWarehouse.[cps_all].PatientProfile pp
		where pp.pid = f.pid
		) AgeRangeAtService,

		c.Zip, 
		case c.Race 
			when 1 then 'American Indian or Alaska Native' 
			when 2 then 'Asian' 
			when 3 then 'Black' 
			when 4 then 'Hawaiian & OPI'
			when 5 then 'White'
			when 6 then 'MoreThanOne'
			when 7 then 'Unspecified'
			when 0 then 'Why'
		end Race,
		c.Ethnicity, 
		case c.FamilySize when '00' then null else c.FamilySize end FamilySize, 
		case when c.MonthlyIncome = '0000' and c.FamilySize = '00'  then null else c.MonthlyIncome end MonthlyIncome,
		case race.SubRace1 when 'More Than One SubRace' then 'More Than One' else race.SubRace1 end SubRace,
		case c.Education
			when 1 then '< HS'
			when 2 then 'HS/ GED'
			when 3 then 'Some College'
			when 4 then 'Associate'
			when 5 then 'Bachelor +'
		end Education,
		c.English,
		case c.CompactFree
			when 1 then 'Marshallese'
			when 2 then 'Chuukese'
			when 5 then 'No'
		end CompactFree,
		ic.InsuranceName, 
		--c.Insurance,
		case c.Insurance
			when 1 then 'Uninsured'
			when 2 then 'Public'
			when 3 then 'Private'
			when 4 then 'Military'
		end Insurance,
		c.Confidential,
		case [Pregnancy Intention 37-1] when 1 then 'UnPlanned (+ or -)' when 2 then 'Planned (+ or -)' end PregnancyIntention,
		case o.[Tobacco 38-1] when 'N' then 'N' when 'Y' then 'Y' end Tobacco, 
			case o.[Alcohol 39-1] when 'N' then 'N' when 'Y' then 'Y' end Alcohol, 
			case o.[Drug Use 40-1] when 'N' then 'N' when 'Y' then 'Y' end Drug, 
			case o.[Domestic Violence 41-1] when 'N' then 'N' when 'Y' then 'Y' end DV, 
			case o.[PHQ2 42-1] when 'N' then 'N' when 'Y' then 'Y' end PHQ, 
			case when o.[BMI 43-6] = ' ' then null else o.[BMI 43-6] end BMI, 
			o.[BP 49-1], o.[PelvicEx 50-1], 
			(CASE WHEN o.[Pap 51-1] = 'Y' OR cl.[Pap 51-1] = 'Y' THEN 'Y' ELSE 'N' END) Pap, 
			o.[TestaEx 52-1], o.[ClinicBreastEx 53-1], 
			cl.[FurtherBreast 54-1], 
			case o.[Pregnancy Result 55-1] when 'P' then 'P' when 'N' then 'N' end PregnancyResult, 
			(CASE WHEN o.[ECPPartial 56-1] = 'Y' OR cl.[EmergencyContra 56-1] = 'Y' THEN 'Y' ELSE 'N' END) EmergencyContra, 
			cl.[Chlam_test 57-1], cl.[Chlam_Retest 58-1], cl.[Gono_test 59-1], cl.[Gono_Retest 60-1], 
			o.[HIV Confidential 61-1], cl.[Syphi_test 62-1],
			cl.[Chlam_treat 63-1],  cl.[Gono_treat 64-1], cl.[Syphi_treat 65-1], o.[CervCap 111-2 03],
			(CASE WHEN cl.[IUDAdd 67-1] = 'Y' OR o.[IUDAdd 67-1] = 'Y' THEN 'Y' ELSE 'N' END) IUDAdd,
			(CASE WHEN cl.[IUDRemove 68-1] = 'Y' OR o.[IUDRemove 68-1] = 'Y' THEN 'Y' ELSE 'N' END) IUDRemove,
			(CASE WHEN cl.[ImplantAdd 69-1] = 'Y' OR o.[ImplanonAdd 69-1] = 'Y' THEN 'Y' ELSE 'N' END) ImplantAdd,
			(CASE WHEN cl.[ImplantRemove 70-1] = 'Y' OR o.[ImplanonRemove 70-1] = 'Y' THEN 'Y' ELSE 'N' END) ImplantRemove,
			o.[ReproHealthEd 71-1], o.[InfertilityEd 72-1], o.[PreconceptionEd 73-1], o.[DVEd 74-1], o.[ReproLifePlanEd 75-1],
			o.[PregEd 76-1], o.[AdolescentEd 77-1], o.[OtherEd 78-1], 
			ltrim(rtrim(o.[OtherEdSpec 79-30])) OtherEducation, 
			o.[HIV/STD 109-1], o.[Condom Use 110-1],
			(CASE 
				WHEN o.[Contraceptive 111-2] = '00' AND cl.[DepoPartial 111-2 14] = 'Y' THEN 'Depo' 
				WHEN o.[Contraceptive 111-2] = '00' AND cl.[OralContra 111-2 11] = 'Y' 
					or o.[Contraceptive 111-2] = '11'THEN 'Oral' 
				WHEN o.[Contraceptive 111-2] = '00' AND cl.[Patch 111-2 15] = 'Y' THEN 'Patch' 
				WHEN (o.[Contraceptive 111-2] = '00' AND cl.[VaginaRing 111-2 16] = 'Y')
					or o.[Contraceptive 111-2] = '16' THEN 'Vagina Ring' 
				when o.[Contraceptive 111-2] = '18' then 'Vasectomy'
				when o.[Contraceptive 111-2] = '07' then 'Female Sterlization'
				when o.[Contraceptive 111-2] = '05' then 'Implant'
				when o.[Contraceptive 111-2] = '02' then 'IUD'
				when o.[Contraceptive 111-2] = '22' then 'LAM'
				when o.[Contraceptive 111-2] = '14' then 'Depo'
				when o.[Contraceptive 111-2] = '18' then 'Vasectomy'
				when o.[Contraceptive 111-2] = '03' then 'CervicalCap'
				when o.[Contraceptive 111-2] = '23' then 'MaleCondom'
				when o.[Contraceptive 111-2] = '24' then 'FemaleCondom'
				when o.[Contraceptive 111-2] = '17' then 'ContraceptiveSponge'
				when o.[Contraceptive 111-2] = '25' then 'Withdrawal'
				when o.[Contraceptive 111-2] = '06' then 'FAM'
				when o.[Contraceptive 111-2] = '09' then 'Spermicide'
				when o.[Contraceptive 111-2] = '26' then 'Other'
				when o.[Contraceptive 111-2] = '12' then 'Abstinence'
				when o.[Contraceptive 111-2] = '06' then 'FAM'
				when o.[Contraceptive 111-2] = '100' then 'No Method'

			END) Contraception,
			(CASE WHEN o.[Contraceptive 111-2] = '00' AND [DepoPartial 111-2 14] = 'Y' THEN '14' 
				WHEN  o.[Contraceptive 111-2] = '00' AND [OralContra 111-2 11] = 'Y' THEN '11' 
				WHEN  o.[Contraceptive 111-2] = '00' AND [Patch 111-2 15] = 'Y' THEN '15' 
				WHEN  o.[Contraceptive 111-2] = '00' AND [VaginaRing 111-2 16] = 'Y' THEN '16' 
				when o.[Contraceptive 111-2] = '99' then '  '
				ELSE O.[Contraceptive 111-2]
			END) ContraceptionNumber,
			o.[OtherContra 113-30], 
			case  o.[NoReason 143-1] 
				when '2' then 'Pregnant'
				when '1' then 'Seeking'
				when '3' then 'Other' end NoContraceptionReason, 
				o.[NoMethodContra 144-30]
	from  CpsWarehouse.[cps_doh].tmp_view_FindCVRPatients f
		left join CpsWarehouse.[cps_doh].CVRClient c 
				on f.PID = c.PID 
					and convert(int,c.SubID) = case f.LoC 
											when 'CVR patient' then 1
											when '915/952' then 1
											when 'Dowtown' then 2
											when 'Kaaahi' then 3
											when 'Living Well' then 5
											when '710' then 4
											end
		left join CpsWarehouse.[cps_all].PatientProfile pp on f.pid = pp.PID
		left join CpsWarehouse.[cps_all].PatientRace race on race.PID = pp.PID
		left join CpsWarehouse.[cps_all].[PatientInsurance] pis on pis.PID = pp.pid
		left join CpsWarehouse.[cps_all].[InsuranceCarriers] ic on pis.PrimCarrierID = ic.InsuranceCarriersID
		left JOIN CpsWarehouse.[cps_doh].[CVRVisitClinicalList] cl on f.SDID = cl.SDID and f.pid = cl.pid
		left JOIN CpsWarehouse.[cps_doh].[CVRClientObs] o on f.SDID = o.SDID and f.pid = o.pid


go
