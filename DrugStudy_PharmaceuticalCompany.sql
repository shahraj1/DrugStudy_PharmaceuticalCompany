-- --------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------
-- Options
-- --------------------------------------------------------------------------------
USE db_SQL1;     -- Get out of the master database
SET NOCOUNT ON; -- Report only errors

-- --------------------------------------------------------------------------------
-- Drop Tables
-- --------------------------------------------------------------------------------

-- TABLES
IF OBJECT_ID( 'TDrugKits' )							IS NOT NULL DROP TABLE		TDrugKits
IF OBJECT_ID( 'TPatientVisits' )					IS NOT NULL DROP TABLE		TPatientVisits
IF OBJECT_ID( 'TPatients' )							IS NOT NULL DROP TABLE		TPatients
IF OBJECT_ID( 'TSites' )							IS NOT NULL DROP TABLE		TSites
IF OBJECT_ID( 'TVisitTypes' )						IS NOT NULL DROP TABLE		TVisitTypes
IF OBJECT_ID( 'TWithdrawReasons' )					IS NOT NULL DROP TABLE		TWithdrawReasons
IF OBJECT_ID( 'TRandomCodes' )						IS NOT NULL DROP TABLE		TRandomCodes
IF OBJECT_ID( 'TGenders' )							IS NOT NULL DROP TABLE		TGenders
IF OBJECT_ID( 'TStudies' )							IS NOT NULL DROP TABLE		TStudies

-- VIEWS
IF OBJECT_ID( 'vPatients' )							IS NOT NULL DROP VIEW		vPatients
IF OBJECT_ID( 'vRandomizedPatients' )				IS NOT NULL DROP VIEW		vRandomizedPatients

IF OBJECT_ID( 'vNextRandomCode' )					IS NOT NULL DROP VIEW		vNextRandomCode


IF OBJECT_ID( 'vPatientStudy1Counts' )				IS NOT NULL DROP VIEW		vPatientStudy1Counts
IF OBJECT_ID( 'vPatientStudy2Counts' )				IS NOT NULL DROP VIEW		vPatientStudy2Counts

IF OBJECT_ID( 'vDrugs' )							IS NOT NULL DROP VIEW		vDrugs

IF OBJECT_ID( 'vWithdrawnPatients' )				IS NOT NULL DROP VIEW		vWithdrawnPatients


-- STORED PROCEDURES

IF OBJECT_ID( 'uspScreenPatientStudy1' )			IS NOT NULL DROP PROCEDURE		uspScreenPatientStudy1
IF OBJECT_ID( 'uspScreenPatientStudy2' )			IS NOT NULL DROP PROCEDURE		uspScreenPatientStudy2

IF OBJECT_ID( 'uspRandomizePatientStudy1' )			IS NOT NULL DROP PROCEDURE		uspRandomizePatientStudy1
IF OBJECT_ID( 'uspRandomizePatientStudy2' )			IS NOT NULL DROP PROCEDURE		uspRandomizePatientStudy2

IF OBJECT_ID( 'uspWithdrawalPatientStudy1' )		IS NOT NULL DROP PROCEDURE		uspWithdrawalPatientStudy1




-- --------------------------------------------------------------------------------
-- Step #1: Create Tables
-- --------------------------------------------------------------------------------
CREATE TABLE TStudies
(
 	 intStudyID			INTEGER			NOT NULL 
	,strStudyDesc		VARCHAR(50)		NOT NULL
	,CONSTRAINT TStudies_PK PRIMARY KEY ( intStudyID)
)

CREATE TABLE TSites
(
	 intSiteID 			INTEGER			NOT NULL
	,intSiteNumber		INTEGER			NOT NULL
	,intStudyID			INTEGER			NOT NULL
	,strName			VARCHAR(50)		NOT NULL
	,strAddress			VARCHAR(50)		NOT NULL
	,strCity			VARCHAR(50)		NOT NULL
	,strState			VARCHAR(50)		NOT NULL
	,strZip				VARCHAR(50)		NOT NULL
	,strPhone			VARCHAR(50) 	NOT NULL
	,CONSTRAINT TSites_PK PRIMARY KEY ( intSiteID )
)

CREATE TABLE TPatients
(
	 intPatientID 		INTEGER			NOT NULL
	,intPatientNumber	INTEGER			NOT NULL
	,intSiteID			INTEGER			NOT NULL
	,dtmDOB				DATETIME		NOT NULL
	,intGenderID		INTEGER			NOT NULL
	,intWeight			INTEGER			NOT NULL
	,intRandomCodeID 	INTEGER			
	,CONSTRAINT TPatients_PK PRIMARY KEY ( intPatientID )
)

CREATE TABLE TVisitTypes
(
	 intVisitTypeID		INTEGER 		NOT NULL
	,strVisitDesc 		VARCHAR(50)		NOT NULL 	-- (Screening, Randomization, Withdrawal)
	,CONSTRAINT TVisitTypes_PK PRIMARY KEY ( intVisitTypeID )
)

CREATE TABLE TPatientVisits
(
	 intVisitID			 INTEGER		NOT NULL
	,intPatientID		 INTEGER		NOT NULL
	,dtmVisit			 DATE			NOT NULL
	,intVisitTypeID		 INTEGER		NOT NULL
	,intWithdrawReasonID INTEGER				-- allow Nulls
	,CONSTRAINT TPatientVisits_PK PRIMARY KEY ( intVisitID )
)

