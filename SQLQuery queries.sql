/*Add check constraint on person_type (student, staff, professor, or uhcs doctor)*/
ALTER table PERSON add constraint PersonType_Check check (personType IN ('st','pf','s','dr'));
 
/*Display person, student, professor, staff, and UHCS doctor details*/
SELECT * FROM PERSON;
SELECT * FROM STUDENT;
SELECT * FROM PROFESSOR;
SELECT * FROM STAFF;
SELECT * FROM UHCS_DOCTOR
 
/*No of the students opted for a particular course. -----> function*/
CREATE FUNCTION getStudentsCountOptedForCourse(
   @course_name VARCHAR(25)
)
RETURNS INT
AS
BEGIN
DECLARE @COUNT INT
   SELECT @COUNT = COUNT(R.NUID) FROM REGISTER R JOIN COURSE C ON R.courseID=C.courseID
   WHERE C.courseName=@course_name
 
   RETURN @COUNT
END;
 
SELECT dbo.getStudentsCountOptedForCourse('DMDD') as StudentsCount;
 
CREATE PROCEDURE getRegisterationDetails AS
BEGIN
SELECT CONCAT(P1.firstName, ' ',P1.lastName) AS STUDENT,
CONCAT(P2.firstName,' ',P2.lastName) AS PROFESSOR, C.courseName
FROM REGISTER R JOIN PROFESSOR PF ON R.PNUID=PF.PNUID JOIN STUDENT S ON S.NUID=R.NUID
JOIN COURSE C ON R.courseID=C.courseID JOIN PERSON P1 ON P1.personID=S.personID JOIN PERSON P2
ON P2.personID=PF.personID
ORDER BY C.courseName
END;
 
EXEC getRegisterationDetails
 
/*A person visited the given building no. for a given date. */
CREATE PROCEDURE getBuildingNoAndTime @buildingID int , @visitTimeStamp date
AS
BEGIN
SELECT distinct p.personID, v.classRoomNumber, CONCAT(p.firstName,' ', p.lastName) AS FullName,
case when personType = 'pf' then 'Professor'
when personType = 'st' then 'Student' else 'Staff'
END AS PersonType
FROM visit v join person p on p.personID=v.personID join building b
on b.buildingID=v.buildingID where b.buildingID=@buildingID and CONVERT(VARCHAR(10), visitTimeStamp, 111)=@visitTimeStamp
END
 
EXEC getBuildingNoAndTime 2,'2021-07-16'


 /*Find person last week visiting history if find out to be covid positive. (Create a procedure and pass a number of days parameter)
A person visited the given building no. for a given time range and date. (if Positive)*/

 CREATE PROCEDURE dbo.getCovidCasesStatus @numberOfDays INT
AS
SELECT distinct p.personID, C.result, CONCAT(p.firstName,' ', p.lastName) AS FullName,
CONCAT(b.collegeName,' ',b.buildingName) AS BUILDING,
case when personType = 'pf' then 'Professor'
when personType = 'st' then 'Student' else 'Staff'
END AS PersonType
FROM PERSON p join COVID_RECORD C on p.personID= C.personID join VISIT V
on V.personID=p.personID JOIN BUILDING b ON b.buildingID = V.buildingID
where c.result = 'Positive'
AND CONVERT(VARCHAR(10), visitTimeStamp, 111) BETWEEN GETDATE() - @numberOfDays and  GETDATE();
GO
 
EXEC getCovidCasesStatus 120

/*People fully vaccinated (Visualization can be done)*/
select P.personID, CONCAT(P.firstName,' ', P.lastName) AS FullName,
V.vaccineName, V.dateOfVaccination,
case when P.personType = 'pf' then 'Professor'
when P.personType = 'st' then 'Student' else 'Staff'
END AS PersonType
from PERSON P
JOIN VACCINATION V ON P.personID=V.personID
WHERE numberOfVaccination=2;
 

 
/*People partially vaccinated(Only return records/Second dose date can be shown)*/
select P.personID, CONCAT(P.firstName,' ', P.lastName) AS FullName,
V.vaccineName, V.dateOfVaccination,
case when P.personType = 'pf' then 'Professor'
when P.personType = 'st' then 'Student' else 'Staff'
END AS PersonType
from PERSON P
JOIN VACCINATION V ON P.personID=V.personID
WHERE numberOfVaccination=1;
 
/*Person details vaccinated by given vaccine name(Graph can be shown, visualization)*/
CREATE PROCEDURE dbo.getVaccinationStatus @vaccine VARCHAR(30)
AS
SELECT distinct p.personID, CONCAT(p.firstName,' ', p.lastName) AS Full_Name,
case when personType = 'pf' then 'Professor'
when personType = 'st' then 'Student' else 'Staff'
END AS PersonType , v.vaccineName AS Vaccine_Name, v.numberOfVaccination AS Total_Vaccinations
FROM PERSON p join VACCINATION v on p.personID = v.personID
where v.vaccineName = @vaccine
GO
 
