CREATE OR REPLACE PACKAGE ProiectGMC AS
  TYPE Varsta IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  ValoriVarsta Varsta;    -- Table for storing average age (Task 4)
  TYPE COMPANII IS TABLE OF COMPANII_AERIENE%ROWTYPE INDEX BY PLS_INTEGER;
  comp COMPANII;          -- Table for storing company data (Task 2)
  PROCEDURE NrPasageri;
  PROCEDURE LocuriLibere;
  PROCEDURE MedieVarsta(companieNume COMPANII_AERIENE.DENUMIRE%TYPE);
  FUNCTION DurataCalatorie(pasagerNume PASAGERI.NUME%TYPE, pasagerPrenume PASAGERI.PRENUME%TYPE)
    RETURN CHAR;
  FUNCTION NrZboruri(aeroportId AEROPORTURI.ID_AEROPORT%type)
    RETURN NUMBER;
END ProiectGMC;
/

CREATE OR REPLACE PACKAGE BODY ProiectGMC AS
  -- Task 1.
  PROCEDURE NrPasageri IS
    -- Declare collections
    TYPE TablouIndexat IS TABLE OF NUMBER;
    TYPE TablouImbricat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE Vector IS VARRAY(50) OF ZBORURI.ID_ZBOR%TYPE;

    -- Collection variables
    tabelPasageri TablouIndexat;
    tabelNumarPasageri TablouImbricat;
    vectorZboruriId Vector := Vector();

    -- Regular variables
    zborId ZBORURI.ID_ZBOR%type; -- Flight ID
    numPasageri NUMBER;          -- Number of passengers per flight
    numZbor NUMBER := 0;         -- Index
  BEGIN
    FOR zbor IN (SELECT ID_ZBOR FROM ZBORURI) LOOP
        -- Get each flight ID
        zborId := zbor.ID_ZBOR;

        -- Select all passengers who are booked on the current flight
        SELECT ID_PASAGER BULK COLLECT INTO tabelPasageri
        FROM CALATORII
        WHERE ID_ZBOR = zborId;

        -- Save the number of passengers for each flight
        numPasageri := tabelPasageri.COUNT;
        numZbor := numZbor + 1;
        tabelNumarPasageri(numZbor) := numPasageri;

        -- Save the flight ID for each flight
        vectorZboruriId.extend;
        vectorZboruriId(numZbor) := zborId;
    END LOOP;

    -- Display the number of passengers for each flight
    FOR i IN tabelNumarPasageri.FIRST..tabelNumarPasageri.LAST LOOP
        IF tabelNumarPasageri(i) = 0 THEN
          DBMS_OUTPUT.PUT_LINE('Flight ' || vectorZboruriId(i) || ': has no passengers.');
        ELSIF tabelNumarPasageri(i) = 1 THEN
          DBMS_OUTPUT.PUT_LINE('Flight ' || vectorZboruriId(i) || ': ' || tabelNumarPasageri(i) || ' passenger');
        ELSE
          DBMS_OUTPUT.PUT_LINE('Flight ' || vectorZboruriId(i) || ': ' || tabelNumarPasageri(i) || ' passengers');
        END IF;
    END LOOP;
  END;

  -- Task 2.
  PROCEDURE LocuriLibere IS
    zborID ZBORURI.ID_ZBOR%TYPE;   -- Flight code
    numb     NUMBER;               -- Number of passengers on the flight
    ind      NUMBER;               -- Index

    -- Explicit cursor to retrieve flights
    CURSOR top_z (companie COMPANII_AERIENE.ID_COMPANIE%TYPE) IS
      SELECT C.ID_ZBOR, A.NR_LOCURI - COUNT(C.ID_PASAGER)
      FROM CALATORII C
           JOIN MATEI.ZBORURI Z ON Z.ID_ZBOR = C.ID_ZBOR
           JOIN MATEI.AVIOANE A ON A.ID_AVION = Z.ID_AVION
      WHERE Z.ID_COMPANIE = companie
      GROUP BY C.ID_ZBOR, A.NR_LOCURI
      ORDER BY A.NR_LOCURI - COUNT(ID_PASAGER) DESC;
  BEGIN
    -- Implicit cursor used in a FOR loop
    -- For each airline, retrieve its flights
    FOR comp IN (SELECT ID_COMPANIE, DENUMIRE
                 FROM COMPANII_AERIENE)
    LOOP
      -- Reset index
      ind := 1;
      DBMS_OUTPUT.PUT_LINE(comp.ID_COMPANIE || '. ' || comp.DENUMIRE || ': ');
      OPEN top_z(comp.ID_COMPANIE);
      FETCH top_z INTO zborID, numb;

      -- Display the flight and number of available seats
      IF numb IS NOT NULL THEN
        LOOP
          IF numb = 1 THEN
            DBMS_OUTPUT.PUT_LINE(ind || ') Flight: ' || zborID || ' has one seat left.');
          ELSE
            DBMS_OUTPUT.PUT_LINE(ind || ') Flight: ' || zborID || ' has ' || numb || ' seats left.');
          END IF;
          ind := ind + 1;
          FETCH top_z INTO zborID, numb;
          EXIT WHEN (top_z%NOTFOUND) OR (numb IS NULL) OR (ind >= 5);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE(' ');
      ELSE
        DBMS_OUTPUT.PUT_LINE('This airline has no flights.');
        DBMS_OUTPUT.PUT_LINE(' ');
      END IF;
      CLOSE top_z;
    END LOOP;
  END;

  -- Task 3.
  FUNCTION DurataCalatorie(pasagerNume PASAGERI.NUME%type, pasagerPrenume PASAGERI.PRENUME%type)
    RETURN CHAR IS
    raspuns VARCHAR2(20);  -- Return variable
    timpMin DATE;          -- Departure time
    timpMax DATE;          -- Arrival time
    minOra NUMBER;         -- Departure hour
    maxOra NUMBER;         -- Arrival hour
    minMinute NUMBER;      -- Departure minute
    maxMinute NUMBER;      -- Arrival minute
    minute NUMBER;         -- Total minutes
    timp NUMBER := 0;      -- Total travel time in minutes

    -- Custom exceptions
    NU_EXISTA_NUME EXCEPTION;
    TIMP_GRESIT EXCEPTION;

    -- Cursor to retrieve the departure and arrival times
    CURSOR datetTimp IS
      SELECT Z.TIMP_DECOLARE, Z.TIMP_SOSIRE
      FROM ZBORURI Z
           JOIN MATEI.CALATORII C2 ON Z.ID_ZBOR = C2.ID_ZBOR
           JOIN MATEI.PASAGERI P ON P.ID_PASAGER = C2.ID_PASAGER
      WHERE P.NUME = pasagerNume AND P.PRENUME = pasagerPrenume;
  BEGIN
    OPEN datetTimp;
    FETCH datetTimp INTO timpMin, timpMax;

    IF timpMin IS NULL OR timpMax IS NULL THEN
      RAISE NU_EXISTA_NUME;
    ELSE
      LOOP
        -- Retrieve all flights the passenger has taken
        EXIT WHEN datetTimp%notfound;

        -- Extract hours and minutes
        minOra := TO_NUMBER(TO_CHAR(timpMin, 'HH24'));
        minMinute := TO_NUMBER(TO_CHAR(timpMin, 'MI'));
        maxOra := TO_NUMBER(TO_CHAR(timpMax, 'HH24'));
        maxMinute := TO_NUMBER(TO_CHAR(timpMax, 'MI'));

        -- Calculate total flight time in minutes
        timp := timp + ((maxOra * 60 + maxMinute) - (minOra * 60 + minMinute));

        FETCH datetTimp INTO timpMin, timpMax;
      END LOOP;
      CLOSE datetTimp;

      IF timp < 0 THEN
        -- Time duration should not be negative
        RAISE TIMP_GRESIT;
      ELSE
        -- Convert time to hours and minutes for output
        minute := (timp - TRUNC(timp / 60) * 60);
        IF minute > 9 THEN
          raspuns := TRUNC(timp / 60) || '.' || (timp - TRUNC(timp / 60) * 60);
        ELSE
          raspuns := TRUNC(timp / 60) || '.0' || (timp - TRUNC(timp / 60) * 60);
        END IF;
        RETURN raspuns;
      END IF;
    END IF;

  EXCEPTION
    WHEN NU_EXISTA_NUME THEN
      RAISE_APPLICATION_ERROR(-20001, 'Error: No passenger found with the name ' || pasagerNume || ' ' || pasagerPrenume || '.');
      RETURN NULL;
    WHEN TIMP_GRESIT THEN
      RAISE_APPLICATION_ERROR(-20002,'Error: Arrival and departure times are invalid.');
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20003,'Unexpected error');
      RETURN NULL;
  END;

  -- Task 4.
  PROCEDURE MedieVarsta (companieNume COMPANII_AERIENE.DENUMIRE%type) IS
    numb INTEGER;                                 -- Average age of the customers
    companieExista NUMBER := 0;                   -- Boolean check to verify if the company exists
    NU_EXISTA_COMP EXCEPTION;                     -- Custom exception for company not found
    companieID COMPANII_AERIENE.ID_COMPANIE%type; -- Company ID
  BEGIN
    -- Check if there is a company with the given name
    SELECT count(*) INTO companieExista
    FROM COMPANII_AERIENE
    WHERE DENUMIRE = companieNume;

    IF companieExista = 0 THEN
      -- If the company doesn't exist, raise a custom exception
      -- This avoids relying on NO_DATA_FOUND in case SELECT returns no rows
      RAISE NU_EXISTA_COMP;
    ELSE
      -- Calculate average age
      SELECT CA.ID_COMPANIE, avg(months_between(SYSDATE, D.ZI_DE_NASTERE) / 12)
      INTO companieID, numb
      FROM COMPANII_AERIENE CA
           JOIN MATEI.ZBORURI Z ON CA.ID_COMPANIE = Z.ID_COMPANIE
           JOIN MATEI.CALATORII C ON Z.ID_ZBOR = C.ID_ZBOR
           JOIN MATEI.PASAGERI P ON P.ID_PASAGER = C.ID_PASAGER
           JOIN MATEI.DOCUMENTE D ON D.ID_DOCUMENT = P.ID_DOCUMENT
      WHERE CA.DENUMIRE = companieNume
      GROUP BY CA.ID_COMPANIE;

      -- Display the result
      ValoriVarsta(companieID) := numb;
    END IF;

  EXCEPTION
    WHEN NU_EXISTA_COMP THEN
      RAISE_APPLICATION_ERROR(-20004, 'Error: No airline company found with the name ' || companieNume || '.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20005, 'Error: ' || companieNume || ' currently has no customers.');
    WHEN TOO_MANY_ROWS THEN
      RAISE_APPLICATION_ERROR(-20006,'Error: Multiple companies found with the same name. Try a different retrieval method.');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20007,'Unexpected error');
  END;

  -- Additional function for Task 9.
  FUNCTION NrZboruri(aeroportId AEROPORTURI.ID_AEROPORT%type)
    RETURN NUMBER IS
    raspuns NUMBER; -- Return value
  BEGIN
    -- Get the number of flights that have not yet departed
    -- based on the given airport ID
    SELECT count(ID_ZBOR) INTO raspuns
    FROM ZBORURI Z
    WHERE TO_NUMBER(TO_CHAR(Z.TIMP_DECOLARE, 'HH24')) > TO_NUMBER(TO_CHAR(SYSDATE, 'HH24'))
      AND TO_NUMBER(TO_CHAR(Z.TIMP_DECOLARE, 'MI')) > TO_NUMBER(TO_CHAR(SYSDATE, 'MI'))
      AND Z.ID_PLECARE = aeroportId;

    RETURN raspuns;
  END;