CREATE TABLE TRandomCodes
(
	 intRandomCodeID		 INTEGER			NOT NULL  -- *		(1,2,3,4, etc.)
	,intRandomCode			 INTEGER			NOT NULL  -- (1000, 1001, 1002, etc.)
	,intStudyID				 INTEGER			NOT NULL
	,strTreatment			VARCHAR(50)			NOT NULL  -- (A-active or P-placebo)
	,blnAvailable			CHAR				NOT NULL  -- (T or F)
	,CONSTRAINT TRandomCodes_PK PRIMARY KEY ( intRandomCodeID )
)


CREATE TABLE TDrugKits
(
	 intDrugKitID			INTEGER			NOT NULL	-- * (1,2,3,4, etc.)
	,intDrugKitNumber		INTEGER			NOT NULL	-- (10000, 10001, 10002, etc.)
	,intSiteID				INTEGER			NOT NULL 
	,strTreatment			VARCHAR(50)		NOT NULL	-- (A-active or P-placebo)
	,intVisitID				INTEGER						-- (if a Visit ID entered it is already assigned and therefore not available) allow Nulls
	,CONSTRAINT TDrugKits_PK PRIMARY KEY ( intDrugKitID )
)

CREATE TABLE TWithdrawReasons
(
	 intWithdrawReasonID	INTEGER			NOT NULL	-- (1,2,3,etc.)
	,strWithdrawDesc		VARCHAR(50)		NOT NULL
	,CONSTRAINT TWithdrawReasons_PK PRIMARY KEY ( intWithdrawReasonID )	
)

CREATE TABLE TGenders
(
	 intGenderID		INTEGER				NOT NULL
	,strGender			VARCHAR(50)			NOT NULL
	,CONSTRAINT TGenders_PK PRIMARY KEY ( intGenderID )
)

-- --------------------------------------------------------------------------------
-- Step #2: Identify and Create Foreign Keys
-- --------------------------------------------------------------------------------
--
-- #	Child					Parent					Column(s)
-- -	-----					------					---------
-- 1	TSites					TStudies				intStudyID
-- 2	TPatients				TSites					intSiteID
-- 3	TPatients				TGenders				intGenderID
-- 4	TPatients				TRandomCodes			intRandomCodeID
-- 5	TPatientVisits			TPatients				intPatientID
-- 6	TPatientVisits			TVisitTypes				intVisitTypeID
-- 7	TPatientVisits			TWithdrawReasons		intWithdrawReasonID
-- 8	TDrugKits				TSites					intSiteID
-- 9	TDrugKits				TPatientVisits			intVisitID

-- 1
ALTER TABLE TSites ADD CONSTRAINT TSites_TStudies_FK
FOREIGN KEY ( intStudyID ) REFERENCES TStudies ( intStudyID )

-- 2
ALTER TABLE TPatients ADD CONSTRAINT TPatients_TSites_FK
FOREIGN KEY ( intSiteID ) REFERENCES TSites ( intSiteID )

-- 3
ALTER TABLE TPatients ADD CONSTRAINT TPatients_TGenders_FK
FOREIGN KEY ( intGenderID ) REFERENCES TGenders ( intGenderID )

-- 4
ALTER TABLE TPatients ADD CONSTRAINT TPatients_TRandomCodes_FK
FOREIGN KEY ( intRandomCodeID ) REFERENCES TRandomCodes ( intRandomCodeID )

-- 5
ALTER TABLE TPatientVisits ADD CONSTRAINT TPatientVisits_TPatients_FK
FOREIGN KEY ( intPatientID ) REFERENCES TPatients ( intPatientID )

-- 6
ALTER TABLE TPatientVisits ADD CONSTRAINT TPatientVisits_TVisitTypes_Fk
FOREIGN KEY ( intVisitTypeID ) REFERENCES TVisitTypes ( intVisitTypeID )

-- 7
ALTER TABLE TPatientVisits ADD CONSTRAINT TPatientVisits_TWithdrawReasons_FK
FOREIGN KEY ( intWithdrawReasonID ) REFERENCES TWithdrawReasons ( intWithdrawReasonID )

-- 8
ALTER TABLE TDrugKits ADD CONSTRAINT TDrugKits_TSites_FK
FOREIGN KEY ( intSiteID ) REFERENCES TSites ( intSiteID )

-- 9
ALTER TABLE TDrugKits ADD CONSTRAINT TDrugKits_TPatientVisits_FK
FOREIGN KEY ( intVisitID ) REFERENCES TPatientVisits ( intVisitID )


-- --------------------------------------------------------------------------------
-- Step #3: Inserts
-- --------------------------------------------------------------------------------
INSERT INTO TStudies(intStudyID,strStudyDesc)
VALUES	 (12345,'Study1')
		,(54321,'Study2')

