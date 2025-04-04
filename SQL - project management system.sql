-- LOAN MANAGEMENT SYSTEM:

create database project_management;
USE PROJECT_MANAGEMENT;
set autocommit = off;
start transaction;
-- sheet 1:
-- Table CUSTOMER_INCOME has been imported.
-- customer criteria and create it as new table based on applicant income:
select * from customer_income;
drop table customer_income;
create table customer_criteria select *,
case
when applicant_income>15000 then 'Grade A'
when applicant_income>9000 then 'Grade B'
when applicant_income>5000 then 'Middle class customer'
else 'Low class'
 end as cus_criteria
 from customer_income;
commit;

select * from customer_criteria;

-- monthly interest percentage:
savepoint s1;
create table customer_criteria_percentange select *, 
case 
when (applicant_income<5000 and property_area = 'Rural') then 3
when (applicant_income<5000 and property_area = 'SemiRural') then 3.5
when (applicant_income<5000 and property_area = 'Urban') then 5
when (applicant_income<5000 and property_area = 'SemiUrban') then 2.5
else 7
end as monthly_interest_percentage from customer_criteria;
select * from customer_criteria_percentange; -- TABLE 1 customer_criteria_percentange;
drop table customer_criteria_percentange;
rollback to s1;


-- sheet 2:
-- loan status:
savepoint s2;
select * from loan_status_temporary_table;
desc loan_status_temporary_table;
rollback to s2;

-- primary_table:
create table Loan_status(
Loan_id varchar(20),
Customer_id varchar(50),
Loan_amount varchar(50),
Loan_amount_term int,
Cibil_score int);


-- secondary table:
create table Remarks_update_details(
Loan_id varchar(20),
Loan_amount varchar(50),
Cibil_score int,
cibil_score_status varchar(50));
desc Remarks_update_details;
select * from Remarks_update_details;

-- Row level trigger:
savepoint s3;
delimiter //
create trigger loan_status_updation before insert on Loan_status for each row
begin
if new.loan_amount is null then set new.loan_amount = 'Loan still processing';
end if;
end //
delimiter ;

-- statement level trigger:
 delimiter //
create trigger remark_update after insert on loan_status for each row
begin
insert into Remarks_update_details(loan_id, loan_amount, cibil_score)
values(new.loan_id, new.loan_amount, new.cibil_score);
begin
if new.cibil_score>900 then update Remarks_update_details set cibil_score_status=('High cibil score') where loan_id = new.loan_id;
elseif new.cibil_score>750 then update Remarks_update_details set cibil_score_status = ('No penalty') where loan_id = new.loan_id;
elseif new.cibil_score>0 then  update Remarks_update_details set cibil_score_status = ('Penalty customers') where loan_id = new.loan_id;
elseif new.cibil_score<=0 then update Remarks_update_details set cibil_score_status = ('Rejected customers') where loan_id = new.loan_id;
end if;
end;
end //
delimiter ;
rollback to s3;
/*delimiter //
create trigger remark_update after insert on loan_status for each row
begin
if new.cibil_score>900 then insert into Remarks_update_details(loan_id, loan_amount, cibil_score, cibil_score_status) 
values(new.loan_id, new.loan_amount, new.cibil_score, 'High cibil score');
elseif new.cibil_score>750 then insert into  Remarks_update_details(loan_id, loan_amount, cibil_score, cibil_score_status)
values(new.loan_id, new.loan_amount, new.cibil_score, 'No penalty');
elseif new.cibil_score>0 then insert into Remarks_update_details(loan_id, loan_amount, cibil_score, cibil_score_status) 
values(new.loan_id, new.loan_amount, new.cibil_score, 'Penalty customers');
else insert into Remarks_update_details(loan_id, loan_amount, cibil_score, cibil_score_status) 
values(new.loan_id, new.loan_amount, new.cibil_score, 'Rejected customers');
end if;
end //
delimiter ;*/

savepoint s5;
insert into loan_status  select * from loan_status_temporary_table;

select * from  remarks_update_details;
select * from loan_status;
select distinct cibil_score_status from remarks_update_details;

delete from remarks_update_details where loan_amount = 'loan still processing' or cibil_score_status = 'Rejected customers';

