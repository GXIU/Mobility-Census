import os
import argparse

import contextily as cx
import geopandas as gpd
import matplotlib.pyplot as plt
import networkx as nx
import numpy as np
import pandas as pd
import scipy.sparse as ss
import scipy.sparse.linalg as ssl
import torch
from torch import nn
from tqdm import tqdm, trange

def diffusion_maps(census, plot=False, k=10, number_of_EVs=50, num_part=50, n_neighbors=100, pairwise_dist_dir='./data/pairwise_distances/', to_dir='./data/eigen_dir/', shape_dir='./data/shape_dir/', figs_dir='./data/figs_dir/'):
    '''
    Diffusion maps on census data.
    '''
    census_ = standardized(census.copy(), how='z').dropna()
    census_ = census_.loc[:, census_.std() > 0]
    for i in range(num_part):
        pairwise_distances(census_, part_id=i, num_part=num_part, how='corr', n_neighbors=n_neighbors, to_dir=pairwise_dist_dir)
    eigenfeatures = eigen_decomposition(census_, pairwise_dist_dir, to_dir, shape_dir=shape_dir, k=k, number_of_EVs=number_of_EVs)
    if plot:
        plotting(to_dir, figs_dir, local_shape_dir=shape_dir, low=1, high=95)

    return pd.DataFrame(eigenfeatures, index=census.index)

def pearsonr(data_from, data_to, dim=1, row_based=True):
    if not row_based:
        x = torch.Tensor(data_from.values).T
    else:
        x = torch.Tensor(data_from.values)
    y = torch.Tensor(data_to.values).repeat(x.shape[0], 1)
    assert x.shape == y.shape
    centered_x = x - x.mean(dim=dim, keepdim=True)
    centered_y = y - y.mean(dim=dim, keepdim=True)
    covariance = (centered_x * centered_y).sum(dim=1, keepdim=True)
    bessel_corrected_covariance = covariance / (x.shape[1] - 1)
    x_std = x.std(dim=dim, keepdim=True)
    y_std = y.std(dim=dim, keepdim=True)
    corr = (bessel_corrected_covariance / (x_std * y_std)).T[0].numpy()
    if row_based:
        return pd.Series(corr, data_from.index)
    else:
        return pd.Series(corr, data_from.columns)


def pearsonr_against(data_from, data_super_to, batch_size=100, k=10, batch_first=True, row_based=True):
    if row_based:
        data_from, data_super_to = data_from.T, data_super_to.T
    '''
    Pearson_corr between a m x n dataframe and a m x k dataframe, returns an n * k correlation matrix.
    Usage: A.corragainst(B)
    '''
    num_batches = int(np.ceil(data_super_to.shape[1] / batch_size))
    corr_total = None

    for i in trange(num_batches):
        start_index = i * batch_size
        end_index = start_index + batch_size
        batch_super_to = data_super_to.iloc[:, start_index:end_index]

        x = torch.Tensor(data_from.values).repeat_interleave(
            batch_super_to.shape[1], dim=1).T
        y = torch.Tensor(batch_super_to.values).repeat(1, data_from.shape[1]).T
        assert x.shape == y.shape

        if batch_first:
            dim = -1
        else:
            dim = 0

        centered_x = x - x.mean(dim=dim, keepdim=True)
        centered_y = y - y.mean(dim=dim, keepdim=True)
        covariance = (centered_x * centered_y).sum(dim=dim, keepdim=True)
        bessel_corrected_covariance = covariance / (x.shape[dim] - 1)
        x_std = x.std(dim=dim, keepdim=True)
        y_std = y.std(dim=dim, keepdim=True)
        corr_batch = (bessel_corrected_covariance /
                      (x_std * y_std)).T[0].numpy()

        # Reshape and retain k largest correlations in each row and set the rest to 0
        corr_batch_reshaped = corr_batch.reshape((data_from.shape[1], -1))
        indices_of_k_largest = np.argpartition(
            corr_batch_reshaped, -k, axis=1)[:, -k-1:-1]
        mask = np.ones(corr_batch_reshaped.shape, dtype=bool)
        np.put_along_axis(mask, indices_of_k_largest, False, axis=1)
        corr_batch_reshaped[mask] = 0
        corr_batch = corr_batch_reshaped.flatten()

        if corr_total is None:
            corr_total = corr_batch
        else:
            corr_total = np.hstack((corr_total, corr_batch))

    return pd.Series(corr_total, pd.MultiIndex.from_product([data_from.columns, data_super_to.columns],
                                                            names=[data_from.index.name, data_super_to.index.name]))

