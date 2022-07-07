library(shiny)
library(slickR)
library(tidyverse)
library(rvest)

load("data/codelist.RData")

ui <- fluidPage(shinybusy::add_busy_spinner(),
  sidebarLayout(
    sidebarPanel(width = 2,
      selectInput(inputId = "country",label = "Country",choices = codelist$country.name.en,selected = "United States"),
      actionButton(inputId = "refreshSite",label = "Refresh Feed")
    ),

    mainPanel(
      # shinyfullscreen::fullscreen_this(
        slickROutput("slickr",height = "50%",width = "50%")
        # )
    )
  )
)

server <- function(input, output) {

  airbnbImageLinks <- reactiveVal()

  observeEvent(input$refreshSite,{

    # browser()

    shinybusy::show_modal_spinner(text = "Pulling AirBnB data")

    system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)
    # binman::list_versions("chromedriver")

    remDr <- RSelenium::rsDriver(browser = "chrome",check = TRUE,chromever = "103.0.5060.24")

    remDr$client$navigate(paste0("https://www.airbnb.com/s/",
                                 #"United-States",
                                 paste0(input$country,collapse = "-"),
                                 "/homes?tab_id=home_tab&refinement_paths%5B%5D=%2Fhomes&query=",
                                 # Colorado%2C%20United%20States,
                                 paste0(input$country,collapse = "%20"),
                                 "&date_picker_type=flexible_dates&flexible_trip_lengths%5B%5D=one_week&adults=1&source=structured_search_input_header&search_type=autocomplete_click"))

    Sys.sleep(2)

    siteDat <- remDr$client$getPageSource()[[1]] %>%
      read_html()

    carouselData <- siteDat%>%
      html_elements("[itemprop='itemListElement']")

    # browser()

    ret <- carouselData %>%
      map_dfr(function(imData){

        name <- html_elements(imData,"[itemprop='name']") %>%
          html_attr("content")

        ims <- html_elements(imData,"a")

        photoTourLink <- ims %>%
          html_attr("href") %>%
          unique()

        # photoTour <- read_html(paste0("https://www.airbnb.com/",photoTourLink,"&modal=PHOTO_TOUR_SCROLLABLE"))

        photoTour <-tryCatch(expr = {
          remDr$client$navigate(paste0("https://www.airbnb.com/",photoTourLink,"&modal=PHOTO_TOUR_SCROLLABLE"))

          Sys.sleep(2)

           remDr$client$getPageSource()[[1]] %>%
            read_html()
          },
          error = function(e){

            NULL

          })

        shinybusy::update_modal_spinner(text = paste0("Pulling data from ",name))

        if(length(photoTour) > 0){

          imLinks <- photoTour %>%
            html_elements("source") %>%
            html_attr("srcset") %>%
            str_remove("\\?.*$") %>%
            unique()

          link <- paste0("https://www.airbnb.com/",photoTourLink)

          # browser()

          return(data.frame(imLinks = imLinks) %>%
            mutate(name = name,
                   link = link,
                   photoTourLink = photoTourLink))

        }

      })

    shinybusy::remove_modal_spinner()

    remDr$server$stop()
    remDr$client$close()

    airbnbImageLinks(ret)

  })

  output$slickr <- renderSlickR({

    # browser()

    req(length(airbnbImageLinks()) > 0)

    slickR(obj = airbnbImageLinks()$name,slideType = "p",objLinks = airbnbImageLinks()$link) %synch%
      (slickR(airbnbImageLinks()$imLinks,padding = 0) +#,objLinks = airbnbImageLinks$link) +
      settings(dots = FALSE,autoplay = TRUE,autoplaySpeed = 2000))

  })

}

# Run the application
shinyApp(ui = ui, server = server)
