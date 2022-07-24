
--- 说明：以工作地作为user汇总的单位，提取该地区内部user移动的特征
--- 提取参数说明
    --- work_grid_id,个体工作地所对应的空间网格id
    --- avg_avg_speed, 个体移动速度的平均值
    --- std_avg_speed,
    --- avg_speed_percentile,
    --- kurt_avg_speed,
    --- skew_avg_speed,
    -- avg_sum_commuting_time, 个体通行时间之和的平均值
    --- std_sum_commuting_time,
    --- sum_commuting_time_percentile,
    --- kurt_sum_commuting_time,
    --- skew_sum_commuting_time,
    --- avg_avg_commuting_time, 个体单次通行时间的平均值
    --- #std_avg_commuting_time,
    --- avg_commuting_time_percentile,
    --- kurt_avg_commuting_time,
    --- skew_avg_commuting_time,
    --- avg_daily_movement, 个体每天移动的次数的平均值
    --- std_daily_movement,
    --- daily_movement_percentile,
    --- kurt_daily_movement,
    --- skew_daily_movement
drop table if exists work_aggregate_commuting_wjy_temp_1;

create table if not exists work_aggregate_commuting_wjy_temp_1 as
SELECT
    a.work_grid_id,
    avg(a.avg_speed) as avg_avg_speed,
    stddev(a.avg_speed) as std_avg_speed,
    percentile_approx(
        a.avg_speed,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as avg_speed_percentile,
    avg(a.sum_commuting_time) as avg_sum_commuting_time,
    stddev(a.sum_commuting_time) as std_sum_commuting_time,
    percentile_approx(
        a.avg_speed,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as sum_commuting_time_percentile,
    avg(a.avg_commuting_time) as avg_avg_commuting_time,
    stddev(a.avg_commuting_time) as std_avg_commuting_time,
    percentile_approx(
        a.avg_commuting_time,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as avg_commuting_time_percentile,
    avg(a.daily_movement) as avg_daily_movement,
    stddev(a.daily_movement) as std_daily_movement,
    percentile_approx(
        a.daily_movement,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as daily_movement_percentile
from
    (
        select
            a.uid,
            a.avg_speed,
            a.sum_commuting_time,
            a.avg_commuting_time,
            a.daily_movement,
            b.home_grid_id,
            b.work_grid_id
        FROM
            indivdiual_move_statics a
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

drop table if exists work_aggregate_commuting_wjy_temp_2;

create table if not exists work_aggregate_commuting_wjy_temp_2 as
SELECT
    d.work_grid_id,
    avg(
        pow(
            (d.avg_speed - d.avg_avg_speed) / d.std_avg_speed,
            3
        )
    ) as skew_avg_speed,
    avg(
        pow(
            (d.avg_speed - d.avg_avg_speed) / d.std_avg_speed,
            4
        )
    ) as kurt_avg_speed,
    avg(
        pow(
            (d.sum_commuting_time - d.avg_sum_commuting_time) / d.std_sum_commuting_time,
            3
        )
    ) as skew_sum_commuting_time,
    avg(
        pow(
            (d.sum_commuting_time - d.avg_sum_commuting_time) / d.std_sum_commuting_time,
            4
        )
    ) as kurt_sum_commuting_time,
    avg(
        pow(
            (d.avg_commuting_time - d.avg_avg_commuting_time) / d.std_avg_commuting_time,
            3
        )
    ) as skew_avg_commuting_time,
    avg(
        pow(
            (d.avg_commuting_time - d.avg_avg_commuting_time) / d.std_avg_commuting_time,
            4
        )
    ) as kurt_avg_commuting_time,
    avg(
        pow(
            (d.daily_movement - d.avg_daily_movement) / d.std_daily_movement,
            3
        )
    ) as skew_daily_movement,
    avg(
        pow(
            (d.daily_movement - d.avg_daily_movement) / d.std_daily_movement,
            4
        )
    ) as kurt_daily_movement
from
    (
        select
            a.sum_commuting_time,
            a.avg_speed,
            a.daily_movement,
            a.avg_commuting_time,
            c.avg_sum_commuting_time,
            c.std_sum_commuting_time,
            c.avg_avg_speed,
            c.std_avg_speed,
            c.avg_avg_commuting_time,
            c.std_avg_commuting_time,
            c.avg_daily_movement,
            c.std_daily_movement,
            a.home_grid_id,
            a.work_grid_id
        from
            (
                select
                    a.uid,
                    a.sum_commuting_time,
                    a.avg_speed,
                    a.avg_commuting_time,
                    a.daily_movement,
                    b.home_grid_id,
                    b.work_grid_id
                FROM
                    indivdiual_move_statics a
                    left join (
                        select
                            a.uid,
                            a.home_grid_id,
                            a.work_grid_id
                        from
                            individual_grid_id a
                    ) b on a.uid = b.uid
            ) a
            left join work_aggregate_commuting_wjy_temp_1 c on a.work_grid_id = c.work_grid_id
    ) d
group by
    d.work_grid_id;

drop table if exists work_aggregate_commuting_wjy;

create table if not exists work_aggregate_commuting_wjy as
select
    a.work_grid_id,
    a.avg_avg_speed,
    a.std_avg_speed,
    a.avg_speed_percentile,
    b.kurt_avg_speed,
    b.skew_avg_speed,
    a.avg_sum_commuting_time,
    a.std_sum_commuting_time,
    a.sum_commuting_time_percentile,
    b.kurt_sum_commuting_time,
    b.skew_sum_commuting_time,
    a.avg_avg_commuting_time,
    a.std_avg_commuting_time,
    a.avg_commuting_time_percentile,
    b.kurt_avg_commuting_time,
    b.skew_avg_commuting_time,
    a.avg_daily_movement,
    a.std_daily_movement,
    a.daily_movement_percentile,
    b.kurt_daily_movement,
    b.skew_daily_movement
from
    work_aggregate_commuting_wjy_temp_1 a
    left join work_aggregate_commuting_wjy_temp_2 b on a.work_grid_id = b.work_grid_id;