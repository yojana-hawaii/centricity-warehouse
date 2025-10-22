
USE master
GO

/*

mklink /d c:\CpsWarehouse \\fileserver\it\apps\sql\centricity-warehouse

linked server separate

Turn on sqlCmd Mode --> Query --> sqlCmd Mode
--create user report
--Job Separately
*/

/******************dbo path******************/
print('Message: Script start.')
print('Message: Not counted > 1 sql CMDscript + 2 csv import + 1 gitignore + 1 proj file = 6')
:setvar path_main c:\CpsWarehouse


GO
/*not counted here 
this script file - 1
import csv - 2 
*/
/*create database - 5*/
:r $(path_main)\01_create_database.sql
:r $(path_main)\02_create_schema.sql
:r $(path_main)\dbo.dimDates.sql
:r $(path_main)\dbo.Numbers.sql
:r $(path_main)\dbo.zipcodes.sql
print('Message: 5 Database Created, schema added, dates and number dimension added')

/*functions > 2 + 6 + 3 + 5 + 2 = 18*/
:r $(path_main)\fxn.ClinicalDateToDate.sql
:r $(path_main)\fxn.ClinicalDateToDateTime.sql

:r $(path_main)\fxn.ConvertFlowsheetIntoColumnNameForInsert.sql
:r $(path_main)\fxn.ConvertFlowsheetIntoColumnNameForTable.sql
:r $(path_main)\fxn.ConvertFlowsheetIntoDynamicPivot.sql
:r $(path_main)\fxn.ConvertNdc10ToNdc11.sql
:r $(path_main)\fxn.ConvertObsHdidIntoDynamicPivot.sql
:r $(path_main)\fxn.ConvertRtfToText.sql

:r $(path_main)\fxn.GetSubstringCount.sql
:r $(path_main)\fxn.ProtocolNextDueDate.sql
:r $(path_main)\fxn.ProtocolPastDue.sql


:r $(path_main)\fxn.RemoveAlphaCharacters.sql
:r $(path_main)\fxn.RemoveNonAlphaCharacters.sql
:r $(path_main)\fxn.RemoveNonAlphaNumericCharacters.sql
:r $(path_main)\fxn.RemoveSpecialCharacters.sql
:r $(path_main)\fxn.RemoveWeirdWhiteSpaces.sql

:r $(path_main)\fxn.SplitStrings.sql
:r $(path_main)\fxn.StripMultipleSpaces.sql
print('Message: 18 functions created')

/*cps all > 3 + 4 + 4 + 1 + 2 + 9 = 23*/
--before temp views
:r $(path_main)\cps_all.ssis_Location.sql
:r $(path_main)\cps_all.ssis_Location-x.sql
:r $(path_main)\cps_all.ssis_DoctorFacility.sql
-- before patient Profile
:r $(path_main)\cps_all.tmp_view_PatientProvider.sql
:r $(path_main)\cps_all.tmp_view_PatientEthnicity.sql
:r $(path_main)\cps_all.tmp_view_PatientEducation.sql
:r $(path_main)\cps_all.tmp_view_PatientCountry.sql
--SSIS
:r $(path_main)\cps_all.ssis_PatientProfile.sql
:r $(path_main)\cps_all.ssis_PatientRace.sql
:r $(path_main)\cps_all.ssis_InsuranceCarriers.sql
:r $(path_main)\cps_all.ssis_PatientInsurance.sql

:r $(path_main)\cps_all.view_DoctorFacility_Active_30days.sql

:r $(path_main)\cps_all.rpt_view_ActiveProviders.sql
:r $(path_main)\cps_all.rpt_view_major_Insurances.sql

:r $(path_main)\cps_all.rpt_active_facility.sql
:r $(path_main)\cps_all.rpt_active_insurance.sql
:r $(path_main)\cps_all.rpt_ActiveProviders.sql
:r $(path_main)\cps_all.rpt_doctorfacility.sql
:r $(path_main)\cps_all.rpt_facility.sql
:r $(path_main)\cps_all.rpt_identify_patient_insurance.sql
:r $(path_main)\cps_all.rpt_identify_patient_with_InsuranceID.sql
:r $(path_main)\cps_all.rpt_InsuranceCarrier_Classify.sql
:r $(path_main)\cps_all.rpt_quest_patient_income.sql

print('Message: 23 cps_all created')

/*cps visit 1 + 6 + 1 + 5 = 13*/
:r $(path_main)\cps_visits.tmp_view_ApptType.sql

