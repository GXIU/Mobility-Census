-- 说明： 计算各个地区的rog,用以度量个体在观测期间访问的空间的覆盖范围the radius of gyration
-- 参数说明：
--- rog： 以访问频率为权重的个体访问各个地区的回转半径。
--- rog_T: 以访问时间为权重的个体移动回转半径。

drop table if exists indivdiual_stay_xy;
create table if not exists indivdiual_stay_xy as
select
    a.uid,
    a.weighted_centroid_lat as centroid_lat,
    a.weighted_centroid_lon as centroid_lon,
    a.stay_fre as cnt,
    a.weekday_day_time + a.weekday_eve_time + a.weekend_day_time + a.weekend_eve_time as duration
from
    stay_poi a
    where
    a.date >= 20180801
    and a.date <= 20180901 
    and a.is_core = 'Y'
    and a.province = '011';
   
    
drop table if exists indivdiual_stay_xy_mean;
create table if not exists indivdiual_stay_xy_mean as
select
    a.uid,
    sum(a.centroid_lat*a.cnt)/sum(a.cnt) as centroid_lat_mean,
    sum(a.centroid_lon*a.cnt)/sum(a.cnt) as centroid_lon_mean,
    sum(a.centroid_lat*a.duration)/sum(a.duration) as centroid_lat_mean_t,
    sum(a.centroid_lon*a.duration)/sum(a.duration) as centroid_lon_mean_t
from
    indivdiual_stay_xy a
group by
    a.uid;

    
drop table if exists indivdiual_stay_rog;
create table if NOT exists indivdiual_stay_rog as
select
    c.uid,
    sqrt(sum((c.x_div + c.y_div)*c.cnt)/sum(c.cnt)) as rog,
    sqrt(sum((c.x_div_t + c.y_div_t)*c.duration)/sum(c.duration)) as rog_T
from
    (
        select
            a.uid,
            a.cnt,
            a.duration,
            (a.centroid_lat - b.centroid_lat_mean) *(a.centroid_lat - b.centroid_lat_mean) as x_div,
            (a.centroid_lon - b.centroid_lon_mean) *(a.centroid_lon - b.centroid_lon_mean) as y_div,
             (a.centroid_lat - b.centroid_lat_mean_t) *(a.centroid_lat - b.centroid_lat_mean_t) as x_div_t,
            (a.centroid_lon - b.centroid_lon_mean_t) *(a.centroid_lon - b.centroid_lon_mean_t) as y_div_t
        from
            indivdiual_stay_xy a
            left join indivdiual_stay_xy_mean b on a.uid = b.uid
    ) c
group by
    c.uid;