# 1. standardizing


def standardized(original_census: pd.DataFrame,
                 how='z',
                 low=0.1,
                 high=99.9,
                 non_allowance=10000,
                 to_dir="./",
                 save=True
                 ):
    """
    Standardize the census data.

    Parameters
    ----------
    low : float, optional
        The lower percentile to clip.
    high : float, optional
        The upper percentile to clip.
    non_allowance : int, optional
        The maximum number of missing values allowed.
    census_dir : str, optional
        The path to the original census data.
    to_dir : str, optional
        The path to the directory where the standardized data will be saved.

    Returns
    -------
    pd.DataFrame
        The standardized census data.
    """
    nan_check = original_census.isna()
    census = pd.DataFrame(
        original_census,
        columns=nan_check.columns[nan_check.sum() < non_allowance].values,
    )
    census = census[census.isna().sum(axis=1) == 0]

    if how == 'z':
        percentiles = np.percentile(census, [low, high], axis=0)
        census = pd.DataFrame(census.clip(percentiles[0], percentiles[1]))
        census = census - census.mean()
        census = census / census.std(axis=0)
        census = census.fillna(0)
    elif how == 'rank':
        census = 2 * census.rank() / census.shape[0] - 1
        census = census.fillna(0)
    else:
        raise NotImplementedError
    census.sort_index(inplace=True)
    if save:
        if to_dir is not None:
            os.makedirs(to_dir, exist_ok=True)
        census.to_hdf(f"{to_dir}/standardized_census_{how}.hdf", "standardized_census")
            
    return census


