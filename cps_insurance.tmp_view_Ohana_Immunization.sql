
use CpsWarehouse
go



drop view if exists cps_insurance.tmp_view_Ohana_Immunization;
go
create view cps_insurance.tmp_view_Ohana_Immunization
as


	/*Immunizations*/
	select 
		imm.PID, imm.SDID, 
		vaccinegroup, Brand,
		datediff(year, pp.dob, imm.AdministeredDate) VaccineAge, pp.DoB,
		case  
			when VaccineGroup = 'PneumoPCV' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'PCV'
			when VaccineGroup = 'Rotavirus' 
						and Brand = 'RotaTeq Oral Solution' 
						and datediff(year, pp.dob, imm.AdministeredDate) < 21  
				then 'ROTA3DOSE'
			when VaccineGroup = 'Rotavirus' 
						and Brand = 'Rotarix Oral Suspension Reconstituted'  
						and datediff(year, pp.dob, imm.AdministeredDate) < 21 
				then 'ROTA2DOSE'
			when VaccineGroup = 'Meningococcal' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'MGN'
			when VaccineGroup = 'Human Papillomavirus' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'HPV'
			when VaccineGroup = 'Polio' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'IPV'
			when VaccineGroup = 'Varicella' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'VZV'
			when VaccineGroup = 'DTaP' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'DTAP'
			when VaccineGroup = 'MMR' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'MMR'
			when VaccineGroup = 'HIB' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'HIB'
			when VaccineGroup = 'TDAP' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'TDAP'
			when VaccineGroup = 'Influenza' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'INF'
			when VaccineGroup = 'Hepatitis A' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'HEP A'
			when VaccineGroup = 'Hepatitis B' and datediff(year, pp.dob, imm.AdministeredDate) < 21 then 'HEP B'
		end Service_Performed,
		'Yes' Service_Result,
		CVXCode, imm.AdministeredDate Service_Date,
		df.DoctorFacilityID, df.ListName, doc.PubUser
	from cps_imm.ImmunizationGiven imm 
		inner join cps_all.PatientInsurance ins on ins.pid = imm.pid
		inner join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = ins.PrimCarrierID
		inner join cps_visits.Document doc on doc.sdid = imm.SDID
		inner join cps_all.DoctorFacility df on df.PVID = doc.PubUser /**remove immunization in unsigned documents*/
		left join cps_all.PatientProfile pp on pp.pid = imm.pid
	where imm.AdministeredDate >= '2019-01-01'
		and ic.Classify_Major_Insurance = 'Ohana'
		and ins.PrimInsuranceNumber is not null
		and ins.PrimInsuranceNumber != ''
		and imm.Historical = 'N' and imm.wasGiven = 'y'

		;

		


go

