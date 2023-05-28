import numpy as np
import pandas as pd


def get_flow_in_out_ratio(trj_df, origin_label, destination_label):
    """
    @input:
        #trj_df: columns contains ['user_ids','origin_label','destination_label'], origin_label and destination_label label are the unique id for locations.
    @return:
        # ratio_df: columns contains ['location_id',"ratio"]

    @example:
        values_o = np.random.randint(0,100,100000)
        values_d = np.random.randint(0,100,100000)
        od_flow = np.array(list(zip(values_o,values_d)))
        trj_df = pd.DataFrame(od_flow,columns=['o_id','d_id'])
        df=get_flow_in_out_ratio(trj_df,'o_id','d_id')
        import seaborn as sns
        sns.distplot(df['out_in_ratio'])
    """

    # 统计每个od的流量大小
    trj_df["weight"] = 1
    grouped_df = (
        trj_df[[origin_label, destination_label, "weight"]]
        .fillna(0)
        .groupby([origin_label, destination_label])
        .sum()
    )
    grouped_df = grouped_df.reset_index()

    # 计算出入流
    out_df = (
        grouped_df[[origin_label, "weight"]].groupby(origin_label).sum().reset_index()
    )
    in_df = (
        grouped_df[[destination_label, "weight"]]
        .groupby(destination_label)
        .sum()
        .reset_index()
    )
    ratio_df = out_df.merge(
        right=in_df,
        left_on=origin_label,
        right_on=destination_label,
        suffixes=["_out", "_in"],
    ).fillna(0)
    ratio_df["out_in_ratio"] = ratio_df["weight_in"] / ratio_df["weight_out"]

    return ratio_df[["weight_in", "weight_out", "out_in_ratio"]]
