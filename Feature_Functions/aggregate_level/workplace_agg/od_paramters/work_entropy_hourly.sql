--- 说明：参数与home_entropy.sql一致，但是时间分辨率为hour，关注od的可预测性随时谱特征。
drop table if exists od_temp;
create table od_temp as
select
    a.start_grid as start_grid_id,
    a.end_grid as end_grid_id,
    substr(a.start_hour,12) as start_hour
from
    aggregate_move_od a
where a.weekday <>'Saturday' and a.weekday<>'Sunday';

drop table if exists flow_temp;
create table flow_temp as
select
    count(1) as cnt,
    a.start_grid_id,
    a.end_grid_id,
    a.start_hour
from od_temp a
group by
    a.start_grid_id,
    a.end_grid_id,
    a.start_hour;

drop table if exists grid_stay_sum_cache;

create table grid_stay_sum_cache as
select
    sum(a.cnt) as visit_num,
    count(distinct end_grid_id) as place_num,
    a.start_grid_id,
    a.start_hour
from
    flow_temp a
group by
    a.start_grid_id,
    a.start_hour;

drop table if exists grid_stay_p_cache;

create table if not exists grid_stay_p_cache as
select
    -(a.cnt / b.visit_num) * log2(a.cnt / b.visit_num) as visit_logp,
    a.start_grid_id,
    a.start_hour
from
    flow_temp a
    left join grid_stay_sum_cache b on a.start_grid_id = b.start_grid_id
    and a.start_hour = b.start_hour;

drop table if exists grid_entropy_wjy_hourly;
create table if not exists grid_entropy_wjy_hourly as
select
    c.start_grid_id,
    c.visit_entropy,
    b.visit_num,
    b.place_num,
    c.start_hour
from
    (
        select
            a.start_grid_id,
            a.start_hour,
            sum(a.visit_logp) as visit_entropy
        from
            grid_stay_p_cache a
        group by
            a.start_grid_id,
            a.start_hour
    ) c
    left join grid_stay_sum_cache b on c.start_grid_id = b.start_grid_id
    and c.start_hour = b.start_hour;
    