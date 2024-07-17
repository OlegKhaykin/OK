CREATE TYPE typ_drug_usage AS
(
  drug_usage_key            BIGINT,
  fill_date                 DATE,
  drug_cd                   VARCHAR(20),
  code_set_type             VARCHAR(10),
  dosage                    VARCHAR(50),
  status                    VARCHAR(255),
  change_reason             VARCHAR(255),
  non_compliant             CHAR(1),
  non_compliant_reason      VARCHAR(255),
  update_source             VARCHAR(20)
);

ALTER TYPE typ_prescription OWNER TO postgres;