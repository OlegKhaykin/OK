CREATE OR REPLACE PACKAGE pkg_math AS
/*
  2023-01-04, O. Khaykin (OK): created
*/
  TYPE typ_tab_tab_v256 IS TABLE OF tab_v256;
  
  FUNCTION factorial(p_num IN SIMPLE_INTEGER) RETURN SIMPLE_INTEGER;
  
  -- Function VARIATIONS returns all possible non-repeating Variations of placing the given Items on the given Places.
  FUNCTION variations
  (
    p_items       IN VARCHAR2,
    p_num_places  IN SIMPLE_INTEGER
  ) 
  RETURN typ_tab_tab_v256 PIPELINED;
END;
/

CREATE OR REPLACE SYNONYM math FOR pkg_math;

GRANT EXECUTE ON pkg_math TO PUBLIC;