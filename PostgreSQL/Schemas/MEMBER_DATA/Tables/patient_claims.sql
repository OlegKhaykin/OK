CREATE TABLE IF NOT EXISTS patient_claims
(
  member_id                         BIGINT NOT NULL,
  claim_key                         BIGINT NOT NULL,
  source_claim_id                   VARCHAR(30) NOT NULL,
  claim_type_cd                     VARCHAR(24),
  service_start_date                DATE NOT NULL,
  service_end_date                  DATE,
  principal_diagnosis_cd            VARCHAR(20),
  admitting_diagnosis_cd            VARCHAR(20),
  code_set_type                     VARCHAR(10) NOT NULL,
  operating_provider_npi            VARCHAR(10),
  attending_provider_npi            VARCHAR(10),
  other_provider_npi                VARCHAR(10),
  facility_npi                      VARCHAR(10),
  diagnosis_related_group_cd        VARCHAR(4),
  discharge_disposition_cd          VARCHAR(24),
  received_date                     DATE,
  replaced_claim_key                BIGINT,
  exclusion_cd                      CHARACTER(2) CONSTRAINT chk_patient_claim_excl CHECK(exclusion_cd IN ('IN','VO')),
  inserted_by                       VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  inserted_dt                       TIMESTAMP(0) DEFAULT CURRENT_TIMESTAMP,
  updated_by                        VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt                        TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(member_id);

ALTER TABLE patient_claims OWNER to postgres;

COMMENT ON TABLE patient_claims IS 'Medical Insurance claims submitted on behalf Members';
COMMENT ON COLUMN patient_claims.claim_key IS 'Surrogate unique key';
COMMENT ON COLUMN patient_claims.source_claim_id IS 'Unique ID received from the source';
COMMENT ON COLUMN patient_claims.member_id IS 'Reference to Member';
COMMENT ON COLUMN patient_claims.service_start_date IS 'Date when services were first rendered in conjunction with this Claim.';
COMMENT ON COLUMN patient_claims.service_end_date IS 'Date when services were completed in conjunction with this Claim.';
COMMENT ON COLUMN patient_claims.principal_diagnosis_cd IS 'Code of the primary diagnosis associated with the Claim';
COMMENT ON COLUMN patient_claims.admitting_diagnosis_cd IS 'Admitting Diagnosis Code is the code which designates the initial diagnosis that was made when the Patient was admitted to the Facility.  The Code Set Type identifies the code system needed to interpret the code.  Currently, the only values are ''ICD9M'' and ''OTHER''.';
COMMENT ON COLUMN patient_claims.code_set_type IS 'Coding system for diagones';
COMMENT ON COLUMN patient_claims.discharge_disposition_cd IS 'Code of the Claim outcome (e.g., death, transfer to home/hospice/skilled nursing facility, etc.)';
COMMENT ON COLUMN patient_claims.diagnosis_related_group_cd IS 'Diagnostic Related Group (DRG) Code is the code which uniquely identifies a DRG.  Since there are a number of systems which assign DRGs and groupings, the code is related to the assigning organization (e.g., CMS, Treo Solutions HSS Inc, Yale University, etc.). For an explanation of the DIAGNOSTIC RELATED GROUP table, refer to that table in this model.';
COMMENT ON COLUMN patient_claims.received_date IS 'Received Date is the date the claim was received by HDMS.  It is currently not being populated.';
COMMENT ON COLUMN patient_claims.facility_npi IS 'Facility NPI (National Provider Identifier) is a unique 10-digit identification number issued to Health Care Providers and Provider Organizations in the United States by the Centers for Medicare and Medicaid Services (CMS).  It is required for all HIPAA covered Care Providers for HIPAA standard transactions.  Once assigned, an NPI is permanent and remains with the Provider  or Provider Organization regardless of job or location changes.  The field is currently not being populated.';
COMMENT ON COLUMN patient_claims.operating_provider_npi IS 'National Provider Identifier (NPI) of the operating Care Provider';
COMMENT ON COLUMN patient_claims.attending_provider_npi IS 'National Provider Identifier (NPI) of the attending Care Provider';
COMMENT ON COLUMN patient_claims.other_provider_npi IS 'National Provider Identifier (NPI) of the other Care Provider';
COMMENT ON COLUMN patient_claims.replaced_claim_key IS 'Key of an earlier Claim that has been replaced by this one';
COMMENT ON COLUMN patient_claims.inserted_dt IS 'Date and Time when this row was inserted.';
COMMENT ON COLUMN patient_claims.inserted_by IS 'User Identifier who inserted this row';
COMMENT ON COLUMN patient_claims.updated_dt IS 'Date and Time when the row was updated';
COMMENT ON COLUMN patient_claims.updated_by IS 'User Identifier who updated this row last time';
