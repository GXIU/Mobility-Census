import pandas as pd
import numpy as np


def k_index(trj_df, origin_label, destination_label, scale=10):
    """
    @input:
        #trj_df: columns contains ['user_ids','origin_label','destination_label'], origin_label and destination_label label are the unique id for locations.
        # scale: a parameter to rescale the flow as flow_=flow*scale, therefore to relieve the influence of the scale of the population
        if scale ==None, we use the percentile as a parameters
    @return:
        # k_index_df: columns contains ['location_id',"k_index"]
    """
    trj_df["weight"] = 1
    grouped_df = (
        trj_df[[origin_label, destination_label, "weight"]]
        .fillna(0)
        .groupby([origin_label, destination_label])
        .sum()
    )
    grouped_df = grouped_df.reset_index()
    if scale == None:
        grouped_df["rank"] = 0
        loc_num = grouped_df.shape[0]
        percentiles = np.linspace(0, loc_num, 100)
        # 根据percentile对数据进行分组
        thresholds = np.percentiles(grouped_df["weight"].values, percentiles)
        for index, threshold in enumerate(thresholds):
            grouped_df.loc[grouped_df[destination_label] > threshold, "rank"] = index
    else:
        grouped_df["rank"] = grouped_df["weight"] * scale

    def __get_rank(df):
        # df['order'] = df['weight'].rank(method = 'min')
        df = df.sort_values("weight")
        df["order"] = np.arange(df.shape[0])
        return df.loc[df["order"] >= df["rank"]].shape[0]

    data = (
        grouped_df[[origin_label, "weight", "rank"]]
        .groupby(origin_label)
        .apply(__get_rank)
    )
    return data, grouped_df


if __name__ == "__main__":
    values_o = np.random.randint(0, 10, 100)
    values_d = np.random.randint(0, 10, 100)
    od_flow = np.array(list(zip(values_o, values_d)))
    trj_df = pd.DataFrame(od_flow, columns=["o_id", "d_id"])
    data, goruped_df = k_index(trj_df, "o_id", "d_id", scale=1)
    goruped_df[["o_id", "weight", "rank"]].head(29)
