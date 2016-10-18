drop database IF EXISTS jpcustomers;
create database jpcustomers owner jpcustomers encoding 'UTF8';

drop database IF EXISTS apaccustomers;
create database apaccustomers owner apaccustomers encoding 'UTF8';

\connect jpcustomers

drop table IF EXISTS customer;

CREATE TABLE customer (
  CustomerID varchar(12) NOT NULL,
  FIRSTNAME varchar(25) NOT NULL,
  LASTNAME varchar(25) NOT NULL,
  Address1 varchar(50) NOT NULL,
  Address2 varchar(50) DEFAULT NULL,
  CITY varchar(25) DEFAULT NULL,
  Province varchar(25) DEFAULT NULL,
  PostalCode varchar(15) NOT NULL,
  Phone varchar(30) DEFAULT NULL,
  PRIMARY KEY (CustomerID)
);

INSERT INTO customer VALUES 
('CST01001','太郎','山田','東京都渋谷区恵比寿4丁目1番18号','恵比寿ネオナート8階',NULL,NULL,'150-0013','0357988500'),
('CST01002','二朗','山本','渋谷区恵比寿4丁目1番18号','恵比寿ネオナート5階',NULL,'東京都','150-0013','0357988501'),
('CST01003','三郎','北島','恵比寿4丁目1番18号','恵比寿ネオナート5階','渋谷区','東京都','150-0013','0357988502');

\connect apaccustomers

drop table IF EXISTS customers;

CREATE TABLE customers (
  custid varchar(12) NOT NULL,
  f_name varchar(25) NOT NULL,
  l_name varchar(25) NOT NULL,
  m_name varchar(15),
  streetaddress varchar(50) NOT NULL,
  streetaddress2 varchar(50) DEFAULT NULL,
  CITY varchar(25) DEFAULT NULL,
  stateprovince varchar(25) DEFAULT NULL,
  PostalCode varchar(15),
  country varchar(10) NOT NULL,
  Phonenumber varchar(30) DEFAULT NULL,
  PRIMARY KEY (custid)
);

insert into customers values
('CST02010','Cladius','Earl','Chance','14 Central Ave',NULL,'Brisbane','Queensland','2150','AU','(61)0011-555-8181'),
('CST02011','Ken','Chan',NULL,'1017 Kwai Fong',NULL,'Hong Kong',NULL,NULL,'PRC','(852)555-1870'),
('CST02012','Athene','Chambers','Elswyth','1212 Berkeley Gardens','Apt 215','Milton','NSW','2100','AU','(61)0011-555-1720'),
('CST02013','John','Albee','Fredrick','99 George Street',NULL,'Parramatta','NSW','2124','AU','(61)0011-555-6709'),
('CST02014','Lifeng','Chen',NULL,'7/F Fortune Plaza','No. 7','Beijing','Zhonglu','100020','China','(86)10-555-5402'),
('CST02015','Sanjeev','Chauhan',NULL,'54 Swami Vivekanand Rd','Apartment 2','Mumbai','Maharashtra','400 302','India','(91)22-555-9120'),
('CST02016','Nanda','Chaudhari',NULL,'27 Marve Rd',NULL,'Mumbai','Maharashtra','400 120','India','(91)555-6225 '),
('CST02017','Kaustubh','Chawla',NULL,'58 Marigold Ave',NULL,'Pune',NULL,'411 014','India','(91)555-2367'),
('CST02018','Simon','Chen','Keat','No. 5 Hengyang Road',NULL,'Taipei City',NULL,'100','Taiwan','(886)45.23.68.89'),
('CST02019','Hong','Choong',NULL,'112 Robinson Road',NULL,'Singapore',NULL,'12210','Singapore','(65)0300-076548'),
('CST02020','Xizhen','Lim',NULL,'1101 Nanking Street',NULL,'Beijing','Zhonglu','100020','China','(86)10-555-5402'),
('CST02021','Lawrence','Du',NULL,'1217 Queen Street',NULL,'Milton','NSW','2100','AU','(61)0011-563-4318');

\q
