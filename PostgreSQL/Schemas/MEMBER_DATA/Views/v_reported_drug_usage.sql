CREATE OR REPLACE VIEW v_reported_drug_usage(member_id, drug_usage) AS
SELECT
  -- 2022-01-29, O. Khaykin: created
  member_id,
  ROW
  (
    drug_usage_key,
    fill_date,
    drug_cd,
    code_set_type,
    dosage,
    status,
    change_reason,
    non_compliant_flag,
    non_compliant_reason,
    update_source
  )::typ_drug_usage
FROM reported_drug_usage
WHERE termed_flag = 'N'
AND fill_date BETWEEN get_begin_date() AND get_end_date();

ALTER VIEW v_reported_drug_usage OWNER TO postgres;
