\set ON_ERROR_STOP on

set schema 'member_data';

\echo reference_codes ...
\COPY reference_codes FROM reference_codes.dat WITH (FORMAT 'csv', DELIMITER '|')

\echo loinc ...
\COPY loinc FROM loinc.dat WITH (FORMAT 'csv', DELIMITER '|')

\echo health_trackers ...
\COPY health_trackers FROM health_trackers.dat WITH (FORMAT 'csv', DELIMITER '|')

\echo health_tracker_elements ...
\COPY health_tracker_elements FROM health_tracker_elements.dat WITH (FORMAT 'csv', DELIMITER '|')

\echo htrack_measurement_types ...
\COPY htrack_measurement_types FROM htrack_measurement_types.dat WITH (FORMAT 'csv', DELIMITER '|')

\echo htrack_element_measurement_xref ...
\COPY htrack_element_measurement_xref FROM htrack_element_measurement_xref.dat WITH (FORMAT 'csv', DELIMITER '|')

\echo hra_questions_answers ...
\COPY hra_questions_answers FROM hra_questions_answers.dat WITH (FORMAT 'csv', DELIMITER '|', QUOTE '"', ESCAPE '\')

\echo members ...
\COPY members FROM PROGRAM 'gzip -dcf members.dat.gz' WITH (FORMAT 'csv', DELIMITER '|')

\echo htrack_results ...
\COPY htrack_results FROM PROGRAM 'gzip -dcf htrack_results.dat.gz' WITH (FORMAT 'csv', DELIMITER '|')

\echo hra_member_survey_results ...
\COPY hra_member_survey_results FROM PROGRAM 'gzip -dcf hra_member_survey_results.dat.gz' WITH (FORMAT 'csv', DELIMITER '|')

\echo patient_claims ...
\COPY patient_claims FROM PROGRAM 'gzip -dcf patient_claims.dat.gz' WITH (FORMAT 'csv', DELIMITER '|')

\echo lab_results ...
\COPY lab_results FROM PROGRAM 'gzip -dcf lab_results.dat.gz' WITH (FORMAT 'csv', DELIMITER '|', QUOTE '`')

\echo patient_diagnoses ...
\COPY patient_diagnoses FROM PROGRAM 'gzip -dcf patient_diagnoses.dat.gz' WITH (FORMAT 'csv', DELIMITER '|')

\echo patient_medical_procedures ...
\COPY patient_medical_procedures FROM PROGRAM 'gzip -dcf patient_medical_procedures.dat.gz' WITH (FORMAT 'csv', DELIMITER '|')

\echo patient_prescriptions ...
\COPY patient_prescriptions FROM PROGRAM 'gzip -dcf patient_prescriptions.dat.gz' WITH (FORMAT 'csv', DELIMITER '|')

\echo pre_cert_insurance_cases ...
\COPY pre_cert_insurance_cases FROM PROGRAM 'gzip -dcf pre_cert_insurance_cases.dat.gz' WITH (FORMAT 'csv', DELIMITER '|')

\echo pre_cert_diagnoses ...
\COPY pre_cert_diagnoses FROM PROGRAM 'gzip -dcf pre_cert_diagnoses.dat.gz' WITH (FORMAT 'csv', DELIMITER '|')

\echo pre_cert_medical_procedures ...
\COPY pre_cert_medical_procedures FROM PROGRAM 'gzip -dcf pre_cert_medical_procedures.dat.gz' WITH (FORMAT 'csv', DELIMITER '|')

\echo reported_drug_usage ...
\COPY reported_drug_usage FROM PROGRAM 'gzip -dcf reported_drug_usage.dat.gz' WITH (FORMAT 'csv', DELIMITER '|')
