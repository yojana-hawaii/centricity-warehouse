

USE CpsWarehouse
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
drop proc if exists cps_setup.rpt_User_Favorite_Form;

go

create proc cps_setup.rpt_User_Favorite_Form
as 
begin

select Title FormOrTextCompName, f.FormID, t.TextComponentID, f.InactiveForms, u.Type, df.PVID, 
	df.ListName
from cpssql.CentricityPS.dbo.USRFAVCOMPS u
	left join cps_setup.Form_Components f on u.comp_id = case when u.type = 'MLI_FORM' then f.FormID end
	left join cps_setup.Text_Components t on u.comp_id = case when u.type = 'MLI_TEXT' then t.TextComponentID end
	left join cps_all.DoctorFacility df on df.PVID = u.usrid
--group by ListName
end

go