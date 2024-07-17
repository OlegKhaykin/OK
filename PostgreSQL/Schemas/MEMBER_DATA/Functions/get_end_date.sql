CREATE OR REPLACE FUNCTION get_end_date() RETURNS DATE
LANGUAGE PLPGSQL STRICT SECURITY DEFINER SET search_path TO 'member_data' AS $$
DECLARE
  ret DATE;
BEGIN
  ret := TO_DATE(CURRENT_SETTING('he.end_date'), 'YYYY-MM-DD');
  
  RETURN CASE WHEN ret > DATE '0001-01-01' THEN ret ELSE DATE '9999-12-31' END;
EXCEPTION
 WHEN OTHERS THEN
  IF SQLSTATE = '42704' THEN
    RETURN DATE '9999-12-31';
  ELSE
    RAISE;
  END IF;
END $$;