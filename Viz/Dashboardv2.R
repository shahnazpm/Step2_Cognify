# Install required packages if not already installed
packages_to_install <- c("shiny", "shinydashboard", "shinythemes", "ggplot2", "dplyr", 
                         "plotly", "DT", "scales", "reshape2", "viridis")
new_packages <- packages_to_install[!(packages_to_install %in% installed.packages()[,"Package"])]
if (length(new_packages)) install.packages(new_packages)

# Load required libraries
library(shiny)
library(shinydashboard)
library(shinythemes)
library(ggplot2)
library(dplyr)
library(plotly)
library(DT)
library(scales)
library(reshape2)
library(viridis)

# Set seed for reproducibility
set.seed(123)

# Generate sample data
political_data <- data.frame(
  State = sample(c("California", "Texas", "Florida", "New York", "Pennsylvania", 
                   "Ohio", "Georgia", "Michigan", "North Carolina", "Arizona"), 1500, replace = TRUE),
  Party = sample(c("Democrat", "Republican", "Independent", "Libertarian"), 1500, 
                 replace = TRUE, prob = c(0.42, 0.39, 0.15, 0.04)),
  Age_Group = sample(c("18-29", "30-44", "45-59", "60+"), 1500, replace = TRUE, 
                     prob = c(0.2, 0.3, 0.3, 0.2)),
  Disability_Status = sample(c("No Disability", "Disability"), 1500, replace = TRUE, 
                             prob = c(0.85, 0.15)),
  Veteran_Status = sample(c("Non-Veteran", "Veteran"), 1500, replace = TRUE, 
                          prob = c(0.92, 0.08)),
  Education = sample(c("High School", "Bachelor's", "Master's", "Doctorate"), 1500, 
                     replace = TRUE, prob = c(0.4, 0.35, 0.2, 0.05)),
  Income_Bracket = sample(c("Low", "Middle", "High"), 1500, replace = TRUE, 
                          prob = c(0.3, 0.5, 0.2)),
  Targeted = sample(c("Yes", "No"), 1500, replace = TRUE, prob = c(0.35, 0.65)),
  Engagement_Score = runif(1500, 0, 100),
  Donation_Amount = pmax(0, round(rnorm(1500, mean = 150, sd = 100), 2))
)

