--- 说明：以工作地作为user汇总的单位，提取该地区内部user的rog的分布特征
--- 提取参数说明
    --- work_grid_id,个体居住地所对应的空间网格id
    --- avg_rog, 平均rog
    --- std_rog, rog方差
    --- rog_percentile, rog的十分位数
    --- kurt_rog, rog的峰度
    --- skew_rog, rog的偏度
    --- avg_rog_T,时间加权rog的均值
    --- std_rog_T, 方差
    --- kurt_rog_T， 峰度
    --- rog_T_percentile, 十分位，
    --- skew_rog_T 偏度


drop table if exists work_aggregate_rog_wjy_temp_1;

create table if not exists work_aggregate_rog_wjy_temp_1 as
SELECT
    a.work_grid_id,
    avg(a.rog) as avg_rog,
    stddev(a.rog) as std_rog,
    percentile_approx(
        a.rog,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as rog_percentile,
    avg(a.rog_T) as avg_rog_T,
    stddev(a.rog_T) as std_rog_T,
    percentile_approx(
        a.rog,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as rog_T_percentile
from
    (
        select
            a.uid,
            a.rog,
            a.rog_T,
            b.home_grid_id,
            b.work_grid_id
        FROM
            indivdiual_stay_rog a
            left join (
                select
                    a.uid,
                    a.home_grid_id,
                    a.work_grid_id
                from
                    individual_grid_id a
            ) b on a.uid = b.uid
    ) a
group by
    a.work_grid_id;
    
drop table if exists work_aggregate_rog_wjy_temp_2;
create table if not exists work_aggregate_rog_wjy_temp_2 as
SELECT
    d.work_grid_id,
    avg(
        pow(
            (d.rog - d.avg_rog) / d.std_rog,
            3
        )
    ) as skew_rog,
    avg(
        pow(
            (d.rog - d.avg_rog) / d.std_rog,
            4
        )
    ) as kurt_rog,
    avg(
        pow(
            (d.rog_T - d.avg_rog_T) / d.std_rog_T,
            3
        )
    ) as skew_rog_T,
    avg(
        pow(
            (d.rog_T - d.avg_rog_T) / d.std_rog_T,
            4
        )
    ) as kurt_rog_T
from
    (
        select
            a.rog_T,
            a.rog,
            c.avg_rog_T,
            c.std_rog_T,
            c.avg_rog,
            c.std_rog,
            a.home_grid_id,
            a.work_grid_id
        from
            (
                select
                    a.uid,
                    a.rog_T,
                    a.rog,
                    b.home_grid_id,
                    b.work_grid_id
                FROM
                    indivdiual_stay_rog a
                    left join (
                        select
                            a.uid,
                            a.home_grid_id,
                            a.work_grid_id
                        from
                            individual_grid_id a
                    ) b on a.uid = b.uid
            ) a
            left join work_aggregate_rog_wjy_temp_1 c on a.work_grid_id = c.work_grid_id
    ) d
group by
    d.work_grid_id;
    
drop table if exists work_aggregate_rog_wjy;
create table if not exists work_aggregate_rog_wjy as
select
    a.work_grid_id,
    a.avg_rog,
    a.std_rog,
    a.rog_percentile,
    b.kurt_rog,
    b.skew_rog,
    a.avg_rog_T,
    a.std_rog_T,
    a.rog_T_percentile,
    b.kurt_rog_T,
    b.skew_rog_T
from
    work_aggregate_rog_wjy_temp_1 a
    left join work_aggregate_rog_wjy_temp_2 b on a.work_grid_id = b.work_grid_id;