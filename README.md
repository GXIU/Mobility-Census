# Mobility Census: New Framework for Comprehensive Human Mobility Analysis

Gezhi Xiu, Jianying Wang, Thilo Gross, Meipo Kwan, and Yu Liu

## Abstract

Understanding the dynamics of cities is an important goal. Traditionally the development of cities has been studied using census datasets, but they are only available every 10 or 5 years. Today we have mobility data that are collected at a much higher frequency, and this data entails much information about the city on much shorter temporal scales. Our challenge is how to use these new mobility data to answer questions that are traditionally studied with census data. The central obstacle addressed in this paper is that mobility patterns are very sophisticated, and  just the origin-destination record is a very high dimensional data. However, also the traditional census is high dimensional, and for the census, it has been shown that the dimensionality can be reduced with manifold learning. Particular progress has been made by diffusion mapping census variables. To apply the diffusion map to mobility data, areas need to be represented by a list of features, so we need to generate these. Here we propose to describe mobility data by a feature set to form a mobility census which can then be studied by diffusion mapping. The example of Beijing illustrates that this is a powerful approach that illustrates the advantages of the method.

- Sample data from [link](https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page), with a corresponding [shapefile](https://s3.amazonaws.com/nyc-tlc/misc/taxi_zones.zip). 

## The structure of the script

+ **individual_level**: Using the individual as a basic analytical unit to reveal the mobility patterns.
  + distance_patterns.sql:  The patterns of trips, including the step length, the distance, and detour.
  + individiual_entropy.sql: The entropy of individual's stay points.
  + individual_grid_id.sql: the relationship between users and the spatial analytical grids.
  + individual_rog.sql: the patterns of the radius of gyration assessed from the stay points of trajectories. 
  + individual_rog2.sql: the radius of gyration of the stay points with the top 2 visitation.
  + move_od.sql: build OD matrices based on individual's stay points.
  + travel_patterns.sql:  The patterns of trips, including travel duration, travel mode and the number of trips.



+ **aggregate_level**:

  + **home_agg**:  
    + **agg_individual**: This folder contains the analytical script considering the spatial distributions of the mobility patterns based on the locations of individuals’ homes
      + home_commuting.sql: the aggregated patterns assessed from travel_patterns.sql
      + home_distance_patterns.sql: the aggregated patterns assessed from distance_patterns.sql
      + home_entropy.sql: the aggregated patterns assessed from individiual_entropy.sql
      + home_rog.sql: the aggregated patterns assessed from individual_rog.sql
      + home_rog2.sql: the aggregated patterns assessed from individual_rog2.sql
    + **od_parameters:** This folder contains the analytical script focusing on OD matrices patterns.
      + home_entropy.sql: The entropy of the destination for a given origin grid.
      + home_entropy_hourly.sql: Hourly entropy of the destination for OD matrices.
      + home_k_index.sql:  The h-index of the grids assess from the OD matrices. 
  + **workplace_agg**: This folder analyzes the spatial distributions of the mobility patterns based on the locations of individuals’ workplaces
    + **agg_individual**: This folder contains the analytical script considering the spatial distributions of the mobility patterns based on the locations of individuals’ workplaces
      + work_commuting.sql: the aggregated patterns assessed from travel_patterns.sql
      + work_distance_patterns.sql: the aggregated patterns assessed from distance_patterns.sql
      + work_entropy.sql: the aggregated patterns assessed from individiual_entropy.sql
      + work_rog.sql: the aggregated patterns assessed from individual_rog.sql
      + work_rog2.sql: the aggregated patterns assessed from individual_rog2.sql
    + **od_parameters:** This folder contains the analytical script focusing on OD matrices patterns.
      + work_entropy.sql: The entropy of the destination for a given origin grid.
      + work_entropy_hourly.sql: Hourly entropy of the destination for OD matrices.
      + work_k_index.sql:  The h-index of the grids assess from the OD matrices. 

  + **others**:
    + in_out_flow.sql: the total in-flow and total out-flow, hourly in-flow and hourly out-flow
    + pop_distribution.sql: the spatial distribution of work population and resident population