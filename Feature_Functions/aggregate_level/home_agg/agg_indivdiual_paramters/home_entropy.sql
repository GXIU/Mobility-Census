--- 说明：以家作为user汇总的单位，提取该地区内部user的entropy的分布特征
--- 提取参数说明
    --- home_grid_id,个体居住地所对应的空间网格id
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

drop table if exists aggregate_entropy_wjy_temp_1;

create table if not exists aggregate_entropy_wjy_temp_1 as
SELECT
    a.home_grid_id,
    avg(a.place_num) as avg_place_num,
    stddev(a.place_num) as std_place_num,
    percentile_approx(
        a.place_num,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as place_num_entropy_percentile,
    avg(a.duration_entropy) as avg_duration_entropy,
    stddev(a.duration_entropy) as std_duration_entropy,
    percentile_approx(
        a.duration_entropy,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as duration_entropy_percentile,
    avg(a.visit_entropy) as avg_visit_entropy,
    stddev(a.visit_entropy) as std_visit_entropy,
    percentile_approx(
        a.visit_entropy,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as visit_entropy_percentile,
    avg(a.visit_num) as avg_visit_num,
    stddev(a.visit_num) as std_visit_num,
    percentile_approx(
        a.visit_num,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as visit_num_percentile,
    avg(a.visit_duration) as avg_visit_duration,
    stddev(a.visit_duration) as std_visit_duration,
    percentile_approx(
        a.visit_duration,
        array(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
        100
    ) as visit_duration_percentile
from
    (
        select
            a.visit_duration,
            a.visit_num,
            a.place_num,
            a.duration_entropy,
            a.visit_entropy,
            b.home_grid_id,
            b.work_grid_id
        FROM
            indivdual_stay_entropy_wjy a
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
    
drop table if exists aggregate_entropy_wjy_temp_2;
create table if not exists aggregate_entropy_wjy_temp_2 as
SELECT
    d.home_grid_id,
    avg(
        pow(
            (d.visit_num - d.avg_visit_num) / d.std_visit_num,
            3
        )
    ) as skew_visit_num,
    avg(
        pow(
            (d.visit_num - d.avg_visit_num) / d.std_visit_num,
            4
        )
    ) as kurt_visit_num,
    avg(
        pow(
            (d.visit_entropy - d.avg_visit_entropy) / d.std_visit_entropy,
            3
        )
    ) as skew_visit_entropy,
    avg(
        pow(
            (d.visit_entropy - d.avg_visit_entropy) / d.std_visit_entropy,
            4
        )
    ) as kurt_visit_entropy,
    avg(
        pow(
            (d.duration_entropy - d.avg_duration_entropy) / d.std_duration_entropy,
            3
        )
    ) as skew_duration_entropy,
    avg(
        pow(
            (d.duration_entropy - d.avg_duration_entropy) / d.std_duration_entropy,
            4
        )
    ) as kurt_duration_entropy,
    avg(
        pow(
            (d.visit_duration - d.avg_visit_duration) / d.std_visit_duration,
            3
        )
    ) as skew_visit_duration,
    avg(
        pow(
            (d.visit_duration - d.avg_visit_duration) / d.std_visit_duration,
            4
        )
    ) as kurt_visit_duration
from
    (
        select
            a.visit_duration,
            a.visit_num,
            a.duration_entropy,
            a.visit_entropy,
            c.avg_duration_entropy,
            c.std_duration_entropy,
            c.avg_visit_entropy,
            c.std_visit_entropy,
            c.avg_visit_num,
            c.std_visit_num,
            c.avg_visit_duration,
            c.std_visit_duration,
            a.home_grid_id,
            a.work_grid_id
        from
            (
                select
                    a.visit_duration,
                    a.visit_num,
                    a.duration_entropy,
                    a.visit_entropy,
                    b.home_grid_id,
                    b.work_grid_id
                FROM
                    indivdual_stay_entropy_wjy a
                    left join (
                        select
                            a.uid,
                            a.home_grid_id,
                            a.work_grid_id
                        from
                            individual_grid_id a
                    ) b on a.uid = b.uid
            ) a
            left join aggregate_entropy_wjy_temp_1 c on a.home_grid_id = c.home_grid_id
    ) d
group by
    d.home_grid_id;
    
drop table if exists aggregate_entropy_wjy;
create table if not exists aggregate_entropy_wjy as
select
    a.home_grid_id,
    a.avg_place_num,
    a.std_place_num,
    a.place_num_entropy_percentile place_num_percentile,
    a.avg_duration_entropy,
    a.std_duration_entropy,
    a.duration_entropy_percentile,
    b.kurt_duration_entropy,
    b.skew_duration_entropy,
    a.avg_visit_entropy,
    a.std_visit_entropy,
    a.visit_entropy_percentile,
    b.kurt_visit_entropy,
    b.skew_visit_entropy,
    a.avg_visit_num,
    a.std_visit_num,
    a.visit_num_percentile,
    b.kurt_visit_num,
    b.skew_visit_num,
    a.avg_visit_duration,
    a.std_visit_duration,
    a.visit_duration_percentile,
    b.kurt_visit_duration,
    b.skew_visit_duration
from
    aggregate_entropy_wjy_temp_1 a
    left join aggregate_entropy_wjy_temp_2 b on a.home_grid_id = b.home_grid_id;
