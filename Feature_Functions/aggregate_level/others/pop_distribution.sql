
--- 说明：以工作地、居住地作为user汇总的单位，分析工作人口和居住人口的空间分布


drop table if exists aggregate_home_distribution;
create table aggregate_home_distribution as
select
        home_grid_id,
        count(1) as home_pop
    from
        individual_grid_id a
        group by home_grid_id;
        
drop table if exists work_aggregate_home_distribution;
create table work_aggregate_home_distribution as
select
        work_grid_id,
        count(1) as work_pop
    from
        individual_grid_id a
        group by work_grid_id;