END ProiectGMC;
/

-- Task 5.
CREATE OR REPLACE TRIGGER ModificariZbor
  BEFORE DELETE ON ZBORURI
DECLARE
  oraActuala NUMBER;      -- Current hour from SYSDATE
  minActual NUMBER;       -- Current minutes from SYSDATE
  celMaiTarziuZbor DATE;  -- Latest departure time of the day
  oraTarzie NUMBER;       -- Hour of the latest flight
  minTarzie NUMBER;       -- Minutes of the latest flight
BEGIN
  -- Do not allow deletion of flights unless all flights for the day have already departed
  oraActuala := TO_NUMBER(TO_CHAR(SYSDATE, 'HH24'));
  minActual := TO_NUMBER(TO_CHAR(SYSDATE, 'MI'));

  SELECT MAX(TIMP_DECOLARE)
  INTO celMaiTarziuZbor
  FROM ZBORURI;

  oraTarzie := TO_NUMBER(TO_CHAR(celMaiTarziuZbor, 'HH24'));
  minTarzie := TO_NUMBER(TO_CHAR(celMaiTarziuZbor, 'MI'));

  IF (oraActuala < oraTarzie) OR ((oraActuala = oraTarzie) AND (minActual < minTarzie)) THEN
    RAISE_APPLICATION_ERROR(-20008, 'Flights can only be deleted after the last flight of the day has departed.');
  END IF;
