CREATE OR REPLACE PACKAGE pkg_etl_utils AS
/*
  =================================================================================================
  Package ETL_UTILS contains procedures for performing data transformation operations:
  add data or delete data to/from target tables based on the content of the source views.

  It was developed by Oleg Khaykin: 1-201-625-3161. OlegKhaykin@gmail.com. 
  Your are allowed to use and change it as you wish.

  There are two main procedures in this package: 1) ADD_DATA and 2) DELETE_DATA.
  Please, see their descriptions below.

  History of changes (newest to oldest) :
  -------------------------------------------------------------------------------------------------
  29-JUL-2024, Oleg Khaykin (OK): new version.
  =================================================================================================

  Procedure ADD_DATA selects data from the specified source table/view/query (parameter P_SOURCE),
  optionally applying a filter condition specified by the parameter P_WHERE.
  Depending on the parameter P_OPERATION (INSERT, UPDATE, MERGE or REPLACE), it either inserts all
  or merges the new/changed source rows into the target table specified by the parameter P_TARGET.
  The source and the target columns are matched by their names, not by their positions.
  If P OPERATION = 'REPLACE', then the procedure first truncates the target table
  and then inserts all the source rows.

  Other parameters:
  ------------------------------------------------------------------------------------------------
  - P_MATCH_COLS - a comma-separated list of the columns on which to match
    the source and the target rows during MERGE/UPDATE operations.
    If not specified, then matching is done on all the columns of the target table's Primary Key.

    Matching on ROWID.
    If the target table is pre-joined in the source view/query, it is recommended
    to include into the source the column ROW_ID holding the target table's ROWIDs
    and specify: P_MATCH_COLS => 'ROWID'.
    In that case, the target (t) and the source (s) will be matched on t.ROWID = s.row_id.
    Also, in this case you should include the following columns in the source view/query:
    - ETL$SRC_INDICATOR - if you use NOTFOUND deletion condition.
      It should have value 1 when a matching source row exists; otherwise - any other value or NULL.
      Please, see below the description of the P_DELETE parameter.
     -<version_number> column calculated as NVL(t.< version_number>, 0) - if the target table
      has such column. Please, see below the description of the P_VERSIONS parameter.

  - P_CHECK CHANGED - defines what columns should be checked for changes in UPDATE/MERGE operations:
    - 'ALL' - check for changes all the columns that are not used for matching;
      perform update only if some of these columns have changed - i.e. their values
      on the source row are different from the values on the matching target row.
    - 'NONE' - do not check for changes, perform update regardless.
    - '<comma-separated list of columns>' - check for changes only the listed columns,
      perform update only if some of them have changed.
    - 'EXCEPT <list of columns>' - like in case of 'ALL' but also exclude the listed here columns.

  - P_GENERATE - defines logic of populating some target columns; should be in the form:
    <column 1>, <column 2> ... = <expression 1>, <expression 2> ...    

    For example:
    q'[vid, cob_date = my_sequence.NEXTVAL, SYS_CONTEXT('IDL_CONTEXT', 'COB_DATE')]'
    Lower/Upper case is important only in string literals. Spaces around "=" and "," are optional.

    This data generation occurs ONLY DURING INSERT, not on during update!
    It is mainly used for generating surrogate keys out of sequences - like the VID column
    in the above example. The other column - COB_DATE - could be included into the source view/query instead,
    in which case it would be assigned BOTH WHILE INSERTING AND UPDATING.

  - P_DELETE - defines deletion logic for UPDATE and MERGE operations.
    It has the form: IF <condition> THEN <action>.
    - The <condition> can be either:
      a) NOTFOUND - meaning that there is no matching row in the source;
      b) Any expression that can be evaluated to TRUE or FALSE.
        It is allowed to refer here to the source columns: s.< column name>.
    - If "THEN <action>" is omitted then the procedure will actually delete the qualifying rows
      from the target table. Otherwise, <action> should have the form:
      <deleted flag column> = <deleted value>:< active value>,
      in which case the qualifying target rows will be logically deleted or un-deleted
      by setting the <deleted flag column> to <deleted value> if <condition> is TRUE
      or to <active value> if <condition> is FALSE.
    
    For example:
    1) 'IF NOTFOUND' - delete from the target table all the rows that do not have matching source rows.
    2) q['IF s.delete_flag='Y']' - delete from the target table the rows for which
       the matching source rows have DELETE FLAG='Y'.
    3) 'IF NOTFOUND THEN active_indicator=0:1' - set ACTIVE_INDICATOR=0 on all the target rows
       for which there are no matching source rows, set ACTIVE_INDICATOR=1
       on all the matching target rows and on the newly inserted ones.

    It is not allowed to have delete flags/indictors on both source and target sides, like this:
    q'[IF s.delete_flag='Y' THEN active_indicator=0:1]'
    In this case, instead of using P_DELETE parameter, you should include the ACTIVE_INDICATOR column
    into the source view/query; for example, like this:
    CASE WHEN s.delete_flag = 'Y' THEN 0 ELSE 1 END AS active_indicator

    If you are using NOTFOUND condition together with ROWID matching (see P_MATCH_COLS above),
    then your source view/query should have the column ETL$SRC_INDICATOR
    having value 1 when the source row exists and being NULL otherwise.
    To achieve that, your source query/view should either OUTER JOIN your source to the target table
    or use FULL JOIN between the source and the target.

  - P_VERSIONS defines versioning logic. The complete form is:
    <version column>; <from column> =< from expession>; <until column> =< until expression>
    For example: q'[VERSION_NUM; START_TS=SYSDATE; END_TS=SYSDATE - INTERVAL '1' SECOND]'

    If P_VERSIONS is specified, then instead of updating the matching "current" rows in the target table,
    the procedure will "end-date" them by setting <until column> = <until expression>
    and then will insert new rows with new attribute values, with <version column> increased by 1,
    with <from column> = <from expression> and with <until column> being set to either '31-DEC-9999' or NULL -
    depending on whether <until column> is mandatory or nullable.
    Here, the "current" rows are those with <until column> being either '31-DEC-9999' or NULL.

    The target table may not have a version number column. In that case,
    <version column> should be omitted in P_VERSIONS parameter, for example like this:
    q'[START TS=SYSTIMESTAMP; END TS=SYSTIMESTAMP - INTERVAL '1' SECOND] '.

    The From/Until expressions can be omitted as well; for example: 'START_DT;END_DT'
    In this case, the default From/Until expressions will be used:
    TRUNC (SYSDATE) and TRUNC (SYSDATE) -1 respectively.

    If you are using <version column> together with ROWID matching, then you should have this column
    in your source query/view, calculated as NVL(t.version_num, 0) AS version_num.

    Note: with versioning, you cannot physically delete data! Therefore, if you need, you must use
    logical deletion: i.e in the P_DELETE condition you must have "THEN <action>" or,
    you should have a <deleted flag> column in both the source and the target and not use P_DELETE at all.

  - P_COMMIT AT: 0 - do not commit, negative number - commit once at the end,
                 positive N - commit after processing every N source rows.

  - P ADD CNT - this output parameter gets the number of the added+changed+deleted rows.
  - P_ERR CNT - gets the number of the source rows that have been rejected and placed into the error table (P_ERRTAB)
    If P_ERRTAB is not specified then the whole transaction is rolled back and the procedure errors-out
    in case of even one error.

  PROCEDURE add data
  (
    p_operation       IN VARCHAR2, -- 'INSERT', 'UPDATE', 'MERGE' or 'REPLACE'
    p target          IN VARCHAR2, -- target table to add rows to
    p_source          IN VARCHAR2, -- source table, view or query
    p_where           IN VARCHAR2 DEFAULT NULL, -- optional WHERE condition to apply to the source
    p_hint            IN VARCHAR2 DEFAULT NULL, -- optional hint to apply to the source
    p_match_cols      IN VARCHAR2 DEFAULT NULL, -- see in the procedure description above
    p_check_changed   IN VARCHAR2 DEFAULT NULL, -- see in the procedure description above
    p_generate        IN VARCHAR2 DEFAULT NULL, -- see in the procedure description above
    p delete          IN VARCHAR2 DEFAULT NULL, -- see in the procedure description above
    p_versions        IN VARCHAR2 DEFAULT NULL, -- see in the procedure description above
    p_commit_at       IN NUMBER   DEFAULT 0,    -- see in the procedure description above
    p_errtab          IN VARCHAR2 DEFAULT NULL, -- optional DML error log table name,
    p_add_cnt         IN OUT INTEGER,           -- number of added/changed/deleted rows
    p err cnt         IN OUT INTEGER            -- number of errors
  );
  

  -- "Silent" version of the previous procedure - i.e. with no OUT parameters
  PROCEDURE add data
  (
    p_operation       IN VARCHAR2, -- 'INSERT', 'UPDATE', 'MERGE' or 'REPLACE'
    p target          IN VARCHAR2, -- target table to add rows to
    p_source          IN VARCHAR2, -- source table, view or query
    p_where           IN VARCHAR2 DEFAULT NULL, -- optional WHERE condition to apply to the source
    p_hint            IN VARCHAR2 DEFAULT NULL, -- optional hint to apply to the source
    p_match_cols      IN VARCHAR2 DEFAULT NULL, -- see in the procedure description above
    p_check_changed   IN VARCHAR2 DEFAULT NULL, -- see in the procedure description above
    p_generate        IN VARCHAR2 DEFAULT NULL, -- see in the procedure description above
    p delete          IN VARCHAR2 DEFAULT NULL, -- see in the procedure description above
    p_versions        IN VARCHAR2 DEFAULT NULL, -- see in the procedure description above
    p_commit_at       IN NUMBER   DEFAULT 0,    -- see in the procedure description above
    p_errtab          IN VARCHAR2 DEFAULT NULL, -- optional DML error log table name
..);


  Procedure DELETE DATA deletes from the target table (P_TARGET)
  the data that exists (P_NOT_IN='N') or does not exists (P_NOT_IN='Y')
  in the source table/view (P_SOURCE) after applying to the source an
  optional filtering condition (P_WHERE), matching source and target rows
  by either all the columns of the target table Primary Key (default)
  -- or by the given list of columns (P_MATCH_COLS).
  PROCEDURE delete data
  (
    IN VARCHAR2, -- target table to delete rows from
    IN VARCHAR2, -- source table/view that contains the list of rows to delete or to preserve
    IN VARCHAR2 DEFAULT NULL, -- optional WHERE condition to apply to the source
    IN VARCHAR2 DEFAULT NULL, -- optional hint for the source query
    IN VARCHAR2 DEFAULT 'N', -- if 'N' then the source lists the rows to be deleted; if 'Y' - the rows to be preserved
    IN VARCHAR2 DEFAULT NULL, -- optional UK column list to use instead of PK columns
    IN PLS INTEGER DEFAULT 0,
    IN OUT PLS INTEGER -- number of deleted rows
  );

  Procedure PARSE_NAME splits the given name into 3 pieces:
  -- 1) schema, 2) table/view name and 3) DB_link
  PROCEDURE parse_name
  (
    p_name    IN VARCHAR2,
    p_schema  OUT VARCHAR2,
    p_table   OUT VARCHAR2,
    p_db_link OUT VARCHAR2
  );
  
  -- Procedure RESOLVE_NAME resolves the given table/view/synonym name
  -- into a complete SCHEMA.NAME description of the underlying table/view.
  PROCEDURE resolve_name
  (
    p_name    IN VARCHAR2,
    p_schema  OUT VARCHAR2,
    p table   OUT VARCHAR2
  );

  -- Procedure FIND TABLE finds the actual SCHEMA.NAME
  -- for the given SCHEMA.NAME, which can be a synonym
  PROCEDURE find_table
  (
    p_schema  IN OUT VARCHAR2,
    p_table   IN OUT VARCHAR2
  );

  -- Function GET_KEY_COL_LIST returns a comma-separated list of the table key column names.
  -- By default, describes the table PK.
  -- Optionally, can describe the given UK.
  FUNCTION get_key_col_list
  (
    p_table IN VARCHAR2,
    p_key   IN VARCHAR2 DEFAULT NULL -- optional name of the UK to be described
  ) RETURN VARCHAR2;

  -- Procedure SET_PARAMETER_VALUE sets parameter value either in CTX_LOCAL_ETL only or in both CTX_LOCAL_ETL and CTX_GLOBAL_ETL contexts.
  -- To set the parameter value in CTX_GLOBAL_ETL, specify a not-NULL value for the parameter P_CLIENT_ID.
  -- If you specify p_client_id => 'NONE' then the value will be set for the sessions that do not have CLIENT_IDENTIFIER set.
  PROCEDURE set_parameter_value(p_name IN VARCHAR2, p_value IN VARCHAR2, p_client_id IN VARCHAR2 DEFAULT NULL);

  -- Function SET_PARAMETER sets parameter value either in CTX_LOCAL_ETL or in both CTX_LOCAL_ETL and CTX_GLOBAL_ETL contexts.
  FUNCTION set_parameter(p_name IN VARCHAR2, p_value IN VARCHAR2, p_client_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

  -- Function SET_PARAMETERS sets parameter values either in CTX_LOCAL_ETL or in both CTX_LOCAL_ETL and CTX_GLOBAL_ETL contexts.
  FUNCTION set_parameters(p_params IN VARCHAR2, p_client_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

  -- Function GET_PARAMETER_VALUE gets parameter value from either CTX_LOCAL_ETL or CTX_GLOBAL_ETL context - wherever it can find it.
  FUNCTION get_parameter_value(p_name IN VARCHAR2) RETURN VARCHAR2;

  -- Function SUBSTITUTE_PARAMETERS replaces tagged parameter names in the given text with the actual values of the corresponding parameters.
  FUNCTION substitute_parameters(p_text IN VARCHAR2, p_begin_tag IN VARCHAR2 DEFAULT '$$', p_end_tag IN VARCHAR2 DEFAULT '$$') RETURN VARCHAR2;

  -- Procedure CLEAR PARAMETER clears the parameter value either CTX_LOCAL_ETL or in both CTX_LOCAL_ETL and CTX_GLOBAL_ETL contexts.
  PROCEDURE clear_parameter(p_name IN VARCHAR2, p_client_id IN VARCHAR2 DEFAULT NULL);

  -- Procedure CLEAR CONTEXT clears all the parameter values from both CTX_LOCAL_ETL and CTX_GLOBAL_ETL contexts.
  PROCEDURE clear_context;

  PROCEDURE close_db_link(p_db_link IN VARCHAR2);
END;
/

CREATE OR REPLACE PUBLIC SYNONYM etl FOR pkg_etl_utils;
GRANT EXECUTE ON etl TO PUBLIC;