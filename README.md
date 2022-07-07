# airbnbSlideshow
An interactive slideshow for Airbnb listings

Do you enjoy looking up Airbnb listings simply for the fun of it?
So do I.
I created this web application using the `shiny` R package to show a slideshow of Airbnb listings from a country of interest.
I scrape image data from Airbnb using the `RSelenium` R package and create a slideshow of the images using the `slickR` package.
Click on the name of a property that you're interested in to see its Airbnb listing.

Note that this app can currently only be run on your local machine, so clone this repo to get started.
Another word of warning: RSelenium may work faster than it takes for the Airbnb page to load (depending on your connection speed), so I added Sys.sleep() between the navigation and scraping calls within the app.
Two seconds worked on my computer over ethernet, but I needed to change it to 20 seconds for my crappy old computer on 2.4 GHz wifi.
If you see a browser window open and almost immediately close without loading the page, you may want to play around with Sys.sleep() values.
