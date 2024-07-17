CREATE TABLE IF NOT EXISTS members
(
  member_id                 BIGINT NOT NULL,
  source_patient_id         VARCHAR(20) NOT NULL,
  member_type_cd            CHAR(1) NOT NULL CONSTRAINT chk_member_type CHECK(member_type_cd IN ('E','S','P','C','O')),
  date_of_birth             DATE,
  gender                    CHAR(1),
  race                      VARCHAR(30),
  primary_member_plan_id    BIGINT NOT NULL,
  effective_start_date      DATE NOT NULL,
  effective_end_date        DATE,
  inserted_by               VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  inserted_dt               TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by                VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt                TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(member_id);

ALTER TABLE members OWNER TO postgres;

COMMENT ON TABLE members IS 'Individuals who participate in medical insurance plans and use health insight services provided by CVS/Aetna';
COMMENT ON COLUMN members.member_type_cd IS 'E - employee, S - spouse, P - domestic partner, C - child, O - other';