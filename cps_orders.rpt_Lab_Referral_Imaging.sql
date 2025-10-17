
go

USE [CpsWarehouse]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_orders].[rpt_Lab_Referral_Imaging] 

go
CREATE procedure [cps_orders].[rpt_Lab_Referral_Imaging] 
(
	@year int = 2021
)
as begin

--declare @year int = 2021

select o.*
from cps_orders.rpt_view_Lab_Referral_Imaging o
where Year = @year

end

go