:r $(path_main)\cps_visits.ssis_Appointments.sql
:r $(path_main)\cps_visits.ssis_ApptCycleTime.sql
:r $(path_main)\cps_visits.ssis_ApptLog.sql
:r $(path_main)\cps_visits.ssis_Document.sql
:r $(path_main)\cps_visits.ssis_PatientVisitType.sql
:r $(path_main)\cps_visits.ssis_PatientVisitType_join_Document.sql

:r $(path_main)\cps_visits.rpt_view_ApptCycle.sql

:r $(path_main)\cps_visits.rpt_PatientPanelPerProvider.sql
:r $(path_main)\cps_visits.rpt_Productivity_by_Medicaid.sql
:r $(path_main)\cps_visits.rpt_Productivity_Monthly_Ticket_Generated.sql
:r $(path_main)\cps_visits.rpt_Productivity_Number_Issues.sql
:r $(path_main)\cps_visits.rpt_random_Visit_per_provider.sql
print('Message: 13 cps-visits created')

/*orders > 5 + 3 + 6 + 2 + 7 + 5 = 28*/
:r $(path_main)\cps_orders.ssis_OrderSpecialist.sql
:r $(path_main)\cps_orders.ssis_OrderCodesAndCategories.sql
:r $(path_main)\cps_orders.ssis_Fact_all_orders.sql
:r $(path_main)\cps_orders.ssis_Referral_Setup_followup_scan.sql
:r $(path_main)\cps_orders.ssis_email_future_orders.sql

:r $(path_main)\cps_orders.view_External_Imaging_Orders.sql
:r $(path_main)\cps_orders.view_External_Referral_Orders.sql
:r $(path_main)\cps_orders.view_Internal_Referral_Orders.sql

:r $(path_main)\cps_orders.rpt_view_EnablingCodes.sql
:r $(path_main)\cps_orders.rpt_view_ExternalReferral.sql
:r $(path_main)\cps_orders.rpt_view_InternalReferral_Appt.sql
:r $(path_main)\cps_orders.rpt_view_LabResults.sql
:r $(path_main)\cps_orders.rpt_view_Lab_Referral_Imaging.sql
:r $(path_main)\cps_orders.rpt_view_Radiology.sql

:r $(path_main)\cps_orders.rpt_EnablingCodeCount.sql
:r $(path_main)\cps_orders.rpt_EnablingCodeCount_HCHP.sql

:r $(path_main)\cps_orders.rpt_External_Referral_All.sql
:r $(path_main)\cps_orders.rpt_External_Referral_Dashboard.sql
:r $(path_main)\cps_orders.rpt_External_Referral_Provider_Summary.sql
:r $(path_main)\cps_orders.rpt_External_Referral_Quarters.sql
:r $(path_main)\cps_orders.rpt_External_Referral_Team_Summary.sql
:r $(path_main)\cps_orders.rpt_External_Referral_Tracking.sql
:r $(path_main)\cps_orders.rpt_internal_referral_tracking.sql

:r $(path_main)\cps_orders.rpt_LabResults.sql
:r $(path_main)\cps_orders.rpt_Lab_Referral_Imaging.sql
:r $(path_main)\cps_orders.rpt_OrderStatusSummary.sql
:r $(path_main)\cps_orders.rpt_Radiology.sql
:r $(path_main)\cps_orders.rpt_EnablingCodeCount_HCHP.sql

print('Message: 28 cps-orders created')


/*cps setup - 3 + 1 + 2 = 6*/
:r $(path_main)\cps_setup.ssis_Encounters_DocumentTemplates.sql
:r $(path_main)\cps_setup.ssis_Form_Components.sql
:r $(path_main)\cps_setup.ssis_Text_Components.sql

:r $(path_main)\cps_setup.view_cpt_prodecure_setup.sql

:r $(path_main)\cps_setup.rpt_Encounters_DocumentTemplates.sql
:r $(path_main)\cps_setup.rpt_User_Favorite_Form.sql
print('Message: 6 cps-setup created')

/*hl7 > 2 + 4 = 6*/
:r $(path_main)\cps_hl7.tmp_view_HL7_External_Source.sql
:r $(path_main)\cps_hl7.ssis_all_HL7_Mapping.sql

:r $(path_main)\cps_hl7.view_CLH_Mapping.sql
:r $(path_main)\cps_hl7.view_DLS_Mapping.sql
:r $(path_main)\cps_hl7.view_DocMan_Mapping.sql
:r $(path_main)\cps_hl7.view_HDRS_Mapping.sql


