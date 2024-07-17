CREATE TABLE IF NOT EXISTS reference_codes
(
  code_group    VARCHAR(12) NOT NULL,
  code          VARCHAR(12) NOT NULL,
  description   VARCHAR(255),
  inserted_by   VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  inserted_dt   TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by    VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt    TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_reference_codes PRIMARY KEY(code_group, code)
);

ALTER TABLE reference_codes OWNER TO postgres;
