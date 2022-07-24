--- 说明：提取个体trip的距离特征
--- 提取参数说明
--- uid：用户id,后续分析关联主键
--- avg_speed:个体出行的平均速度
--- avg_length：个体出行的平均距离
--- sum_commuting_time：个体三十天在途时间之和
--- avg_commuting_time：个体每次出行的时间的平均值
--- others_mode/road_mode/railway_mode/airplane_mode/subway_mode 出行模式
--- daily_movement 每日移动的数量


drop table if exists indivdiual_move_statics;

create table if not exists indivdiual_move_statics as
select
    a.uid,
    avg(
        if(
            (
                a.distance < 500
                or a.speed > 150
            ),
            null,
            a.speed
        )
    ) as avg_speed,
    avg(a.distance) as avg_length,
    sum(time) / count(distinct date) as sum_commuting_time,
    avg(time) as avg_commuting_time,
    sum(if(moi_id == 0, 1, 0)) as others_mode,
    sum(if(moi_id == 1, 1, 0)) as road_mode,
    sum(if(moi_id == 2, 1, 0)) as railway_mode,
    sum(if(moi_id == 3, 1, 0)) as airplane_mode,
    sum(if(moi_id == 4, 1, 0)) as subway_mode,
    count(1) / count(distinct date) as daily_movement
from
    move_month a
where
    a.date >= 20180801
    and a.date < 20180901
    and a.is_core = 'Y'
    and a.province = '011'
group by
    a.uid;
    
-- select avg_speed from indivdiual_move_statics where avg_speed>0 limit 100;