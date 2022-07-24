--- 说明：提取个体访问各个地区（0.05°*0.05°）的可预测性，即熵值。
--- 提取参数说明
--- uid：用户id,后续分析关联主键
--- visit_entropy:访问各个地点的熵值，按照访问频率作为权重
--- duration_entropy： 访问各个地点的熵值，按照访问时间作为权重
--- visit_num：访问各个地点频次之和
--- visit_duration：访问各个地点的时间之和
--- place_num：访问去重地点id的数量.后续用来筛除观测时间内未发生移动的个体。

drop table if exists indivdual_stay_point_wjy;

create table if not exists indivdual_stay_point_wjy as
select
    sum(b.stay_fre) as cnt,
    sum(b.duration) as duration,
    b.uid,
    b.grid_id
from
    (
        select
            a.weekday_day_time + a.weekday_eve_time + a.weekend_day_time + a.weekend_eve_time as duration,
            a.stay_fre,
            a.uid,
            cast(a.weighted_centroid_lon * 200 as bigint) * 100000 + cast(a.weighted_centroid_lat * 200 as bigint) as grid_id
        from
            stay_poi a
        where
            a.date >= 20180801
            and a.date <= 20180901
            and a.is_core = 'Y'
            and a.province = '011'
    ) b
group by
    b.uid,
    b.grid_id;


drop table if exists indivdual_stay_sum_cache;
create table if not exists indivdual_stay_sum_cache as
select
    sum(a.cnt) as visit_num,
    sum(a.duration) as visit_duration,
    count(distinct grid_id) as place_num,
    a.uid
from
    indivdual_stay_point_wjy a
group by
    a.uid;

drop table if exists indivdual_stay_p_cache;
create table if not exists indivdual_stay_p_cache as
select
    -(a.cnt / b.visit_num) * log2(a.cnt / b.visit_num) as visit_logp,
    -(a.duration / b.visit_duration) * log2(a.duration / b.visit_duration) as duration_logp,
    a.uid
from
    indivdual_stay_point_wjy a
    left join indivdual_stay_sum_cache b on a.uid = b.uid;

drop table if exists indivdual_stay_entropy_wjy;
create table if not exists indivdual_stay_entropy_wjy as
select
    c.uid,
    c.visit_entropy,
    c.duration_entropy,
    b.visit_num,
    b.visit_duration,
    b.place_num
from
    (
        select
            a.uid,
            sum(a.visit_logp) as visit_entropy,
            sum(a.duration_logp) as duration_entropy
        from
            indivdual_stay_p_cache a
        group by
            a.uid
    ) c
    left join indivdual_stay_sum_cache b on c.uid = b.uid;
    
    
select a.visit_entropy,
    a.duration_entropy,
    a.visit_num,
    a.visit_duration,a.place_num from indivdual_stay_entropy_wjy a limit 1000;
    
