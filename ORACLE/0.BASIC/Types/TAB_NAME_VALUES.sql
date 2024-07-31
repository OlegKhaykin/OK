CREATE OR REPLACE TYPE obj_name_value AS OBJECT
(
  name  VARCHAR2(30),
  value VARCHAR2(1000)
);
/

GRANT EXECUTE ON obj_name_value TO PUBLIC;

CREATE OR REPLACE TYPE tab_name_values AS TABLE OF obj_name_value;
/
GRANT EXECUTE ON tab_name_values TO PUBLIC;
