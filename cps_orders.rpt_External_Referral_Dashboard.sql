
USE CpsWarehouse
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_orders].[rpt_External_Referral_Dashboard];
go

create procedure [cps_orders].[rpt_External_Referral_Dashboard] 
(
	@StartDate date,
	@EndDate date,
	@FilterDate nvarchar(10),
	@Facility nvarchar(10) = null,
	@RefSpecialist nvarchar(20) = null,
	@FollowupSpecialist nvarchar(20) = null,
	@SummaryOfCare Nvarchar(25) = null,
	@Retro nvarchar(25) = null,
	@Stat nvarchar(25) = null,
	@CurrentStatus nvarchar(10) = null,
	@Insurance nvarchar(30) = null
)
as 
begin

	


select 
	@CurrentStatus = case when @CurrentStatus = 'All' then null else @CurrentStatus end,
	@refSpecialist = case when @refSpecialist = 'All' then null  else @refSpecialist end,
	@FollowupSpecialist = case when @FollowupSpecialist = 'All' then null  else @FollowupSpecialist end,
	@Stat = case when @Stat = 'All' then null  else @Stat end,
	@Retro = case when @Retro = 'All' then null  else @Retro end,
	@SummaryOfCare = case when @SummaryOfCare = 'All' then null  else @SummaryOfCare end,
	@Facility = case when @Facility = 'All' then null  else @Facility end,
	@Insurance = case when @Insurance = 'All' then null else @Insurance end


 
select r.*
from cps_orders.rpt_view_ExternalReferral r --where CurrentStatus  in ('h')

where 
	(
		(r.OrderDate >= @startDate and r.OrderDate <= @endDate and @FilterDate = 'Order')
		or
		(r.ReferralDate >= @startDate and r.ReferralDate <= @endDate and @FilterDate = 'Referral')
		or
		(r.FollowupDate >= @startDate and r.FollowupDate <= @endDate and @FilterDate = 'FollowUp')
	)
	and r.facilityID = isnull(@facility, r.facilityID)
	and r.CurrentStatus = isnull(@CurrentStatus, r.CurrentStatus)
	and r.ReferralSpecialistID = isnull(@refSpecialist, r.ReferralSpecialistID)
	and r.followupSpecialistID = isnull(@FollowupSpecialist, r.followupSpecialistID)
	and r.ReferralStat = isnull(@Stat, r.ReferralStat)
	and r.ReferralRetro = isnull(@Retro, r.ReferralRetro)
	and r.ReferralSummaryOfCare = isnull(@SummaryOfCare, r.ReferralSummaryOfCare)
	and isnull(r.Classify_Major_Insurance,'') = isnull(@Insurance, isnull(r.Classify_Major_Insurance,'') )

end 
go
