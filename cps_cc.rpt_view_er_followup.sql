
USE CpsWarehouse
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

drop view if exists [cps_cc].[rpt_view_er_followup];
go

create view [cps_cc].[rpt_view_er_followup]
as

	select
	f.ER_Followup_GUID,
	d.year, d.month, d.MonthName, d.quarter,
	pp.PID, pp.PatientID, pp.Name, pp.DoB, pp.Sex, 
	pr.Ethnicity1, pr.Ethnicity2, pr.SubRace1, pr.SubRace2, 
	case pp.IsHomeless when 1 then 'Yes' else 'No' end Homeless,
	pp.Language, case pp.LimitedEnglish when 1 then 'Yes' else 'No' end NeedTranslator, 
	pp.Phone1, pp.Phone2, pp.Phone3,
	--pp1.Address1 Address1, pp1.Address2 Address2, pp1.City City, pp1.State, 
	pp.Zip Zip,

	isnull(ic.InsuranceName,'') PrimaryInsurance, 
	isnull(ic.Classify_Major_Insurance,'Not Sure') PrimaryInsuranceGroup,
	isnull(ic2.InsuranceName,'') SecondaryInsurance, 
	isnull(ic2.Classify_Major_Insurance, 'Not Sure') SecondaryInsuranceGroup,

	pvt.InitialDoS, pvt.LastBilledDoS, f.ApptDateInCPS ApptAfterER,
	f.FutureApptDate, pp.PCP PCP, f.ApptFacility [Location],
	f.No_Show_Count,

	f.DischargeDate, f.ER, f.ER_Hosp_Name, f.Actual_Qualified_Appt_Range, 
	er_cnt.[Total for Year] ER_Count_Year, er_cnt.Years erYear,
	h_cnt.[Total for Year] Hosp_Count_Year, h_cnt.Years hospYear

	from cps_cc.ER_Followup f
		left join cps_all.PatientProfile pp on f.pid = pp.pid
		left join dimDate d on d.date = f.DischargeDate
		left join cps_all.PatientRace pr on pr.PID = pp.PID
		--left join cps_all.PatientProfile pp1 on pp1.PID = pp.PID
		left join cps_all.PatientInsurance ins on ins.PID = pp.PID
		--left join cps_all.DoctorFacility df on pp.PCPID = df.PVID
		left join cps_all.InsuranceCarriers ic on ins.PrimCarrierID = ic.InsuranceCarriersID
		left join cps_all.InsuranceCarriers ic2 on ins.SecCarrierID = ic2.InsuranceCarriersID
		left join (
					select PID, convert(date, max(pvt.DoS) ) LastBilledDoS, convert(date, min(pvt.Dos) ) InitialDoS
					from cps_visits.PatientVisitType pvt
					where pvt.MedicalVisit = 1 or pvt.BHVisit = 1
					group By PID
				) pvt on pvt.PID = f.PID 

		left join cps_cc.ER_Count er_cnt on er_cnt.PID = f.PID and er_cnt.er = 1 and er_cnt.Years = year(DischargeDate )  and er_cnt.years != 'PastYear'
		left join cps_cc.ER_Count h_cnt on h_cnt.PID = f.PID and h_cnt.er = 0 and h_cnt.Years = year(DischargeDate )  and h_cnt.years != 'PastYear'



GO
