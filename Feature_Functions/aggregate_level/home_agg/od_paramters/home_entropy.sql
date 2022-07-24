--- 说明：对于任意网格而言，分析其od矩阵中，终点为各个地区（0.05°*0.05°）的可预测性，即熵值。
--- 提取参数说明
---     start_grid_id, od矩阵中起点网格的id，作为计算的唯一标识
--- visit_entropy,d点的可预测性，即熵值
--- visit_num, od矩阵中，每个网格作为起点的总流量
--- place_num：去重后的d点的数量
drop table if exists flow_temp;

create table flow_temp as
select
    count(1) as cnt,
    a.start_grid as start_grid_id,
    a.end_grid as end_grid_id
from
    aggregate_move_od a
group by
    a.start_grid,
    a.end_grid;

drop table if exists grid_stay_sum_cache;

create table grid_stay_sum_cache as
select
    sum(a.cnt) as visit_num,
    count(distinct end_grid_id) as place_num,
    a.start_grid_id
from
    flow_temp a
group by
    a.start_grid_id;

drop table if exists grid_stay_p_cache;

create table if not exists grid_stay_p_cache as
select
    -(a.cnt / b.visit_num) * log2(a.cnt / b.visit_num) as visit_logp,
    a.start_grid_id
from
    flow_temp a
    left join grid_stay_sum_cache b on a.start_grid_id = b.start_grid_id;

drop table if exists grid_entropy_wjy;

create table if not exists grid_entropy_wjy as
select
    c.start_grid_id,
    c.visit_entropy,
    b.visit_num,
    b.place_num
from
    (
        select
            a.start_grid_id,
            sum(a.visit_logp) as visit_entropy
        from
            grid_stay_p_cache a
        group by
            a.start_grid_id
    ) c
    left join grid_stay_sum_cache b on c.start_grid_id = b.start_grid_id;
