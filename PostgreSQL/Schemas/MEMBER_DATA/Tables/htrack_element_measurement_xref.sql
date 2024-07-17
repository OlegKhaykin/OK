CREATE TABLE IF NOT EXISTS htrack_element_measurement_xref
(
  element_key       INT NOT NULL,
  measurement_key   INT NOT NULL,
  range_min_value   NUMERIC,
  range_max_value   NUMERIC,
  goal_min_value    NUMERIC,
  goal_max_value    NUMERIC,
  high_risk_value   NUMERIC,
  inserted_by       VARCHAR(30)   NOT NULL DEFAULT SESSION_USER,
  inserted_dt       TIMESTAMP(0)  NOT NULL DEFAULT current_timestamp,
  updated_by        VARCHAR(30)   NOT NULL DEFAULT SESSION_USER,
  updated_dt        TIMESTAMP(0)  NOT NULL DEFAULT current_timestamp,
  CONSTRAINT pk_htrack_element_measurement_xref PRIMARY KEY (element_key, measurement_key),
  CONSTRAINT fk_htrack_xref_msrmnt_element FOREIGN KEY(element_key) REFERENCES health_tracker_elements(element_key),
  CONSTRAINT fk_htrack_xref_element_msrmnt FOREIGN KEY(measurement_key) REFERENCES htrack_measurement_types(measurement_key)
);

ALTER TABLE htrack_element_measurement_xref OWNER to postgres;

CREATE INDEX IF NOT EXISTS ix_htrack_xref_element_msrmnt ON htrack_element_measurement_xref(measurement_key);

COMMENT ON TABLE htrack_element_measurement_xref IS 'Allowed combinations of Health Tracker Elements and Measurement Types together with range, goal and high risk values';