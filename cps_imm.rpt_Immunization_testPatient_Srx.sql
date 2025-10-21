
go
use CpsWarehouse
go


drop proc if exists cps_imm.rpt_Immunization_testPatient_Srx;
go

create proc cps_imm.rpt_Immunization_testPatient_Srx
as
begin

	select pp.Name, pp.PatientID, s.[RxSRXID], s.rxname, s.ndcCode NDC10, fxn.ConvertNdc10ToNdc11(s.NDCCode) NDC11, s.lotNo, convert(date, s.Expdate) ExpDate, s.Dose, s.mfr, s.locationID, convert(date,s.shotDate) ShotDate, s.SpFullName, s.HcpFullName
	FROM cpssql.[SRX_Cps].[dbo].[Shot] s
		left join cps_all.PatientProfile pp on s.patientid = pp.PatientID 
	where pp.TestPatient = 1
		and convert(date,s.shotDate) >= '2022-06-01'
		and s.[RxSRXID] not in ('testvac')

end

go
