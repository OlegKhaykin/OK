CREATE TABLE IF NOT EXISTS health_trackers
(
  health_tracker_id   INT           NOT NULL CONSTRAINT pk_health_trackers PRIMARY KEY,
  health_tracker_cd   VARCHAR(10)   NOT NULL CONSTRAINT uk_health_trackers UNIQUE,
  name                VARCHAR(64)   NOT NULL,
  description         VARCHAR(255)  NOT NULL,
  inserted_by         VARCHAR(30)   NOT NULL DEFAULT SESSION_USER,
  inserted_dt         TIMESTAMP(0)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by          VARCHAR(30)   NOT NULL DEFAULT SESSION_USER,
  updated_dt          TIMESTAMP(0)  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE health_trackers OWNER to postgres;

COMMENT ON TABLE health_trackers IS 'General information about parameters that can be tracked by Health Tracker devices';