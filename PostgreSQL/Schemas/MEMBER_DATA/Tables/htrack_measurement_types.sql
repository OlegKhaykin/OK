CREATE TABLE IF NOT EXISTS htrack_measurement_types
(
  measurement_key         INT NOT NULL CONSTRAINT pk_htrack_measurement_types PRIMARY KEY,
  measurement_type        VARCHAR(40)   NOT NULL,
  measurement_sub_type    VARCHAR(40)   NOT NULL,
  unit_of_measure         VARCHAR(30),
  non_numeric_flag        CHAR(1)       NOT NULL CONSTRAINT chk_hlth_trck_msr_type_non_num CHECK(non_numeric_flag IN ('Y','N')),
  inserted_by             VARCHAR(30)   NOT NULL DEFAULT SESSION_USER,
  inserted_dt             TIMESTAMP(0)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by              VARCHAR(30)   NOT NULL DEFAULT SESSION_USER,
  updated_dt              TIMESTAMP(0)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_htrack_measurement_types UNIQUE(measurement_type, measurement_sub_type)
);

ALTER TABLE htrack_measurement_types OWNER to postgres;

COMMENT ON TABLE htrack_measurement_types IS 'Types of Measurements that can be performed by Health Tracker devices used by Members';