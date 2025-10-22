
use CpsWarehouse
go

drop proc if exists cps_insurance.ElectronicInsuranceVerification;
go

create proc cps_insurance.ElectronicInsuranceVerification
(
	@ApptDay varchar(5) = 'Today'
)
as begin
	--declare @days varchar(5) = 'Today';
	declare @Today date = convert(date, getdate() );
	declare @StartDate date = '07-01-2021';
	set @Today = case when @ApptDay = 'All' then null else @Today end;

	;with x as (
		select  
			pp.PatientId PatientId, 
			ic.Name Insurance,
			ins.EligibilityVerified EligibilityStatus, 
			Convert(date, ins.EligibilityVerifiedDate) EligibilityVerifiedDate,
			rowNum = ROW_NUMBER() over(partition by patientId, Name order by apptstart asc)
		from cpssql.CentricityPS.dbo.Appointments ap
		left join cpssql.CentricityPS.dbo.PatientInsurance ins on ins.PatientProfileId = ap.OwnerId and Inactive = 0
		left join cpssql.CentricityPS.dbo.InsuranceCarriers ic on ic.InsuranceCarriersId = ins.InsuranceCarriersId
		left join cpssql.CentricityPS.dbo.PatientProfile pp  on pp.PatientProfileId = ins.PatientProfileId
		where 
			convert(date,ins.EligibilityVerifiedDate) <= convert(date,apptstart)
			and ApptKind = 1
			and ins.EligibilityVerifiedDate >= @StartDate
			and EligibilityVerifiedBy = 'CHE-EligibilityAutomation'
			and Convert(date, ap.ApptStart) = isnull(@Today, Convert(date, ap.ApptStart))
	)
		select pvt.Insurance, pvt.[0] NotVerified, pvt.[1] Verified, pvt.[2] EligibilityFailed, pvt.[3] EligibilityPending
		from (
				select PatientId, Insurance, EligibilityStatus
				from x 
				where rowNum = 1
			) q
			pivot (
				count(patientID)
				for EligibilityStatus in ([0],[1],[2],[3])
			) pvt

end

go