print('Message: 6 cps-hl7 created')



/*obs*/
:r $(path_main)\cps_obs.ssis_obshead.sql
:r $(path_main)\cps_obs.ssis_Aapcho.sql
:r $(path_main)\cps_obs.ssis_Age_Sex_Protocol_obs.sql
:r $(path_main)\cps_obs.ssis_Diabetes_Obs.sql
:r $(path_main)\cps_obs.ssis_DirectMessaging_Sent.sql
:r $(path_main)\cps_obs.ssis_ExternalLabsResults.sql
:r $(path_main)\cps_obs.ssis_Flowsheet_Recussive.sql
:r $(path_main)\cps_obs.ssis_LabsFlowsheet.sql
:r $(path_main)\cps_obs.ssis_VitalSignFlowsheet.sql
print('Message: 9 cps_obs created')
GO

/*cps bh > 1 + 5 + 2 + 8 = 16*/
:r $(path_main)\cps_bh.tmp_view_BH_Appointments.sql

:r $(path_main)\cps_bh.ssis_BH_Patient.sql
:r $(path_main)\cps_bh.ssis_BH_Metric_All.sql
:r $(path_main)\cps_bh.ssis_BH_SbirtCode.sql
:r $(path_main)\cps_bh.ssis_BH_SbirtObs.sql
:r $(path_main)\cps_bh.ssis_BH_phq_Gad.sql

:r $(path_main)\cps_bh.rpt_view_BH_Gad_PhQ.sql
:r $(path_main)\cps_bh.rpt_view_BHSbirt_Code_Obs.sql

:r $(path_main)\cps_bh.rpt_BH_Gad_Phq_Changes.sql
:r $(path_main)\cps_bh.rpt_BH_Gad_Phq_Count_By_Month.sql
:r $(path_main)\cps_bh.rpt_BH_Gad_Phq_Details.sql
:r $(path_main)\cps_bh.rpt_bh_gad_phq_Provider.sql
:r $(path_main)\cps_bh.rpt_BH_PatientList.sql
:r $(path_main)\cps_bh.rpt_BH_sbirt_count_by_month.sql
:r $(path_main)\cps_bh.rpt_BH_sbirt_details.sql
:r $(path_main)\cps_bh.rpt_BH_sbirt_provider.sql
print('Message: 16 cps_bh created')

/*meds*/
:r $(path_main)\cps_meds.ssis_PatientMedication.sql

:r $(path_main)\cps_meds.view_ActivePharmacy.sql
:r $(path_main)\cps_meds.rpt_Walgreens_340B.sql
print('Message: 4 cps_meds created')

/*diag*/
:r $(path_main)\cps_diag.ssis_Problem_First_Last_Assessment.sql
print('Message: 1 cps_diag created')


/*cps-imm> 4 + 2 + 1 + 9 + 1= 17**/
:r $(path_main)\cps_imm.ssis_ImmunizationSetup.sql
:r $(path_main)\cps_imm.ssis_ImmunizationGiven.sql
:r $(path_main)\cps_imm.ssis_ImmunizationWithCombo.sql
:r $(path_main)\cps_imm.ssis_Immunization_Combo.sql

:r $(path_main)\cps_imm.ssis_SrxCurrentInventory.sql
:r $(path_main)\cps_imm.ssis_SrxDuplicateInventory.sql

:r $(path_main)\cps_imm.view_FullyVaccineStatus.sql

:r $(path_main)\cps_imm.rpt_ImmunizationSetup.sql
:r $(path_main)\cps_imm.rpt_VaccineDoseTracker.sql
:r $(path_main)\cps_imm.rpt_DistinctVaccineGroup.sql
:r $(path_main)\cps_imm.rpt_ImmunizationAggByFacility.sql
:r $(path_main)\cps_imm.rpt_ImmunizationAggByProvider.sql
:r $(path_main)\cps_imm.rpt_email_duplicate_in_srx.sql
:r $(path_main)\cps_imm.rpt_Immunization_PositiveInventory.sql
:r $(path_main)\cps_imm.rpt_Immunization_testPatient_Srx.sql
:r $(path_main)\cps_imm.rpt_Immunization_ZeroInventory.sql

:r $(path_main)\cps_imm.rpt_Immnization_CpsSrxQA.sql
print('Message: 17 cps_imm  created')
GO