INSERT INTO TSites(intSiteID,intSiteNumber,intStudyID,strAddress,strCity,strName,strPhone,strState,strZip)
VALUES	 (101,101,'12345','Dr. Stan Heinrich ','123 E. Main St','Atlanta','GA','25869','1234567890')
		,(111,102,'12345','Mercy Hospital','3456 Elmhurst Rd.','Secaucus','NJ','32659','5013629564')
		,(121,103,'12345','St. Elizabeth Hospital','976 Jackson Way','Ft. Thomas','KY','41258','3026521478')
		,(131,104,'12345','Dr. Jim Smith','32454 Morris Rd.','Hamilton','OH','45013','3256847596')
		,(141,105,'12345','Dr. Dan Jones','1865 Jelico Hwy.','Knoxville','TN','34568','2145798241')
		,(501,106,'54321','Dr. Robert Adler','9087 W. Maple Ave.','Cedar Rapids','IA','42365','6149652574')
		,(511,107,'54321','Dr. Tim Schmitz','4539 Helena Run','Johnson City','TN','34785','5066987462')
		,(521,108,'54321','Dr. Lawrence Snell','9201 NW. Washington Blvd.','Bristol','VA','20163','3876510249')
		,(531,109,'54321','Cedar Sinai Medical Center','40321 Hollywood Blvd.','Portland','OR','50236','5439510246')
		,(541,110,'54321','Vally View Hospital','398 Hampton Rd.','Seattle','WA','41203','7243780036')

INSERT INTO TGenders(intGenderID,strGender)
VALUES	 (1,'Female')
		,(2,'Male')

INSERT INTO TVisitTypes(intVisitTypeID,strVisitDesc)
VALUES	 (1,'Randomization')
		,(2,'Screening')
		,(3,'Withdrawal')

INSERT INTO TWithdrawReasons(intWithdrawReasonID,strWithdrawDesc)
VALUES	 (1,'Patient withdrew consent')
		,(2,'Adverse event')
		,(3,'Health issue-related to study')
		,(4,'Health issue-unrelated to study')
		,(5,'Personal reason')
		,(6,'Completed the study')

INSERT INTO TRandomCodes(intRandomCodeID,intRandomCode,intStudyID,strTreatment,blnAvailable)
VALUES	 (1,1000,12345,'A','T')
		,(2,1001,12345,'P','T')
		,(3,1002,12345,'A','T')
		,(4,1003,12345,'P','T')
		,(5,1004,12345,'P','T')
		,(6,1005,12345,'A','T')
		,(7,1006,12345,'A','T')
		,(8,1007,12345,'P','T')
		,(9,1008,12345,'A','T')
		,(10,1009,12345,'P','T')
		,(11,1010,12345,'P','T')
		,(12,1011,12345,'A','T')
		,(13,1012,12345,'P','T')
		,(14,1013,12345,'A','T')
		,(15,1014,12345,'A','T')
		,(16,1015,12345,'A','T')
		,(17,1016,12345,'P','T')
		,(18,1017,12345,'P','T')
		,(19,1018,12345,'A','T')
		,(20,1019,12345,'P','T')

		,(21,5000,54321,'A','T')
		,(22,5001,54321,'A','T')
		,(23,5002,54321,'A','T')
		,(24,5003,54321,'A','T')
		,(25,5004,54321,'A','T')
		,(26,5005,54321,'A','T')
		,(27,5006,54321,'A','T')
		,(28,5007,54321,'A','T')
		,(29,5008,54321,'A','T')
		,(30,5009,54321,'A','T')
		,(31,5010,54321,'P','T')
		,(32,5011,54321,'P','T')
		,(33,5012,54321,'P','T')
		,(34,5013,54321,'P','T')
		,(35,5014,54321,'P','T')
		,(36,5015,54321,'P','T')
		,(37,5016,54321,'P','T')
		,(38,5017,54321,'P','T')
		,(39,5018,54321,'P','T')
		,(40,5019,54321,'P','T')


INSERT INTO TDrugKits(intDrugKitID,intDrugKitNumber,intSiteID,strTreatment,intVisitID)
VALUES	 (1,10000,101,'A',NULL)
		,(2,10001,101,'A',NULL)
		,(3,10002,101,'A',NULL)
		,(4,10003,101,'A',NULL)
		,(5,10004,101,'P',NULL)
		,(6,10005,101,'P',NULL)
		,(7,10006,101,'P',NULL)
		,(8,10007,101,'P',NULL)
		,(9,10008,111,'A',NULL)
		,(10,10009,111,'A',NULL)
		,(11,10010,111,'A',NULL)
		,(12,10011,111,'A',NULL)
		,(13,10012,111,'P',NULL)
		,(14,10013,111,'P',NULL)
		,(15,10014,111,'P',NULL)
		,(16,10015,111,'P',NULL)
		,(17,10016,121,'A',NULL)
		,(18,10017,121,'A',NULL)
		,(19,10018,121,'A',NULL)
		,(20,10019,121,'A',NULL)
		,(21,10020,121,'P',NULL)
		,(22,10021,121,'P',NULL)
		,(23,10022,121,'P',NULL)
		,(24,10023,121,'P',NULL)
		,(25,10024,131,'A',NULL)
		,(26,10025,131,'A',NULL)
		,(27,10026,131,'A',NULL)
		,(28,10027,131,'A',NULL)
		,(29,10028,131,'P',NULL)
		,(30,10029,131,'P',NULL)
		,(31,10030,131,'P',NULL)
		,(32,10031,131,'P',NULL)
		,(33,10032,141,'A',NULL)
		,(34,10033,141,'A',NULL)
		,(35,10034,141,'A',NULL)
		,(36,10035,141,'A',NULL)
		,(37,10036,141,'P',NULL)
		,(38,10037,141,'P',NULL)
		,(39,10038,141,'P',NULL)
		,(40,10039,141,'P',NULL)
		,(41,10040,501,'A',NULL)
		,(42,10041,501,'A',NULL)
		,(43,10042,501,'A',NULL)
		,(44,10043,501,'A',NULL)
		,(45,10044,501,'P',NULL)
		,(46,10045,501,'P',NULL)
		,(47,10046,501,'P',NULL)
		,(48,10047,501,'P',NULL)
		,(49,10048,511,'A',NULL)
		,(50,10049,511,'A',NULL)
		,(51,10050,511,'A',NULL)
		,(52,10051,511,'A',NULL)
		,(53,10052,511,'P',NULL)
		,(54,10053,511,'P',NULL)
		,(55,10054,511,'P',NULL)
		,(56,10055,511,'P',NULL)
		,(57,10056,521,'A',NULL)
		,(58,10057,521,'A',NULL)
		,(59,10058,521,'A',NULL)
		,(60,10059,521,'A',NULL)
		,(61,10060,521,'P',NULL)
		,(62,10061,521,'P',NULL)
		,(63,10062,521,'P',NULL)
		,(64,10063,521,'P',NULL)
		,(65,10064,531,'A',NULL)
		,(66,10065,531,'A',NULL)
		,(67,10066,531,'A',NULL)
		,(68,10067,531,'A',NULL)
		,(69,10068,531,'P',NULL)
		,(70,10069,531,'P',NULL)
		,(71,10070,531,'P',NULL)
		,(72,10071,531,'P',NULL)
		,(73,10072,541,'A',NULL)
		,(74,10073,541,'A',NULL)
		,(75,10074,541,'A',NULL)
		,(76,10075,541,'A',NULL)
		,(77,10076,541,'P',NULL)
		,(78,10077,541,'P',NULL)
		,(79,10078,541,'P',NULL)
		,(80,10079,541,'P',NULL)

