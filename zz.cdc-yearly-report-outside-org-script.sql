/*
	
*/
select  distinct
			--Carrier at the time of visit
			ins.InsuranceCarrierName as [Primary Insur Carrier],					--Amerigroup
			ins.InsuredId as [Primary IC Insured Id], 
			--Demos... routine
			mem.First as 'Member First Name',
			mem.Last as 'Member Last Name',
			mem.Address1 AS 'Address 1',
			mem.Address2 AS 'Address 2',
			mem.City,
			mem.STATE,
			mem.Zip as Zipcode,
			mem.Phone1 as 'Telephone',
			mem.EMailAddress as 'Email Address',				
			mem.Sex as 'Gender'	,					--Entered as 'M' or 'F' in this table 
			mem.SSN,
			mem.PatientId as 'Patient ID',
			RaceDesc.Description as 'Race',
			EthDesc.Description as 'Ethnicity',
			marital.Description	as 'Marital Status',					-- Marital Status


			--Demos join is to provide relationship, otherwise duplicates mem
			demos.PatientRelationToGuarantor as Relationship, --rel.Description as Relationship,			--Needs expanded; have to find the table
			convert(varchar(10),mem.Birthdate,101) as DOB,

			doc.UPIN as [Provider Key],			--NULLS ARE RETURNED IN SAMPLE DATA
			doc.First+' '+doc.Last as [Provider Name],
			doc.NPI as [Provider NPI],
			doc.FederalTaxId as [Provider Tax Id],
			doc.Specialty as [Provider Specialty],
			-- Start and end date are same
			convert(varchar(10),visit.visit,101) as [Start Date of Service],
			convert(varchar(10),visit.Visit,101) as [End Date of Service],
			-- Return primary and four secondary ICDs
			icd1.ICD9Code as ICDDxPri,
			icd1.Description as ICDDxPri_Desc,
			icd2.ICD9Code as ICDDxSec,
			icd2.Description as ICDDxSec_Desc,
			icd3.ICD9Code as ICDDxSec1,
			icd3.Description as ICDDxSec1_Desc,
			icd4.ICD9Code as ICDDxSec2,
			icd4.Description as ICDDxSec2_Desc,
			icd5.ICD9Code as ICDDxSec3,	
			icd5.Description as ICDDxSec3_Desc,
			-- Smoking status, from OBS
			s.smoking,
				-- CPT from PatientVisitProcs
				cpt.[cptcode] as CPT,
				null as CPTII,							--CPTII not used
				null as HPCS,							--HPCS not used
				-- Labs due date is in OBS
				-- Labs don't feed back to (this version of) Centricity
				labs.LabsDue as [Lab Fulfillment Date],	
				null as LOINC,							--Each lab entry has a LOINC
				null as NDC,
				-- BMI, height, weight from OBS							--National drug code
				bmi.BMI as BMI,
				h.Height as Height,						--inches
				w.[weight] as [Weight],					--pounds
				-- LDL is in OBS, but labs dont' feed back
				ldl.ldl as LDL,
				-- BP information in OBS
				Z.BP_SYS as [Systolic Blood Pressure],	
				y.BP_DIA as [Diastolic Blood Pressure],
				t.TEMPERATURE as [Temperature],
				-- Lead, A1C are in OBS, but labs dont' feed back
				lead.Lead  as [Lead Screening],
				a1c.HBA1C as HBA1c,						--A1C
				-- Eye exam is in OBS
				eyes.eye_exam as [Eye Exam Negative]
				-- Reflects prescription date, not fill date
--				convert(varchar(10),pharm.CLINICALDATE,101) as [Rx Fill Date],	--Dte prescription issued
				-- Reflects quantity, not days supply
--				pharm.quantity as [Rx Days Supply],				--Rx quantity or days supply not stated
				-- Facility location as string.
				-- Often entered two ways for one visit