/*CC > 1 + 2 + 2 + 4 + 5 + 1 + 7 = 22*/
:r $(path_main)\cps_cc.tmp_view_Protocol_PatientsList.sql

:r $(path_main)\cps_cc.ssis_er_followup.sql
:r $(path_main)\cps_cc.ssis_er_count.sql

:r $(path_main)\cps_cc.ssis_Protocol_Age_Sex.sql
:r $(path_main)\cps_cc.ssis_Protocol_Diabetes.sql

:r $(path_main)\cps_cc.ssis_covid_tracking.sql
:r $(path_main)\cps_cc.ssis_covid_supplyTracker.sql
:r $(path_main)\cps_cc.ssis_Covid_Vaccine_Supplier.sql
:r $(path_main)\cps_cc.ssis_covid_wellness_form.sql

:r $(path_main)\cps_cc.ssis_CCCKD.sql
:r $(path_main)\cps_cc.ssis_CCDiabetes.sql
:r $(path_main)\cps_cc.ssis_cchabbits.sql
:r $(path_main)\cps_cc.ssis_ccHTN.sql
:r $(path_main)\cps_cc.ssis_ccSMG.sql

:r $(path_main)\cps_cc.rpt_view_er_followup.sql

:r $(path_main)\cps_cc.rpt_CovidSupplyTracker.sql
:r $(path_main)\cps_cc.rpt_Covid_Tracking.sql
:r $(path_main)\cps_cc.rpt_covid_vaccine.sql
:r $(path_main)\cps_cc.rpt_erFollowup_Insurance_Monthly.sql
:r $(path_main)\cps_cc.rpt_erFollowup_Insurance_Quarterly.sql
:r $(path_main)\cps_cc.rpt_ER_Followup.sql
:r $(path_main)\cps_cc.rpt_protocols.sql
print('Message: 22 cps_cc Created')
GO

/*cps_hchp > 1 + 3 + 2 + 5 + 1 + 5 + 5 + 5 + 3 + 2 = 32*/
:r $(path_main)\cps_hchp.tmp_view_HCHPClients.sql

:r $(path_main)\cps_hchp.ssis_HCHP_Dashboard.sql
:r $(path_main)\cps_hchp.ssis_HCHP_LastClientStatus.sql
:r $(path_main)\cps_hchp.ssis_HCHP_Patient_Appointments.sql

:r $(path_main)\cps_hchp.ssis_CBCMMetricDueNow.sql
:r $(path_main)\cps_hchp.ssis_CBCM_AcuityScore.sql

:r $(path_main)\cps_hchp.rpt_view_hchpDemographics.sql
:r $(path_main)\cps_hchp.rpt_view_CBCMClients.sql
:r $(path_main)\cps_hchp.rpt_view_HFClients.sql
:r $(path_main)\cps_hchp.rpt_view_OutreachClients.sql
:r $(path_main)\cps_hchp.rpt_view_PSHClients.sql

:r $(path_main)\cps_hchp.ssis_CBCM_metric.sql
:r $(path_main)\cps_hchp.ssis_Care_Plan_Management.sql

:r $(path_main)\cps_hchp.rpt_CaseLoad_CBCM.sql
:r $(path_main)\cps_hchp.rpt_CaseLoad_HFCM.sql
:r $(path_main)\cps_hchp.rpt_CaseLoad_HFSpecialist.sql
:r $(path_main)\cps_hchp.rpt_CaseLoad_Outreach.sql
:r $(path_main)\cps_hchp.rpt_CaseLoad_PSH.sql

:r $(path_main)\cps_hchp.rpt_EncounterDetails_CBCM.sql
:r $(path_main)\cps_hchp.rpt_EncounterDetails_HFCM.sql
:r $(path_main)\cps_hchp.rpt_EncounterDetails_HFSpecialist.sql
:r $(path_main)\cps_hchp.rpt_EncounterDetails_Outreach.sql
:r $(path_main)\cps_hchp.rpt_EncounterDetails_PSH.sql

:r $(path_main)\cps_hchp.rpt_Timeliness_CBCM.sql
:r $(path_main)\cps_hchp.rpt_Timeliness_HFCM.sql
:r $(path_main)\cps_hchp.rpt_Timeliness_HFSpecialist.sql
:r $(path_main)\cps_hchp.rpt_Timeliness_Outreach.sql
:r $(path_main)\cps_hchp.rpt_Timeliness_PSH.sql

