# Load necessary libraries
library(shiny)
library(shinythemes)
library(ggplot2)
library(dplyr)
library(DT)
library(plotly)
library(tidyr)
library(stringr)
library(sf)
library(urbnmapr)
library(readr)

# Set working directory (optional if running in a specific environment)
setwd("C:\\Users\\GINE\\OneDrive - Loyalist College\\Desktop\\AI_DataScience\\steps_R")

# Load data
data_2020 <- read.csv("2020_presidential_election.csv")
data_2023 <- read.csv("2023_presidential_election.csv")
predvsactual <- read.csv("Prediction_results.csv")

# Prepare the spatial data for mapping
states_sf <- get_urbn_map(map = "states", sf = TRUE) %>% 
  filter(state_name != "District of Columbia")

# Rename and join data
predvsactual <- predvsactual %>% rename("state_name" = "State")
pred_vs_actual <- left_join(states_sf, predvsactual, by = "state_name")

# Generate centroids for state labels
states_sf$centroid <- st_centroid(pred_vs_actual)
coordinates_ <- st_coordinates(states_sf$centroid)
pred_vs_actual$Longitude <- coordinates_[, "X"]
pred_vs_actual$Latitude <- coordinates_[, "Y"]

# Define UI
ui <- navbarPage(
  title = "Election Dashboard",
  theme = shinytheme("flatly"),
  
  # Overview Tab
  tabPanel("Overview",
           sidebarLayout(
             sidebarPanel(
               checkboxGroupInput("year_overview", "Select Year:", choices = c("2020", "2023"), selected = c("2020")),
               selectInput("state_overview", "Select State:", 
                           choices = unique(data_2020$State), 
                           selected = unique(data_2020$State), multiple = TRUE)
             ),
             mainPanel(
               h3("Election Overview"),
               plotlyOutput("overview_plot"),
               DTOutput("overview_table")
             )
           )
  ),
  
  # UI: Demographics Tab
  tabPanel("Demographics",
           sidebarLayout(
             sidebarPanel(
               width = 3,
               selectInput(
                 "state_demographics",
                 "Select State:",
                 choices = unique(data_2020$State),
                 selected = "California",
                 multiple = TRUE
               ),
               selectInput(
                 "metric_demographics",
                 "Select Metric:",
                 choices = c(
                   "Male Population (%)" = "SEXAndAgeTotalPeopleMaleInPercent",
                   "Female Population (%)" = "SEXAndAgeTotalPeopleFemaleInPercent",
                   "Population Under 18 Years" = "SEXAndAgeTotalPeopleUnder18Years",
                   "Population Over 65 Years" = "SEXAndAgeTotalPeople65YearsAndOver",
                   "Median Age" = "SEXAndAgeTotalPeopleMedianAge_Years_"
                 ),
                 selected = "SEXAndAgeTotalPeopleMaleInPercent"
               ),
             ),
             mainPanel(
               width = 9,
               plotlyOutput("demographics_plot")
             )
           )
  ),
  
  # Mapping Tab
  tabPanel("Maps",
           sidebarLayout(
             sidebarPanel(
               h4("Map Selection"),
               radioButtons("map_type", "Select Map Type:", choices = c("Predicted Parties", "Actual Result")),
               helpText("Visualize predicted and actual party results on the U.S. map.")
             ),
             mainPanel(
               h3("Election Maps"),
               plotlyOutput("map_plot")
             )
           )
  ),
  
  # Comparison Tab
  tabPanel("Comparison",
           sidebarLayout(
             sidebarPanel(
               selectInput("state_comparison", "Select State:", 
                           choices = unique(data_2020$State), 
                           selected = "California", 
                           multiple = TRUE),
               selectInput("metric", "Metric for Comparison", 
                           choices = c(
                             "Unemployment Rate (%)" = "EMPLOYMENTStatusPeople16YearsAndOverInLaborForceCivilianLaborForceUnemployedUnemploymentRateInPercent",
                             "Median Household Income (Dollars)" = "INCOMEInThePast12Months_PastYearInflation_AdjustedDollars_HouseholdsMedianHouseholdIncome_Dollars_",
                             "Poverty Rate (%)" = "POVERTYRatesForFamiliesAndPeopleForWhomPovertyStatusIsDeterminedAllPeopleInPercent",
                             "Per Capita Income (Dollars)" = "INCOMEInThePast12Months_PastYearInflation_AdjustedDollars_IndividualsPerCapitaIncome_Dollars_"
                           ),
                           selected = "EMPLOYMENTStatusPeople16YearsAndOverInLaborForceCivilianLaborForceUnemployedUnemploymentRateInPercent")
             ),
             mainPanel(
               h3("State Comparison"),
               plotlyOutput("comparison_plot")
             )
           )
  ),
  
  # Accessibility Tab
  tabPanel("Accessibility",
           sidebarLayout(
             sidebarPanel(
               width = 3,
               selectInput("font_size", "Font Size", choices = c("Small", "Medium", "Large"), selected = "Medium"),
               radioButtons("theme", "Theme", choices = c("Light", "Dark"), selected = "Light")
             ),
             mainPanel(
               width = 9,
               h3("User Accessibility Options"),
               p("Adjust font size and theme through the sidebar.")
             )
           )
  ) # Added missing closing parenthesis
)

