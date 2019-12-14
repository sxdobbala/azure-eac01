-- "not exists" makes idempotent

insert into client_config  (client_id, config_key, config_value)
select client_id, 'instance_id' as config_key, max(config_value) as config_value
from client_config a
where config_key like '%/instance_id' 
and not exists (select 1 from client_config b where a.client_id=b.client_id and b.config_key='instance_id')
group by client_id;

-- note this only works for now because all env-* keys are 6 digits; this won't work forever

insert into client_config  (client_id, config_key, config_value)
select client_id, 'env_id' as config_key, substr(max(config_value), 1, 10) as config_value
from client_config a
where config_value like 'env-%' 
and not exists (select 1 from client_config b where a.client_id=b.client_id and b.config_key='env_id')
group by client_id;
