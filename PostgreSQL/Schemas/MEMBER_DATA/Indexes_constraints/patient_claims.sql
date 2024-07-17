ALTER TABLE patient_claims ADD CONSTRAINT pk_patient_claims PRIMARY KEY(member_id, claim_key);
ALTER TABLE patient_claims ADD CONSTRAINT uk_patient_claims UNIQUE(member_id, source_claim_id);
ALTER TABLE patient_claims ADD CONSTRAINT fk_patient_claim_member FOREIGN KEY(member_id) REFERENCES members(member_id);