--INSERT INTO TPatients(intPatientID, intPatientNumber, intSiteID, dtmDOB,intGenderID,intWeight,intRandomCodeID)
--VALUES	 (1, 101001, 101,'01/01/2001',1,140,1)
--			,(2, 111001, 111,'02/02/2002',2,138,2)
--			,(3, 121001, 121,'03/03/2003',1,142,3)
--			,(4, 101002, 101,'04/04/2004',2,170,4)
--			,(5, 131001, 131,'05/05/2005',2,180,5)

--			,(6, 511001, 511,'06/06/2006',2,190,25)
--			,(7, 501001, 501,'07/07/2007',2,220,26)
--			,(8, 521001, 521,'08/08/2008',1,120,27)
--			,(9, 531001, 531,'09/09/2009',1,135,31)

--INSERT INTO TPatientVisits(intVisitID,intPatientID,dtmVisit,intVisitTypeID,intWithdrawReasonID)
--VALUES		 (1,1,'03/01/2018',1,NULL)
--			,(2,2,'03/02/2018',1,NULL)
--			,(3,3,'03/03/2018',1,NULL)
--			,(4,4,'03/04/2018',1,NULL)
--			,(5,7,'03/05/2018',1,NULL)
--			,(6,9,'03/06/2018',1,NULL)
--			,(7,8,'03/06/2018',1,NULL)
--			,(8,5,'03/06/2018',1,NULL)
--			,(9,6,'03/07/2018',1,NULL)

--			,(10,1,'03/08/2018',2,NULL)
--			,(11,1,'03/08/2018',3,6)
			
--			,(12,7,'03/09/2018',2,NULL)

-- --------------------------------------------------------------------------------
-- Step #4: VIEWS 
-- Question 4.#3 - Show all patients at all sites for both studies
-- --------------------------------------------------------------------------------	
GO
CREATE VIEW vPatients
AS 
SELECT 
	 TP.intPatientID
	,TP.intPatientNumber
	,TS.intSiteID
	,TS.intSiteNumber
	,TSD.intStudyID
	,TSD.strStudyDesc
FROM
	 TPatients AS TP
	,TStudies AS TSD
	,TSites AS TS
WHERE
	TP.intSiteID=TS.intSiteID
AND TS.intStudyID=TSD.intStudyID

GO

------ Execute
--SELECT * FROM vPatients


-- --------------------------------------------------------------------------------
-- Question 4.#4 - Show all randomized patients, their site and their treatment for both studies
-- --------------------------------------------------------------------------------	
GO
CREATE VIEW vRandomizedPatients
AS
SELECT 
	 TPV.intPatientID
	,TP.intPatientNumber
	,TS.intSiteNumber
	,TS.intStudyID
	,TSD.strStudyDesc
	,TP.intRandomCodeID
	,TRC.intRandomCode
	,TRC.strTreatment
FROM
	 TPatientVisits AS TPV
	,TPatients AS TP
	,TSites AS TS
	,TStudies AS TSD
	,TRandomCodes AS TRC
WHERE
	TPV.intVisitTypeID=1
AND TPV.intPatientID= TP.intPatientID
AND TS.intSiteID=TP.intSiteID
AND TSD.intStudyID=TS.intStudyID
AND	TP.intRandomCodeID=TRC.intRandomCodeID


GO
---- Execute
--SELECT * FROM vRandomizedPatients

-- --------------------------------------------------------------------------------
-- Question 4.#5 - show the next available random codes (MIN) for both studies
-- --------------------------------------------------------------------------------	


