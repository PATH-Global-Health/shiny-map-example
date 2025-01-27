# Prepare app data

# Load required libraries
library(tidyverse)
library(tmap)
library(sf)
library(malariaAtlas)
library(terra)
library(exactextractr)

# Load Nigeria shapefile
ng_data <- readRDS("data/ad2-nga.rds")

# Load  data
data <- cart::pull_cart(iso3c = "NGA", year = 2019)
plot(data$pop)

inc <- getRaster("Explorer__2020_Global_PfPR", shp = ng_data)
inc$`Number of newly diagnosed Plasmodium falciparum cases per 1,000 population, on a given year 2000-2022`
tt <- getRaster("Accessibility__202001_Global_Walking_Only_Travel_Time_To_Healthcare", shp = ng_data)

# Resample population raster to MAP raster
pop <- data$pop |> terra::resample(inc)
pop_tt <- data$pop |> terra::resample(tt)

# Extract population data to shapefile
ng_data$population <- exactextractr::exact_extract(pop, ng_data, fun = "sum")

# Extract malaria incidence data to shapefile using population weighted average
ng_data$incidence <- exactextractr::exact_extract(inc, ng_data, fun = "weighted_mean", weights = pop) * 1000

# Extract travel time data to shapefile using population weighted average
ng_data$tt <- exactextractr::exact_extract(tt, ng_data, fun = "weighted_mean", weights = pop_tt)

# Save shapefile
saveRDS(ng_data, "data/ng_data.rds")
