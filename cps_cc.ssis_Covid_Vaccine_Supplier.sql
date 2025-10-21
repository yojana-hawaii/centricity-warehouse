use CpsWarehouse
go

drop table if exists cps_cc.Covid_Vaccine_Supplier;
go
create table cps_cc.Covid_Vaccine_Supplier
(
	ID int identity(1,1) not null,
	[Delivery_Date] varchar(10) not null,
	[Number_Of_Vials] int not null,
	[Total_Doses] int not null,
	[LotNumber] varchar(50) not null,
	[Expiration_Date] varchar(10) not null,
	[Comments] varchar(200) null,
	[Supplier] varchar(50) not null,
	constraint covid_lot_number primary key ([LotNumber], [Expiration_Date])
);

go


drop proc if exists cps_cc.ssis_Covid_Vaccine_Supplier;
go

create proc cps_cc.ssis_Covid_Vaccine_Supplier
as
begin

truncate table cps_cc.Covid_Vaccine_Supplier

/* manual load  */
insert into cps_cc.Covid_Vaccine_Supplier 
(Delivery_Date, Number_Of_Vials, Total_Doses, LotNumber, Expiration_Date, Comments, Supplier)
values
('2021-03-08', 10, 100, '001B21A', '2021-09-06', 'Delivered by FedEx', 'state'),
('2021-02-22', 40, 400, '002A21A', '2021-08-11', 'Delivered by FedEx', 'state'),
('2021-03-16', 20, 200, '003B21A', '2021-09-09', 'Delivered by FedEx', 'state'),
('2021-01-11', 30, 300, '011J20A', '2021-05-11', 'Picked up from DOH by facilities', 'state'),
('2021-02-01', 30, 300, '012M20A', '2021-07-20', 'Delivered by FedEx', 'state'),
('2021-03-22', 10, 100, '016B21A', '2021-09-13', 'Delivered by FedEx', 'state'),
('2021-03-23', 20, 200, '019B21A', '2021-09-21', 'Delivered by FedEx', 'state'),
('2021-03-29', 10, 100, '026B21A', '2021-09-17', 'Delivered by FedEx', 'state'),
('2021-03-01', 10, 100, '027A21A', '2021-08-22', 'Delivered by FedEx', 'state'),
('2021-03-30', 10, 100, '027B21A', '2021-09-18', 'Delivered by FedEx', 'state'),
('2021-03-09', 10, 100, '031A21A', '2021-08-28', 'Delivered by FedEx', 'state'),
('2021-03-30', 10, 100, '031B21A', '2021-09-22', 'FEDS Supply; Delivered by UPS', 'fed'),
('2021-02-09', 10, 100, '031L20A', '2021-07-22', 'Delivered by FedEx', 'state'),
('2021-02-08', 10, 100, '031M20A', '2021-08-05', 'Delivered by FedEx', 'state'),
('2021-03-02', 10, 100, '036A21A', '2021-08-26', 'Delivered by FedEx', 'state'),
('2021-04-05', 10, 100, '037B21A', '2021-10-01', 'FEDS Supply; Delivered by UPS', 'fed'),
('2021-04-05', 10, 100, '038B21A', '2021-09-25', 'Delivered by FedEx', 'state'),
('2021-04-06', 20, 200, '041B21A', '2021-10-04', 'Delivered by FedEx', 'state'),
('2021-04-13', 20, 200, '043B21A', '2021-10-03', 'FEDS Supply; Delivered by UPS', 'fed'),
('2021-03-15', 10, 100, '045A21A', '2021-08-29', 'Delivered by FedEx', 'state'),
('2021-04-23', 20, 200, '004C21A', '2021-10-19', 'FEDS Supply; Delivered by UPS', 'fed'),
('2021-05-03', 60, 600, '027C21A', '2021-10-26', 'FEDS Supply; Delivered by UPS', 'fed'),

('2021-05-11', 60, 600, '041C21A', '2021-11-01', 'FEDS Supply; Delivered by UPS', 'fed'),

