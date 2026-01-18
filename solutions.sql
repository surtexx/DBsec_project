-- 2. Data Encryption TODO

ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER SYSTEM SET "_TABLESPACE_ENCRYPTION_DEFAULT_ALGORITHM" = 'AES256' SCOPE = BOTH SID = '*';
ALTER SYSTEM SET WALLET_ROOT = 'C:\Users\rober\Desktop\oracle19c\admin\wallet' SCOPE = SPFILE SID = '*';
ALTER SYSTEM SET TDE_CONFIGURATION="KEYSTORE_CONFIGURATION=FILE" SCOPE = BOTH SID = '*';
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY MyPassword; -- ran from cmd as sysdba
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY MyPassword; -- ran from cmd as sysdba
SELECT STATUS FROM V$ENCRYPTION_WALLET;
ADMINISTER KEY MANAGEMENT SET KEY FORCE KEYSTORE IDENTIFIED BY MyPassword WITH BACKUP USING 'emp_key_backup'; -- ran from cmd as sysdba
ALTER TABLE SPONSOR MODIFY (VENIT_ANUAL NUMBER ENCRYPT);
SELECT *
FROM dba_encrypted_columns
WHERE table_name = 'SPONSOR';
ALTER SESSION SET CONTAINER = dbsecdb2;

-- 3. Database activity Auditing
--  a. Standard Auditing

AUDIT SESSION;

AUDIT INSERT, DELETE ON PARTIDA BY ACCESS;

-- Test
INSERT INTO PARTIDA
VALUES(177, 176, 160, 27, 4, 3, 48519);
DELETE FROM PARTIDA WHERE id_partida=177;
SELECT ACTION_NAME, OBJ_NAME FROM dba_audit_trail;

--  b.	Audit Triggers

CREATE TABLE echipa_audit_log (
    user_name VARCHAR2(30),
    action VARCHAR2(10),
    id_echipa NUMBER,
    data_modificare DATE
);

CREATE OR REPLACE TRIGGER audit_echipa_changes
AFTER INSERT OR UPDATE OR DELETE ON ECHIPA
FOR EACH ROW
DECLARE
    v_actiune   VARCHAR2(10);
    v_id_echipa NUMBER;
BEGIN
    IF INSERTING THEN
        v_actiune   := 'INSERT';
        v_id_echipa := :NEW.id_echipa;
    ELSIF UPDATING THEN
        v_actiune   := 'UPDATE';
        v_id_echipa := :NEW.id_echipa;
    ELSIF DELETING THEN
        v_actiune   := 'DELETE';
        v_id_echipa := :OLD.id_echipa;
    END IF;

    INSERT INTO echipa_audit_log (
        user_name,
        action,
        id_echipa,
        data_modificare
    )
    VALUES (
        USER,
        v_actiune,
        v_id_echipa,
        SYSDATE
    );
END;
/

-- Test
INSERT INTO ECHIPA VALUES(177, 1, 'test', 1999, 2, 2);
DELETE FROM ECHIPA WHERE id_echipa=177;
SELECT * FROM echipa_audit_log;

--  c.	Audit Policies
CREATE AUDIT POLICY campionat_policy
  ACTIONS INSERT, UPDATE, DELETE ON CAMPIONAT;

AUDIT POLICY campionat_policy BY PUBLIC;

-- Test

INSERT INTO CAMPIONAT(id_campionat, tara, an_infiintare_campionat, rang) VALUES (8, 'test', 1999, 1);
DELETE FROM CAMPIONAT where ID_CAMPIONAT = 8;
SELECT *
FROM UNIFIED_AUDIT_TRAIL
WHERE object_name = 'CAMPIONAT';

-- 4. Management of Database Users and Computational Resources
--  b. Implementing the identity management configuration in the database

-- 5. Privileges and Roles

CREATE ROLE C##admin_campionat;
CREATE ROLE C##admin_echipa;
CREATE ROLE C##admin_jucator;
CREATE ROLE C##moderator_campionat;
CREATE ROLE C##moderator_echipa;
CREATE ROLE C##moderator_jucator;
CREATE ROLE C##readonly_user;

