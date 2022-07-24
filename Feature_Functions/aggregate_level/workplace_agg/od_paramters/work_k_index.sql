--- 说明：以移动od为研究对象，分析地区交互的h-index
--- 提取参数说明
    --- grid_id,od 中d点的id
    --- k_index, od metrix中的h-index，即对于一个网格而言，有最多k个od其流量大于k


drop table if exists work_aggregate_k_index;

create table work_aggregate_k_index as
select
    a.end_grid as grid_id,
    count(1) as k_index
from
    (
        select
            a.end_grid,
            a.flow,
            row_number() over (
                partition by a.end_grid
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
    a.end_grid;
    