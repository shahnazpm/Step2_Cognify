# Set the working directory
setwd("/Users/obianujuanuma/Library/CloudStorage/OneDrive-Personal/Loyalist/Semester 2/Step2")

#import libraries
library(ggplot2)
library(plotly)
library(dplyr)
library(tidyr)
library(stringr)
library(writexl)
library(archive)
library(sf)
library(vroom) # to read large dataset into R
library(urbnmapr)
library(readr)

# Losd the shapes for US states
states_sf <- get_urbn_map(map = "states", sf = TRUE)
# Exclude District of Columbia
states_sf <- states_sf %>% filter (state_name != "District of Columbia")

# Import the data
predvsactual <- read.csv("./CombinedData/Prediction_results.csv")
head(predvsactual)

# Rename the State to state_name
predvsactual <- predvsactual %>% rename("state_name" = "State")

# Join both sf and predvsactual tables on state_name
pred_vs_actual <- left_join(states_sf, predvsactual, by = "state_name")

# use st_centroid to get a central coordinates representative
states_sf$centroid <- st_centroid(pred_vs_actual)
coordinates_ <- st_coordinates(states_sf$centroid)
# head(coordinates_)
# Add coordinates to target_votes
pred_vs_actual$Longitude = coordinates_[, "X"]
pred_vs_actual$Latitude = coordinates_[, "Y"]


# Create the map
g <- ggplot(pred_vs_actual) +
  geom_sf(aes(fill=Predicted.Party, geometry=geometry), color = "white") +
  geom_text(aes(x=Longitude, y=Latitude, label=state_abbv), colour = "white")+
  scale_fill_manual("Predicted Party", values = c("Democrat" = "#007bff", "Republican" = "#dc143c")) +
  ggtitle("U.S Elections 2024 - Predicted Parties") +
  theme_minimal() +
  theme(
    panel.background = element_blank(),
    panel.grid = element_blank()
  )

ggplotly(g)


#Create the map for actual
ac <- ggplot(pred_vs_actual) +
  geom_sf(aes(fill=Actual.Party, geometry=geometry), color = "white") +
  geom_text(aes(x=Longitude, y=Latitude, label=state_abbv), colour = "white")+
  scale_fill_manual("Party", values = c("Democrat" = "#007bff", "Republican" = "#dc143c")) +
  ggtitle("U.S Elections 2024 - Actual Result") +
  theme_minimal() +
  theme(
    panel.background = element_blank(),
    panel.grid = element_blank()
  )

ggplotly(ac)



# Note - target_votes has been saved to Excel. So, import the data and use it
