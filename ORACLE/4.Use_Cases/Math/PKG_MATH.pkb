CREATE OR REPLACE PACKAGE BODY pkg_math AS
  FUNCTION factorial(p_num IN SIMPLE_INTEGER) RETURN SIMPLE_INTEGER IS
    ret SIMPLE_INTEGER := 1;
  BEGIN
    IF p_num > 1 THEN
      FOR i IN 2..p_num LOOP
        ret := ret * i;
      END LOOP;
    END IF;
    
    RETURN ret;
  END;
  
  -- Function VARIATIONS returns all possible non-repeating Variations of placing the given Items on the given Places.
  FUNCTION variations(p_items IN VARCHAR2, p_num_places IN SIMPLE_INTEGER) RETURN typ_tab_tab_v256 PIPELINED IS
  
    TYPE typ_table_of_int IS TABLE OF PLS_INTEGER;

    t_items   tab_v256;
    idx       typ_table_of_int;
    
    n_items   PLS_INTEGER;
    ni        PLS_INTEGER;
    np        PLS_INTEGER;
    nr        PLS_INTEGER;
    
    t_res     typ_tab_tab_v256;
    
    PROCEDURE arrange(sp IN SIMPLE_INTEGER) IS
    BEGIN
      FOR i IN 1..ni LOOP
        FOR k IN sp..np LOOP idx(k) := 0; END LOOP;
        
        IF i NOT MEMBER OF idx THEN
          idx(sp) := i;
          
          IF sp < np THEN
            arrange(sp+1);
          ELSE
            t_res.EXTEND;
            nr := nr+1;
            t_res(nr) := tab_v256();
            t_res(nr).EXTEND(p_num_places);
            
            FOR n IN 1..np LOOP
              IF n_items < p_num_places THEN
                t_res(nr)(idx(n)) := t_items(n);
              ELSE
                t_res(nr)(n) := t_items(idx(n));
              END IF;
            END LOOP;
          END IF;
        END IF;
      END LOOP;
    END;
    
  BEGIN
    t_items := split_string(p_items);
    n_items := t_items.COUNT;
    
    IF n_items < p_num_places THEN
      ni := p_num_places;
      np := n_items;
    ELSE
      ni := n_items;
      np := p_num_places;
    END IF;
    
    idx := typ_table_of_int();
    idx.EXTEND(np);
    
    t_res := typ_tab_tab_v256();
    nr := 0;
    arrange(1);
    
    FOR n in 1..nr LOOP
      PIPE ROW(t_res(n));
    END LOOP;
  END;
END;
/