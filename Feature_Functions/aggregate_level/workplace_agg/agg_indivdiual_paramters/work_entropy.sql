--- 说明：以家作为user汇总的单位，提取该地区内部user的entropy的分布特征
--- 提取参数说明
    --- work_grid_id,个体工作地所对应的空间网格id
    --- avg_place_num,格子内 个体访问的去重的格子的数量的个数
    --- std_place_num,方差
    --- place_num_percentile, 十分位数
    --- avg_duration_entropy, 格子内，时间加权的entropy的平均值
    --- std_visit_entropy,方差
    --- duration_entropy_percentile，十分位数
    --- kurt_duration_entropy， 峰度
    --- skew_visit_entropy， 偏度
    --- visit_entropy_percentile， 格子内，访问次数加权的entropy的平均值
    ---std_visit_entropy， 方差
    --- visit_entropy_percentile， 十分位
    --- kurt_visit_entropy  峰度
    --- skew_visit_entropy  偏度
    --- avg_visit_num  格子内 每个人每天访问的地点的数量平均值
    --- std_visit_num 方差
    --- visit_num_percentile 十分位
    --- kurt_visit_num 峰度
    --- skew_visit_num 偏度
    --- avg_visit_duration, 格子内 所有个体出行时间的平均值
    --- std_visit_duration, 方差
    --- visit_duration_percentile 十分位
    --- kurt_visit_duration, 峰度
    --- skew_visit_duration, 偏度

drop table if exists work_aggregate_step_length_wjy_temp_1;

create table if not exists work_aggregate_step_length_wjy_temp_1 as
SELECT
    a.work_grid_id,
    avg(a.step_length) as avg_step_length,
    stddev(a.step_length) as std_step_length,
    percentile_approx(
        a.step_length,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as step_length_percentile,
    avg(a.distance) as avg_distance,
    stddev(a.distance) as std_distance,
    percentile_approx(
        a.step_length,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as distance_percentile,
    avg(a.detour_ratio) as avg_detour_ratio,
    stddev(a.detour_ratio) as std_detour_ratio,
    percentile_approx(
        a.detour_ratio,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as detour_ratio_percentile
from
    (
        select
            a.uid,
            a.step_length,
            a.distance,
            a.detour_ratio,
            b.home_grid_id,
            b.work_grid_id
        FROM
            indivdiual_step_length a
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

drop table if exists work_aggregate_step_length_wjy_temp_2;

create table if not exists work_aggregate_step_length_wjy_temp_2 as
SELECT
    d.work_grid_id,
    avg(
        pow(
            (d.step_length - d.avg_step_length) / d.std_step_length,
            3
        )
    ) as skew_step_length,
    avg(
        pow(
            (d.step_length - d.avg_step_length) / d.std_step_length,
            4
        )
    ) as kurt_step_length,
    avg(
        pow(
            (d.distance - d.avg_distance) / d.std_distance,
            3
        )
    ) as skew_distance,
    avg(
        pow(
            (d.distance - d.avg_distance) / d.std_distance,
            4
        )
    ) as kurt_distance,
    avg(
        pow(
            (d.detour_ratio - d.avg_detour_ratio) / d.std_detour_ratio,
            3
        )
    ) as skew_detour_ratio,
    avg(
        pow(
            (d.detour_ratio - d.avg_detour_ratio) / d.std_detour_ratio,
            4
        )
    ) as kurt_detour_ratio
from
    (
        select
            a.distance,
            a.step_length,
            a.detour_ratio,
            c.avg_distance,
            c.std_distance,
            c.avg_step_length,
            c.std_step_length,
            c.avg_detour_ratio,
            c.std_detour_ratio,
            a.home_grid_id,
            a.work_grid_id
        from
            (
                select
                    a.uid,
                    a.distance,
                    a.step_length,
                    a.detour_ratio,
                    b.home_grid_id,
                    b.work_grid_id
                FROM
                    indivdiual_step_length a
                    left join (
                        select
                            a.uid,
                            a.home_grid_id,
                            a.work_grid_id
                        from
                            individual_grid_id a
                    ) b on a.uid = b.uid
            ) a
            left join work_aggregate_step_length_wjy_temp_1 c on a.work_grid_id = c.work_grid_id
    ) d
group by
    d.work_grid_id;

drop table if exists work_aggregate_step_length_wjy;

create table if not exists work_aggregate_step_length_wjy as
select
    a.work_grid_id,
    a.avg_step_length,
    a.std_step_length,
    a.step_length_percentile,
    b.kurt_step_length,
    b.skew_step_length,
    a.avg_distance,
    a.std_distance,
    a.distance_percentile,
    b.kurt_distance,
    b.skew_distance,
    a.avg_detour_ratio,
    a.std_detour_ratio,
    a.detour_ratio_percentile,
    b.kurt_detour_ratio,
    b.skew_detour_ratio
from
    work_aggregate_step_length_wjy_temp_1 a
    left join work_aggregate_step_length_wjy_temp_2 b on a.work_grid_id = b.work_grid_id;