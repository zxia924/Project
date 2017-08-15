# Load required packages.
library(shiny)
library(shinydashboard)
library(dplyr)
library(data.table)
library(ggplot2)
library(forcats)

# Define default colors of GreatNonprofits for visualization.
ciBlue <- "#11A7A5"
ciOrange <- "#F7931E"

#============================================== UI ================================================
ui <- dashboardPage(
  skin = "black",
  dashboardHeader(
    title = "GreatNonprofits Survey Analytics", 
    titleWidth = 320),
  dashboardSidebar(
    width = 250,
    #Selector for file upload
    fileInput('datafile', 'Choose your CSV file',
              accept=c('text/csv', 'text/comma-separated-values,text/plain')),
    
    #These column selectors are dynamically created when the file is loaded
    uiOutput("x"),
    uiOutput("y"),
    br(),
    uiOutput("titletab"),
    br(),
    #The plot button prevents an action firing before we're ready
    uiOutput("plotbutton"),
    br(),
    br(),
    #The download button exports our plot in png format
    uiOutput("downloadplot")
  ),
  
  dashboardBody(
    #Show all images of all different types of plots this app creates
    fluidRow(
      column(3,
             helpText(strong("Bar chart"),
                      p("X variable: Character"),
                      "Y variable: N/A")),
      column(3,
             helpText(strong("Histogram"),
                      p("X variable: Numeric"),
                      "Y variable: N/A")),
      column(3,
             helpText(strong("Scatter plot"),
                      p("X variable: Numeric"),
                      "Y variable: Numeric")),
      column(3,
             helpText(strong("Boxplot"),
                      p("X variable: Character"),
                      "Y variable: Numeric"))
    ),
    
    fluidRow(
      column(3,
             img(src = "Bar Chart.png", 
                 height = 100, width = 120)),
      column(3,
             img(src = "Histogram.png",
                 height = 100, width = 120)),
      column(3,
             img(src = "Scatter plot.png",
                 height = 100, width = 120)),
      column(3,
             img(src = "Boxplot.png",
                 height = 100, width = 120))
    ),
    br(),
    # Create tabs for the plot and the data table
    tabsetPanel(
      tabPanel("Plot", plotOutput("plot")),
      tabPanel("Data Table", dataTableOutput("table"))
    )
  ))

#============================================== Server ===============================================
server <- function(input, output) {
  
  #This function is repsonsible for loading in the selected file
  filedata <- reactive({
    infile <- input$datafile
    if (is.null(infile)) {
      # User has not uploaded a file yet
      return(NULL)
    }
    read.csv(infile$datapath, header = TRUE, stringsAsFactors = FALSE)
  })
  
  #The following set of functions populate the column selectors, plot button, and download button
  output$x <- renderUI({
    df <- filedata()
    if (is.null(df)) return(NULL)
    
    Question = names(df)
    names(Question) = Question
    selectInput("x", "Choose your variable for the x-axis:", 
                Question, selected = NULL, multiple = T)
  })
  
  output$y <- renderUI({
    df <- filedata()
    if (is.null(df)) return(NULL)
    
    Question = names(df)
    names(Question) = Question
    selectInput("y", "Choose your variable for the y-axis (Leave blank if not applicable):", 
                Question, selected = NULL, multiple = T)
  })
  
  output$plotbutton <- renderUI({
    df <- filedata()
    if (is.null(df)) return(NULL)
    
    div(style="display:inline-block;width:200%;text-align: center;",actionButton('button', 'Plot Data'))
  })
  
  #The following set of ggplots generate the plots we expect the app to create
  plotInput <- eventReactive(input$button,{
    dfplot <- filedata()
    
    #Unlist the input variable to allow R to recognize its data type
    plotX <- dfplot[,input$x] %>% unlist 
    plotY <- dfplot[,input$y] %>% unlist 
    
    # Bar Chart
    if (mode(plotX) == "character" & is.null(input$y)){
      p <- ggplot(dfplot, aes_string(x = input$x)) + 
        geom_bar(color = I('black'),fill = I(ciBlue), width = 0.7) +
        geom_text(stat = 'count', aes(label=..count..), hjust=-0.3) +
        coord_flip() +
        xlab(input$x) +
        ylab("Number of Respondents") 
    } 
    # Histogram
    else if (mode(plotX) == "numeric" & is.null(input$y)){
      p <- ggplot(dfplot, aes_string(x = input$x)) + 
        geom_histogram(color = I('black'),fill = I(ciBlue)) +
        xlab(input$x) +
        ylab("Number of Respondents") 
    }
    # Scatter plot
    else if (mode(plotX) == "numeric" & mode(plotY) == "numeric"){
      p <- ggplot(dfplot, aes_string(x = input$x, y = input$y)) + 
        geom_point(stat = "identity", color = ciBlue, alpha = 0.5) +
        geom_smooth(span = 0.2, color = ciOrange) +
        xlab(input$x) +
        ylab(input$y) 
    }
    # Boxplot
    else if (mode(plotX) == "character" & mode(plotY) == "numeric"){
      p <- ggplot(dfplot, aes_string(x = input$x, y = input$y, fill = input$x)) + 
        geom_boxplot() +
        xlab(input$x) +
        ylab(input$y) 
    }
    # Aesthetics for text styles.
    p + 
      ggtitle(input$title) + 
      theme_bw() +
      theme(plot.title = element_text(family = "Trebuchet MS", 
                                      color = ciOrange, 
                                      face = "bold", 
                                      size = 22, 
                                      hjust = 0.5)) +
      theme(axis.title = element_text(family = "Trebuchet MS", 
                                      size = 14)) +
      theme(axis.text.x = element_text(hjust = 1, 
                                       size = 10,
                                       face = "bold",
                                       angle = 45)) +
      theme(axis.text.y = element_text(hjust = 1, 
                                       size = 10,
                                       face = "bold"))
  })
  
  output$plot <- renderPlot({
    print(plotInput())
  })
  
  output$titletab <- renderUI({
    df <- filedata()
    if (is.null(df)) return(NULL)
    
    textInput(inputId = "title",
              label = "Enter a title for the plot")
  })
  output$table <- renderDataTable({
    infile <- input$datafile 
    if(is.null(infile)) {
    } else {read.csv(infile$datapath)}
  }, options = list(scrollX = TRUE, pageLength = 10))
  
  # Download button
  output$downloadplot <- renderUI({
    df <- filedata()
    if (is.null(df)) return(NULL)
    
    div(style="display:inline-block",downloadButton('plotdownload', 'Download Plot'))
  })
  
  output$plotdownload <- downloadHandler(
    filename = function() { paste(input$datafile, '.png', sep='') },
    content = function(file) {
      device <- function(..., width, height) grDevices::png(..., width = width, height = height, res = 300, units = "in")
      ggsave(file, plot = plotInput(), device = "png", width = 8, height = 6)
  }
) 
  
}

shinyApp(ui = ui, server = server)