alter table remarks_update_details modify loan_amount int;
create table Loan_cibil_score_status select * from remarks_update_details; 
rollback to s5;
commit;
select * from Loan_cibil_score_status;
-- sheet 1:
-- New field creation based on interest:
savepoint s6;
select * from Loan_cibil_score_status;
select * from customer_criteria_percentange;
create table customer_int select l.loan_amount, l.cibil_score, l.cibil_score_status, c.*
from Loan_cibil_score_status l inner join customer_criteria_percentange c on l.loan_id = c.loan_id;
drop table customer_int;
select * from customer_interest_analysis;


-- monthly interest:
/*
mi = loan_amount* (monthly_interest_percentage/100)
ai = mi*12
*/
create table customer_interest_analysis select *, round((loan_amount*(monthly_interest_percentage)/100),2) mon_int_amount,
(round((loan_amount*(monthly_interest_percentage)/100),2)*12)annual_int_amount from customer_int;
select * from customer_interest_analysis; -- TABLE 2 CUSTOMER_INTEREST_ANALYSIS
DROP TABLE CUSTOMER_INTerest_analysis;
rollback to s6;
commit;

-- sheet 3
-- import customer_det table
savepoint s7;
select * from customer_det;
drop table customer_det;

update customer_det
set gender=case
when customer_id = 'IP43006' then 'Female'
when customer_id = 'IP43016' then 'Female'
when customer_id = 'IP43018' then 'Male'
when customer_id = 'IP43038' then 'Male'
when customer_id = 'IP43508' then 'Female'
when customer_id = 'IP43577' then 'Female'
when customer_id = 'IP43589' then 'Female'
when customer_id = 'IP43593' then 'Female'
else gender
end;


update customer_det
set age = case
when customer_id = 'IP43007' then 45
when customer_id = 'IP43009' then 32
else age
end;
rollback to s7;

-- sheet 4 and sheet 5:
savepoint s8;
select * from customer_criteria_percentange;
SELECT * FROM CUSTOMER_INTEREST_ANALYSIS;
select * from customer_det;
select * from country_state;
select * from region_info;

-- add percentage to interest:
alter table customer_criteria_percentange modify monthly_interest_percentage varchar(20);
update customer_criteria_percentange set monthly_interest_percentage = concat(monthly_interest_percentage, '%');

alter table CUSTOMER_INTEREST_ANALYSIS modify monthly_interest_percentage varchar(20);
update CUSTOMER_INTEREST_ANALYSIS set monthly_interest_percentage = concat(monthly_interest_percentage, '%');
select * from CUSTOMER_INTEREST_ANALYSIS;
rollback to s8;

-- join 5 tables without repeating columns:
savepoint s9;
commit;
select ccp.*,
 cca.loan_amount,cca.cibil_score, cca.cibil_score_status, cca.mon_int_amount, cca.annual_int_amount,
cd.customer_name, cd.gender, cd.age, cd.married, cd.education, cd.self_employed, cd.region_id,
cs.postal_code, cs.segment, cs.state,
ri.region 
from customer_criteria_percentange ccp 
inner join CUSTOMER_INTEREST_ANALYSIS cca on ccp.loan_id = cca.loan_id
inner join customer_det cd on cca.loan_id = cd.loan_id
inner join country_state cs on cd.customer_id = cs.customer_id
inner join region_info ri on cs.region_id = ri.region_id; -- output 1

select ri.region, cs.*, cd.gender, cd.age, cd.married, cd.education, cd.self_employed from region_info ri 
left join country_state cs on ri.region_id = cs.region_id
left join customer_det cd on cs.region_id = cd.region_id having region_id is null; -- output 2

-- Filter high cibil score:
select ccp.*,
 cca.loan_amount,cca.cibil_score, cca.cibil_score_status, cca.mon_int_amount, cca.annual_int_amount,
cd.customer_name, cd.gender, cd.age, cd.married, cd.education, cd.self_employed, cd.region_id,
cs.postal_code, cs.segment, cs.state,
ri.region 
from customer_criteria_percentange ccp 
inner join CUSTOMER_INTEREST_ANALYSIS cca on ccp.loan_id = cca.loan_id
inner join customer_det cd on cca.loan_id = cd.loan_id
inner join country_state cs on cd.customer_id = cs.customer_id
inner join region_info ri on cs.region_id = ri.region_id where cibil_score_status = 'High cibil score'; -- output 3

