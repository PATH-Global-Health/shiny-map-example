# Shiny App with Authentication and bslib Theming

# Load required libraries
library(shiny)
library(shinyauthr)
library(bslib)
library(tidyverse)
library(tmap)
library(sf)

# Create user database
user_base <- tibble(
  user = c("admin", "user"),
  password = c("adminpass", "userpass"),
  permissions = c("admin", "standard"),
  name = c("Administrator", "Regular User")
)

# Load NC dataset
# nc_data <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
ng_data <- readRDS("data/ng_data.rds")


# Define available variables for mapping
map_variables <- c(
  "Population 2020" = "population",
  "Malaria Incidence per 1000" = "incidence",
  "Avg walking time to healthcare (mins)" = "tt"
)

# Define custom theme
custom_theme <- bs_theme(
  version = 5,
  primary = "#0073e6",
  secondary = "#6c757d",
  bg = "#f4f6f9",
  fg = "#333333"
)

# UI with bslib page layout
ui <- page_fluid(
  theme = custom_theme,
  shinyauthr::loginUI(id = "login"),
  uiOutput("app_content")
)

# Server logic
server <- function(input, output, session) {
  # Authentication server
  credentials <- shinyauthr::loginServer(
    id = "login",
    data = user_base,
    user_col = user,
    pwd_col = password,
    log_out = reactive(logout_init())
  )
  
  # Logout trigger
  logout_init <- reactiveVal(FALSE)
  
  # Check authentication status
  user_auth <- reactive({
    credentials()$user_auth
  })
  
  # User info reactive
  user_info <- reactive({
    credentials()$info
  })
  
  # Render main app UI only when authenticated
  output$app_content <- renderUI({
    req(user_auth())
    
    page_fluid(
      nav(
        title = "Dashboard",
        nav_spacer(),
        nav_item(
          shinyauthr::logoutUI(id = "logout")
        )
      ),
      
      layout_column_wrap(
        width = 1/2,
        card(
          card_header(
            paste("Welcome,", user_info()$name)
          ),
          card_body(
            p("You are logged in with", user_info()$permissions, "permissions.")
          )
        ),
        card(
          card_header("Quick Stats"),
          card_body(
            value_box(
              title = "User Type",
              value = user_info()$permissions,
              showcase = bsicons::bs_icon("person-badge")
            )
          )
        )
      ),
      
      navset_card_pill(
        nav_panel(
          title = "Home",
          layout_column_wrap(
            width = 1,
            card(
              card_header("Interactive Map"),
              card_body(
                layout_column_wrap(
                  width = 1/4,
                  selectInput(
                    "map_variable",
                    "Select Variable to Display:",
                    choices = map_variables
                  )
                ),
                tmapOutput("interactive_map", height = 500)
              )
            )
          )
        ),
        nav_panel(
          title = "Profile",
          layout_column_wrap(
            width = 1,
            card(
              card_header("User Details"),
              card_body(
                p("Username: ", user_info()$user),
                p("Name: ", user_info()$name)
              )
            )
          )
        ),
        nav_panel(
          title = "Settings",
          p("User settings can be configured here.")
        )
      )
    )
  })
  
  # Interactive map output
  output$interactive_map <- renderTmap({
    req(input$map_variable)
    
    tmap_mode("view")
    
    tm_shape(ng_data) +
      tm_polygons(
        col = input$map_variable,
        title = names(map_variables)[map_variables == input$map_variable],
        style = "jenks",
        palette = "viridis",
        alpha = 0.7,
        id = "NAME"
      ) +
      tm_layout(
        main.title = paste("Distribution of", 
                          names(map_variables)[map_variables == input$map_variable]),
        frame = FALSE
      )
  })
  
  # Logout server
  logout <- shinyauthr::logoutServer(
    id = "logout",
    active = reactive(credentials()$user_auth)
  )
}

# Run the application 
shinyApp(ui = ui, server = server)
