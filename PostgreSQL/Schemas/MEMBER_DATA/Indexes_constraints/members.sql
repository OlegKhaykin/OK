ALTER TABLE members ADD CONSTRAINT pk_members PRIMARY KEY(member_id);
ALTER TABLE members ADD CONSTRAINT uk_members UNIQUE(source_patient_id, member_id);
CREATE INDEX ix_member_plan_id ON members(primary_member_plan_id);