END;
/

-- Task 6.
CREATE OR REPLACE TRIGGER VerificaDateDocument
  BEFORE UPDATE OF AN_VALIDARE, AN_EXPIRARE ON DOCUMENTE
  FOR EACH ROW
DECLARE
  anNouValidare NUMBER;   -- Year from the new validation date
  anNouExpirare NUMBER;   -- Year from the new expiration date
  anVechiValidare NUMBER; -- Year from the old validation date
  anVechiExpirare NUMBER; -- Year from the old expiration date
BEGIN
  -- Extract years from the old and new values
  anNouValidare := EXTRACT(YEAR FROM :NEW.AN_VALIDARE);
  anNouExpirare := EXTRACT(YEAR FROM :NEW.AN_EXPIRARE);
  anVechiValidare := EXTRACT(YEAR FROM :OLD.AN_VALIDARE);
  anVechiExpirare := EXTRACT(YEAR FROM :OLD.AN_EXPIRARE);

  -- New dates must not be earlier than the old dates
  IF (anNouValidare < anVechiValidare) OR (anNouExpirare < anVechiExpirare) THEN
    RAISE_APPLICATION_ERROR(-20009, 'New dates must be later than the old ones.');
  END IF;
END;
/

-- Task 7.
CREATE OR REPLACE TRIGGER InainteDeDropDown
  BEFORE DROP ON SCHEMA
