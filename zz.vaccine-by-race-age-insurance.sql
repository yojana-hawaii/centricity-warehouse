

use CpsWarehouse
go
/*american indian vaccinated in past 12 months*/
with u as (
	select distinct
		pp.pid, 
			case 
				when pp.AgeDecimal >= 19 and pp.AgeDecimal < 35  then 'age 19-34'
				when pp.AgeDecimal >= 35 and pp.AgeDecimal < 50  then 'age 35-49'
				when pp.AgeDecimal >= 50  then 'age 50+'
			end AgeRange
	from cps_imm.ImmunizationGiven imm 
		left join cps_all.PatientProfile pp on pp.pid = imm.PID
		left join cps_all.PatientRace pr on pr.pid = pp.PID
	where wasGiven = 'y'
		and Historical ='n'
		and AdministeredDate >= '9-5-2022'
		and datediff(year, pp.DoB, imm.AdministeredDate) >= 19
		and (pr.Race1 = 'American Indian or Alaska Native' or pr.Race2 = 'American Indian or Alaska Native')
		and TestPatient = 0
)
select AgeRange, count(*) Total 
from u
group by AgeRange


go
/*uninsured adult vaccinated in past 12 months*/
with u as (
	select distinct
		pp.pid, pp.AgeDecimal,
			case 
				when pp.AgeDecimal >= 19 and pp.AgeDecimal < 35  then 'age 19-34'
				when pp.AgeDecimal >= 35 and pp.AgeDecimal < 50  then 'age 35-49'
				when pp.AgeDecimal >= 50  then 'age 50+'
			end AgeRange
	from cps_imm.ImmunizationGiven imm 
		left join cps_all.PatientProfile pp on pp.pid = imm.PID
		left join cps_all.PatientInsurance pins on pins.pid = pp.PID
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pins.PrimCarrierID
	where wasGiven = 'y'
		and Historical ='n'
		and AdministeredDate >= '9-5-2022'
		and pp.AgeDecimal >= 19
		and ic.Classify_DoH_CVR = 'Uninsured'
		and TestPatient = 0
)
select AgeRange, count(*) Total 
from u
group by AgeRange

go 


/*private insurance adult vaccinated in past 12 months*/
with u as (
	select distinct
		pp.pid, pp.AgeDecimal,
			case 
				when pp.AgeDecimal >= 19 and pp.AgeDecimal < 35  then 'age 19-34'
				when pp.AgeDecimal >= 35 and pp.AgeDecimal < 50  then 'age 35-49'
				when pp.AgeDecimal >= 50  then 'age 50+'
			end AgeRange
	from cps_imm.ImmunizationGiven imm 
		left join cps_all.PatientProfile pp on pp.pid = imm.PID
		left join cps_all.PatientInsurance pins on pins.pid = pp.PID
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pins.PrimCarrierID
	where wasGiven = 'y'
		and Historical ='n'
		and AdministeredDate >= '9-5-2022'
		and pp.AgeDecimal >= 19
		and ic.Classify_DoH_CVR = 'Private'
		and TestPatient = 0
)
select AgeRange, count(*) Total 
from u
group by AgeRange

go 

/*public insurance adult vaccinated in past 12 months*/
with u as (
	select distinct
		pp.pid, pp.AgeDecimal, pp.last, pp.first, ic.InsuranceName,
			case 
				when pp.AgeDecimal >= 19 and pp.AgeDecimal < 35  then 'age 19-34'
				when pp.AgeDecimal >= 35 and pp.AgeDecimal < 50  then 'age 35-49'
				when pp.AgeDecimal >= 50  then 'age 50+'
			end AgeRange
	from cps_imm.ImmunizationGiven imm 
		left join cps_all.PatientProfile pp on pp.pid = imm.PID
		left join cps_all.PatientInsurance pins on pins.pid = pp.PID
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pins.PrimCarrierID
	where wasGiven = 'y'
		and Historical ='n'
		and AdministeredDate >= '9-5-2022'
		and pp.AgeDecimal >= 19
		and ic.Classify_DoH_CVR = 'Public'
		and TestPatient = 0
)
select AgeRange, count(*) Total 
from u
group by AgeRange

go 

/*not public, not private, and not uninsuranced insurance adult vaccinated in past 12 months*/
with u as (
	select distinct
		pp.pid, pp.AgeDecimal, pp.last, pp.first, ic.InsuranceName,
			case 
				when pp.AgeDecimal >= 19 and pp.AgeDecimal < 35  then 'age 19-34'
				when pp.AgeDecimal >= 35 and pp.AgeDecimal < 50  then 'age 35-49'
				when pp.AgeDecimal >= 50  then 'age 50+'
			end AgeRange
	from cps_imm.ImmunizationGiven imm 
		left join cps_all.PatientProfile pp on pp.pid = imm.PID
		left join cps_all.PatientInsurance pins on pins.pid = pp.PID
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pins.PrimCarrierID
	where wasGiven = 'y'
		and Historical ='n'
		and AdministeredDate >= '9-5-2022'
		and pp.AgeDecimal >= 19
		and ic.Classify_DoH_CVR not in ('Uninsured','Private','Public')
		and TestPatient = 0
)
select AgeRange, count(*) Total 
from u
group by AgeRange

go 

;with u as (
	select  pp.pid, pp.AgeDecimal,
		case 
			when AgeDecimal >= 0.5 and AgeDecimal < 5 then 'Age 6 mnths to 4 years'
			when AgeDecimal >= 5 and AgeDecimal < 12 then 'age 5-11'
			when AgeDecimal >= 12 and AgeDecimal < 19 then 'age 12-18'
		end AgeRange
	from cps_all.PatientProfile pp
	where TestPatient = 0 and PatientActive = 1
		and AgeDecimal < 19
		and AgeDecimal >= 0.5
)
	select AgeRange, count(*) Total
	from u
	group by AgeRange
