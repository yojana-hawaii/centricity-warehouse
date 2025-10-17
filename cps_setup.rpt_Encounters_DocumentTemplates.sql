
USE [CpsWarehouse]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
drop proc if exists cps_setup.rpt_Encounters_DocumentTemplates;

go

create procedure cps_setup.rpt_Encounters_DocumentTemplates
	(
		@EncounterID nvarchar(20) = null,
		@DocumentTemplateID nvarchar(20) = null,
		@FormID nvarchar(20) = null
	)

	as begin


	--declare
	--	@EncounterID nvarchar(20) = 'All',
	--	@DocumentTemplateID nvarchar(20) = 'All',
	--	@FormID nvarchar(20) = '1834612446067820';
		
	select 
		@EncounterID = case when @EncounterID = 'All' then null else @EncounterID end,
		@DocumentTemplateID = case when @DocumentTemplateID = 'All' then null else @DocumentTemplateID end,
		@FormID = case when @FormID = 'All' then null else @FormID end;

	select * 
	from CpsWarehouse.cps_setup.Encounters_DocumentTemplates u
	where
		u.EncounterID = isnull(@EncounterID, u.EncounterID)
		and u.DocumentTemplateID = isnull(@DocumentTemplateID, u.DocumentTemplateID)
		and u.FormID = isnull(@FormID, u.FormID) 

	end

	go