-- --------------------------------------------------------------------------------
-- ********************************************************************************
-- ************************************ STUDY 1 *********************************** 
-- ********************************************************************************
-- --------------------------------------------------------------------------------	

-- Changing all 'A' to 0 and Passive to '1'. so that it is easier to count the values
GO

CREATE VIEW vPatientStudy1Counts
AS 
SELECT 
	 SUM(LEN(REPLACE(VRP.strTreatment, 'A', ''))) AS intPassivePatientCount
	,SUM(LEN(REPLACE(vRP.strTreatment, 'P', ''))) AS intActivePatientCount

FROM
	vRandomizedPatients as vRP

WHERE
	intStudyID=12345

GO

-- See the active and passive patients
--SELECT * FROM vPatientStudy1Counts

GO 

DECLARE @intRandomVariable integer
DECLARE @strRandomVariable char

-- get a random variable

SET @intRandomVariable=RAND()

-- flip a coin logic
-- compare 
IF @intRandomVariable >= 0.5 

	SET @strRandomVariable='A'

ELSE IF @intRandomVariable < 0.5  

	SET @strRandomVariable='P'


DECLARE @intActiveCount integer,@intPassiveCount integer

-- set the variable for active and passive count from the view
SET @intActiveCount=(SELECT	intActivePatientCount FROM vPatientStudy1Counts)
SET @intPassiveCount=(SELECT intPassivePatientCount FROM vPatientStudy1Counts)


IF (@intActiveCount-@intPassiveCount) = 2   

	--DECLARE GetSite CURSOR LOCAL FOR
	--(SELECT MIN(intRandomCodeID) AS intRandomCodeID,MIN(intRandomCode) AS intRandomCode, 'P'  AS strTreatment  from TRandomCodes WHERE intRandomCodeID NOT IN (SELECT intRandomCodeID FROM TPatients) AND strTreatment='P' AND blnAvailable='T')
	

	 -- SELECT FROM passive
	(SELECT MIN(intRandomCodeID) AS intRandomCodeID,MIN(intRandomCode) AS intRandomCode, 'P'  AS strTreatment  from TRandomCodes WHERE intRandomCodeID NOT IN (SELECT intRandomCodeID FROM TPatients) AND strTreatment='P' AND blnAvailable='T')
	

ELSE IF (@intActiveCount-@intPassiveCount) = -2

	-- SELLECT FROM active
	(SELECT MIN(intRandomCodeID) AS intRandomCodeID ,MIN(intRandomCode) AS intRandomCode, 'A' AS strTreatment from TRandomCodes WHERE intRandomCodeID NOT IN (SELECT intRandomCodeID FROM TPatients) AND strTreatment='A' AND blnAvailable='T')

ELSE 

	BEGIN 

	-- from random variable
	IF @strRandomVariable='A' 

		-- take active
		(SELECT MIN(intRandomCodeID) AS intRandomCodeID ,MIN(intRandomCode) AS intRandomCode, 'A' AS strTreatment  from TRandomCodes WHERE intRandomCodeID NOT IN (SELECT intRandomCodeID FROM TPatients) AND blnAvailable='T' )

	ELSE IF @strRandomVariable='P'
	
		-- take passive
		(SELECT MIN(intRandomCodeID) AS intRandomCodeID ,MIN(intRandomCode) AS intRandomCode, 'P' AS strTreatment  from TRandomCodes WHERE intRandomCodeID NOT IN (SELECT intRandomCodeID FROM TPatients) AND intStudyID='12345' AND blnAvailable='T' )

	END 

	--DECLARE @intRandomCodeID		INTEGER
	--DECLARE @intRandomCode			INTEGER
	--DECLARE @strTreatment			VARCHAR(50)

	--OPEN GetSite 

	--FETCH FROM GetSite 
	--INTO @intRandomCodeID,@intRandomCode, @strTreatment

	--Close GetSite

	--GO 

	--CREATE VIEW vRandomCodeStudy1
	--AS 
	--SELECT @intRan


	-- --------------------------------------------------------------------------------
	-- ********************************************************************************
	-- ************************************ STUDY 2 *********************************** 
	-- ********************************************************************************
	-- --------------------------------------------------------------------------------

-- Changing all 'A' to 0 and Passive to '1'. so that it is easier to count the values
GO

CREATE VIEW vPatientStudy2Counts
AS 
SELECT
 
	 SUM(LEN(REPLACE(VRP.strTreatment, 'A', ''))) AS intPassivePatientCount
	,SUM(LEN(REPLACE(vRP.strTreatment, 'P', ''))) AS intActivePatientCount

FROM
	vRandomizedPatients as vRP

WHERE
	intStudyID=54321

GO

-- See the active and passive patients
--SELECT * FROM vPatientStudy2Counts


DECLARE @intRandomVariable integer
DECLARE @strRandomVariable char

-- flip a coin logic
SET @intRandomVariable=RAND()

IF @intRandomVariable >= 0.5 

	SET @strRandomVariable='A'

ELSE IF @intRandomVariable < 0.5  

	SET @strRandomVariable='P'


DECLARE @intActiveCount integer,@intPassiveCount integer

-- select active and passive count from the view
SET @intActiveCount=(SELECT	intActivePatientCount FROM vPatientStudy2Counts)
SET @intPassiveCount=(SELECT intPassivePatientCount FROM vPatientStudy2Counts)