DECLARE
  table_name VARCHAR2(30);
BEGIN
  -- Get the name of the table that is about to be dropped
  table_name := ORA_DICT_OBJ_NAME;

  -- Dropping tables is not allowed
  RAISE_APPLICATION_ERROR(-20000, 'Dropping the table ' || table_name || ' is not allowed.');
END;
/

---------------------------------------------------------------------------------------------------------------
-- Project Testing
---------------------------------------------------------------------------------------------------------------

-- Task 1
BEGIN
  ProiectGMC.NrPasageri();
END;
/

-- Task 2
BEGIN
  ProiectGMC.LocuriLibere();
END;
/

-- Task 3
DECLARE
  raspuns VARCHAR2(10);
BEGIN
  FOR pas IN (SELECT NUME, PRENUME FROM PASAGERI) LOOP
      raspuns := ProiectGMC.DurataCalatorie(pas.NUME, pas.PRENUME);
      DBMS_OUTPUT.PUT_LINE(pas.NUME || ' ' || pas.PRENUME || ' has a total travel time of: ' || raspuns || ' hours');
  END LOOP;
END;
/

-- EXCEPTION: NAME DOES NOT EXIST
DECLARE
  raspuns VARCHAR2(10);
BEGIN
  raspuns := ProiectGMC.DurataCalatorie('Antoneta', 'Maria');
  DBMS_OUTPUT.PUT_LINE('Antoneta Maria has a total travel time of: ' || raspuns || ' hours');
END;
/

