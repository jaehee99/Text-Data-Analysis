# Sentiment Analysis

# Load library

library(tidyverse)
library(tidytext)
library(stringr)
library(gutenbergr)

# 1. Download the following two works from the early 20^th^ century from Project Gutenberg:
# - Upton Sinclair: "*The Jungle*" (1906)
# - W.E.B. Du Bois: "*The Quest of the Silver Fleece*" (1911)
# Upton Sinclair: "*The Jungle*" (1906)
gutenberg_works() %>%  
  filter(title == "The Jungle") %>%  
  select(gutenberg_id)  %>%  
  gutenberg_download() -> jungle

# W.E.B. Du Bois: "*The Quest of the Silver Fleece*" (1911)
gutenberg_works() %>%  
  filter(title == "The Quest of the Silver Fleece: A Novel")  %>% 
  select(gutenberg_id) %>% 
  gutenberg_download() -> silver

# 2. Write a function 'to take an argument of a downloaded book tibble and return it in tidy text format.'
# - The function must add line and chapter numbers as variables
# - The function must unnest tokens at the word level
# - The function must remove any Project Gutenberg formatting so only the words remain
# - The function must remove any stop_words and filter out any `NA`s
# - The function must remove any front matter (words before Chapter 1)
# - The function can consider the unique nature of the front matter but cannot consider exactly how many chapters are in each book based on looking at the data i.e., no math based on knowing the number of chapters.

jungle_function <- function(jungle){
  jungle %>%  
    mutate(linenumber = row_number()) %>%  
    mutate(chapter = cumsum(str_detect(text, regex("^CHAPTER [\\divxlc]",ignore_case = TRUE)))) %>%  
    ungroup() %>% 
    select(chapter, linenumber, everything()) -> jungle
  jungle <- jungle[-(1:51), , drop = FALSE]
  
  jungle%>% 
    unnest_tokens(word,text) %>%
    mutate(word = str_extract(word, "[a-z']+")) %>%
    anti_join(stop_words, by = "word") %>%  
    drop_na() -> jungle_jungle
  return(jungle_jungle)
}

silver_function <- function(silver){
  silver %>%  
    mutate(linenumber = row_number()) %>%  
    mutate(chapter = cumsum(str_detect(text, regex("(^_)([a-z]+)([-]{0,1})([a-z]+)(_$)",ignore_case = TRUE))))  %>%  
    ungroup() %>% 
    select(chapter, linenumber, everything())-> silver 
  silver <- silver[-(1:143), , drop = FALSE]
  
  silver %>%  
    unnest_tokens(word,text) %>% 
    mutate(word = str_extract(word, "[a-z']+")) %>% 
    anti_join(stop_words, by = "word") %>%  
    drop_na()  -> silver_silver
  return(silver_silver)
}

# 3. Use the function from step 2
# - Tidy each book and then add `book` and `author` as variables and save each tibble to a new variable. How many rows are in each book?
jungle_function(jungle) %>%   
  mutate(author = "Upton Sinclair") %>%  
  mutate(book = "The Jungle") -> new_jungle
nrow(new_jungle)

silver_function(silver) %>%  
  mutate(author = "W.E.B. Du Bois") %>%  
  mutate(book = "The Quest of the Silver Fleece: A Novel") -> new_silver
nrow(new_silver)

# 4. Use a dplyr function to combine the two tibbles into a new tibble. 
# - It should have 89,434 rows with 6 variables
bind_rows(mutate(new_jungle, author = "Upton Sinclair"), 
          mutate(new_silver, author = "W.E.B. Du Bois")) -> jungle_silver
nrow(jungle_silver)
ncol(jungle_silver)

# 5. Measure the net sentiment using bing for each block of 50 lines
# - Plot the sentiment for each book in an appropriate faceted plot - either line or column. 
# - Be sure to remove the legend.
# - Save the plot to a variable
# - Interpret the plots for each book and compare them.

jungle_silver %>%  
  inner_join(get_sentiments("bing")) %>%  
  count(book, index = linenumber %/% 50, sentiment) %>%  
  spread(sentiment, n, fill = 0) %>%  
  mutate(sentiment = positive - negative) %>%  
  ggplot(aes(index, sentiment, fill = book)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~book, ncol = 2, scales = "free_x") -> compare_sentiment

compare_sentiment

# Interpretation: Both of the books have significantly more negative sentiments compared to positive sentiments. This is because most of the lines are below 0. However, when we compare two graphs, it seems like "The Quest of the Silver Fleece" have more positive words than "the Jungle".

# 6. Measure the total for each nrc sentiment in each block of 500 lines and then,
# - Filter out the "positive" and "negative" and save to a new variable. You should have 464 observations.
# - Plot the count of the sentiments for each block in each book in an appropriate faceted plot with the books in two columns and the sentiments in 8 rows. 
# - Be sure to remove the legend.

get_sentiments("nrc") %>%  
  filter(sentiment != "positive" & sentiment != "negative") -> removed_data

jungle_silver %>%  
  inner_join(removed_data, by = "word") %>%  
  count(book, index = linenumber %/% 500, sentiment) -> observations
