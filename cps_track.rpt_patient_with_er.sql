

use CpsWarehouse
go

drop proc if exists cps_track.rpt_patient_with_er;
go

create proc cps_track.rpt_patient_with_er
(
	@Facility varchar(5)
)

as 
begin
	
--	declare @facility varchar(5) = '1';/*915*/
	declare @today date = convert(date, getdate() ) ;

	declare @facilityid int = convert(int, @Facility);

	select distinct
		pp.PatientID, pp.Name,  ap.ApptDate, min(ap.StartTime) ApptTime,
		ap.FacilityID, ap.Facility, 
		isnull(er.[Total for Year],0) + isnull(hos.[Total for Year],0) 'Er/hosp',
		 ic.InsuranceName, df.ListName
	from cps_visits.Appointments ap
		left join cps_all.PatientProfile pp on pp.pid = ap.PID
		--left join cps_all.Location loc on loc.FacilityID = ap.FacilityID and loc.MainFacility = 1
		left join cps_cc.ER_Count er on er.PID = ap.PID and er.Years = 'PastYear' and er.er = 1
		left join cps_cc.ER_Count hos on hos.PID = ap.PID and hos.Years = 'PastYear' and hos.er = 0
		left join cps_all.PatientInsurance pin on pin.pid = pp.pid
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pin.PrimCarrierID
		left join cps_all.DoctorFacility df on ap.DoctorFacilityID = df.DoctorFacilityID
	where ap.ApptDate = @today
		and isnull(er.[Total for Year],0) + isnull(hos.[Total for Year],0) >= 2
		and ap.FacilityID = @facilityid
	group by pp.PatientID, pp.Name, ap.FacilityID, ap.Facility, er.[Total for Year], hos.[Total for Year], ic.InsuranceName, df.ListName, ap.ApptDate

end

go
