
	use CpsWarehouse
	go

	drop view if exists cps_doh.tmp_view_FindCVRPatients;
	go

	create VIEW cps_doh.tmp_view_FindCVRPatients
	AS
		WITH FPExclusive AS (
			SELECT 
				ifInOfficeVisit.PID,ifInOfficeVisit.SDID,ifInOfficeVisit.XID,ifInOfficeVisit.DOCTYPE,ifInOfficeVisit.SUMMARY,ifInOfficeVisit.PatientVisitId,obs.OBSVALUE
			FROM [cpssql].CentricityPS.dbo.OBS
				INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT ifInOfficeVisit ON (ifInOfficeVisit.SDID = OBS.SDID AND ifInOfficeVisit.DOCTYPE = 1)
			WHERE hdid = 462432

			UNION

			SELECT 
				joinMainDoc.PID,joinMainDoc.SDID,joinMainDoc.XID,joinMainDoc.DOCTYPE,joinMainDoc.SUMMARY,joinMainDoc.PatientVisitId,obs.OBSVALUE
			FROM [cpssql].CentricityPS.dbo.OBS
				INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT ifAppended ON (ifAppended.SDID = OBS.SDID AND ifAppended.DOCTYPE = 31)
				INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT joinMainDoc ON (ifAppended.XID = joinMainDoc.SDID)
			WHERE hdid = 462432
		) 
		, AllCVRPatients AS (
			SELECT 
				ifInOfficeVisit.PID,ifInOfficeVisit.SDID,ifInOfficeVisit.XID,ifInOfficeVisit.DOCTYPE,ifInOfficeVisit.SUMMARY,ifInOfficeVisit.PatientVisitId,obs.OBSVALUE,ifInOfficeVisit.DB_CREATE_DATE,ifInOfficeVisit.PUBUSER,ifInOfficeVisit.usrid
			FROM [cpssql].CentricityPS.dbo.OBS
				INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT ifInOfficeVisit ON (ifInOfficeVisit.SDID = OBS.SDID AND ifInOfficeVisit.DOCTYPE IN (1,6) )
			WHERE hdid = 97955

			UNION 

			SELECT 
				joinMainDoc.PID,joinMainDoc.SDID,joinMainDoc.XID,joinMainDoc.DOCTYPE,joinMainDoc.SUMMARY,joinMainDoc.PatientVisitId,obs.OBSVALUE,joinMainDoc.DB_CREATE_DATE,joinMainDoc.PUBUSER,joinMainDoc.usrid
			FROM [cpssql].CentricityPS.dbo.OBS
				INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT ifAppended ON (ifAppended.SDID = OBS.SDID AND ifAppended.DOCTYPE = 31)
				INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT joinMainDoc ON (ifAppended.XID = joinMainDoc.SDID)
			WHERE hdid = 97955
		)
			select 
				cvr.PID, pp.PatientId, pp.PatientProfileId, (pp.last + ', ' + pp.First) SearchName,CVR.OBSVALUE LoC,
				cvr.xid,cvr.sdid,cvr.doctype,cvr.DB_CREATE_DATE,cvr.Summary,
				df.ListName Provider,(LEFT(df.First, 1) + LEFT(df.Last, 1)) AS [Provider Initial], df.Suffix,cvr.PatientVisitId,
				(CASE WHEN fpex.PID IS NULL THEN 0 ELSE 1 END) FPExclusive
			from AllCVRPatients cvr
				LEFT JOIN FPExclusive fpex on fpex.SDID = cvr.SDID
				INNER JOIN CpsWarehouse.cps_all.PatientProfile AS pp ON pp.PId = cvr.PID 
				INNER JOIN [cpssql].CentricityPS.dbo.DoctorFacility AS df ON cvr.usrid = df.PVId 
			WHERE pp.testPatient = 0
	go

