--- 说明：提取个体trip的距离特征
--- 提取参数说明
--- uid：用户id,后续分析关联主键
--- distance:trip的轨迹距离
--- step_length：trip的起点和终点的欧式距离
--- detour_ratio：distance和step_length的比值



drop table if exists indivdiual_step_length_temp1;

create table if not exists indivdiual_step_length_temp1 as
select
    d.uid,
    d.distance,
    sqrt(
        (d.start_centroid_lat - d.end_centroid_lat) *(d.start_centroid_lat - d.end_centroid_lat) +(d.start_centroid_lon - d.end_centroid_lon) *(d.start_centroid_lon - d.end_centroid_lon)
    ) as step_length,
    d.distance/sqrt(
        (d.start_centroid_lat - d.end_centroid_lat) *(d.start_centroid_lat - d.end_centroid_lat) +(d.start_centroid_lon - d.end_centroid_lon) *(d.start_centroid_lon - d.end_centroid_lon)
    ) as detour_ratio
from
    (
        select
            a.uid,
            a.distance,
            b.centroid_lat as start_centroid_lat,
            b.centroid_lon as start_centroid_lon,
            c.centroid_lat as end_centroid_lat,
            c.centroid_lon as end_centroid_lon
        from
            move_month a
            left join grid b on a.start_grid_id = b.grid_id
            left join grid c on a.end_grid_id = c.grid_id
        where
            a.date >= 20180801
            and a.date < 20180901
            and a.is_core = 'Y'
            and a.province = '011'
    ) d;
    
    
drop table if exists indivdiual_step_length;
create table if not exists indivdiual_step_length as
select
    d.uid,
    avg(d.distance) as distance,
    avg(d.step_length) as step_length,
    avg(if(
            d.distance < 500,
            null,
            d.detour_ratio
        )) as detour_ratio
from
    indivdiual_step_length_temp1 d group by d.uid;
    
select   step_length,detour_ratio from indivdiual_step_length limit 1000;