:r $(path_main)\cps_hchp.rpt_AcuityReport.sql
:r $(path_main)\cps_hchp.rpt_HCHPRoster.sql
:r $(path_main)\cps_hchp.rpt_CaseManagerList.sql
:r $(path_main)\cps_hchp.rpt_CBCMLastDates.sql

:r $(path_main)\cps_hchp.rpt_SPC_Match_PatientId.sql
:r $(path_main)\cps_hchp.rpt_SPC_Match_HCHPDashboard.sql
print('Message: 32 cps_hchp Created')
GO

/*opt > 2*/
:r $(path_main)\cps_opt.ssis_GlassPrescription.sql
:r $(path_main)\cps_opt.ssis_ContactPrescription.sql
print('Message: 2 cps_opt Created')

/*doh > 1 + 3 + 1 + 2 + 5 = 12*/
:r $(path_main)\cps_doh.tmp_view_FindCVRPatients.sql

:r $(path_main)\cps_doh.ssis_CVRClient.sql
:r $(path_main)\cps_doh.ssis_CVRCLientObs.sql
:r $(path_main)\cps_doh.ssis_CVRVisitClinicalList.sql

:r $(path_main)\cps_doh.view_CVR_Verify_Data.sql

:r $(path_main)\cps_doh.rpt_view_FindCVRPatients.sql
:r $(path_main)\cps_doh.rpt_view_CVR_VisitFile.sql

:r $(path_main)\cps_doh.rpt_cvr_accounting_summary.sql
:r $(path_main)\cps_doh.rpt_cvr_accouting.sql
:r $(path_main)\cps_doh.rpt_cvr_acct_revenue.sql
:r $(path_main)\cps_doh.rpt_CVR_ClientFile.sql
:r $(path_main)\cps_doh.rpt_CVR_VisitFile.sql
print('Message: 12 cps_doh Created')

/*cps-dentrix > 4 + 1 = 4*/
:r $(path_main)\cps_den.ssis_dentalPatientProfile.sql
:r $(path_main)\cps_den.ssis_Den_CPS_PatientMatching_Alogrithm.sql
:r $(path_main)\cps_den.ssis_SlidingFeeCyrca.sql

:r $(path_main)\cps_den.rpt_slidingfee_cyrca.sql
print('Message: 4 cps_den Created')

/*track > 3 + 3 + 7 + 3 = 16*/
:r $(path_main)\cps_track.ssis_breastDiagnosis.sql
:r $(path_main)\cps_track.ssis_papHPVTracking.sql
:r $(path_main)\cps_track.ssis_patientPortalSignup.sql

:r $(path_main)\cps_track.rpt_SummaryTracking.sql
:r $(path_main)\cps_track.rpt_MammoTracking.sql
:r $(path_main)\cps_track.rpt_PapHpvTracking.sql

:r $(path_main)\cps_track.Billing_ticket_questions.sql
:r $(path_main)\cps_track.Medicaid_Weekly_Breakdown.sql
:r $(path_main)\cps_track.Yearly_Productivity_By_Site.sql
:r $(path_main)\cps_track.Yearly_Productivity_Report.sql
:r $(path_main)\cps_track.Yearly_Telehealth_By_Month.sql
:r $(path_main)\cps_track.Yearly_Telehealth_By_Site.sql
:r $(path_main)\cps_track.Yearly_Telehealth_Details.sql

:r $(path_main)\cps_track.rpt_aapcho_enabling_service.sql
:r $(path_main)\cps_track.rpt_patient_with_er.sql
:r $(path_main)\cps_track.rpt_ProviderProductivityOverTheYears.sql
print('Message: 13 cps_track Created')

/*ohana > 1 + 6 + 3 + 1 + 3 + 7 = 21 */
:r $(path_main)\cps_insurance.ssis_NPIDetails.sql

:r $(path_main)\cps_insurance.tmp_view_OhanaEncounters.sql
:r $(path_main)\cps_insurance.tmp_view_OhanaMember.sql
:r $(path_main)\cps_insurance.tmp_view_Ohana_Immunization.sql
:r $(path_main)\cps_insurance.tmp_view_OhanaAppointments.sql
:r $(path_main)\cps_insurance.tmp_view_OhanaMedication.sql
:r $(path_main)\cps_insurance.tmp_view_OhanaProviders.sql

:r $(path_main)\cps_insurance.ssis_Ohana_Services.sql
:r $(path_main)\cps_insurance.ssis_OhanaCPT_ICD.sql
:r $(path_main)\cps_insurance.ssis_Ohana_Labs_Referrals.sql