IF (@intActiveCount-@intPassiveCount) = 2   

    -- SELECT FROM passive
	(SELECT MIN(intRandomCodeID) AS intRandomCodeID,MIN(intRandomCode) AS intRandomCode, 'P' AS strTreatment from TRandomCodes WHERE intRandomCodeID NOT IN (SELECT intRandomCodeID FROM TPatients) AND intStudyID=54321 AND strTreatment='P' AND blnAvailable='T')

ELSE IF (@intActiveCount-@intPassiveCount) = -2

	-- SELLECT FROM active
	(SELECT MIN(intRandomCodeID) AS intRandomCodeID ,MIN(intRandomCode) AS intRandomCode, 'A' AS strTreatment from TRandomCodes WHERE intRandomCodeID NOT IN (SELECT intRandomCodeID FROM TPatients) AND intStudyID=54321  AND strTreatment='A' AND blnAvailable='T')

ELSE 

	BEGIN 

	IF @strRandomVariable='A' 

		-- take active
		(SELECT MIN(intRandomCodeID) AS intRandomCodeID ,MIN(intRandomCode) AS intRandomCode, 'A' AS strTreatment from TRandomCodes WHERE intRandomCodeID NOT IN (SELECT intRandomCodeID FROM TPatients) AND blnAvailable='T' )

	ELSE IF @strRandomVariable='P'
	
		-- take passive 
			
			--GO
			--CREATE VIEW vRandomCode 
			--AS 
			(SELECT MIN(intRandomCodeID) AS intRandomCodeID ,MIN(intRandomCode) AS intRandomCode, 'P' AS strTreatment from TRandomCodes WHERE intRandomCodeID NOT IN (SELECT intRandomCodeID FROM TPatients) AND intStudyID='54321' AND blnAvailable='T' )
			
	END 

-- --------------------------------------------------------------------------------
-- Question 4.#6 - show all available drug at all sites for both studies
-- --------------------------------------------------------------------------------	

GO
CREATE VIEW vDrugs
AS 
SELECT 
	 TDK.intDrugKitID
	,TDK.intDrugKitNumber
	,TS.intSiteID
	,TS.intSiteNumber
	,TSD.intStudyID
	,TSD.strStudyDesc
FROM
	 TDrugKits AS TDK
	,TStudies AS TSD
	,TSites AS TS
WHERE
	TDK.intSiteID=TS.intSiteID
AND TS.intStudyID=TSD.intStudyID
AND intVisitID NOT IN (SELECT intVisitID FROM TPatientVisits)

GO

--SELECT * FROM vDrugs

-- --------------------------------------------------------------------------------
-- Question 4.#7 - show all withdrawn patients, their site, withdrawal date and withdrawal reason for both studies
-- --------------------------------------------------------------------------------	

GO 
CREATE VIEW vWithdrawnPatients
AS 
SELECT 
	
	 TWR.intWithdrawReasonID
	,TWR.strWithdrawDesc
	,TS.intSiteID
	,TS.intSiteNumber

FROM 

	 TWithdrawReasons AS TWR
	,TSites AS TS
	,TPatientVisits	AS TPV
	,TPatients AS TP

WHERE
		
	TPV.intWithdrawReasonID=TWR.intWithdrawReasonID
AND TPV.intPatientID=TP.intPatientID
AND TP.intSiteID=TS.intSiteID

GO

--SELECT * FROM vWithdrawnPatients


-- --------------------------------------------------------------------------------
-- Question 4.#8a - Additional Views
-- --------------------------------------------------------------------------------	





-- --------------------------------------------------------------------------------
-- Question 4.#8b - Additional Views
-- --------------------------------------------------------------------------------	







-- --------------------------------------------------------------------------------
-- Question 4.#9 - the stored procedure(s) that will screen a patient for both/each studies
-- --------------------------------------------------------------------------------	

-- Study 1
GO

CREATE PROCEDURE uspScreenPatientStudy1
	 @intPatientID		AS INTEGER			OUTPUT
	,@dtmDateOfBirth	AS DATETIME
	,@intGenderID		AS INTEGER	
	,@intWeight			AS INTEGER
	,@dtmVisitDate		AS DATE	
AS 
	

SET XACT_ABORT ON -- TERMINATE AND ROLL BACK ENTIRE TRANASCTION ON ANY ERRORS