observations %>%  
  ggplot(aes(index, n, fill = sentiment)) + 
  geom_col(show.legend = FALSE) +
  facet_wrap(~book,scales = "free_y") 

# - Interpret the plots for each book and then compare them. 
# These are stacked bar plots showing to compare the total and also see the changes for sentiment level. 
# We can see that for the book Jungle, for each index there is around average 700-750 sentiments for each index. 
# We can see that for the book Quest Silver, for each index there is around average 500-600 sentiments for each index. Exception for few index, most of the sentiments in each index,have similar amount of sentiments.
# We can see that the values drop off so suddenly at the end for the Jungle book. I will explain this in the next question. 

# - Why did the values drop off so suddenly at the end?
# In the Jungle graph, we can see that at the end the values drop off so suddenly. This is because of the index and linenumber. To be specific: 
# In the Jungle there are 28 index, 14027 line numbers. 500 * 28 = 14000, 14027 - 14000 so there are 27 lines left.
# In the Quest Silver book there are 28 index, 14489 line numbers. 500 * 28 = 14000, 14489 - 14000 so there are 489 lines left.
# Therefore, we can see that for the last part drop suddenly in the Jungle book because there are only 27 lines for the word to show the sentiment, whereas other parts for each index have 500 lines. 
# However, the book Quest Silver didn't drop at the end, this is because, the left lines are 489 lines, therefore this is almost 500lines, that is why the height is similar with other parts. 

# 7. Using bing, create a new data frame with the counts of the positive and negative sentiment words for each book.
# - Show the "top 20" most frequent words across both books along with their book, sentiment, and count, in descending order by count.
# - What are the positive words in the list of "top 20"?
jungle_silver %>%  
  inner_join(get_sentiments("bing")) %>% 
  count(book, word, sentiment, sort = TRUE) -> bing_pos_neg

bing_pos_neg %>%  
  top_n(20) %>%  
  filter(sentiment == "positive") 

# 8. Plot the top ten for each positive and negative sentiment faceting by book.
# - Ensure each facet has the words in the proper order for that book.
# - Identify any that may be inappropriate for the context of the book and should be excluded from the sentiment analysis.
bing_pos_neg %>% 
  group_by(sentiment, book) %>%  
  slice_max(order_by = n, n=10) %>%
  ungroup() %>%  
  mutate(word = reorder(word, n)) -> data 
