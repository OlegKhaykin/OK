ALTER TABLE pre_cert_medical_procedures ADD CONSTRAINT pk_pre_cert_medical_procedure PRIMARY KEY(member_id, procedure_key);
ALTER TABLE pre_cert_medical_procedures ADD CONSTRAINT uk_pre_cert_medical_procedure UNIQUE(member_id, case_key, service_date, procedure_cd, code_set_type);
ALTER TABLE pre_cert_medical_procedures ADD CONSTRAINT fk_pre_cert_procedure_case FOREIGN KEY(member_id, case_key) REFERENCES pre_cert_insurance_cases(member_id, case_key);
