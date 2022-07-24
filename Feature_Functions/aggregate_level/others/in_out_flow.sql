
--- 说明：分析每个单元的流入和流出流量
--- 提取参数说明
    --- total_out, 网格总流出流量
    --- out_flows, 网格每小时流出的流量，共24维向量
    --  out_hours,网格每小时流出的流量所对应的时间
    --  total_in, 网格总流入的流量
    --- in_flows,网格每小时流出的流量
    --- in_hours,网格每小时流出的流量所对应的时间
    --- grid_id 网格id

drop table if exists out_flow_step1;

create table out_flow_step1 as
select
    a.start_grid,
    a.start_hour,
    count(1) as out_flow
from
    (
        select
            substr(a.start_hour, 12) as start_hour,
            a.start_grid
        from
            aggregate_move_od a
    ) a
group by
    a.start_grid,
    a.start_hour;
  
            
drop table if exists out_flow;
create table out_flow as
select
    collect_list(a.start_hour) as out_hours,
    collect_list(a.out_flow) as out_flows,
    a.start_grid,
    sum(a.out_flow) as total_out
from
   out_flow_step1 a
group by
    a.start_grid;

drop table if exists in_flow_step1;
create table in_flow_step1 as
select
            a.end_grid,
            a.start_hour,
            count(1) as out_flow
        from
           (select
            substr(a.start_hour, 12) as start_hour,
            a.end_grid
        from
            aggregate_move_od a) a
        group by
            a.start_hour,
            a.end_grid;
            
            
drop table if exists in_flow;
create table in_flow as
select
    collect_list(a.start_hour) as in_hours,
    collect_list(a.out_flow) as in_flows,
    a.end_grid,
    sum(a.out_flow) as total_in
from
   in_flow_step1 a
group by
    a.end_grid;


drop table if exists in_out_flow;
create table in_out_flow as
select
    b.total_out,
    b.out_flows,
    b.out_hours,
    c.total_in,
    c.in_flows,
    c.in_hours,
    a.grid_id
from
    all_grid a
    left join out_flow b on a.grid_id = b.start_grid
    left join in_flow c on a.grid_id = c.end_grid;
    create table grid_entropy_wjy_output as
left semi
    join grid_mobility_index_4 b 
    on a.grid_id = b.grid_id;
    