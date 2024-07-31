SELECT 
  i.instance_number, i.host_name, i.instance_name,
  p.value par_cpu_count_value,
  s.value actual_cpus, s.comments
FROM gv$instance i
JOIN gv$parameter p ON p.inst_id = i.inst_id AND p.name = 'cpu_count'
JOIN gv$osstat s ON s.inst_id = i.inst_id AND s.stat_name = 'NUM_CPUS';
