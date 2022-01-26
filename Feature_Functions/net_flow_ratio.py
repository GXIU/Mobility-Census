# -*- coding: utf-8 -*-

import numpy as np
import pandas as pd


def get_net_flow_ratio(trj_df, origin_label, destination_label):
    '''
    @input:
        # trj_df: columns contains ['user_ids','origin_label','destination_label'], origin_label and destination_label label are the unique id for locations.
    @return:
        # net_flow_ratio: columns contains ['location_id', 'net_flow_ratio']
    '''
    trj_df['weight'] = 1
    grouped_df = trj_df[[origin_label, destination_label, 'weight']].fillna(0).groupby([origin_label, destination_label]).sum()
    grouped_df = grouped_df.reset_index()

    out_flow = grouped_df[[origin_label, 'weight']].groupby(origin_label).sum().reset_index()
    in_flow = grouped_df[[destination_label, 'weight']].groupby(destination_label).sum().reset_index()
    ratio_df = out_flow.merge(right=in_flow, how='outer', left_on=origin_label, right_on=destination_label, suffixes=['_out', '_in']).fillna(0)
    ratio_df['location_id'] = ratio_df[['o_id', 'd_id']].max(axis=1).map(int)
    ratio_df['net_flow_ratio'] = ratio_df['weight_in'] - ratio_df['weight_out'] / (ratio_df['weight_in'] + ratio_df['weight_out'])

    return ratio_df[['location_id', 'net_flow_ratio']]


if __name__ == '__main__':
    values_o = np.random.randint(0, 5, 4)
    values_d = np.random.randint(0, 5, 4)
    od_flow = np.array(list(zip(values_o, values_d)))
    trj_df = pd.DataFrame(od_flow, columns=['o_id', 'd_id'])

    nfr = get_net_flow_ratio(trj_df, 'o_id', 'd_id')
    print(nfr)
