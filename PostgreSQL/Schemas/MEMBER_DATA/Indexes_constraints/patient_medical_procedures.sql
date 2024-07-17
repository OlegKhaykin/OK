ALTER TABLE patient_medical_procedures ADD CONSTRAINT pk_patient_medical_procedures PRIMARY KEY(member_id, procedure_key);
ALTER TABLE patient_medical_procedures ADD CONSTRAINT uk_patient_medical_procedures UNIQUE(procedure_cd, service_date, member_id);

CREATE INDEX IF NOT EXISTS ix_patient_diagnoses_medproc ON patient_medical_procedures(claim_key, member_id);

ALTER TABLE patient_medical_procedures ADD CONSTRAINT fk_patient_medproc_member FOREIGN KEY(member_id) REFERENCES members(member_id);
ALTER TABLE patient_medical_procedures ADD CONSTRAINT fk_patient_medproc_claim FOREIGN KEY(member_id, claim_key) REFERENCES patient_claims(member_id, claim_key);