def pairwise_distances(census, part_id, num_part=40, n_neighbors=100,
                       how='distance', to_dir="../data/pairwise_distances/"):
    """_summary_

    Args:
        census (_type_): _description_
        part_id (_type_): _description_
        num_part (int, optional): _description_. Defaults to 40.
        n_neighbors (int, optional): _description_. Defaults to 100.
        how (str, optional): _description_. Defaults to 'distance'.
        to_dir (str, optional): _description_. Defaults to "../data/pairwise_distances/".
    """    
    data_to = torch.Tensor(census.values)
    len_slice = int(data_to.shape[0] // (num_part - 1))
    slice_ = census.iloc[part_id * len_slice: (part_id + 1) * len_slice, :]

    distances = []
    if how == 'distance':    
        for location_id, feature in tqdm(slice_.iterrows()):
            data_from = torch.Tensor(feature)  # m identical rows
            data_from = data_from.repeat((data_to.shape[0], 1))
            distance_vec = nn.functional.pairwise_distance(
                data_from, data_to, p=2).numpy()
            # Keep only n_neighbors smallest distances, set the rest to a large value
            indices_of_smallest = np.argpartition(
                distance_vec, n_neighbors)[:n_neighbors]
            mask = np.ones(distance_vec.shape, dtype=bool)
            mask[indices_of_smallest] = False
            distance_vec[mask] = np.inf

            result = pd.Series(distance_vec, index=census.index)
            result = result.reset_index()
            result.insert(0, "ego", location_id, True)
            distances.append(result.values)
    elif how == 'corr':
        for location_id, feature in tqdm(slice_.iterrows()):
            corr_vec = (1/pearsonr(census, feature).nlargest(n_neighbors)).reset_index()
            corr_vec.insert(0, "ego", location_id, True)
            distances.append(corr_vec.values)

    pd.to_pickle(distances, f"{to_dir}/{part_id}.p", protocol=4)


def eigen_decomposition(
    census, pairwise_distance_dir, to_dir, shape_dir,  # shapefile .shp
    k=10, number_of_EVs=50, dist=True
):
    """_summary_

    Args:
        census (_type_): _description_
        pairwise_distance_dir (_type_): _description_
        to_dir (_type_): _description_
        shape_dir (_type_): _description_
        number_of_EVs (int, optional): _description_. Defaults to 50.
        dist (bool, optional): _description_. Defaults to True.

    Returns:
        _type_: _description_
    """    
    data_to = torch.Tensor(census.values)
    shape = gpd.read_file(shape_dir).set_index("geo_code")
    pairwisefiles = [
        x for x in os.listdir(pairwise_distance_dir) if (".p" in x) and (x[0] != ".")
    ]
    pairwise_distances = np.concatenate(
        [pd.read_pickle(f"{pairwise_distance_dir}/" + file)
         for file in pairwisefiles]
    )
    edgelist = np.concatenate([x[:k]
                              for x in tqdm(pairwise_distances)])  # k closest

    # constructing complex network
    indexing = dict(zip(census.index, np.arange(census.shape[0])))
    sources = [indexing[x] for x in edgelist[:, 0]]
    targets = [indexing[x] for x in edgelist[:, 1]]
    From = sources + targets
    To = targets + sources
    if dist == True:
        Prob = np.tile(1 / (edgelist[:, 2].astype(float)), 2)
    else:  # correlations
        Prob = np.tile((edgelist[:, 2].astype(float)), 2)
    X = ss.csr_matrix((Prob, (From, To)))  # sparse csr matrix
    G = nx.Graph()
    G.add_edges_from(np.array([sources, targets]).T)
    print(
        f"G of {X.shape[0]} nodes is connected for k = {k}? ", nx.is_connected(G))
    for i, row in tqdm(enumerate(X)):
        X[i, :] = row / np.sum(row)
    adjacency = ss.identity(len(census.index), format="csr") - X.tocsr()
    print("adjacency matrix got")
    eigvals, eigvecs = ssl.eigs(adjacency, k=number_of_EVs, which="SR")
    sorts = np.argsort(eigvals.real)
    eigvals, eigvecs = eigvals[sorts], eigvecs[:, sorts]
    features = pd.DataFrame(eigvecs.real, index=census.index)
    features.index.rename("geo_code", inplace=True)

    features = shape.join(features)

    features.columns = features.columns.astype(str)
    features.to_file(to_dir)
    return features


def plotting(features_dir, to_dir, local_shape_dir=None, low=1, high=95):
    """_summary_

    Args:
        features_dir (_type_): _description_
        to_dir (_type_): _description_
        local_shape_dir (_type_, optional): _description_. Defaults to None.
        low (int, optional): _description_. Defaults to 1.
        high (int, optional): _description_. Defaults to 95.
    """    
    if not os.path.isdir(to_dir):
        os.mkdir(to_dir)
    features = gpd.read_file(features_dir).set_index("geo_code")
    if local_shape_dir != None:
        local_shape = gpd.read_file(local_shape_dir)
        local_features = features.loc[local_shape.index, :]
        for i in trange(50):
            str_i = str(i)
            low_pct, high_pct = np.percentile(
                local_features[str_i], [low, high], axis=0
            )
            ax = local_features.plot(
                figsize=(40, 40),
                alpha=0.55,
                vmin=low_pct,
                vmax=high_pct,
                column=str_i,
                cmap="bwr",
            )
            ax.set_title(f"Eigenvector {str_i}")
            cx.add_basemap(
                ax,
                crs=local_features.crs.to_string(),
                source=cx.providers.Stamen.TonerLite,
            )
            plt.savefig(f"{to_dir}/{str_i}.png")
            plt.cla()
    else:  # global case
        for i in trange(50):
            str_i = str(i)
            low_pct, high_pct = np.percentile(
                features[str_i], [low, high], axis=0)
            ax = features.plot(
                figsize=(40, 40),
                alpha=0.55,
                vmin=low_pct,
                vmax=high_pct,
                column=str_i,
                cmap="bwr",
            )
            ax.set_title(f"Eigenvector {str_i}")
            cx.add_basemap(
                ax, crs=features.crs.to_string(), source=cx.providers.Stamen.TonerLite
            )
            plt.savefig(f"{to_dir}/{str_i}.png")
            plt.cla()

if __name__=='__main__':
    args = argparse.ArgumentParser()
    census_dir = args.census_dir

    pd.core.frame.DataFrame.corrwith = pearsonr
    pd.core.frame.DataFrame.corragainst = pearsonr_against

    original_census = pd.read_csv(census_dir, index_col='GeographyCode')
    diffusion_maps(original_census, args.to_dir, args.shape_dir, args.k, args.dist)