:r $(path_main)\cps_insurance.rpt_view_OhanaFlatFile.sql

:r $(path_main)\cps_insurance.rpt_OhanaProviders_MissingDetails.sql
:r $(path_main)\cps_insurance.rpt_OhanaProviders.sql
:r $(path_main)\cps_insurance.rpt_Ohana_FlatFile.sql

:r $(path_main)\cps_insurance.rpt_appointment_summary_byInsurance.sql
:r $(path_main)\cps_insurance.rpt_ElectronicIinsuranceVerification.sql
:r $(path_main)\cps_insurance.rpt_Two_Year_Immunization.sql
:r $(path_main)\cps_insurance.rpt_UHC_CCD_DM.sql
:r $(path_main)\cps_insurance.rpt_VisitType_By_Insurance.sql
:r $(path_main)\cps_insurance.rpt_well_child_15_months.sql
:r $(path_main)\cps_insurance.rpt_well_child_30_months.sql
print('Message: 21 cps_insurance Created')

/*ssis job*/
:r $(path_main)\dbo.ssis_job_cps_all.sql
:r $(path_main)\dbo.ssis_job_cps_visit.sql
:r $(path_main)\dbo.ssis_job_cps_orders.sql
:r $(path_main)\dbo.ssis_job_cps_setup.sql
:r $(path_main)\dbo.ssis_job_cps_hl7.sql
:r $(path_main)\dbo.ssis_job_cps_obs.sql
:r $(path_main)\dbo.ssis_job_cps_bh.sql
:r $(path_main)\dbo.ssis_job_cps_meds_diag.sql
:r $(path_main)\dbo.ssis_job_cps_imm.sql
:r $(path_main)\dbo.ssis_job_cps_cc.sql
:r $(path_main)\dbo.ssis_job_cps_hchp.sql
:r $(path_main)\dbo.ssis_job_cps_opt.sql
:r $(path_main)\dbo.ssis_job_cps_doh.sql
:r $(path_main)\dbo.ssis_job_cps_den.sql
:r $(path_main)\dbo.ssis_job_cps_track.sql
:r $(path_main)\dbo.ssis_job_cps_insurance.sql
print('Message: 16 jobs created')


/*run ssis*/
go
exec cpswarehouse.dbo.ssis_job_cps_all
print('Message: cps_all ssis complete')
go
exec cpswarehouse.dbo.ssis_job_cps_visit
print('Message: cps_visit ssis complete')
go
exec cpswarehouse.dbo.ssis_job_cps_orders
print('Message: cps_orders ssis complete')
go
exec cpswarehouse.dbo.ssis_job_cps_setup
print('Message: cps_setup ssis complete')
go
exec cpswarehouse.dbo.ssis_job_cps_hl7
print('Message: cps_hl7 ssis complete')
go
exec cpswarehouse.dbo.ssis_job_cps_obs
print('Message: cps_obs ssis complete')
go
exec cpswarehouse.dbo.ssis_job_cps_bh
print('Message: cps_bh ssis complete')
go
exec cpswarehouse.dbo.ssis_job_cps_meds_diag
print('Message: meds & diagnosis complete')
go
exec cpswarehouse.dbo.ssis_job_cps_imm
print('Message: immunization complete')
go
exec cpswarehouse.dbo.ssis_job_cps_cc
print('Message: care coord complete')
go
exec cpswarehouse.dbo.ssis_job_cps_hchp
print('Message: hchp complete')
go
exec cpswarehouse.dbo.ssis_job_cps_opt
print('Message: opt complete')
go
exec cpswarehouse.dbo.ssis_job_cps_doh
print('Message: doh complete')
go
exec cpswarehouse.dbo.ssis_job_cps_den
print('den complete')
go
exec cpswarehouse.dbo.ssis_job_cps_track
print('track complete')
go
exec cpswarehouse.dbo.ssis_job_cps_insurance
print('insurance complete')
go


/*incomplete script > might be useful
zz.carf-bh-referral-appt-scheduled.sql
zz.cdc-yearly-data.sql
zz.cdc-yearly-report-outside-org-script.sql
zz.cycle-time.sql
zz.meds-ordered.sql
zz.nachc-average-appointments-per-specialty-per-week.sql
zz.pharmacy-audit-internal-meds.sql
zz.useful-diagnosis-tables.sql
zz.well-app-success.sql
zz.UDS-HIV.sql
zz.vaccine-by-race-age-insurance.sql
*/




print('Message: script end')
go