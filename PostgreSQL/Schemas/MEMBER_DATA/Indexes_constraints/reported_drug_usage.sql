ALTER TABLE reported_drug_usage ADD CONSTRAINT pk_member_reported_drug_usage PRIMARY KEY(member_id, drug_usage_key);
ALTER TABLE reported_drug_usage ADD CONSTRAINT uk_member_reported_drug_usage UNIQUE(member_id, fill_date, drug_cd);
ALTER TABLE reported_drug_usage ADD CONSTRAINT fk_reported_drug_usage_member FOREIGN KEY(member_id) REFERENCES members(member_id);

CREATE INDEX IF NOT EXISTS idx_reported_drug_usage_ndc ON reported_drug_usage(drug_cd);
