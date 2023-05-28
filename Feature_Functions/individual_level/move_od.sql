--- 说明：根据个体停留点来提取od
--- 提取参数说明
--- uid：用户id,后续分析关联主键
--- start_grid, 移动起点所对应的grid_id
--- end_grid, 移动终点所对应的grid_id
--- 起点所对应的时间 start_hour,
--- weekday,起点所对应的weekday

drop table if exists aggregate_move_temp_1;

create table aggregate_move_temp_1 as
select
    a.uid,
    a.poi_id,
    b.weighted_centroid_lat,
    b.weighted_centroid_lon,
    cast(b.weighted_centroid_lon * 200 as bigint) * 100000 + cast(b.weighted_centroid_lat * 200 as bigint) as join_key,
    from_unixtime(a.stime,'yyyy-MM-dd-HH') as htime,
    from_unixtime(a.stime, 'EEEE') as weekday,
    row_number() over (
        partition by a.uid
        order by
            stime
    ) as rnk1
from
    (
        select
            a.uid,
            a.poi_id,
            unix_timestamp(a.stime, 'yyyy/MM/dd HH:mm') as stime
        from
            stay_month a
        where
            a.date >= 20180801
            and a.date <= 20180901
            and a.province = 011
            and a.is_core = 'Y'
    ) a
    join (
        select
            a.uid,
            a.poi_id,
            a.weighted_centroid_lat,
            a.weighted_centroid_lon
        from
            stay_poi a
        where
            a.date >= 20180801
            and a.date <= 20180901
            and a.province = 011
            and a.is_core = 'Y'
    ) b on a.uid = b.uid
    and a.poi_id = b.poi_id;

drop table if exists aggregate_move_od;

create table aggregate_move_od as
select
    a.uid,
    b.join_key as start_grid,
    a.join_key as end_grid,
    a.htime as start_hour,
    substr(a.htime,12) as hour,
    a.weekday
from
    aggregate_move_temp_1 a
    join (
        select
            a.uid,
            a.poi_id,
            a.join_key,
            a.rnk1 + 1 as rnk2
        from
            aggregate_move_temp_1 a
    ) b on a.uid = b.uid;