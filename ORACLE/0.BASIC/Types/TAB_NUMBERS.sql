CREATE OR REPLACE TYPE tab_numbers AS TABLE OF NUMBER;
/
CREATE OR REPLACE PUBLIC SYNONYM tab_numbers FOR tab_numbers;
GRANT EXECUTE ON tab_numbers TO PUBLIC;