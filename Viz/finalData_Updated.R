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

# Import the data and keep only unique rows
oval_final <- vroom(archive_read("/Users/obianujuanuma/Library/CloudStorage/OneDrive-Personal/Loyalist/Semester 2/Step2/CombinedData/combined_data.7z")) %>% distinct()

tail(oval_final)

# Leading party is col 13, target votes is col 17
# Get distinct rows for target votes and leading party in each state
targetvotes <- oval_final[,c(12,13,17)] %>% distinct()

# Create a space before the next upper case letter in the State column
targetvotes$State <- gsub("([a-z])([A-Z])","\\1 \\2",targetvotes$State)

# Rename the State to state_name
targetvotes <- targetvotes %>% rename("state_name" = "State")

# Join both sf and targetvotes tables on state_name
target_votes <- left_join(states_sf, targetvotes, by = "state_name")

# Replace NA with "None" where there is no leading party on the LeadingParty column
target_votes <- target_votes %>%
  mutate(LeadingParty = ifelse(is.na(LeadingParty),"None", LeadingParty))

# Write table to a csv file

write_csv(x = target_votes, file = "/Users/obianujuanuma/Library/CloudStorage/OneDrive-Personal/Loyalist/Semester 2/Step2/CombinedData/target_votes1.csv")

# write_csv(x = oval_final, file = "/Users/obianujuanuma/Library/CloudStorage/OneDrive-Personal/Loyalist/Semester 2/Step2/CombinedData/oval_office.csv")

# use st_centroid to get a central coordinates representative
states_sf$centroid <- st_centroid(target_votes)
coordinates_ <- st_coordinates(states_sf$centroid)
# head(coordinates_)
# Add coordinates to target_votes
target_votes$long = coordinates_[, "X"]
target_votes$lat = coordinates_[, "Y"]


# Create the map
g <- ggplot(target_votes) +
  geom_sf(aes(fill=LeadingParty, geometry=geometry), color = "white") +
  geom_text(aes(x=long, y=lat, label=state_abbv), colour = "white")+
  scale_fill_manual("Predicted Party", values = c("Democrat" = "#007bff", "Republican" = "#dc143c")) +
  ggtitle("U.S Elections 2024 - Predicted Parties") +
  theme_minimal() +
  theme(
    panel.background = element_blank(),
    panel.grid = element_blank()
  )

ggplotly(g)

# Check the values in leading Party
print(table(target_votes$LeadingParty))



# This is to be modified
# Spectral color scale for continuous data; Viridis for data with a meaningful midpoint
p <- ggplot(target_votes) +
  geom_sf(aes(fill=TargetVotes, geometry=geometry), color = "white") +
  scale_fill_distiller("Target Votes") +
  ggtitle("Leading Party and Target Votes Comparison Across States")+
  theme_minimal() +
  theme(
    panel.background = element_blank(),
    panel.grid = element_blank()
  )
ggplotly(p)



# Next: Where does each party lead, and what are the relative strengths of support?
# Show leading party on the cloropleth map - perhaps a slicer?
# Note - target_votes has been saved to Excel. So, import the data and use it