--				locreg.SEARCHNAME as [Place of Service]
				
		from 
		cpssql.CentricityPS.dbo.patientvisit visit 		
				LEFT JOIN cpssql.CentricityPS.dbo.PatientVisitProcs cpt
						on cpt.PatientVisitId=visit.PatientVisitId
				inner join cpssql.CentricityPS.dbo.patientprofile mem
						on visit.patientprofileid=mem.PatientProfileId

				left join cpssql.CentricityPS.dbo.PatientRace race				--Race links RDR
						on race.PatientProfileId=mem.PatientProfileId
				left join cpssql.CentricityPS.dbo.MedLists RaceDesc
						on racedesc.MedListsId=race.PatientRaceMid

				left join cpssql.CentricityPS.dbo.PatientEthnicity ethnicity				--Ethnicity links RDR
						on ethnicity.PatientProfileId=mem.PatientProfileId
				left join cpssql.CentricityPS.dbo.MedLists EthDesc
						on ethdesc.MedListsId=ethnicity.PatientEthnicityMid

				left join cpssql.CentricityPS.dbo.MedLists Marital
						on Marital.MedListsId=mem.MaritalStatusMId

				inner join cpssql.CentricityPS.dbo.uvPatientInsurance ins
						on ins.PatientInsuranceId=visit.CurrentPICarrierId
				left join cpssql.CentricityPS.dbo.uvPatientDemographics demos 
						on demos.PatientProfileId=ins.patientprofileid
				LEFT join cpssql.CentricityPS.dbo.uvdoctor doc
						on DOC.DoctorID=Visit.DoctorID
						/* multiple trips for ICD9 */
				LEFT join cpssql.CentricityPS.dbo.PatientVisitDiags icd1
						on (icd1.PatientVisitId=visit.PatientVisitId
						and icd1.ListOrder=1)
				LEFT JOIN (select a.ICD9Code,a.PatientVisitId, a.Description 
						from cpssql.CentricityPS.dbo.PatientVisitDiags a
						where listorder=2) icd2
						on icd2.PatientVisitId=visit.PatientVisitId		
				LEFT JOIN (select a.ICD9Code ,a.PatientVisitId, a.Description 
						from cpssql.CentricityPS.dbo.PatientVisitDiags a
						where listorder=3) icd3
						on icd3.PatientVisitId=visit.PatientVisitId		
				LEFT JOIN (select a.ICD9Code ,a.PatientVisitId, a.Description 
						from cpssql.CentricityPS.dbo.PatientVisitDiags a
						where listorder=4) icd4
						on icd4.PatientVisitId=visit.PatientVisitId		
				LEFT JOIN (select a.ICD9Code ,a.PatientVisitId, a.Description
						from cpssql.CentricityPS.dbo.PatientVisitDiags a
						where listorder=5) icd5
						on icd5.PatientVisitId=visit.PatientVisitId		
				/* OBS = OBServations? 
					Has to join PatientVisits by pid,date, reject deleteds*/
				left join cpssql.CentricityPS.dbo.OBS
						on mem.pid=obs.PID 
						and (CONVERT(varchar(10),obs.obsdate,101)=CONVERT(varchar(10),visit.Visit,101)
						and obs.XID=1000000000000000000)
				left join cpssql.CentricityPS.dbo.LOCREG
						on locreg.FacilityId=visit.FacilityId
				left join cpssql.CentricityPS.dbo.PRESCRIB pharm
						on pharm.sdid=obs.sdid
						
				--SMOK STATUS
					left join (select m.obsvalue as SMOKING,m.pid,m.SDID
						from cpssql.CentricityPS.dbo.OBS m,
							cpssql.CentricityPS.dbo.OBSHEAD n
						where n.HDID=m.HDID
							and n.name = 'SMOK STATUS'
							and n.XID=1000000000000000000) s on obs.sdid=s.SDID

				--BP SYSTOLIC
				left outer join (select m.obsvalue as BP_SYS,m.pid ,m.sdid
					from cpssql.CentricityPS.dbo.OBS m,
						cpssql.CentricityPS.dbo.OBSHEAD n
					where n.HDID=m.HDID
						and n.name = 'BP SYSTOLIC'
						and n.XID=1000000000000000000) z on obs.sdid=z.sdid
						
				--BP DIASTOLIC
				left outer join (select m.obsvalue as BP_DIA,m.pid ,m.sdid
					from cpssql.CentricityPS.dbo.OBS m,
						cpssql.CentricityPS.dbo.OBSHEAD n
					where n.HDID=m.HDID
						and n.name = 'BP DIASTOLIC'
						and n.XID=1000000000000000000) y on obs.sdid=y.sdid

				--Temperature
				left outer join (select m.obsvalue as TEMPERATURE,m.pid ,m.sdid
					from cpssql.CentricityPS.dbo.OBS m,
						cpssql.CentricityPS.dbo.OBSHEAD n
					where n.HDID=m.HDID
						and n.name = 'Temperature'
						and n.XID=1000000000000000000) t on obs.sdid=t.sdid

				--HEIGHT
				left outer join (select m.obsvalue as Height,m.pid ,m.sdid
					from cpssql.CentricityPS.dbo.OBS m,
						cpssql.CentricityPS.dbo.OBSHEAD n
					where n.HDID=m.HDID
						and n.name = 'HEIGHT'
						and n.XID=1000000000000000000) h on obs.sdid=h.sdid 

				--WEIGHT
				left outer join (select m.obsvalue as weight,m.pid ,m.sdid
					from cpssql.CentricityPS.dbo.OBS m,
						cpssql.CentricityPS.dbo.OBSHEAD n
					where n.HDID=m.HDID
					and n.name = 'WEIGHT'
					and n.XID=1000000000000000000) w on obs.sdid=w.sdid

				--LABS DUE DTE		
				left outer join (select m.obsvalue as LabsDue,m.pid ,m.sdid
					from cpssql.CentricityPS.dbo.OBS m,
						cpssql.CentricityPS.dbo.OBSHEAD n
					where n.HDID=m.HDID
						and n.name = 'LABS DUE'
						and n.XID=1000000000000000000) labs on obs.sdid=labs.sdid 

				--LDL
				left outer join (select m.obsvalue as LDL,m.pid ,m.sdid
					from cpssql.CentricityPS.dbo.OBS m,
						cpssql.CentricityPS.dbo.OBSHEAD n
					where n.HDID=m.HDID
						and n.name = 'LDL'
						and n.XID=1000000000000000000) LDL on obs.sdid=Ldl.sdid
						
				--LEAD
				left outer join (select m.obsvalue as Lead,m.pid ,m.sdid
					from cpssql.CentricityPS.dbo.OBS m,
						cpssql.CentricityPS.dbo.OBSHEAD n
					where n.HDID=m.HDID
						and n.name = 'LEAD SCREENI'
						and n.XID=1000000000000000000) lead on obs.sdid=lead.sdid 

				--BMI
				left outer join (select m.obsvalue as BMI,m.pid ,m.sdid
					from cpssql.CentricityPS.dbo.OBS m,
						cpssql.CentricityPS.dbo.OBSHEAD n
					where n.HDID=m.HDID
						and n.name = 'BMI'
						and n.XID=1000000000000000000) bmi on obs.sdid=bmi.sdid

				--HGBA1C
				left outer join (select m.obsvalue as HBA1C,m.pid,m.sdid 
					from cpssql.CentricityPS.dbo.OBS m,
						cpssql.CentricityPS.dbo.OBSHEAD n
					where n.HDID=m.HDID
						and n.name = 'HGBA1C'
						and n.XID=1000000000000000000) a1c on obs.sdid=A1C.sdid 

				--EYE EXAM (NOT EYE EXAM RESULTS)
				left outer join (select m.obsvalue as eye_exam,m.pid,m.sdid 
					from cpssql.CentricityPS.dbo.OBS m,
						cpssql.CentricityPS.dbo.OBSHEAD n
					where n.HDID=m.HDID
						and n.name = 'EYE EXAM'
						and n.XID=1000000000000000000) eyes on obs.sdid=eyes.sdid 
					
where 	visit.Visit >= '2021-01-01'	--start date
	and visit.Visit < '2022-01-02'	--end date