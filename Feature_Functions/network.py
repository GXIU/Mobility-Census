# -*- coding: utf-8 -*-

import networkx as nx
import numpy as np
import pandas as pd


def create_graph(trj_df, origin_label, destination_label):
    '''
    @input:
        # trj_df: columns contains ['user_ids','origin_label','destination_label'], origin_label and destination_label label are the unique id for locations.
    @return:
        # g: a digraph.
    '''
    trj_df['weight'] = 1
    g = nx.DiGraph()
    # print(trj_df[[origin_label, destination_label, 'weight']].values)
    g.add_weighted_edges_from(trj_df[[origin_label, destination_label, 'weight']].values)
    return g


def get_degree(g):
    '''
        @input:
            # g: a digraph.
        @return:
            # node_deg: columns contains ['location_id', 'deg', 'in_deg', 'out_deg']
    '''
    deg = np.array(g.degree())
    in_deg = np.array(g.in_degree())[:, 1].reshape((-1, 1))
    out_deg = np.array(g.out_degree())[:, 1].reshape((-1, 1))

    node_deg = pd.DataFrame(np.hstack((deg, in_deg, out_deg)), columns=['location_id', 'deg', 'in_deg', 'out_deg'])
    return node_deg


def get_centrality(g):
    '''
        @input:
            # g: a digraph.
        @return:
            # node_centrality: columns contains ['location_id', 'dc', 'in_dc', 'out_dc', 'katz_c', 'cc']
                dc - degree centrality
                in_dc - in_degree centrality
                out_dc - out_degree centrality
                katz_c - Katz centrality
                cc - closeness centrality
    '''
    dc = nx.degree_centrality(g)
    in_dc = nx.in_degree_centrality(g)
    out_dc = nx.out_degree_centrality(g)
    katz_c = nx.katz_centrality_numpy(g, alpha=0.1, beta=1.0)
    cc = nx.closeness_centrality(g)

    node_centrality = []
    for k, v in dc.items():
        node_centrality.append([k, v, in_dc[k], out_dc[k], katz_c[k], cc[k]])
    node_centrality = pd.DataFrame(node_centrality, columns=['location_id', 'dc', 'in_dc', 'out_dc', 'katz_c', 'cc'])
    return node_centrality


if __name__ == '__main__':
    values_o = np.random.randint(0, 5, 4)
    values_d = np.random.randint(0, 5, 4)
    od_flow = np.array(list(zip(values_o, values_d)))
    trj_df = pd.DataFrame(od_flow, columns=['o_id', 'd_id'])

    g = create_graph(trj_df, 'o_id', 'd_id')

    node_deg = get_degree(g)
    print(node_deg)

    node_centrality = get_centrality(g)
    print(node_centrality)