data %>% 
  ggplot(aes(word, n, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(sentiment~book, scales = "free_y") +
  labs(y = "Contribution to sentiment", x = NULL) +
  coord_flip()

# I think removing word "miss" is better than removing other words. This is because the word miss has many different meanings that can be positive or negative or neutral. 
# According to Cambridge dictionary, the word miss means several things:
# 1. to fail to do or experience something, often something planned or expected, or to avoid doing or experiencing something
# 2. to feel sad that a person or thing is not present
# 3. to fail to hit something, or to avoid hitting something
# 4. to notice that something is lost or absent
# 5. a girl or young woman, especially one who behaves rudely or shows no respect
# 6. a title used before the family name or full name of a single woman who has no other title 
# and so on..
# The word miss cannot always be negative. This is because miss can be used when calling someone such as "Miss Helena Lewis".


# 9. Remove the inappropriate word(s) from the analysis.
# - Replot the top 10 for each sentiment per book from step 8.
# - Interpret the plots
data %>%  
  filter(word !=  "miss") %>% 
  group_by(sentiment, book) %>%  
  slice_max(order_by = n, n=10) %>%
  ungroup() %>%  
  mutate(word = reorder(word, n)) %>% 
  ggplot(aes(word, n, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(sentiment~book, scales = "free_y") +
  labs(y = "Contribution to sentiment", x = NULL) +
  coord_flip()

# Interpretation: 
# The most frequently occurring word is "poor" in the negative words from the book "Jungle". “cold”, “lost” "wild",and “hard” are the next most frequently occurring words, which indicate that most people feel challenging about the life in the Jungle. 
# The most frequently occurring word is "slowly" in the negative words from the book "The Quest of the Silver Fleece". "dark" is the next most frequently occurring words, which indicate that the background of this book is very dark and slow. 
# The most frequently occurring word is "free" in the positive words from the book "Jungle". This indicates that people living in the Jungle have freedom. 
# The most frequently occurring word is "love" in the positive words from the book "The Quest of the Silver Fleece". "mighty", "strong", "silent", "trust" are the next most frequently occuring words. This indicates that the characters in this book love each other with strong trust. 


# 10. Rerun the analysis from step 5 and recreate the plot with the title "Custom Bing".
# - Show both the original step 5 plot with the new plot in the same output graphic, one on top of the other.

get_sentiments("bing") %>%
  filter(word != "miss") ->
  bing_no_miss

# Original
jungle_silver %>%  
  inner_join(get_sentiments("bing"), by = "word") %>%  
  count(book, index = linenumber %/% 50, sentiment) %>%  
  pivot_wider(names_from = sentiment, values_from = n, values_fill = list(n=0)) %>% 
  mutate(net = positive - negative) -> original
# Recreate 
jungle_silver %>%  
  inner_join(bing_no_miss, by = "word") %>%  
  count(book, index = linenumber %/% 50, sentiment) %>%  
  pivot_wider(names_from = sentiment, values_from = n, values_fill = list(n=0)) %>% 
  mutate(net = positive - negative) -> recreate

original %>%
  ggplot(aes(index, net, fill = book)) +
  geom_col(show.legend = FALSE) +
  ggtitle("Original") +
  facet_wrap(~book, ncol = 2, scales = "free_x") -> p1

recreate %>%
  ggplot(aes(index, net, fill = book)) +
  geom_col(show.legend = FALSE) + 
  ggtitle("Custom Bing") +
  facet_wrap(~book, ncol = 2, scales = "free_x") -> p2

library(gridExtra)
grid.arrange(p1, p2, nrow=2)

# - Interpret the plots: 
# For the Jungle plot,overall this book has more negative words than positive words ,however, there are some factors that make the characters positive feelings. What this implies is that maybe they encountered a lot of challenges while in Jungle, but while in the Jungle they feel other positive feelings.   
# After removing the word miss, Custom bing plot of the book "The Quest of the Silver Fleece: A Novel" has more positive words compared to the original plot. This book also has negative feelings words a lot and based on that characters feel some kind of positive feelings. 
# When we compare two books each other, we can say that the book Jungle is much more negative compared to the other one. This is because there are fewer lines above 0 in the Jungle plot than the other Sliver Fleece book plot. 

# 1. Use a single call to download all the following complete books at once from author Mark Twain from Project Gutenberg
# - Use the meta_fields argument to include the Book title as part of the download
# - *Huckleberry Finn*,  *Tom Sawyer* , *Connecticut Yankee in King Arthur's Court*, *Life on the Mississippi* , *Prince and the Pauper*,  and *A Tramp Abroad* 
gutenberg_authors %>%
  filter(author == "Twain, Mark") %>%
  select(gutenberg_author_id) -> mark_info

gutenberg_works(gutenberg_author_id == mark_info[[1]]) %>%
  arrange(title) %>%
  filter(title %in% c("Adventures of Huckleberry Finn",  "The Adventures of Tom Sawyer" , "A Connecticut Yankee in King Arthur's Court", "Life on the Mississippi" , "The Prince and the Pauper","A Tramp Abroad" )) %>%
  select(gutenberg_id) -> title_info

title_info[[1]]
gutenberg_download(c(title_info[[1]]), meta_fields = "title") -> complete_books


# 2. Modify your earlier function or create a new one to output a tf-idf ready dataframe (**leave the stop words in the text**)
# - Unnest, remove any formatting, and get rid of any `NA`s  
# - Add the count for each word by title.
# - Use your function to tidy the downloaded texts and save to a variable. It should have 56,759 rows.

new_function <- function(complete_books){
  complete_books %>% 
    unnest_tokens(word, text) %>%
    mutate(word = str_extract(word, "[a-z']+")) %>%
    count(word, title, sort = TRUE) %>%  
    drop_na()-> tf_idf_data
  
  return(tf_idf_data)
}

book_words <-  new_function(complete_books)


# 3. Calculate the tf-idf
# - Save back to the data frame.

book_words %>% 
  bind_tf_idf(word, title, n) -> book_words 

# 4. Plot the tf for each book using a faceted graph.
# - Facet by book and constrain the data or the X axis to see the shape of the distribution.

ggplot(book_words, aes(tf, fill = title)) +
  geom_histogram(show.legend = FALSE) +
  xlim(NA, 0.0009) +
  facet_wrap(~title, ncol = 2, scales = "free_y") 

# 5. Show the words with the 15 highest tf-idfs across across all books
# - Only show those rows.
# - How many look like possible names?

book_words %>% 
  arrange(desc(tf_idf)) %>%  
  head(15) %>%  
  select(word) 

# hendon, becky, huck, canty, joe seem like possible names. Therefore, 4 looks like possible names among the above result.

# 6.  Plot the top 7 tf_idf words from each book.
# - Sort in descending order of tf_idf
# - Interpret the plots.
show <- book_words %>%
  group_by(title) %>%
  slice_max(tf_idf, n = 7) %>% 
  ungroup() %>%
  arrange(title, -tf_idf)

show %>%
  mutate(term = reorder_within(word, tf_idf, title)) %>%
  ggplot(aes(tf_idf, term, fill = factor(title))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ title, scales = "free") +
  scale_y_reordered()

# Interpretation: tf-idf is to find out what words are important in the book. Above results show that Mark Twain used similar words throughout the six books. Among these 6 books, what distinguishes the one book and another is the name of the character/place of the background. That is why we use tf-idf. tf-idf helps to find out which book is what based on the words that are important in the book and mostly it is distinguished by the proper nouns. For example, we can assume that the book "the adventures of Tom Sawyer" main character is becky since it is the most frequently used. Also, the book "The Prince and the Pauer" main place is hendon since it is the most frequently used. So we can think if the book has the most frequent word is becky then the book will be the adventrue of Tom Sawyer. 







