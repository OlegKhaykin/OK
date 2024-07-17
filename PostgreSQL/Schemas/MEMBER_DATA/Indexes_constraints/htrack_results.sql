ALTER TABLE htrack_results ADD CONSTRAINT pk_htrack_results PRIMARY KEY(member_id, result_key);
ALTER TABLE htrack_results ADD CONSTRAINT uk_htrack_results UNIQUE(element_key, measurement_key, measurement_date, member_id);
ALTER TABLE htrack_results ADD CONSTRAINT fk_htrack_result_member FOREIGN KEY(member_id) REFERENCES members(member_id);
ALTER TABLE htrack_results ADD CONSTRAINT fk_htrack_result_element_msrmnt FOREIGN KEY(element_key, measurement_key) REFERENCES htrack_element_measurement_xref(element_key, measurement_key);