-- EXCEPTION: INVALID TIME (TIMP GRESIT)
DECLARE
  raspuns VARCHAR2(10);
BEGIN
  UPDATE ZBORURI
  SET TIMP_SOSIRE = TO_DATE('2023-05-26 05:00:00', 'YYYY-MM-DD HH24:MI:SS')
  WHERE ID_ZBOR = 20;

  raspuns := ProiectGMC.DurataCalatorie('Doe', 'John');
  DBMS_OUTPUT.PUT_LINE('Doe John has a total travel time of: ' || raspuns || ' hours');
  ROLLBACK;
END;
/

-- Task 4
DECLARE
  companienume COMPANII_AERIENE.DENUMIRE%type := 'Pacific Wings';
  companieID COMPANII_AERIENE.ID_COMPANIE%type := 5677;
BEGIN
  ProiectGMC.MedieVarsta(companienume);
  DBMS_OUTPUT.PUT_LINE('The company ' || companienume || ', with ID ' || companieID ||
                       ', has an average customer age of ' || ProiectGMC.ValoriVarsta(companieID) || '.');
END;
/

-- EXCEPTION: COMPANY DOES NOT EXIST
DECLARE
  companienume COMPANII_AERIENE.DENUMIRE%type := 'DANAir';
  companieID COMPANII_AERIENE.ID_COMPANIE%type := 5679;
BEGIN
  ProiectGMC.MedieVarsta(companienume);
  DBMS_OUTPUT.PUT_LINE('The company ' || companienume || ', with ID ' || companieID ||
                       ', has an average customer age of ' || ProiectGMC.ValoriVarsta(companieID) || '.');
END;
/

-- EXCEPTION: NO DATA FOUND
DECLARE
  companienume COMPANII_AERIENE.DENUMIRE%type := 'Airline One';
  companieID COMPANII_AERIENE.ID_COMPANIE%type := 5673;
BEGIN
  ProiectGMC.MedieVarsta(companienume);
  DBMS_OUTPUT.PUT_LINE('The company ' || companienume || ', with ID ' || companieID ||
                       ', has an average customer age of ' || ProiectGMC.ValoriVarsta(companieID) || '.');
END;
/

-- EXCEPTION: TOO MANY ROWS
DECLARE
  companienume COMPANII_AERIENE.DENUMIRE%type := 'AirExpress';
  companieID COMPANII_AERIENE.ID_COMPANIE%type := 5676;
BEGIN
  ProiectGMC.MedieVarsta(companienume);
  DBMS_OUTPUT.PUT_LINE('The company ' || companienume || ', with ID ' || companieID ||
                       ', has an average customer age of ' || ProiectGMC.ValoriVarsta(companieID) || '.');
END;
/

-- Task 9
BEGIN
  FOR aer IN (SELECT ID_AEROPORT, NUME FROM AEROPORTURI) LOOP
    DBMS_OUTPUT.PUT_LINE(aer.NUME || ' has ' || ProiectGMC.NrZboruri(aer.ID_AEROPORT) ||
                         ' flights yet to depart');
  END LOOP;
END;
/

-- Task 5 (Trigger test - statement-level)
DELETE FROM ZBORURI
WHERE ID_ZBOR = 21;
/

-- Task 6 (Trigger test - row-level)
-- Invalid update (NEW.AN_VALIDARE is earlier than OLD.AN_VALIDARE)
UPDATE DOCUMENTE
SET AN_VALIDARE = TO_DATE('2021-01-01', 'YYYY-MM-DD')
WHERE ID_DOCUMENT = 1;
/

-- Invalid update (NEW.AN_EXPIRARE is earlier than OLD.AN_EXPIRARE)
UPDATE DOCUMENTE
SET AN_EXPIRARE = TO_DATE('2022-01-01', 'YYYY-MM-DD')
WHERE ID_DOCUMENT = 1;
/

-- Task 7 (DDL Trigger)
CREATE TABLE TestTable (
    ID NUMBER PRIMARY KEY,
    Name VARCHAR2(50),
    Description VARCHAR2(255)
);

DROP TABLE TestTable;