
use CpsWarehouse
go
drop table if exists CpsWarehouse.[cps_all].[PatientInsurance] ;
go

CREATE TABLE CpsWarehouse.[cps_all].[PatientInsurance] (
    [PID]                 NUMERIC (19)  NOT NULL,
    [PrimCarrierID]       INT           NULL,
    [PrimEffectiveDate]   DATE          NULL,
    [PrimInsuranceNumber] VARCHAR (50)  NULL,
    [PrimVerifiedBy]      VARCHAR (160)  NULL,
    [PrimVerifiedDate]    DATE          NULL,
    [PrimVerifiedNotes]   VARCHAR (MAX) NULL,
    [SecCarrierID]        INT           NULL,
    [SecEffectiveDate]    DATE          NULL,
    [SecInsuranceNumber]  VARCHAR (50)  NULL,
    [SecVerifiedBy]       VARCHAR (160)  NULL,
    [SecVerifiedDate]     DATE          NULL,
    [SecVerifiedNotes]    VARCHAR (MAX) NULL,
	PRIMARY KEY CLUSTERED ([PID] ASC),
);


go
drop proc if exists [cps_all].[ssis_PatientInsurance];
go
CREATE PROCEDURE [cps_all].[ssis_PatientInsurance]
AS BEGIN

truncate table cps_all.PatientInsurance;
WITH u AS (
select 
	pp.pid [PID],
	ins.InsuranceCarriersId [PrimCarrierID],
	case when CONVERT(DATE,Ins.InsCardEffectiveDate) between '1800-01-01' and '2099-01-01' then CONVERT(DATE,Ins.InsCardEffectiveDate) end [PrimEffectiveDate],
	ins.InsuredId [PrimInsuranceNumber],
	ins.EligibilityVerifiedBy [PrimVerifiedBy],
	CONVERT(DATE,ins.EligibilityVerifiedDate) [PrimVerifiedDate],
	convert(varchar(max),ins.EligibilityNotes) [PrimVerifiedNotes],
	ins2.InsuranceCarriersId [SecCarrierID],
	CONVERT(DATE,Ins2.InsCardEffectiveDate) [SecEffectiveDate],
	ins2.InsuredId [SecInsuranceNumber],
	ins2.EligibilityVerifiedBy [SecVerifiedBy],
	CONVERT(DATE,ins2.EligibilityVerifiedDate) [SecVerifiedDate],
	CONVERT(VARCHAR(MAX),ins2.EligibilityNotes) [SecVerifiedNotes]
FROM CpsWarehouse.[cps_all].PatientProfile AS pp
	left JOIN [cpssql].CentricityPS.dbo.PatientInsurance AS ins 	ON (ins.PatientProfileId = pp.PatientProfileId	AND ins.Inactive = '0'	AND ins.OrderForClaims = '1')
	left JOIN [cpssql].CentricityPS.dbo.PatientInsurance AS ins2	ON (ins2.PatientProfileId = pp.PatientProfileId	AND ins2.Inactive = '0'	AND ins2.OrderForClaims = '2' and ins2.InsuredId is not null)
)
 INSERT into cps_all.PatientInsurance 
	(
		PID,[PrimCarrierID],PrimEffectiveDate,[PrimInsuranceNumber],PrimVerifiedBy,PrimVerifiedDate,PrimVerifiedNotes,
		[SecCarrierID],SecEffectiveDate,[SecInsuranceNumber],SecVerifiedDate,SecVerifiedBy,SecVerifiedNotes
	)
select 
	PID,[PrimCarrierID],PrimEffectiveDate,[PrimInsuranceNumber],PrimVerifiedBy,PrimVerifiedDate,PrimVerifiedNotes,
	[SecCarrierID],PrimEffectiveDate,[SecInsuranceNumber],SecVerifiedDate,SecVerifiedBy,SecVerifiedNotes
from u

END

go
