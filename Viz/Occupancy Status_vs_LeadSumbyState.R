# Load necessary libraries
library(data.table)
library(ggplot2)
library(dplyr)

# Read the dataset using fread for faster performance
data <- fread("D:/Loyalist/Term2/Step2/Week7/combined_data.csv")

# Summarize data to get counts of each OccupancyStatus by State
data_summary <- data %>%
  group_by(State, OccupancyStatus) %>%
  summarise(Count = n(), .groups = 'drop')

# Calculate proportion of each OccupancyStatus within each State
data_summary <- data_summary %>%
  group_by(State) %>%
  mutate(Proportion = Count / sum(Count))  # Calculate proportion per state

# Plot stacked area chart
ggplot(data_summary, aes(x = State, y = Proportion, fill = OccupancyStatus, group = OccupancyStatus)) +
  geom_area() +
  labs(title = "Proportion of Occupancy Status by State",
       x = "State",
       y = "Proportion",
       fill = "Occupancy Status") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels for readability
