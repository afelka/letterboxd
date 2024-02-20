#load packages
library(tidyr)
library(dplyr)
library(rvest)
library(stringr)
library(stringi)
library(qdapRegex)
library(lubridate)
library(ggplot2)
library(ggimage)

#read the diary.csv downloaded from LetterboxD and filter by tag berlinale and new columns
berlinale <- read.csv("./diary.csv") %>% distinct(Letterboxd.URI, .keep_all = TRUE) %>% 
             filter(Tags == "berlinale") %>% mutate(title = NA,
                                                    image_url = NA,
                                                    image_name = NA)

#for each movie get the title and download the image
for(i in seq_len(nrow(berlinale))) {
  
  url <- berlinale$Letterboxd.URI[i]
  
  get_request <- httr::GET(url)
  content <- httr::content(get_request)
  
  films_main_url <- paste0("https://letterboxd.com", 
                    content %>%
                    html_node(xpath = "//span[@class='film-title-wrapper']//a") %>%
                    html_attr("href"))
  
  get_request2 <- httr::GET(films_main_url)
  content2 <- httr::content(get_request2)
  
  title <- content2 %>% 
    html_nodes(xpath = '//meta[@property="og:title"]') %>%
    html_attr("content")
  
  themoviedb_url <- (content2 %>%
    html_nodes(xpath = "//p[@class='text-link text-footer']//a") %>%
    html_attr("href"))[2] 
  
  get_request3 <- httr::GET(themoviedb_url)
  content3 <- httr::content(get_request3)
  
  image_url <- content3 %>% 
    html_node(xpath = '//img[@class="poster"]') %>%
    html_attr("src")
  
  image_name <- paste0(gsub(" ","_",str_to_lower(gsub("[^[:alnum:][:space:]]","",title))),".jpg")
  
  berlinale$title[i] <- title
  berlinale$image_url[i] <- image_url
  berlinale$image_name[i] <- image_name
  
  download.file(image_url, destfile = image_name ,mode = "wb")
  
  Sys.sleep(round(runif(1,1,1)))
  
}

#convert watched date to year
berlinale$berlinale_year <- lubridate::year(berlinale$Watched.Date)

#add watched_number to be able to create ggplot
berlinale <- berlinale %>% group_by(berlinale_year) %>% mutate(watched_number = 1:n()/2)

#add manually downloaded festival posters
berlinale_poster_rows <- data.frame(
  Name = c("Berlinale 2024","Berlinale 2023","Berlinale 2020","Berlinale 2019","Berlinale 2017","Berlinale 2016","Berlinale 2015" ),
  berlinale_year = c(2024,2023,2020,2019,2017,2016,2015),
  watched_number = c(0,0,0,0,0,0,0),
  image_name = c("berlinale_2024.jpg",
                 "berlinale_2023.jpg",
                 "berlinale_2020.jpg",
                 "berlinale_2019.jpg",
                 "berlinale_2017.jpg",
                 "berlinale_2016.jpg",
                 "berlinale_2015.jpg")
)

berlinale_posters_added <- bind_rows(berlinale, berlinale_poster_rows)

# Convert Year to factor
berlinale_posters_added$berlinale_year <- as.factor(berlinale_posters_added$berlinale_year)

#create ggplot
berlinale_movies <- ggplot(berlinale_posters_added, aes(y = berlinale_year, x = watched_number, label = as.character(berlinale_year))) +
  geom_image(aes(image = image_name), size = 0.08) +
  labs(title = "Movies Watched in Berlinale over the Years") +
  theme_classic() +
  scale_y_discrete() +
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.ticks = element_blank(),
        axis.line = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_text(size = 12, face = "bold")) +
  #to distingusih between festival posters and movie posters
  geom_vline(xintercept = 0.25, linetype = "solid", color = "red", linewidth = 1)

#save ggplot
ggsave("berlinale_movies.png", plot = berlinale_movies, width = 6, height = 4, dpi = 300)