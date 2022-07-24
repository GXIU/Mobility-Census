--- 说明：以移动od为研究对象，分析地区交互的h-index
--- 提取参数说明
    --- grid_id,od 中o点的id
    --- k_index, od metrix中的h-index，即对于一个网格而言，有最多k个od，其od流量大于k

drop table if exists aggregate_move_temp_1;

create table aggregate_move_temp_1 as
select
    a.uid,
    a.poi_id,
    b.weighted_centroid_lat,
    b.weighted_centroid_lon,
    cast(b.weighted_centroid_lon * 200 as bigint) * 100000 + cast(b.weighted_centroid_lat * 200 as bigint) as join_key,
    a.stime,
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
            a.date >= 20210501
            and a.date <= 20210528
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
            a.date >= 20210501
            and a.date <= 20210528
            and a.province = 011
            and a.is_core = 'Y'
    ) b on a.uid = b.uid
    and a.poi_id = b.poi_id;

drop table if exists aggregate_move_od_temp;

create table aggregate_move_od_temp as
select
    a.uid,
    b.join_key as start_grid,
    a.join_key as end_grid
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

drop table if exists aggregate_k_index;

create table aggregate_k_index as
select
    a.start_grid as grid_id,
    count(1) as k_index
from
    (
        select
            a.start_grid,
            a.flow,
            row_number() over (
                partition by a.start_grid
                order by
                    flow DESC
            ) as rnk
        from
            (
                select
                    a.start_grid,
                    a.end_grid,
                    count(1) as flow
                from
                    aggregate_move_od_temp a
                group by
                    start_grid,
                    end_grid
            ) a
    ) a
where
    a.rnk <= a.flow
group by
    a.start_grid;
    
-- select
--     a.rnk,
--     a.flow
-- from
--     (
--         select
--             a.start_grid,
--             a.flow,
--             row_number() over (
--                 partition by a.start_grid
--                 order by
--                     flow DESC
--             ) as rnk
--         from
--             (
--                 select
--                     a.start_grid,
--                     a.end_grid,
--                     count(1) as flow
--                 from
--                     aggregate_move_od_temp a
--                 where
--                     a.start_grid = "2325907996"
--                 group by
--                     start_grid,
--                     end_grid
--             ) a
--     ) a
--     order by a.rnk limit 1000;
    