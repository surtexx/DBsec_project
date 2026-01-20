-- 2. Data Encryption

ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER SYSTEM SET "_TABLESPACE_ENCRYPTION_DEFAULT_ALGORITHM" = 'AES256' SCOPE = BOTH SID = '*';
ALTER SYSTEM SET WALLET_ROOT = 'C:\Users\rober\Desktop\oracle19c\admin\wallet' SCOPE = SPFILE SID = '*';
ALTER SYSTEM SET TDE_CONFIGURATION="KEYSTORE_CONFIGURATION=FILE" SCOPE = BOTH SID = '*';
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY MyPassword; -- ran from cmd as sysdba
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY MyPassword; -- ran from cmd as sysdba
SELECT STATUS FROM V$ENCRYPTION_WALLET;
ADMINISTER KEY MANAGEMENT SET KEY FORCE KEYSTORE IDENTIFIED BY MyPassword WITH BACKUP USING 'emp_key_backup'; -- ran from cmd as sysdba
ALTER TABLE SPONSOR MODIFY (VENIT_ANUAL NUMBER ENCRYPT);
SELECT ENCRYPTION_ALG
FROM dba_encrypted_columns
WHERE table_name = 'SPONSOR';
ALTER SESSION SET CONTAINER = dbsecdb2;

-- 3. Database activity Auditing
--  a. Standard Auditing
AUDIT SESSION;

AUDIT INSERT, DELETE ON PARTIDA BY ACCESS;

-- Test
INSERT INTO PARTIDA VALUES(177, 176, 160, 27, 4, 3, 48519);
DELETE FROM PARTIDA WHERE id_partida=177;
select COUNT(*) from dba_audit_trail where obj_name = 'PARTIDA';

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

create or replace procedure proc_audit as
begin
    dbms_fga.add_policy(
        object_schema => 'SYSTEM',
        object_name => 'CAMPIONAT',
        policy_name => 'campionat_policy',
        enable => false,
        statement_types => 'INSERT,UPDATE'
    );
end;
/
execute proc_audit;
begin
    dbms_fga.enable_policy(
        object_schema => 'SYSTEM',
        object_name => 'CAMPIONAT',
        policy_name => 'campionat_policy'
    );
end;
/

-- Test
INSERT INTO SYSTEM.CAMPIONAT(id_campionat, tara, an_infiintare_campionat, rang) VALUES (8, 'test', 1999, 1); -- ca alt user decat system (test_adm)
DELETE FROM SYSTEM.CAMPIONAT where ID_CAMPIONAT = 8; -- ca alt user decat system (test_adm)
select db_user, userhost, policy_name, timestamp, sql_text
from dba_fga_audit_trail where db_user = 'TEST_ADM';

-- 4. Management of Database Users and Computational Resources
--  b. Implementing the identity management configuration in the database

CREATE USER adm1 IDENTIFIED BY adm1;
CREATE USER adm2 IDENTIFIED BY adm2;
CREATE USER adm3 IDENTIFIED BY adm3;
CREATE USER mod1 IDENTIFIED BY mod1;
CREATE USER mod2 IDENTIFIED BY mod2;
CREATE USER mod3 IDENTIFIED BY mod3;

CREATE PROFILE profil_admin LIMIT
    SESSIONS_PER_USER 1
    PASSWORD_LIFE_TIME 60
    FAILED_LOGIN_ATTEMPTS 3
    CPU_PER_CALL 7000
    IDLE_TIME 10;

CREATE PROFILE profil_moderator limit
    SESSIONS_PER_USER 2
    PASSWORD_LIFE_TIME 60
    FAILED_LOGIN_ATTEMPTS 3
    CPU_PER_CALL 7000
    IDLE_TIME 10;
    
ALTER USER adm1 profile profil_admin;
ALTER USER adm2 profile profil_admin;
ALTER USER adm3 profile profil_admin;
ALTER USER mod1 profile profil_moderator;
ALTER USER mod2 profile profil_moderator;
ALTER USER mod3 profile profil_moderator;

-- 5. Privileges and Roles

CREATE ROLE admin_campionat;
CREATE ROLE admin_echipa;
CREATE ROLE admin_jucator;
CREATE ROLE moderator_campionat;
CREATE ROLE moderator_echipa;
CREATE ROLE moderator_jucator;
CREATE ROLE readonly_user;

GRANT CREATE SESSION TO admin_campionat;
GRANT CREATE SESSION TO admin_echipa;
GRANT CREATE SESSION TO admin_jucator;
GRANT CREATE SESSION TO moderator_campionat;
GRANT CREATE SESSION TO moderator_echipa;
GRANT CREATE SESSION TO moderator_jucator;
GRANT CREATE SESSION TO readonly_user;

GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.CAMPIONAT TO admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.SPONSOR TO admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.STADION TO admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.DIVIZIE TO admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.ARBITRU TO admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.PARTIDA TO admin_campionat;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.ARBITRU_PARTIDA TO admin_campionat; -- example of c.	Privileges on dependent objects
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.ECHIPA TO admin_campionat;

GRANT SELECT, INSERT, UPDATE, DELETE ON ECHIPA TO admin_echipa;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.ANTRENOR TO admin_echipa;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.LICENTA TO admin_echipa;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.JUCATOR TO admin_echipa;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.STATISTICI_INDIVIDUALE TO admin_echipa;

GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.JUCATOR TO admin_jucator;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYSTEM.STATISTICI_INDIVIDUALE TO admin_jucator;

