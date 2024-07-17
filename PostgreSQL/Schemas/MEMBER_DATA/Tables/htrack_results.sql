CREATE TABLE IF NOT EXISTS htrack_results
(
  member_id               BIGINT NOT NULL,
  result_key              BIGINT NOT NULL,
  measurement_date        DATE NOT NULL,
  element_key             INT NOT NULL,
  measurement_key         INT NOT NULL,
  numeric_value           NUMERIC,
  text_value              VARCHAR(40),
  med_help_id             VARCHAR(60) NOT NULL,
  device_type             VARCHAR(255),
  vendor_source           VARCHAR(50),
  inserted_by             VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  inserted_dt             TIMESTAMP(0) DEFAULT CURRENT_TIMESTAMP,
  updated_by              VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt              TIMESTAMP(0) DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(member_id);

ALTER TABLE htrack_results OWNER to postgres;

COMMENT ON TABLE htrack_results IS 'Results of mesurements made by Health Tracker devices used by Members';