EXEC getVaccinationStatus 'Covishield'
 
/*Find max and min no. of people vaccinated by a vaccine(Graph/ I guess we are Considering count here)*/
 
select MAX(vaccineName)as MostUsedVaccine 
from VACCINATION
Group by vaccineName
Order by (vaccineName) DESC;
 
select MIN(vaccineName)as LeastUsedVaccine, Count(personID)as noOfPersonsVaccinated
from VACCINATION
Group by vaccineName
 
select (vaccineName) as mostUsedVaccine, Count(personID)as noOfPersonsVaccinated 
from VACCINATION
Group by vaccineName
Order by (vaccineName) DESC;
 
 
/*Get person details who had covid symptoms*/
 
SELECT  p.personID, CONCAT(p.firstName,' ', p.lastName) AS FullName, p.healthInsuranceID, ur.symptoms
FROM PERSON AS p
JOIN UHCS_RECORD AS ur ON p.personID= ur.personID
WHERE symptoms LIKE 'cold' OR symptoms LIKE 'cough' OR symptoms LIKE 'fever';
 
 
/*Get the no. of people who are positive or negative. 
Assumption - Same day report*/
SELECT distinct p.personID, CONCAT(p.firstName,' ', p.lastName) AS FullName,
case when personType = 'pf' then 'Professor'
when personType = 'st' then 'Student' else 'Staff'
END AS PersonType , C.result, C.typeOfTest, C.CovidTestTimestamp
FROM PERSON p join COVID_RECORD C on p.personID= C.personID
where C.result = 'Positive'
ORDER BY C.CovidTestTimestamp DESC, personID;
 
SELECT distinct COUNT(p.personID) AS Total_Positive_Cases
FROM PERSON p join COVID_RECORD C on p.personID= C.personID
where c.result = 'Positive'
 
/*Average temperature or oxygen level of the people who are positive.
Body Temp*/
CREATE FUNCTION getAverageBodyTemp()
RETURNS FLOAT
AS
BEGIN
  DECLARE @avgTemp FLOAT
  select @avgTemp = AVG(bodyTemperature) from COVID_RECORD WHERE result = 'positive'
  RETURN @avgTemp
END;
 
SELECT dbo.getAverageBodyTemp() as Average_Body_Temperature;
 
/*Oxyegn*/
CREATE FUNCTION getAverageOxygenLevel()
RETURNS FLOAT
AS
BEGIN
  DECLARE @avgOxygen FLOAT
  select @avgOxygen = AVG(oxygenLevel) from COVID_RECORD WHERE result = 'positive'
  RETURN @avgOxygen
END;
 
SELECT dbo.getAverageOxygenLevel() as Average_Oxygen_Level;
 
 
/*If the person is positive then what are the quarantine centers available ---> trigger*/
create TRIGGER covidCenterDetails
ON COVID_RECORD
FOR insert
as
BEGIN
select * from QUARANTINE_CENTER WHERE (select [result] from INSERTED) = 'Positive'
END
 

/*Add Constraint to wellnesscehckstatus in UHCS_RECORD*/
ALTER TABLE UHCS_RECORD ADD CONSTRAINT WellnessCheckStatus CHECK (wellnessCheckStatus IN ('C', 'NC'))
 
/*Next Vaccination date for partially vaccinated people.*/
	
CREATE PROCEDURE getNextVaccinationDate AS
BEGIN
SELECT DISTINCT p.personID, CONCAT(p.firstName,' ', p.lastName) AS Full_Name,
v.vaccineName AS Vaccine_Taken, v.dateOfVaccination AS Date_Of_Vaccination,
DATEADD(month, 3, v.dateOfVaccination) AS Next_Vaccination_Date
from VACCINATION v JOIN PERSON p ON p.personID = v.personID
WHERE numberOfVaccination = 1
END
 
EXEC getNextVaccinationDate
 
/*View to get a positive number of people in last few(60) days.*/
 
CREATE VIEW getRegistrationForDMDD AS
SELECT CONCAT(P1.firstName, ' ',P1.lastName) AS STUDENT,
CONCAT(P2.firstName,' ',P2.lastName) AS PROFESSOR, C.courseName
FROM REGISTER R JOIN PROFESSOR PF ON R.PNUID=PF.PNUID JOIN STUDENT S ON S.NUID=R.NUID
JOIN COURSE C ON R.courseID=C.courseID JOIN PERSON P1 ON P1.personID=S.personID JOIN PERSON P2
ON P2.personID=PF.personID
WHERE C.courseName = 'DMDD';
 