-- Filter home office and corporate:
select ccp.*,
 cca.loan_amount,cca.cibil_score, cca.cibil_score_status, cca.mon_int_amount, cca.annual_int_amount,
cd.customer_name, cd.gender, cd.age, cd.married, cd.education, cd.self_employed, cd.region_id,
cs.postal_code, cs.segment, cs.state,
ri.region 
from customer_criteria_percentange ccp 
inner join CUSTOMER_INTEREST_ANALYSIS cca on ccp.loan_id = cca.loan_id
inner join customer_det cd on cca.loan_id = cd.loan_id
inner join country_state cs on cd.customer_id = cs.customer_id
inner join region_info ri on cs.region_id = ri.region_id where segment in('home office', 'corporate'); -- output 4
rollback to s9;

-- store output as procedure:
savepoint s10;
delimiter //
create procedure output1()
begin
select ccp.*,
 cca.loan_amount,cca.cibil_score, cca.cibil_score_status, cca.mon_int_amount, cca.annual_int_amount,
cd.customer_name, cd.gender, cd.age, cd.married, cd.education, cd.self_employed, cd.region_id,
cs.postal_code, cs.segment, cs.state,
ri.region 
from customer_criteria_percentange ccp 
inner join CUSTOMER_INTEREST_ANALYSIS cca on ccp.loan_id = cca.loan_id
inner join customer_det cd on cca.loan_id = cd.loan_id
inner join country_state cs on cd.customer_id = cs.customer_id
inner join region_info ri on cs.region_id = ri.region_id;
end //
delimiter ;

call output1();


delimiter //
create procedure output2()
begin
select ri.region, cs.*, cd.gender, cd.age, cd.married, cd.education, cd.self_employed from region_info ri 
left join country_state cs on ri.region_id = cs.region_id
left join customer_det cd on cs.region_id = cd.region_id having region_id is null;
end //
delimiter ;

call output2();

delimiter //
create procedure output3()
begin
select ccp.*,
 cca.loan_amount,cca.cibil_score, cca.cibil_score_status, cca.mon_int_amount, cca.annual_int_amount,
cd.customer_name, cd.gender, cd.age, cd.married, cd.education, cd.self_employed, cd.region_id,
cs.postal_code, cs.segment, cs.state,
ri.region 
from customer_criteria_percentange ccp 
inner join CUSTOMER_INTEREST_ANALYSIS cca on ccp.loan_id = cca.loan_id
inner join customer_det cd on cca.loan_id = cd.loan_id
inner join country_state cs on cd.customer_id = cs.customer_id
inner join region_info ri on cs.region_id = ri.region_id where cibil_score_status = 'High cibil score';
end //
delimiter ;

call output3();

delimiter //
create procedure output4()
begin
select ccp.*,
 cca.loan_amount,cca.cibil_score, cca.cibil_score_status, cca.mon_int_amount, cca.annual_int_amount,
cd.customer_name, cd.gender, cd.age, cd.married, cd.education, cd.self_employed, cd.region_id,
cs.postal_code, cs.segment, cs.state,
ri.region 
from customer_criteria_percentange ccp 
inner join CUSTOMER_INTEREST_ANALYSIS cca on ccp.loan_id = cca.loan_id
inner join customer_det cd on cca.loan_id = cd.loan_id
inner join country_state cs on cd.customer_id = cs.customer_id
inner join region_info ri on cs.region_id = ri.region_id where segment in('home office', 'corporate');
end //
delimiter ;

call output4();
rollback to s10;
commit;


alter table CUSTOMER_INTEREST_ANALYSIS modify loan_id varchar(50);
alter table CUSTOMER_INTEREST_ANALYSIS add primary key(loan_id);
alter table region_info add primary key(region_id);
alter table customer_det modify customer_id varchar(50);
alter table customer_det add primary key(customer_id);
alter table customer_det modify loan_id varchar(50);
alter table country_state modify loan_id varchar(50);
alter table country_state modify customer_id varchar(50);
alter table country_state add primary key(customer_id);



-- Foreign key:
alter table customer_interest_analysis add constraint interest_foreign foreign key(customer_id) references customer_det(customer_id);
alter table customer_det add constraint region_foreign foreign key(region_id) references region_info(region_id);
alter table country_state add constraint country_foreign foreign key(region_id) references region_info(region_id);