BEGIN TRANSACTION
		

	-- DECLARE VARIABLES
	DECLARE @intRandomCodeID	AS INTEGER
	DECLARE @intVisitID			AS INTEGER
	DECLARE @intPatientNumber	AS INTEGER
	DECLARE	@intSiteID			AS INTEGER 


	SELECT @intPatientID = MAX(intPatientID) + 1 
	FROM TPatients (TABLOCKX) -- LOCK TABLE UNTIL END OF TRANSACTION

	SELECT @intPatientID = COALESCE(@intPatientID,1)

	-- OR WHAT SITE DOES THEY WANT --
	-- Cursor for a Site
	DECLARE GetSite CURSOR LOCAL FOR
	SELECT MAX(intSiteID) FROM TSites
	WHERE intStudyID=12345

	OPEN GetSite 

	FETCH FROM GetSite 
	INTO @intSiteID

	Close GetSite

	-- Cursor for a PatientNumber
	DECLARE GetPatientNumber CURSOR LOCAL FOR
	SELECT MAX(intPatientNumber) FROM vPatients
	WHERE intSiteID=@intSiteID
	
	OPEN GetPatientNumber 

	FETCH FROM GetPatientNumber 
	INTO @intPatientNumber

	Close GetPatientNumber
	

	-- if null
	IF @intPatientNumber= NULL 
	
	BEGIN
	
	SELECT @intPatientNumber = COALESCE(@intPatientNumber,0)

	-- INCREMENT by 1 for each new Patients
	SET @intPatientNumber = @intSiteID * 1000

	END

	SET @intPatientNumber += 1

	INSERT INTO TPatients (intPatientID, intPatientNumber, intSiteID, dtmDOB,intGenderID,intWeight,intRandomCodeID)
	VALUES	(@intPatientID, @intPatientNumber, @intSiteID, @dtmDateOfBirth,@intGenderID,@intWeight,NULL)


	-- Insert into TPatientVisits

	SELECT @intVisitID = MAX(intVisitID) + 1 
	FROM TPatientVisits (TABLOCKX) -- LOCK TABLE UNTIL END OF TRANSACTION

	SELECT @intVisitID = COALESCE(@intVisitID,1)

	INSERT INTO TPatientVisits(intVisitID, intPatientID, dtmVisit, intVisitTypeID,intWithdrawReasonID)
	VALUES	(@intVisitID, @intPatientID, @dtmVisitDate, 1 ,NULL) -- 1 for screening


COMMIT TRANSACTION

Go


-- Study 2
GO

CREATE PROCEDURE uspScreenPatientStudy2
	 @intPatientID		AS INTEGER			OUTPUT
	,@dtmDateOfBirth	AS DATETIME
	,@intGenderID		AS INTEGER	
	,@intWeight			AS INTEGER
	,@dtmVisitDate		AS DATE	
AS 
	

SET XACT_ABORT ON -- TERMINATE AND ROLL BACK ENTIRE TRANASCTION ON ANY ERRORS

BEGIN TRANSACTION
		

	-- DECLARE VARIABLES
	DECLARE @intRandomCodeID	AS INTEGER
	DECLARE @intVisitID			AS INTEGER
	DECLARE @intPatientNumber	AS INTEGER
	DECLARE	@intSiteID			AS INTEGER 


	SELECT @intPatientID = MAX(intPatientID) + 1 
	FROM TPatients (TABLOCKX) -- LOCK TABLE UNTIL END OF TRANSACTION

	SELECT @intPatientID = COALESCE(@intPatientID,1)

	-- OR WHAT SITE DOES THEY WANT --
	--------------------------------------
	-- Cursor for a Site
	DECLARE GetSite CURSOR LOCAL FOR
	SELECT MAX(intSiteID) FROM TSites
	WHERE intStudyID=54321	-- For Study2 
	--------------------------------------

	OPEN GetSite 

	FETCH FROM GetSite 
	INTO @intSiteID

	Close GetSite

	-- Cursor for a PatientNumber
	DECLARE GetPatientNumber CURSOR LOCAL FOR
	SELECT MAX(intPatientNumber) FROM vPatients
	WHERE intSiteID=@intSiteID
	
	OPEN GetPatientNumber 

	FETCH FROM GetPatientNumber 
	INTO @intPatientNumber

	Close GetPatientNumber
		

	-- if null
	IF @intPatientNumber= NULL 
	
	BEGIN
	
	SELECT @intPatientNumber = COALESCE(@intPatientNumber,0)

	-- INCREMENT by 1 for each new Patients
	SET @intPatientNumber = @intSiteID * 1000

	END

	-- INCREMENT by 1 for each new Patients
	SET @intPatientNumber += 1


	INSERT INTO TPatients (intPatientID, intPatientNumber, intSiteID, dtmDOB,intGenderID,intWeight,intRandomCodeID)
	VALUES	(@intPatientID, @intPatientNumber, @intSiteID, @dtmDateOfBirth,@intGenderID,@intWeight,NULL)


	-- Insert into TPatientVisits

	SELECT @intVisitID = MAX(intVisitID) + 1 
	FROM TPatientVisits (TABLOCKX) -- LOCK TABLE UNTIL END OF TRANSACTION

	SELECT @intVisitID = COALESCE(@intVisitID,1)

	INSERT INTO TPatientVisits(intVisitID, intPatientID, dtmVisit, intVisitTypeID,intWithdrawReasonID)
	VALUES	(@intVisitID, @intPatientID, @dtmVisitDate, 1 ,NULL) -- 1 for screening


COMMIT TRANSACTION

Go


-- --------------------------------------------------------------------------------
-- Question 4.#10 - the stored procedure(s) that will randomize a patient for both/each studies
-- --------------------------------------------------------------------------------	

---- Study 1

GO

CREATE PROCEDURE uspRandomizePatientStudy1
	 @intPatientID		AS INTEGER			
AS 
	

SET XACT_ABORT ON -- TERMINATE AND ROLL BACK ENTIRE TRANASCTION ON ANY ERRORS