# Define server logic
server <- function(input, output, session) {
  
  # Overview Plot
  output$overview_plot <- renderPlotly({
    plot_data <- data_2020 %>% 
      filter(State %in% input$state_overview) %>% 
      mutate(Year = "2020")
    
    plot <- ggplot(plot_data, aes(x = State, y = ScoreAverage, fill = Year)) +
      geom_bar(stat = "identity", position = "dodge") +
      theme_minimal() +
      labs(title = "Average Scores by State", x = "State", y = "Score Average", fill = "Year")
    
    ggplotly(plot)
  })
  
  # Overview Table
  output$overview_table <- renderDT({
    data_2020 %>% 
      select(State, ScoreAverage, ScoreSum) %>% 
      filter(State %in% input$state_overview)
  })
  
  # Demographics Tab
  output$demographics_plot <- renderPlotly({
    demographics_data <- bind_rows(
      data_2020 %>% mutate(Year = "2020"),
      data_2023 %>% mutate(Year = "2023")
    ) %>% filter(State %in% input$state_demographics)
    
    plot <- ggplot(demographics_data, aes(x = State, y = !!sym(input$metric_demographics), fill = Year)) +
      geom_bar(stat = "identity", position = "dodge") +
      labs(title = paste(input$metric_demographics, "by State"), x = "State", y = input$metric_demographics) +
      theme_minimal()
    
    ggplotly(plot)
  })
  
  # Election Map
  output$map_plot <- renderPlotly({
    map_data <- pred_vs_actual
    map_data <- map_data %>%
      mutate(
        count_diff = ifelse(Predicted.Party == Actual.Party, 0, 1)  # Calculate the difference (1 if different, 0 if same)
      )
    fill_var <- if (input$map_type == "Predicted Parties") "Predicted.Party" else "Actual.Party"
    
    plot <- ggplot(map_data) +
      geom_sf(aes_string(fill = fill_var, geometry = "geometry"), color = "white", size = 1.5) +
      geom_text(aes(x = Longitude, y = Latitude, label = state_abbv), color = "white") +
      scale_fill_manual("Party", values = c("Democrat" = "#007bff", "Republican" = "#dc143c")) +
      theme_minimal() +
      theme(
        panel.grid = element_blank(),    # Remove grid lines
        axis.text = element_blank(),     # Remove axis text
        axis.ticks = element_blank(),    # Remove axis ticks
        axis.title = element_blank()     # Remove axis titles
      ) +
      labs(title = paste("U.S. Elections 2024 -", input$map_type))
    
    ggplotly(plot)
  })
  
  # State Comparison Plot
  output$comparison_plot <- renderPlotly({
    metric <- input$metric
    comparison_data <- bind_rows(
      data_2020 %>% mutate(Year = "2020"),
      data_2023 %>% mutate(Year = "2023")
    ) %>% filter(State %in% input$state_comparison)
    
    plot <- ggplot(comparison_data, aes(x = State, y = !!sym(metric), fill = Year)) +
      geom_bar(stat = "identity", position = "dodge") +
      labs(title = "State Comparison", x = "State", y = metric) +
      theme_minimal()
    
    ggplotly(plot)
  })
  
  # Accessibility and theme CSS
  output$theme_css <- renderUI({
    font_size_css <- switch(input$font_size, 
                            "Small" = "font-size: 12px;", 
                            "Medium" = "font-size: 16px;", 
                            "Large" = "font-size: 20px;")
    
    theme_css <- if (input$theme == "Dark") {
      "
      body, .navbarPage, .container-fluid, .navbar, .tab-pane, .sidebarPanel, .mainPanel, .dataTables_wrapper, .selectize-input, .tab-content, .well, .shiny-output-error, .shiny-input-container {
        background-color: #2b2b2b !important;
        color: #e0e0e0 !important;
      }
      .navbar, .sidebarPanel {
        background-color: #333333 !important;
      }
      .tab-content, .mainPanel, .dataTables_wrapper {
        background-color: #2b2b2b !important;
        color: #e0e0e0;
      }
      .btn, .btn-default, .form-control {
        background-color: #444444 !important;
        color: #e0e0e0 !important;
        border-color: #555555 !important;
      }
      label, p, h3, .dt-button {
        color: #e0e0e0 !important;
      }
      .navbar-brand {
        color: inherit !important;
      }
      "
    } else {
      "
      body, .navbarPage, .container-fluid, .navbar, .tab-pane, .sidebarPanel, .mainPanel, .dataTables_wrapper, .selectize-input, .tab-content, .well, .shiny-output-error, .shiny-input-container {
        background-color: #ffffff !important;
        color: #333333 !important;
      }
      .navbar, .sidebarPanel {
        background-color: #f8f9fa !important;
      }
      .tab-content, .mainPanel, .dataTables_wrapper {
        background-color: #ffffff !important;
        color: #333333;
      }
      .btn, .btn-default, .form-control {
        background-color: #ffffff !important;
        color: #333333 !important;
        border-color: #cccccc !important;
      }
      label, p, h3, .dt-button {
        color: #333333 !important;
      }
      .navbar-brand {
        color: inherit !important;
      }
      "
    }
    
    tags$style(HTML(paste0("
    .container-fluid {", font_size_css, theme_css, "}
    h3, p, label, .btn, .navbar-brand {", font_size_css, "}
  ")))
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