GRANT CREATE SESSION TO C##admin_campionat;
GRANT CREATE SESSION TO C##admin_echipa;
GRANT CREATE SESSION TO C##admin_jucator;
GRANT CREATE SESSION TO C##moderator_campionat;
GRANT CREATE SESSION TO C##moderator_echipa;
GRANT CREATE SESSION TO C##moderator_jucator;
GRANT CREATE SESSION TO C##readonly_user;

GRANT SELECT, INSERT, UPDATE, DELETE ON CAMPIONAT TO C##admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON SPONSOR TO C##admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON STADION TO C##admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON DIVIZIE TO C##admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON ARBITRU TO C##admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON PARTIDA TO C##admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON ARBITRU_PARTIDA TO C##admin_campionat; -- example of c.	Privileges on dependent objects
GRANT SELECT, INSERT, UPDATE, DELETE ON ECHIPA TO C##admin_campionat;

GRANT SELECT, INSERT, UPDATE, DELETE ON ECHIPA TO C##admin_echipa;
GRANT SELECT, INSERT, UPDATE, DELETE ON ANTRENOR TO C##admin_echipa;
GRANT SELECT, INSERT, UPDATE, DELETE ON LICENTA TO C##admin_echipa;
GRANT SELECT, INSERT, UPDATE, DELETE ON JUCATOR TO C##admin_echipa;
GRANT SELECT, INSERT, UPDATE, DELETE ON STATISTICI_INDIVIDUALE TO C##admin_echipa;

GRANT SELECT, INSERT, UPDATE, DELETE ON JUCATOR TO C##admin_jucator;
GRANT SELECT, INSERT, UPDATE, DELETE ON STATISTICI_INDIVIDUALE TO C##admin_jucator;

GRANT SELECT, INSERT, UPDATE ON CAMPIONAT TO C##moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON SPONSOR TO C##moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON STADION TO C##moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON DIVIZIE TO C##moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON ARBITRU TO C##moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON PARTIDA TO C##moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON ARBITRU_PARTIDA TO C##moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON ECHIPA TO C##moderator_campionat;

GRANT SELECT, INSERT, UPDATE ON ECHIPA TO C##moderator_echipa;
GRANT SELECT, INSERT, UPDATE ON ANTRENOR TO C##moderator_echipa;
GRANT SELECT, INSERT, UPDATE ON LICENTA TO C##moderator_echipa;
GRANT SELECT, INSERT, UPDATE ON JUCATOR TO C##moderator_echipa;
GRANT SELECT, INSERT, UPDATE ON STATISTICI_INDIVIDUALE TO C##moderator_echipa;

GRANT SELECT, INSERT, UPDATE ON JUCATOR TO C##moderator_jucator;
GRANT SELECT, INSERT, UPDATE ON STATISTICI_INDIVIDUALE TO C##moderator_jucator;

GRANT SELECT ON CAMPIONAT TO C##readonly_user;
GRANT SELECT ON SPONSOR TO C##readonly_user;
GRANT SELECT ON STADION TO C##readonly_user;
GRANT SELECT ON DIVIZIE TO C##readonly_user;
GRANT SELECT ON ARBITRU TO C##readonly_user;
GRANT SELECT ON PARTIDA TO C##readonly_user;
GRANT SELECT ON ARBITRU_PARTIDA TO C##readonly_user;
GRANT SELECT ON ECHIPA TO C##readonly_user;
GRANT SELECT ON ANTRENOR TO C##readonly_user;
GRANT SELECT ON LICENTA TO C##readonly_user;
GRANT SELECT ON JUCATOR TO C##readonly_user;
GRANT SELECT ON STATISTICI_INDIVIDUALE TO C##readonly_user;

GRANT C##readonly_user TO C##moderator_jucator; -- example of b. Privileges hierarchies
GRANT C##readonly_user TO C##moderator_echipa;
GRANT C##readonly_user TO C##moderator_campionat;

GRANT C##moderator_jucator TO C##admin_jucator;
GRANT C##moderator_echipa TO C##admin_echipa;
GRANT C##moderator_campionat TO C##admin_campionat;

-- Test
SELECT * 
FROM dba_tab_privs
WHERE grantee IN (
  'C##READONLY_USER',
  'C##MODERATOR_JUCATOR',
  'C##ADMIN_JUCATOR'
);

-- 6. Database Applications and Data Security