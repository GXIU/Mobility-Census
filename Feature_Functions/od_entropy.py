def od_entropy(trj_df, origin_label, destination_label, topk=None):
    """2
    @input:
        #trj_df: columns contains ['user_ids','origin_label','destination_label'], origin_label and destination_label label are the unique id for locations.
    @return:
        # entropy_df: columns contains ['location_id',"entropy"] ratio---the in_flow/out_flow
    @example:
        values_o = np.random.randint(0,100,100000)
        values_d = np.random.randint(0,100,100000)
        od_flow = np.array(list(zip(values_o,values_d)))
        trj_df = pd.DataFrame(od_flow,columns=['o_id','d_id'])
        df=od_entropy(trj_df,'o_id','d_id',4)
    """
    # 统计每个od的流量大小
    trj_df["weight"] = 1  # 以后方便更改weight输入
    grouped_df = (
        trj_df[[origin_label, destination_label, "weight"]]
        .fillna(0)
        .groupby([origin_label, destination_label])
        .sum()
    )
    grouped_df = grouped_df.reset_index()

    # 计算出入流
    def __get_entropy(df):
        if topk != None:
            val = df["weight"].values[-topk - 1 :]
        else:
            val = df["weight"].values
        p = val / val.sum()
        return scipy.stats.entropy(p)

    out_df = (
        grouped_df[[origin_label, "weight"]].groupby(origin_label).apply(__get_entropy)
    )
    dict_results = {"o_id": out_df.index, "entropy": out_df.values}
    out_df = pd.DataFrame(dict_results)
    return out_df
