
use CpsWarehouse
go

drop proc if exists cps_all.rpt_active_insurance
go

create proc cps_all.rpt_active_insurance
as 
begin

declare @cutoff_date date = dateadd(year, -1, convert(date, getdate()));
with cnt as (
	select  ic.InsuranceCarriersid,
		count(distinct pvt.PID) Unique_Patients, count(pvt.PID) Total_Encounters 
	from cpssql.CentricityPS.dbo.InsuranceCarriers ic
		left join cps_visits.PatientVisitType pvt on pvt.InsuranceCarrierUsed = ic.InsuranceCarriersid
	where ic.inactive = 0 
		and pvt.DoS >= @cutoff_date
	group by  ic.InsuranceCarriersid--, ic.ListName, ic.Address1, ic.City, ic.State, ic.Zip, ic.Phone1, ic.Notes, ic.AlertNotes
)
	select 
		ic.Name, ic.ListName, ic.Address1, ic.City, ic.State, ic.Zip, ic.Phone1, ic.Notes, ic.AlertNotes, 
		isnull(Unique_Patients,0) Unique_Patients,
		isnull(Total_Encounters, 0) Total_Encounters
	from cpssql.CentricityPS.dbo.InsuranceCarriers IC
		left join cnt on cnt.InsuranceCarriersid = ic.InsuranceCarriersid
	where ic.inactive = 0 
end

go



