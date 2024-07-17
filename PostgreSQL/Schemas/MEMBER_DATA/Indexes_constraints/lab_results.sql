ALTER TABLE lab_results ADD CONSTRAINT pk_lab_results PRIMARY KEY(result_key, member_id);
ALTER TABLE lab_results ADD CONSTRAINT uk_lab_results UNIQUE(member_id, service_date, loinc);

CREATE INDEX ix_lab_result_claim ON lab_results(claim_key, member_id);
CREATE INDEX ix_lab_result_loinc ON lab_results(loinc);
CREATE INDEX ix_lab_result_care_provider ON lab_results(care_provider_npi);

ALTER TABLE lab_results ADD CONSTRAINT fk_lab_result_member FOREIGN KEY(member_id) REFERENCES members(member_id);
ALTER TABLE lab_results ADD CONSTRAINT fk_lab_result_claim FOREIGN KEY(member_id, claim_key) REFERENCES patient_claims(member_id, claim_key);
ALTER TABLE lab_results ADD CONSTRAINT fk_lab_result_loinc FOREIGN KEY(loinc) REFERENCES loinc(loinc);
