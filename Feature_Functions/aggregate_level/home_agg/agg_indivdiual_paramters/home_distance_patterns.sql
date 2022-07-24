
--- 说明：以家作为user汇总的单位，提取该地区内部user移动的特征
--- 提取参数说明
    --- home_grid_id,个体居住地所对应的空间网格id
    --- avg_step_length, 个体移动步长平均值 （步长==欧氏距离）
    --- std_step_length, 方差
    --- step_length_percentile,十分位
    --- kurt_step_length,峰度
    --- skew_step_length, 偏度
    --- avg_distance, 个体移动距离的平均值 （移动距离==真实的轨迹距离）
    --- std_distance, 方差
    --- distance_percentile,十分位
    --- kurt_distance, 峰度
    --- skew_distance, 偏度
    --- avg_detour_ratio, 个体每次移动的距离与步长之比的平均值
    --- std_detour_ratio, 方差
    --- detour_ratio_percentile, 十分位
    --- kurt_detour_ratio, 峰度
    --- skew_detour_ratio，偏度
drop table if exists aggregate_step_length_wjy_temp_1;

create table if not exists aggregate_step_length_wjy_temp_1 as
SELECT
    a.home_grid_id,
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
    a.home_grid_id;

drop table if exists aggregate_step_length_wjy_temp_2;

create table if not exists aggregate_step_length_wjy_temp_2 as
SELECT
    d.home_grid_id,
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
            left join aggregate_step_length_wjy_temp_1 c on a.home_grid_id = c.home_grid_id
    ) d
group by
    d.home_grid_id;

drop table if exists aggregate_step_length_wjy;

create table if not exists aggregate_step_length_wjy as
select
    a.home_grid_id,
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
    aggregate_step_length_wjy_temp_1 a
    left join aggregate_step_length_wjy_temp_2 b on a.home_grid_id = b.home_grid_id;
    
select avg_detour_ratio,avg_step_length from aggregate_step_length_wjy limit 100;