CREATE VIEW getRegistrationForAED AS
SELECT CONCAT(P1.firstName, ' ',P1.lastName) AS STUDENT,
CONCAT(P2.firstName,' ',P2.lastName) AS PROFESSOR, C.courseName
FROM REGISTER R JOIN PROFESSOR PF ON R.PNUID=PF.PNUID JOIN STUDENT S ON S.NUID=R.NUID
JOIN COURSE C ON R.courseID=C.courseID JOIN PERSON P1 ON P1.personID=S.personID JOIN PERSON P2
ON P2.personID=PF.personID
WHERE C.courseName = 'AED';
 
CREATE VIEW getRegistrationForDeepLearning AS
SELECT CONCAT(P1.firstName, ' ',P1.lastName) AS STUDENT,
CONCAT(P2.firstName,' ',P2.lastName) AS PROFESSOR, C.courseName
FROM REGISTER R JOIN PROFESSOR PF ON R.PNUID=PF.PNUID JOIN STUDENT S ON S.NUID=R.NUID
JOIN COURSE C ON R.courseID=C.courseID JOIN PERSON P1 ON P1.personID=S.personID JOIN PERSON P2
ON P2.personID=PF.personID
WHERE C.courseName = 'Deep Learning';
 
 /*View to get list of people vaccinated by each quarter of year 2021.*/
CREATE VIEW GetVaccinatedPeopleFirstQ AS
select P.personID ,CONCAT(p.firstName,' ', p.lastName) AS FullName,
case when P.personType = 'pf' then 'Professor'
when P.personType = 'st' then 'Student' else 'Staff'
END AS PersonType, V.vaccineName,V.dateOfVaccination, V.numberOfVaccination
from PERSON P JOIN VACCINATION V ON P.personID=V.personID WHERE CONVERT(VARCHAR(10), dateOfVaccination, 111)
BETWEEN '2021/01/01' and  '2021/04/30';

SELECT * FROM GetVaccinatedPeopleFirstQ
 
CREATE VIEW GetVaccinatedPeopleSecondQ AS
select P.personID ,CONCAT(p.firstName,' ', p.lastName) AS FullName,
case when P.personType = 'pf' then 'Professor'
when P.personType = 'st' then 'Student' else 'Staff'
END AS PersonType, V.vaccineName,V.dateOfVaccination, V.numberOfVaccination
from PERSON P JOIN VACCINATION V ON P.personID=V.personID WHERE CONVERT(VARCHAR(10), dateOfVaccination, 111)
BETWEEN '2021/05/01' and  '2021/08/31';

SELECT * FROM GetVaccinatedPeopleSecondQ
 
CREATE VIEW GetVaccinatedPeopleThirdQ AS
select P.personID ,CONCAT(p.firstName,' ', p.lastName) AS FullName,
case when P.personType = 'pf' then 'Professor'
when P.personType = 'st' then 'Student' else 'Staff'
END AS PersonType, V.vaccineName,V.dateOfVaccination, V.numberOfVaccination
from PERSON P JOIN VACCINATION V ON P.personID=V.personID WHERE CONVERT(VARCHAR(10), dateOfVaccination, 111)
BETWEEN '2021/09/01' and  '2021/12/31';
 
SELECT * FROM GetVaccinatedPeopleThirdQ

/*Add encryption on health insurance id.*/
ALTER table PERSON add [Encrypted_Health_Insurance] varbinary(400) NULL
 
GO
create MASTER KEY
ENCRYPTION BY PASSWORD = 'PERSON@1234';
 
SELECT name KeyName,
symmetric_key_id KeyID,
key_length KeyLength,
algorithm_desc KeyAlgorithm
FROM sys.symmetric_keys;
go
 
CREATE CERTIFICATE healthInsuranceNumber
WITH SUBJECT = 'Person Health Insurance Number';
GO
 
CREATE SYMMETRIC KEY HealthPass_SM WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE healthInsuranceNumber;
GO
 
UPDATE PERSON set [Encrypted_Health_Insurance] = EncryptByKey(Key_GUID('HealthPass_SM'), CONVERT(varbinary,[healthInsuranceID]) )
GO
 
OPEN SYMMETRIC KEY HealthPass_SM DECRYPTION BY CERTIFICATE healthInsuranceNumber;
GO
 
SELECT *, CONVERT(varchar, DecryptByKey([Encrypted_Health_Insurance])) AS 'Decrypted Health Insurance Number'  FROM dbo.PERSON;
 
select * FROM PERSON;
 
SELECT *, CONVERT(varchar, DecryptByKey(Encrypted_Health_Insurance)) AS 'Decrypted Bank account number' FROM dbo.PERSON;