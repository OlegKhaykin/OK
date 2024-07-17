ALTER TABLE patient_diagnoses ADD CONSTRAINT pk_patient_diagnoses PRIMARY KEY(member_id, diagnosis_key);
ALTER TABLE patient_diagnoses ADD CONSTRAINT uk_patient_diagnoses UNIQUE(member_id, diagnosis_cd, service_date);

CREATE INDEX IF NOT EXISTS ix_patient_diagnoses_claim ON patient_diagnoses(member_id, claim_key);

ALTER TABLE patient_diagnoses ADD CONSTRAINT fk_patient_diagnosis_member FOREIGN KEY(member_id) REFERENCES members(member_id);

ALTER TABLE patient_diagnoses ADD CONSTRAINT fk_patient_diagnosis_claim FOREIGN KEY (member_id, claim_key) REFERENCES patient_claims(member_id, claim_key);
