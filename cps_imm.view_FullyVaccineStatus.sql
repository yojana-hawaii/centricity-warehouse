

use CpsWarehouse
go
drop view if exists cps_imm.view_fullyVaccinatedStatus
go
create view cps_imm.view_fullyVaccinatedStatus
as
	with viz_recommended_vaccine as (
		select 'Dtap' VaccineGroup, 4 Recommended
		union
		select 'PneumoPCV' VaccineGroup, 4 Recommended
		union
		select 'hepatitis b' VaccineGroup, 3 Recommended
		union
		select 'hib' VaccineGroup, 3 Recommended
		union
		select 'polio' VaccineGroup, 3 Recommended
		union
		select 'rotovirus' VaccineGroup, 2 Recommended
		union
		select 'mmr' VaccineGroup, 1 Recommended
		union
		select 'varicella' VaccineGroup, 1 Recommended
		union
		select 'MeningB' VaccineGroup, 2 Recommended
		union
		select 'hepatitis A' VaccineGroup, 1 Recommended
	)
	, cnt as (
		select PID, VaccineGroup, count(*) Total
		from cps_imm.ImmunizationWithCombo
		group by PID, VaccineGroup
	) , dose as (
		select 
			PID, u.VaccineGroup, Total, Recommended, 
			case 
				when Recommended is not null and u.Total <= Recommended then 1 
				when Recommended is not null and u.Total > Recommended then 0 
			End DoseComplete
		from cnt u
			left join viz_recommended_vaccine rec on rec.VaccineGroup = u.VaccineGroup
	) --select * from dose
	, u as (
		select 
			PID, PatientID, DoB, VaccineGroup,
			convert(numeric(19,0), [1]) Series1,
			convert(numeric(19,0), [2]) Series2,
			convert(numeric(19,0), [3]) Series3,
			convert(numeric(19,0), [4]) Series4,
			convert(numeric(19,0), [5]) Series5,
			convert(numeric(19,0), [6]) Series6,
			convert(numeric(19,0), [7]) Series7,
			convert(numeric(19,0), [8]) Series8
		from ( 
			select 
				PID, PatientID, DoB,  VaccineGroup, Series ,convert(varchar(20), ImmunizationId) ImmunizationId
			from cps_imm.ImmunizationWithCombo
			--where pid = 1920797233315810
		) q
		pivot (
			max(ImmunizationId)
			for Series in ([1],[2],[3],[4],[5],[6],[7],[8])
		) pvt
	) 
	select 
		u.PID, u.PatientID, u.DoB, u.VaccineGroup, 
		cnt.Total, cnt.Recommended Viz_Recommended, cnt.DoseComplete,
		s1.AdministeredDate Series1Date, s1.AdministeredBy Series1By, s1.Brand Series1Brand, s1.Facility Series1Facility, s1.VFCEligibility Series1VFC,
		
		s2.AdministeredDate Series2Date, s2.AdministeredBy Series2By, s2.Brand Series2Brand, s2.Facility Series2Facility, s2.VFCEligibility Series2VFC,
		s3.AdministeredDate Series3Date, s3.AdministeredBy Series3By, s3.Brand Series3Brand, s3.Facility Series3Facility, s3.VFCEligibility Series3VFC,
		s4.AdministeredDate Series4Date, s4.AdministeredBy Series4By, s4.Brand Series4Brand, s4.Facility Series4Facility, s4.VFCEligibility Series4VFC,
		s5.AdministeredDate Series5Date, s5.AdministeredBy Series5By, s5.Brand Series5Brand, s5.Facility Series5Facility, s5.VFCEligibility Series5VFC,
		s6.AdministeredDate Series6Date, s6.AdministeredBy Series6By, s6.Brand Series6Brand, s6.Facility Series6Facility, s6.VFCEligibility Series6VFC,
		s7.AdministeredDate Series7Date, s7.AdministeredBy Series7By, s7.Brand Series7Brand, s7.Facility Series7Facility, s7.VFCEligibility Series7VFC,
		s8.AdministeredDate Series8Date, s8.AdministeredBy Series8By, s8.Brand Series8Brand, s8.Facility Series8Facility, s8.VFCEligibility Series8VFC
	from u
		left join dose cnt on cnt.PID = u.PID and u.VaccineGroup = cnt.VaccineGroup
		left join cps_imm.ImmunizationGiven s1 on s1.ImmunizationId = u.Series1
		left join cps_imm.ImmunizationGiven s2 on s2.ImmunizationId = u.Series2
		left join cps_imm.ImmunizationGiven s3 on s3.ImmunizationId = u.Series3
		left join cps_imm.ImmunizationGiven s4 on s4.ImmunizationId = u.Series4
		left join cps_imm.ImmunizationGiven s5 on s5.ImmunizationId = u.Series5
		left join cps_imm.ImmunizationGiven s6 on s6.ImmunizationId = u.Series6
		left join cps_imm.ImmunizationGiven s7 on s7.ImmunizationId = u.Series7
		left join cps_imm.ImmunizationGiven s8 on s8.ImmunizationId = u.Series8	
--	where PatientId = 12101789

go
