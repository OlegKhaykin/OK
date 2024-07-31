SELECT * FROM gv$cache 
WHERE 1=1
AND file# = 1
AND name = 'TST_OK'
ORDER BY block#, status;