# UI Definition
ui <- dashboardPage(
  dashboardHeader(
    title = "Political Targeting Insights",
    dropdownMenu(type = "notifications",
                 notificationItem(
                   text = "Dashboard Guide",
                   icon = icon("info-circle"),
                   status = "info"
                 )
    )
  ),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Detailed Analytics", tabName = "details", icon = icon("chart-bar")),
      menuItem("Demographic Breakdown", tabName = "demographics", icon = icon("users")),
      selectInput("party", "Political Party", 
                  choices = c("All", unique(political_data$Party)), 
                  selected = "All"),
      selectInput("age_group", "Age Group", 
                  choices = c("All", unique(political_data$Age_Group)), 
                  selected = "All"),
      selectInput("education", "Education Level", 
                  choices = c("All", unique(political_data$Education)), 
                  selected = "All"),
      selectInput("income", "Income Bracket", 
                  choices = c("All", unique(political_data$Income_Bracket)), 
                  selected = "All"),
      checkboxInput("show_targeted", "Show Only Targeted", value = FALSE)
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "overview",
              fluidRow(
                valueBoxOutput("total_population", width = 3),
                valueBoxOutput("targeting_rate", width = 3),
                valueBoxOutput("avg_engagement", width = 3),
                valueBoxOutput("top_state", width = 3)
              ),
              fluidRow(
                box(plotlyOutput("party_distribution"), width = 6, 
                    title = "Party Composition", status = "primary", solidHeader = TRUE),
                box(plotlyOutput("targeting_breakdown"), width = 6, 
                    title = "Targeting Strategy Breakdown", status = "success", solidHeader = TRUE)
              )
      ),
      tabItem(tabName = "details",
              fluidRow(
                box(plotlyOutput("multidimensional_analysis"), width = 12, 
                    title = "Multidimensional Targeting Insights", status = "info", solidHeader = TRUE)
              ),
              fluidRow(
                box(DTOutput("demographic_table"), width = 12, 
                    title = "Detailed Demographic Data", status = "primary", solidHeader = TRUE)
              )
      ),
      tabItem(tabName = "demographics",
              fluidRow(
                box(plotlyOutput("age_party_distribution"), width = 6, 
                    title = "Party Distribution by Age", status = "primary", solidHeader = TRUE),
                box(plotlyOutput("education_income_scatter"), width = 6, 
                    title = "Education vs Income Targeting", status = "success", solidHeader = TRUE)
              ),
              fluidRow(
                box(plotlyOutput("donation_analysis"), width = 12, 
                    title = "Donation Amount Analysis", status = "warning", solidHeader = TRUE)
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive filtering
  filtered_data <- reactive({
    data <- political_data
    if (input$party != "All") {
      data <- data %>% filter(Party == input$party)
    }
    if (input$age_group != "All") {
      data <- data %>% filter(Age_Group == input$age_group)
    }
    if (input$education != "All") {
      data <- data %>% filter(Education == input$education)
    }
    if (input$income != "All") {
      data <- data %>% filter(Income_Bracket == input$income)
    }
    if (input$show_targeted) {
      data <- data %>% filter(Targeted == "Yes")
    }
    data
  })
  
  output$total_population <- renderValueBox({
    total <- nrow(filtered_data())
    valueBox(
      format(total, big.mark = ","),
      "Total Population",
      icon = icon("users"),
      color = "blue"
    )
  })
  
  output$targeting_breakdown <- renderPlotly({
    targeting_data <- filtered_data() %>%
      group_by(Targeted) %>%
      summarise(Count = n()) %>%
      mutate(Percentage = Count / sum(Count) * 100)
    
    plot_ly(
      targeting_data,
      x = ~Targeted,
      y = ~Percentage,
      type = 'bar',
      text = ~paste("Count:", Count, "<br>Percentage:", round(Percentage, 2), "%"),
      textposition = "auto",
      marker = list(color = c("green", "red"))
    ) %>%
      layout(
        title = "Targeting Strategy Breakdown",
        xaxis = list(title = "Targeting Status"),
        yaxis = list(title = "Percentage")
      )
  })
  
  output$age_party_distribution <- renderPlotly({
    age_party_data <- filtered_data() %>%
      group_by(Age_Group, Party) %>%
      summarise(Count = n(), .groups = "drop")
    
    plot_ly(
      age_party_data,
      x = ~Age_Group,
      y = ~Count,
      color = ~Party,
      type = 'bar',
      text = ~paste("Party:", Party, "<br>Count:", Count),
      hoverinfo = 'text'
    ) %>%
      layout(
        barmode = 'stack',
        title = "Party Distribution by Age Group",
        xaxis = list(title = "Age Group"),
        yaxis = list(title = "Count")
      )
  })
  
  output$education_income_scatter <- renderPlotly({
    scatter_data <- filtered_data()
    
    plot_ly(
      scatter_data,
      x = ~Education,
      y = ~Income_Bracket,
      type = 'scatter',
      mode = 'markers',
      color = ~Targeted,
      marker = list(size = 10),
      text = ~paste("Education:", Education, "<br>Income:", Income_Bracket, "<br>Targeted:", Targeted)
    ) %>%
      layout(
        title = "Education vs Income Targeting",
        xaxis = list(title = "Education Level"),
        yaxis = list(title = "Income Bracket")
      )
  })
  
  output$donation_analysis <- renderPlotly({
    donation_data <- filtered_data()
    
    plot_ly(
      donation_data,
      x = ~Party,
      y = ~Donation_Amount,
      type = 'box',
      color = ~Party,
      boxpoints = 'all',
      jitter = 0.3,
      pointpos = -1.8
    ) %>%
      layout(
        title = "Donation Amount Analysis by Party",
        xaxis = list(title = "Political Party"),
        yaxis = list(title = "Donation Amount (USD)")
      )
  })
  
  output$multidimensional_analysis <- renderPlotly({
    heatmap_data <- filtered_data() %>%
      group_by(State, Income_Bracket) %>%
      summarise(Targeting_Rate = mean(Targeted == "Yes") * 100, .groups = "drop")
    
    plot_ly(
      heatmap_data,
      x = ~Income_Bracket,
      y = ~State,
      z = ~Targeting_Rate,
      type = 'heatmap',
      colors = viridis(100)
    ) %>%
      layout(
        title = "Targeting Rate Heatmap (State vs Income Bracket)",
        xaxis = list(title = "Income Bracket"),
        yaxis = list(title = "State")
      )
  })
  
  output$party_distribution <- renderPlotly({
    party_data <- filtered_data() %>%
      group_by(Party) %>%
      summarise(Count = n())
    
    plot_ly(
      party_data,
      labels = ~Party,
      values = ~Count,
      type = 'pie',
      textinfo = 'label+percent'
    ) %>%
      layout(title = "Political Party Distribution")
  })
}

shinyApp(ui, server)
