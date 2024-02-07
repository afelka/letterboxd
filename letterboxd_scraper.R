#load packages
library(tidyr)
library(dplyr)
library(rvest)
library(stringr)
library(stringi)
library(qdapRegex)
library(arules)
library(DT)

#read the watched.csv downloaded from LetterboxD
movies <- read.csv("./watched.csv") %>% distinct(Letterboxd.URI, .keep_all = TRUE)

#function for testing whether we can download a given url
readUrl <- function(url) {
  out <- tryCatch(
    {
      download.file(url, destfile = "scrapedpage.html", quiet = TRUE)
      return(1)
    },
    error = function(cond) {
      return(0)
    },
    warning = function(cond) {
      return(0)
    }
  )
  return(out)
}

#create an empty data.frame
total_list <- data.frame(people = character(), people_links = character(), title = character(), director = character())

#for each movie get the actor list, director and title
for(i in seq_len(nrow(movies))) {

url <- movies$Letterboxd.URI[i]

readUrl(url)

content <- read_html("scrapedpage.html")

title <- content %>% 
  html_nodes(xpath = '//meta[@property="og:title"]') %>%
  html_attr("content")

director <- content %>% 
  html_nodes(xpath = '//meta[@name="twitter:data1"]') %>%
  html_attr("content")

actors <- rm_between(content, '"actors":', '],"dateCreated":', extract=TRUE)[[1]]

people <- rm_between(actors, '"Person","name":"', '","sameAs":"', extract=TRUE)[[1]]

people_links <- rm_between(actors, '"sameAs":"', '"}', extract=TRUE)[[1]]

combined <- data.frame(people, people_links)

combined$title <- title
combined$director <- director

total_list <<- rbind(total_list, combined)

Sys.sleep(round(runif(1,1,1)))

}

#find top 20 most watched actors
top20_actors <- total_list %>% filter(!is.na(people)) %>%
                               group_by(people, people_links) %>%
                               summarise(count_of_movies = n()) %>% 
                               arrange(desc(count_of_movies)) %>% 
                               head(20)

#download the picture of top 20 actors
for(i in 1:nrow(top20_actors)) {
  
actor_url <- paste0("https://letterboxd.com", top20_actors$people_links[i])

readUrl(actor_url)

content <- read_html("scrapedpage.html")

image_name <- paste0(gsub(" ","_",str_to_lower(gsub("[^[:alnum:][:space:]]","",top20_actors$people[i]))),".jpg")

tmdb_url <- content %>%
  html_nodes(xpath = '//p[@class="text-link text-footer"]//a') %>%
  html_attr("href")

readUrl(tmdb_url)

content <- read_html("scrapedpage.html")

image_url <- content %>%
  html_nodes(xpath = '//meta[@property="og:image"]') %>%
  html_attr("content")

download.file(image_url, destfile = image_name ,mode = "wb")

top20_actors$image_name[i] <- image_name

}

#function for converting images to be used in DT
img_to_base64 <- function(path) {
  img <- readBin(path, "raw", file.info(path)$size)
  sprintf('<img src="data:image/jpeg;base64,%s" height="50" width="50">', base64enc::base64encode(img))
}

top20_actors$image <- sapply(top20_actors$image_name, img_to_base64)

colnames(top20_actors) <- c("Actor", "Link", "Count of Movies", "Image Name", "Image")

#create datatable with images and count of movies
datatable(top20_actors[, c("Image", "Actor", "Count of Movies")], escape = FALSE, 
          options = list(dom = 't', ordering = FALSE, pageLength = 20), rownames = FALSE) %>%
  formatStyle('Image', 'width' = '50px')

#list top 20 most watched directors and list the movies
top20_directors <- total_list %>% distinct(title, director) %>%
                                  group_by(director) %>%
                                  summarise(count_of_movies = n(), movies = paste(title, collapse = ", ")) %>% 
                                  arrange(desc(count_of_movies)) %>% 
                                  rename("Director" = director,
                                         "Count of movies" = count_of_movies,
                                         "Movies" = movies) %>%
                                  head(20)

#create a datatable for top20_directors
datatable(top20_directors,  escape = FALSE, options = list(dom = 't', ordering = FALSE, pageLength = 20), rownames = FALSE)

#convert movies into transactions to be able to find most watched pairs
transactions <- total_list %>% filter(!is.na(people)) %>%
  group_by(title) %>%
  summarize(actors = list(people)) %>%
  select(actors)

transactions <- as(transactions$actors, "transactions")

# Mine association rules
rules <- apriori(transactions, parameter = list(support = 0.001, confidence = 0.005, maxlen = 2,  target = "rules"))

# Extract pairs of actors and their support
rules_df <- as(rules, "data.frame") 

rules_df <- rules_df %>% filter(!str_detect(rules_df$rules,'\\{\\}')) %>% select(rules, count)

# Function to sort actors in a pair
sort_actors <- function(pair) {
  pair_sorted <- sort(unlist(strsplit(pair, " => ")))
  return(paste(pair_sorted, collapse = " => "))
}

# Sort actors within each pair
rules_df <- rules_df %>%
  mutate(rules_sorted = sapply(rules, sort_actors))

rules_df$rules_sorted <- gsub("[{}]","", rules_df$rules_sorted )

# find top 20 most watched pairs
top20_pairs <- unique(rules_df[c("rules_sorted", "count")]) %>%
                separate(rules_sorted, c("First Actor", "Second Actor"),sep = " => ") %>%
                arrange(desc(count)) %>%
                rename("Count of movies" = count) %>%
                head(20)


#create a datatable for top_20pairs
datatable(top20_pairs,  escape = FALSE, options = list(dom = 't', ordering = FALSE, pageLength = 20), rownames = FALSE)







