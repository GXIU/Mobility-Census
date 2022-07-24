--- 说明：个体和空间网格特征
--- 提取参数说明
--- uid：用户id,后续分析关联主键
--- home_grid_id:个体家的位置所处的网格
--- work_grid_id:个体工作地的位置所处的网格



drop table if exists individual_grid_id;

create table individual_grid_id as
select
    a.uid,
    a.home_join_key as home_grid_id,
    a.work_join_key as work_grid_id
from
    (
        select
            a.uid,
            cast(a.home_lon * 200 as bigint) * 100000 + cast(a.home_lat * 200 as bigint) as home_join_key,
            cast(a.work_lon * 200 as bigint) * 100000 + cast(a.work_lat * 200 as bigint) as work_join_key
        from
            (
                select
                    a.uid,
                    a.home_lon,
                    a.home_lat,
                    a.work_lon,
                    a.work_lat,
                    row_number() over (partition by a.uid) as ord
                from
                    user_attribute a
                where
                    a.date >= 20180801
                    and a.date <= 20180901
                    and a.province = '011'
            ) as a
        where
            a.ord = 1
    ) as a left semi
    join (
        select
            a.uid
        from
            indivdual_stay_entropy_wjy a
        where
            a.visit_num >= 3
    ) b on a.uid = b.uid;