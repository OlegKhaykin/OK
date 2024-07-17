ALTER TABLE pre_cert_insurance_cases ADD CONSTRAINT pk_pre_cert_insurance_case PRIMARY KEY(member_id, case_key);
ALTER TABLE pre_cert_insurance_cases ADD CONSTRAINT uk_pre_cert_insurance_case UNIQUE(member_id, source_case_id, case_type_id);
ALTER TABLE pre_cert_insurance_cases ADD CONSTRAINT fk_precertcase_member FOREIGN KEY(member_id) REFERENCES members(member_id);