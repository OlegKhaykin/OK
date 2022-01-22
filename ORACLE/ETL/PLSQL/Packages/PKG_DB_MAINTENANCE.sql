CREATE OR REPLACE PACKAGE pkg_db_maintenance AS 
  PROCEDURE add_columns(p_column_definitions IN VARCHAR2, p_table_list IN VARCHAR2);
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_db_maintenance AS 
  PROCEDURE add_columns(p_column_definitions IN VARCHAR2, p_table_list IN VARCHAR2) IS
  BEGIN
    etladmin.pkg_db_maintenance.add_columns(p_column_definitions, p_table_list);
  END;
END;
/

CREATE OR REPLACE SYNONYM dbm FOR pkg_db_maintenance;

BEGIN
  FOR r IN
  (
    SELECT role FROM dba_roles
    WHERE role = 'DEPLOYER'
  )
  LOOP
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON dbm TO '||r.role;
  END LOOP;
END;
/