BEGIN TRANSACTION
		

	-- DECLARE VARIABLES
	DECLARE @dtmCurrentDate		AS DATE
	DECLARE @intVisitID			AS INTEGER
	DECLARE @intSiteID			AS INTEGER
	DECLARE @intDrugKitID		AS INTEGER
		
	-- Insert into TPatientVisits for Visit

	SELECT @intVisitID = MAX(intVisitID) + 1 
	FROM TPatientVisits (TABLOCKX) -- LOCK TABLE UNTIL END OF TRANSACTION

	SELECT @intVisitID = COALESCE(@intVisitID,1)

	SET @dtmCurrentDate =  GETDATE()



			--- NEED RANDOM CODE(s) ---




	INSERT INTO TPatientVisits(intVisitID,intPatientID,dtmVisit,intVisitTypeID,intWithdrawReasonID)
	VALUES	(@intVisitID,@intPatientID,@dtmCurrentDate, 2, NULL) 


	-- Get the Site to get a drug kit
	-- Get Site Cursor
	DECLARE GetSite CURSOR LOCAL FOR
	SELECT (intSiteID) FROM vPatients
	WHERE intPatientID=@intPatientID	

	OPEN GetSite 

	FETCH FROM GetSite 
	INTO @intSiteID

	Close GetSite

	-- Assign Drug Kits
	SELECT @intDrugKitID = MIN(intDrugKitID)  
	FROM vDrugs
	WHERE intSiteID = @intSiteID
	AND intStudyID=12345		-- For Study 1


	-- Update the Visit ID in the Drug Kit
	UPDATE
	 TDrugKits
	SET 
	intVisitID=@intVisitID	
	WHERE 
	intDrugKitID=@intDrugKitID

COMMIT TRANSACTION

Go

-- Study 2
GO

CREATE PROCEDURE uspRandomizePatientStudy2
	 @intPatientID		AS INTEGER			
AS 
	

SET XACT_ABORT ON -- TERMINATE AND ROLL BACK ENTIRE TRANASCTION ON ANY ERRORS

BEGIN TRANSACTION
		

	-- DECLARE VARIABLES
	DECLARE @dtmVisitDate		AS DATE	
	DECLARE @intVisitID			AS INTEGER
	DECLARE @intSiteID			AS INTEGER
	DECLARE @intDrugKitID		AS INTEGER
		
	-- Insert into TPatientVisits for Visit

	SELECT @intVisitID = MAX(intVisitID) + 1 
	FROM TPatientVisits (TABLOCKX) -- LOCK TABLE UNTIL END OF TRANSACTION

	SELECT @intVisitID = COALESCE(@intVisitID,1)

	SET @dtmVisitDate =  GETDATE()


			--- NEED RANDOM CODE(s) ---


	INSERT INTO TPatientVisits(intVisitID,intPatientID,dtmVisit,intVisitTypeID,intWithdrawReasonID)
	VALUES	(@intVisitID,@intPatientID,@dtmVisitDate, 2, NULL) 


	-- Get the Site to get a drug kit
	-- Get Site Cursor
	DECLARE GetSite CURSOR LOCAL FOR
	SELECT (intSiteID) FROM vPatients
	WHERE intPatientID=@intPatientID	

	OPEN GetSite 

	FETCH FROM GetSite 
	INTO @intSiteID

	Close GetSite

	-- Assign Drug Kits
	SELECT @intDrugKitID = MIN(intDrugKitID)  
	FROM vDrugs
	WHERE intSiteID = @intSiteID
	AND intStudyID=54321		-- For Study 2


	-- Update the Visit ID in the Drug Kit
	UPDATE
		TDrugKits
	SET 
		intVisitID=@intVisitID	
	WHERE 
		intDrugKitID=@intDrugKitID

COMMIT TRANSACTION

Go


-- --------------------------------------------------------------------------------
-- Question 4.#11 - the stored procedure(s) that will withdraw a patient for both/each studies
-- --------------------------------------------------------------------------------	

-- Study 1
GO

CREATE PROCEDURE uspWithdrawalPatientStudy1
	 @intPatientID				AS INTEGER			
	,@dtmVisitDate				AS DATE
	,@intWithdrawalReasonID		AS INTEGER	
AS 
	

SET XACT_ABORT ON -- TERMINATE AND ROLL BACK ENTIRE TRANASCTION ON ANY ERRORS

BEGIN TRANSACTION
		

	-- DECLARE VARIABLES
	DECLARE @intVisitID				AS INTEGER
	DECLARE @intSiteID				AS INTEGER
	DECLARE @intDrugKitID			AS INTEGER
	DECLARE @dtmPreviousVisitDate	AS DATE
		
	-- Insert into TPatientVisits for Visit
	SELECT @intVisitID = MAX(intVisitID) + 1 
	FROM TPatientVisits (TABLOCKX) -- LOCK TABLE UNTIL END OF TRANSACTION

	SELECT @intVisitID = COALESCE(@intVisitID,1)

	-- GET THE previous VIsit Date of the Patient
	SET @dtmPreviousVisitDate= (SELECT dtmVisit FROM TPatientVisits WHERE intPatientID=@intPatientID)

	IF DATEDIFF(dd,@dtmVisitDate,@dtmPreviousVisitDate) > 0 
	BEGIN 

		INSERT INTO TPatientVisits(intVisitID,intPatientID,dtmVisit,intVisitTypeID,intWithdrawReasonID)
		VALUES	(@intVisitID,@intPatientID,@dtmVisitDate, 3, @intWithdrawalReasonID) 

	END

	ELSE 
	
	BEGIN 

		SET XACT_ABORT ON		-- ROLL BACK TRANSACTION
	
	END 

COMMIT TRANSACTION

Go









