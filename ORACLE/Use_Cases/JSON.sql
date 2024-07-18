CREATE TABLE tst_ok_json
(
  id RAW (16) NOT NULL,
  date_loaded TIMESTAMP(6) WITH TIME ZONE,
  po_document CLOB CONSTRAINT ensure_json CHECK (po_document IS JSON)
);

INSERT INTO j_purchaseorder
VALUES 
(
  SYS_GUID(),
  SYSTIMESTAMP,
  '{
    "PONumber" : 1600,
    "Reference" : "ABULL-20140421",
    "Requestor" : "Alexis Bull",
    "User" : "ABULL",
    "CostCenter" : "A50",
    "ShippingInstructions": 
    {
      "name" : "Alexis Bull",
      "Address":
      {
        "street" : "200 Sporting Green",
        "city" : "South San Francisco",
        "state" : "CA",
        Chapter 7
        "zipCode" : 99236,
        "country" : "United States of America"},
        "Phone" : 
        [
          {"type" : "Office", "number" : "909-555-7307"},
          {"type" : "Mobile", "number" : "415-555-1234"}
        ]
      },
      "Special Instructions" : null,
      "AllowPartialShipment" : true,
      "LineItems" : 
      [
        {
          "ItemNumber" : 1,
          "Part" : {"Description" : "One Magic Christmas", "UnitPrice" : 19.95, "UPCCode" : 13131092899},
          "Quantity" : 9.0},
  {"ItemNumber" : 2,
  "Part" : {"Description" : "Lethal Weapon",
  "UnitPrice" : 19.95,
  "UPCCode" : 85391628927},
  "Quantity" : 5.0}]}'
);

drop function get_column_definition(p_col_dfn in varchar2) return obj_column_definition as
  ret obj_column_definition;
begin
  execute immediate 'begin :ret := obj_column_definition('''||replace(p_col_dfn, ':', ''',''')||'''); end;' using out ret;
  return ret;
end;
/
 
select q.cdef.name column_name, q.cdef.data_type data_type, q.cdef.nullable nullable
from
(
  select get_column_definition(column_value) cdef
  from table(split_string('NAME:VARCHAR2(30):NOT NULL,DOB:DATE:NULL'))
) q;


select d.*
from
(select 'SSN' column_name from dual) d
join user_tab_columns utc
  on utc.table_name = 'WHATEVER'
 and utc.column_name = d.column_name;