('2021-05-24', 20, 200, '047c21a', '2021-11-07', 'FEDS Supply; Delivered by UPS', 'fed'),
('2021-05-28', 20, 200, '053c21a', '2021-11-09', 'FEDS Supply; Delivered by UPS', 'fed'),
('2021-06-21', 20, 200, '048C21A', '2021-11-09', 'FEDS Supply; Delivered by UPS', 'fed'),
(convert(date,'07/16/21'),	10,	100,	'006D21A',	convert(date,'11/21/21'),	'FEDS Supply; Delivered by UPS; supplies received', 'fed'),
(convert(date,'07/26/21'),	20,	200,	'045C21A',	convert(date,'11/04/21'),	'FEDS Supply; Delivered by UPS; supplies received', 'fed'),
(convert(date,'07/30/21'),	20,	280,	'003F21A',	convert(date,'01/15/22'),	'FEDS Supply; Delivered by UPS; supplies received', 'fed'),
('2021-8-15',10,100, 'FC3181', '2021-10-31', 'fed','fed'),
('2021-8-15',10,100, '053E21A', '2022-02-15', 'fed','fed'),
(convert(date,'08/23/21'),	10,	140,	'939906',	convert(date, '01/28/22'),	'FEDS Supply; Delivered by UPS; supplies received', 'fed'),
(convert(date,'08/27/21'),	20,	280,	'014F21A',	convert(date, '01/23/22'),	'FEDS Supply; Delivered by UPS; supplies received', 'fed'),
--(convert(date,'09/14/21'),	10,	100,	'047C21A',	convert(date,'11/07/21'),	'FEDS Supply; Delivered by UPS; supplies received', 'fed'),
(convert(date,'09/17/21'),	10,	140,	'019F21A',	convert(date,'01/20/22'),	'FEDS Supply; Delivered by UPS; supplies received', 'fed'),
(convert(date,'09/14/21'),	195,	1170,	'FF8839',	convert(date,'12/31/21'),	'FEDS Supply; Delivered by FedEx; supplies received', 'fed'),
(convert(date,'09/22/21'),	10,	100,	'076C21A',	convert(date,'11/13/21'),	'FEDS Supply; Delivered by UPS; supplies received', 'fed'),
('2021-09-27', 10, 140, '011F21A', '2022-01-19', 'Fed', 'fed'),
('2021-11-03', 20, 200, 'FK5127', '2022-01-10', '', 'redeived from kaiser'),
('2021-11-03', 10, 140, '034F21A', '2022-01-29', 'Fed', 'fed'),
('2021-11-09', 30, 420, '013F21A', '2022-01-22', 'fed', 'fed'),
('2021-11-17', 195, 1170, 'FJ1620', '2022-02-28', 'fed', 'fed'),
('2021-11-17', 10, 100, 'FK5618', '2022-02-28', 'fed', 'fed'),
('2021-11-29', 20, 200, '045J21A', '2022-05-02', 'fed', 'fed'),
('2021-12-23', 0, 0, 'FL0007', '2022-03-30', 'fed', 'fed'),
('2021-12-09', 0, 0, '046L21A', '2022-07-22', 'fed', 'fed'),
('2021-12-09', 0, 0, 'FK9894', '2022-06-30', 'fed', 'fed'),
('2022-05-05', 0, 0, '057M21A', '2022-07-09', 'fed', 'fed'),
('2022-05-05', 0, 0, '049L21A', '2022-08-13', 'fed', 'fed'),
('2022-05-10', 0, 0, 'FN2908', '2022-08-13', 'fed', 'fed'),
('2022-05-10', 0, 0, 'FL8095', '2022-08-13', 'fed', 'fed'),
('2022-06-20', 20, 200, 'FL2757', '2022-09-30', 'fed', 'fed'),
('2022-06-21', 10,100,'FT9142', '2022-12-31','fed','fed'),
('2022-07-11',20,200, '013B22A', '2022-11-22','fed','fed'),
('2022-07-25',20,200, '011B22A', '2022-11-18','fed','fed'),
('2022-07-26',50,300, 'FP7138', '2022-11-30','fed','fed'),
('2022-08-15',20,200, '083B22A', '2022-11-28','fed','fed'),
('2022-08-16',50,300, 'FP7140', '2022-11-30','fed','fed'),
('2022-09-10',0,0, 'AS7148B', '2022-11-30','fed','fed'),
('2022-09-10',0,0, 'GH9694', '2022-11-30','fed','fed'),
('2022-09-10',0,0, 'FT1551', '2022-11-30','fed','fed'),
('2022-09-10',0,0, '063B22A', '2022-11-30','fed','fed'),
('2022-09-10',0,0, 'GH9693', '2022-11-30','fed','fed'),
('2022-09-10',0,0, '057f22a', '2022-11-30','fed','fed'),
('2022-09-10',0,0, 'gh9702', '2022-11-30','fed','fed'),
('2022-09-10',0,0, '021h22a', '2022-11-30','fed','fed'),
('2022-09-10',0,0, 'gl0446', '2022-11-30','fed','fed'),
('2022-09-10',0,0, 'gk1657', '2022-11-30','fed','fed'),
('2022-09-10',0,0, '015h22a', '2022-11-30','fed','fed'),
('2022-09-10',0,0, 'gd1857', '2022-11-30','fed','fed'),
('2022-09-10',0,0, 'GK1337', '2022-12-30','fed','fed'),
('2022-09-10',0,0, 'GK1657', '2022-12-30','fed','fed'),
('2022-09-10',0,0, 'FR2583', '2022-12-30','fed','fed'),
('2022-09-10',0,0, '020H22A', '2022-12-30','fed','fed'),
('2022-09-10',0,0, 'AS7168B', '2022-12-30','fed','fed'),
('2022-09-10',0,0, 'GK1667', '2022-12-30','fed','fed'),
('2022-09-10',0,0, 'FY3680', '2022-12-30','fed','fed'),
('2022-09-10',0,0, '022H22A', '2023-06-01','fed','fed'),
('2023-01-27',0,0, '074B22A', '2023-06-01','fed','fed'),
('2023-01-27',0,0, 'GP4345', '2023-06-01','fed','fed'),
('2023-01-27',0,0, 'GK0876', '2023-06-01','fed','fed'),
('2023-01-27',0,0, 'FW1333', '2023-06-01','fed','fed'),
('2023-01-27',0,0, '066H22A', '2023-06-01','fed','fed'),
('2023-01-27',0,0, '067H22A', '2023-06-01','fed','fed'),
('2023-01-27',0,0, 'GW8170', '2023-06-01','fed','fed'),
('2023-01-27',0,0, 'GL0087', '2023-06-01','fed','fed'),
('2023-01-27',0,0, '023H22A', '2023-06-01','fed','fed'),
('2023-01-27',0,0, 'GY5686', '2023-06-01','fed','fed'),
('2023-01-27',0,0, 'AS7645B', '2023-06-01','fed','fed'),

('2023-01-27',0,0, 'GY5673', '2023-06-01','fed','fed'),
('2023-01-27',0,0, 'AS7646C', '2023-06-01','fed','fed')



end



go