GRANT SELECT, INSERT, UPDATE ON SYSTEM.CAMPIONAT TO moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.SPONSOR TO moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.STADION TO moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.DIVIZIE TO moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.ARBITRU TO moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.PARTIDA TO moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.ARBITRU_PARTIDA TO moderator_campionat;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.ECHIPA TO moderator_campionat;

GRANT SELECT, INSERT, UPDATE ON SYSTEM.ECHIPA TO moderator_echipa;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.ANTRENOR TO moderator_echipa;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.LICENTA TO moderator_echipa;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.JUCATOR TO moderator_echipa;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.STATISTICI_INDIVIDUALE TO moderator_echipa;

GRANT SELECT, INSERT, UPDATE ON SYSTEM.JUCATOR TO moderator_jucator;
GRANT SELECT, INSERT, UPDATE ON SYSTEM.STATISTICI_INDIVIDUALE TO moderator_jucator;

GRANT SELECT ON SYSTEM.CAMPIONAT TO readonly_user;
GRANT SELECT ON SYSTEM.SPONSOR TO readonly_user;
GRANT SELECT ON SYSTEM.STADION TO readonly_user;
GRANT SELECT ON SYSTEM.DIVIZIE TO readonly_user;
GRANT SELECT ON SYSTEM.ARBITRU TO readonly_user;
GRANT SELECT ON SYSTEM.PARTIDA TO readonly_user;
GRANT SELECT ON SYSTEM.ARBITRU_PARTIDA TO readonly_user;
GRANT SELECT ON SYSTEM.ECHIPA TO readonly_user;
GRANT SELECT ON SYSTEM.ANTRENOR TO readonly_user;
GRANT SELECT ON SYSTEM.LICENTA TO readonly_user;
GRANT SELECT ON SYSTEM.JUCATOR TO readonly_user;
GRANT SELECT ON SYSTEM.STATISTICI_INDIVIDUALE TO readonly_user;

GRANT readonly_user TO moderator_jucator; -- example of b. Privileges hierarchies
GRANT readonly_user TO moderator_echipa;
GRANT readonly_user TO moderator_campionat;

GRANT moderator_jucator TO admin_jucator;
GRANT moderator_echipa TO admin_echipa;
GRANT moderator_campionat TO admin_campionat;

GRANT admin_campionat TO adm1;
GRANT admin_echipa TO adm2;
GRANT admin_jucator TO adm3;
GRANT moderator_campionat TO mod1;
GRANT moderator_echipa TO mod2;
GRANT moderator_jucator TO mod3

-- Test
INSERT INTO SYSTEM.JUCATOR VALUES(10000, 'Ederson Moraes', 1, 'portar', 1, 'drept'); -- as mod3
DELETE FROM SYSTEM.JUCATOR where id_jucator = 10000 -- won't work as mod3, but as adm3 yes

-- 6. Database Applications and Data Security
--  b. SQL Injection

CREATE OR REPLACE PROCEDURE get_echipa_vulnerabil (
    p_nume_echipa IN VARCHAR2
) IS
    v_sql   VARCHAR2(4000);
    c       SYS_REFCURSOR;
    v_nume  ECHIPA.nume_echipa%TYPE;
BEGIN
    v_sql := 'SELECT nume_echipa FROM ECHIPA WHERE nume_echipa = '''
             || p_nume_echipa || '''';

    DBMS_OUTPUT.PUT_LINE('Execut: ' || v_sql);

    OPEN c FOR v_sql;
    LOOP
        FETCH c INTO v_nume;
        EXIT WHEN c%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Echipa: ' || v_nume);
    END LOOP;
    CLOSE c;
END;
/

-- Test
SET SERVEROUTPUT ON;

-- Vulnerabil
BEGIN
    get_echipa_vulnerabil(''' OR 1=1 --');
END;
/

-- Sigur
BEGIN
    get_echipa_vulnerabil('Borussia Dortmund');
END;
/

-- 7. Data masking

CREATE OR REPLACE DIRECTORY masking_dir AS 'C:\Users\rober\Desktop\oracle19c\admin\mask';
GRANT READ, WRITE ON directory masking_dir TO admin_campionat;
GRANT READ, WRITE ON directory masking_dir TO admin_echipa;
GRANT READ, WRITE ON directory masking_dir TO admin_jucator;
GRANT READ, WRITE ON directory masking_dir TO moderator_campionat;
GRANT READ, WRITE ON directory masking_dir TO C#moderator_echipa;
GRANT READ, WRITE ON directory masking_dir TO moderator_jucator;

CREATE OR REPLACE PACKAGE data_masking is
    FUNCTION masking_nume_sponsor(nume VARCHAR2) return VARCHAR2;
    FUNCTION masking_venit_anual_sponsor(venit_anual NUMBER) return VARCHAR2;
end;
/

CREATE OR REPLACE PACKAGE BODY data_masking IS
  FUNCTION masking_nume_sponsor (nume VARCHAR2) return VARCHAR2 IS
    v_nume VARCHAR2(100);
    v_len NUMBER;
  BEGIN
        v_nume := SUBSTR(nume, 1, 1);
        SELECT LENGTH(nume) INTO v_len from dual;
        v_nume := RPAD(v_nume, v_len, '*');
        return v_nume;
  END masking_nume_sponsor;
  
  FUNCTION masking_venit_anual_sponsor (venit_anual NUMBER) return VARCHAR2 IS
    v_len NUMBER;
  BEGIN
    v_len := TRUNC(DBMS_RANDOM.VALUE(3, 11));
    RETURN RPAD('$', v_len, '$');
  END masking_venit_anual_sponsor;
END;
/

-- Test
SELECT data_masking.masking_nume_sponsor('Test') FROM dual;
SELECT data_masking.masking_venit_anual_sponsor('1700000') FROM dual;
