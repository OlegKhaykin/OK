ALTER TABLE pre_cert_diagnoses ADD CONSTRAINT pk_pre_cert_diagnoses PRIMARY KEY(member_id, diagnosis_key);
ALTER TABLE pre_cert_diagnoses ADD CONSTRAINT uk_pre_cert_diagnoses UNIQUE(member_id, case_key, diagnosis_cd);
ALTER TABLE pre_cert_diagnoses ADD CONSTRAINT fk_pre_cert_diagnoses_case FOREIGN KEY(member_id, case_key) REFERENCES pre_cert_insurance_cases(member_id, case_key);
