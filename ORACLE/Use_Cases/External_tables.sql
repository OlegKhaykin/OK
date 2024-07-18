CREATE TABLE att_calls_ext
(
  num NUMBER(4),
  call_datetime VARCHAR2(40),
  call_number VARCHAR2(200),
  call_place VARCHAR2(200),
  quantity NUMBER(3),
  unit VARCHAR2(200),
  rate NUMBER,
  descriptions VARCHAR2(2000),
  charges NUMBER
)
ORGANIZATION EXTERNAL
(
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY external
  ACCESS PARAMETERS
  (
    RECORDS DELIMITED BY NEWLINE SKIP 1
    FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' AND '"' MISSING FIELD VALUES ARE NULL
    (
      num INTEGER EXTERNAL(4),
      call_date CHAR,
      call_time CHAR,
      call_number CHAR,
      call_place CHAR,
      quantity INTEGER EXTERNAL(4),
      unit CHAR,
      rate FLOAT EXTERNAL,
      descriptions CHAR,
      charges FLOAT EXTERNAL
    )
    COLUMN TRANSFORMS
    (
      call_datetime FROM CONCAT (call_date, CONSTANT " ", call_time, CONSTANT "M")
    )
  )
  LOCATION ('9083913022.csv')
)
