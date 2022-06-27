# Text Analysis using R
### Packages that are used
- 'tidyverse' 
- 'tidytext' 
- 'stringr'
- 'gutenbergr'
### Used Project Gutenberg package
- Upton Sinclair: "*The Jungle*" (1906)
- W.E.B. Du Bois: "*The Quest of the Silver Fleece*" (1911)
### What kind of work is done here?
1. Function 'to take an argument of a downloaded book tibble and return it in tidy text format.'
2. Tidy each book and then add `book` and `author` as variables and save each tibble to a new variable.
3. Use a dplyr function to combine the two tibbles into a new tibble.
4. Measure the net sentiment using bing for each block of 50 lines.
5. Measure the total for each nrc sentiment in each block of 500 lines.
6. Interpret the plots for each book and then compare them.
7. Plot the top ten for each positive and negative sentiment faceting by book.
8. Remove the inappropriate word(s) from the analysis.
9. Rerun the analysis from step 5 and recreate the plot with the title "Custom Bing".
10. Calculate and plot the 'tf-idf'.
