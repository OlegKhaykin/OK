CREATE TABLE IF NOT EXISTS health_tracker_elements
(
  element_key                 INT CONSTRAINT pk_health_tracker_elements PRIMARY KEY,
  name                        VARCHAR(64) NOT NULL CONSTRAINT uk_htrack_element_name UNIQUE,
  health_tracker_id           INT NOT NULL,
  loinc                       VARCHAR(10) CONSTRAINT uk_htrack_element_loinc UNIQUE,
  medical_procedure_cd        VARCHAR(20) CONSTRAINT uk_htrack_element_medproc UNIQUE,
  inserted_by                 VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  inserted_dt                 TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by                  VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt                  TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_element_health_tracker FOREIGN KEY(health_tracker_id) REFERENCES health_trackers(health_tracker_id),
  CONSTRAINT fk_htrack_elem_loinc FOREIGN KEY(loinc) REFERENCES loinc(loinc)
);

COMMENT ON TABLE health_tracker_elements IS 'Detail information about parameters that can be tracked by Health Tracker devices';

ALTER TABLE health_tracker_elements OWNER to postgres;

CREATE INDEX IF NOT EXISTS ix_health_tracker_element ON health_tracker_elements(health_tracker_id);
