ALTER TABLE patient_prescriptions ADD CONSTRAINT pk_patient_prescriptions PRIMARY KEY(member_id, prescription_key);
ALTER TABLE patient_prescriptions ADD CONSTRAINT uk_patient_prescriptions UNIQUE(member_id, service_date, drug_cd);

CREATE INDEX IF NOT EXISTS ix_patient_prescription_claim ON patient_prescriptions(claim_key, member_id);

ALTER TABLE patient_prescriptions ADD CONSTRAINT fk_patient_prescription_member FOREIGN KEY(member_id) REFERENCES members(member_id);
ALTER TABLE patient_prescriptions ADD CONSTRAINT fk_patient_prescription_claim FOREIGN KEY(member_id, claim_key) REFERENCES patient_claims(member_id, claim_key);
