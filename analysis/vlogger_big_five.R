# Vlogger Big Five Prediction - R analysis
# Adapted from the original Kaggle notebook, with portable file paths.
# This is a faithful research-portfolio adaptation, not an independently validated reproduction.
# Set working directory to this repository root before running:
# Rscript analysis/vlogger_big_five.R

dir.create("results", showWarnings = FALSE)

# --- Notebook cell 2 ---
# Dependencies: see README.md
library(tidyverse)
library(tidytext)
library(textdata)
library(wordcloud)
library(caret)

# Run from project root. Explicit filenames avoid reliance on directory listing order.
master_dir <- file.path("data", "bda-2023-profiling-personality", "youtube-personality")
path_to_transcripts <- file.path(master_dir, "transcripts")
AudioVisual_file <- file.path(master_dir, "YouTube-Personality-audiovisual_features.csv")
Gender_file <- file.path(master_dir, "YouTube-Personality-gender.csv")
Personality_file <- file.path(master_dir, "YouTube-Personality-Personality_impression_scores_train.csv")
stopifnot(all(file.exists(c(AudioVisual_file, Gender_file, Personality_file))), dir.exists(path_to_transcripts))


# --- Notebook cell 4 ---
# Importing the transcripts
transcript_files = list.files(path_to_transcripts, full.names = TRUE) 
print(head(transcript_files))

# Encoding the ID
vlogId = basename(transcript_files)
vlogId = str_replace(vlogId, pattern = ".txt$", replacement = "")
head(vlogId)

# Including features extracted from the transcript texts
transcripts_df = tibble(
    
    # vlogId connects each transcripts to a vlogger
    vlogId=vlogId,
    
    # Read the transcript text from all file and store as a string
    TEXT = map_chr(transcript_files, ~ paste(readLines(.x), collapse = "\\n")), 
    
    # `filename` keeps track of the specific video transcript
    filename = transcript_files
)

# Inspecting the first two examples
transcripts_df %>% 
    head(2)

# --- Notebook cell 6 ---
# Import the Personality scores
pers_df = read_delim(Personality_file, delim=" ")

# Checking the data frame
head(pers_df)

# --- Notebook cell 8 ---
# Storing gender info
gender_df = read.delim(Gender_file, head=FALSE, sep=" ", skip = 2)

# Add column names
names(gender_df) = c('vlogId', 'gender')

# preview data
head(gender_df)

# --- Notebook cell 10 ---
# merging gender and pers with left_join
vlogger_df01 = left_join(gender_df, pers_df, by='vlogId')

# switching characters for numeric values for gender variable
vlogger_df01$gender[vlogger_df01$gender == "Female"] <- 1
vlogger_df01$gender[vlogger_df01$gender == "Male"] <- 0

# preview data
head(vlogger_df01)

# --- Notebook cell 13 ---
# Importing the audio and visual information
AudioVisual_df <- read.delim(AudioVisual_file, sep = " ", head=TRUE)

# preview data
head(AudioVisual_df)

# --- Notebook cell 16 ---
# select all columns containing the mean 
selected_columns <- grep("^mean", names(AudioVisual_df), value = TRUE)

# Join the selected columns to vlogger_df01
vlogger_df1 <- left_join(vlogger_df01, select(AudioVisual_df, vlogId, all_of(selected_columns)), by = 'vlogId')

# Print the first few rows of the resulting data frame
head(vlogger_df1)

# --- Notebook cell 19 ---
# Tokenizing the transcripts into words
transcript_features_df = 
    transcripts_df %>%
    unnest_tokens(token, TEXT, token = 'words') 

# Creating a wordcloud to see the 100 most used words
transcript_features_df %>%
    mutate(token = tolower(token)) %>%
count(token, sort= TRUE) %>%
with(., wordcloud::wordcloud(token, n, max.words = 100))

# --- Notebook cell 21 ---
# Merging transcript_features_df with vlogger_df1
vlogger_df = left_join(vlogger_df1, transcript_features_df, by='vlogId') %>%
   select(-filename)

# preview of data
head(vlogger_df)

# --- Notebook cell 23 ---
# NRC lexicon from tidytext/textdata. On first run textdata may prompt for NRC terms.
nrc <- tidytext::get_sentiments("nrc")
transcript_sentiment <- left_join(vlogger_df, nrc, by = c(token = "word"), relationship = "many-to-many") %>%
  count(vlogId, sentiment) %>%
  pivot_wider(id_cols = "vlogId", names_from = sentiment, values_from = n, values_fill = 0)


# --- Notebook cell 25 ---
# getting stopwords
stopwords <- get_stopwords() 

# removing stopwords
transcript_features_df <- transcript_features_df %>%
    anti_join(stopwords, by = c(token = "word"))

#creating a wordcloud to see the 100 most used words without stopwords
transcript_features_df %>%
count(token, sort= TRUE) %>%
with(., wordcloud::wordcloud(token, n, max.words = 100))

# --- Notebook cell 27 ---
# merging our dataframe 
data01 <- inner_join(vlogger_df1,transcript_sentiment, by = "vlogId")

# preview data
head(data01)

# --- Notebook cell 29 ---
# make a column that counts the length of a sentence by summing the words per vlog.
transcript_features_df_2 <- 
    transcripts_df %>%
    unnest_tokens(sentences, TEXT, token = 'sentences') %>%
  group_by(vlogId) %>%
  summarize(sentences = n()) %>%
  as_tibble()

# Merge the two data frames
data02 <- inner_join(data01, transcript_features_df_2, by = "vlogId")

# preview data
head(data02)

# --- Notebook cell 31 ---
# make a dataframe that counts the letters in each word:
word_length <- transcript_features_df %>%
    select(vlogId, token) %>%
    mutate(token = nchar(token))

# objectivly calculate what short and long words should be by calculating std
summary(word_length$token)

# creating a variable that contains the length of the words
word_length <- word_length %>%
    mutate(long_word = token >= 11)

# creating a variable that contains long words
long_word_df <- word_length %>%
  group_by(vlogId) %>%
  summarize(long_words = sum(long_word))

# now adding the feature to the data 
data <- data02 %>%
  left_join(long_word_df, by = "vlogId")

# preview data
head(data)

# --- Notebook cell 34 ---
# building an additive model
mod_01 <- lm(cbind(Extr, Agr, Cons, Emot, Open) ~ gender + mean.pitch + mean.conf.pitch + mean.spec.entropy + mean.val.apeak + mean.loc.apeak + mean.num.apeak + mean.num.apeak + mean.energy + mean.d.energy + anger + anticipation + disgust + fear + joy + negative + positive + sadness + surprise + trust + sentences + long_words, data = data)

# print model summary
summary(mod_01)

# RMSE for the training dataset
(RMSE_01 <- sqrt(mean(mod_01$residuals^2)))

# --- Notebook cell 36 ---
# building a second additive model
mod_02 <- lm(cbind(Extr, Agr, Cons, Emot, Open) ~ gender + mean.conf.pitch + mean.spec.entropy + mean.val.apeak + mean.loc.apeak + mean.num.apeak + mean.num.apeak + mean.energy + mean.d.energy + anger + anticipation + fear + joy + positive + surprise + sentences + long_words, data = data)

# print model summary
summary(mod_02)

# RMSE for the training dataset
(RMSE_02 <- sqrt(mean(mod_02$residuals^2)))

# --- Notebook cell 38 ---
# building an interactive model
mod_03 <- lm(cbind(Extr, Agr, Cons, Emot, Open) ~ gender + mean.pitch * mean.conf.pitch + mean.spec.entropy + mean.val.apeak * mean.loc.apeak * mean.num.apeak * mean.num.apeak + mean.energy * mean.d.energy + anger * disgust * fear * negative * sadness + anticipation * joy * positive * surprise * trust + sentences * long_words, data = data)

# print model summary
summary(mod_03)

# RMSE for the training dataset
(RMSE_03 <- sqrt(mean(mod_03$residuals^2)))

# --- Notebook cell 40 ---
# Remove highly correlated predictor columns before fitting the revised model.
corr_data <- data[, 8:28]
correlation_matrix <- cor(corr_data, use = "pairwise.complete.obs")
highly_correlated_vars <- caret::findCorrelation(correlation_matrix, cutoff = 0.8)
if (length(highly_correlated_vars)) corr_data <- corr_data[, -highly_correlated_vars, drop = FALSE]
data_cor <- cbind(data[, 1:7, drop = FALSE], corr_data)
print(names(data_cor))


# --- Notebook cell 41 ---
# building an additive model with remaining features
mod_04 <- lm(cbind(Extr, Agr, Cons, Emot, Open) ~ gender + mean.pitch + mean.conf.pitch + mean.spec.entropy + mean.val.apeak + mean.loc.apeak + mean.energy + mean.d.energy + disgust + fear + joy + surprise + sentences + long_words, data = data)

# print model summary
summary(mod_04)

# RMSE for the training dataset
(RMSE_04 <- sqrt(mean(mod_04$residuals^2)))

# --- Notebook cell 43 ---
# List of response variables
response_vars <- c("Extr", "Agr", "Cons", "Emot", "Open")

# Create an empty list to store the stepwise models
stepwise_models <- list()

# Iterate over each response variable and fit a stepwise model
for (response_var in response_vars) {
  # Create the formula for the current response variable
  formula_str <- paste(response_var, "~ gender + mean.pitch + mean.conf.pitch + mean.spec.entropy + 
  mean.val.apeak + mean.loc.apeak + mean.num.apeak + mean.num.apeak + mean.energy + mean.d.energy + 
  anger + anticipation + disgust + fear + joy + negative + positive + sadness + surprise + trust + 
  sentences + long_words")
  lm_formula <- as.formula(formula_str)
  
  # Fit the linear model
  lm_model <- lm(lm_formula, data = data)
  
  # Perform stepwise regression
  stepwise_model <- step(lm_model, direction = "both")
  
  # Store the stepwise model in the list
  stepwise_models[[response_var]] <- stepwise_model
}

# Access and view the summaries of the stepwise models
for (response_var in response_vars) {
  cat("Summary for response variable:", response_var, "\n")
  print(summary(stepwise_models[[response_var]]))
  cat("\n")
}

# best model based on smallest AIC
mod_05 <- lm(cbind(Extr, Agr, Cons, Emot, Open) ~ mean.loc.apeak + mean.num.apeak + anticipation + joy + 
    positive + sadness + trust, data = data)

# RMSE for the training dataset
(RMSE_05 <- sqrt(mean(mod_05$residuals^2)))

# --- Notebook cell 45 ---
# building a model only including audio and visual features
mod_6 <- lm(cbind(Extr, Agr, Cons, Emot, Open) ~ mean.pitch + mean.conf.pitch + mean.spec.entropy + mean.val.apeak + mean.loc.apeak + mean.num.apeak + mean.num.apeak + mean.energy + mean.d.energy, data = data)

# print model summary
summary(mod_6)

# RMSE for the training dataset
(RMSE_06 <- sqrt(mean(mod_6$residuals^2)))

# --- Notebook cell 47 ---
# building a model only including text features
mod_07 <- lm(cbind(Extr, Agr, Cons, Emot, Open) ~ anger + anticipation + disgust + fear + joy + negative + positive + sadness + surprise + trust + sentences + long_words, data = data)

# print model summary
summary(mod_07)

# RMSE for the training dataset
(RMSE_07 <- sqrt(mean(mod_07$residuals^2)))

# --- Notebook cell 49 ---
# combine RMSEs into one vector:
all_rmse <- c(RMSE_01, RMSE_02, RMSE_03, RMSE_04, RMSE_05, RMSE_06, RMSE_07)

# Names of the RMSE values 
names <- c("MOD_01", "MOD_02", "MOD_03", "MOD_04", "MOD_05", "MOD_06", "MOD_07")

# Create a barplot with names on the X-axis and values on the Y-axis
barplot(all_rmse, names.arg = names, main = "RMSE Values", xlab = "RMSE Names", ylab = "RMSE Values", col = "grey")



# --- Notebook cell 51 ---
# Creating a subset for test data
test_data = data %>% 
    filter(is.na(Extr))

# counting rows
nrow(test_data)

# --- Notebook cell 53 ---
# Prediction for test data
pred_mod_all = predict(mod_07, new = test_data)

# Compute output data frame
test_data_pred = test_data %>% 
    mutate(
        Extr = pred_mod_all[,'Extr'], 
        Agr  = pred_mod_all[,'Agr' ],
        Cons = pred_mod_all[,'Cons'],
        Emot = pred_mod_all[,'Emot'],
        Open = pred_mod_all[,'Open']
    ) %>%
    select(vlogId, Extr:Open)

# preview of data
head(test_data_pred)

# --- Notebook cell 55 ---
# Converting our data to long format
test_data_pred_long <- test_data_pred %>% 
    pivot_longer(c(Extr, Agr, Cons, Emot, Open), names_to='pers_axis')

# Obtain the right format for Kaggle
test_data_pred_final <- test_data_pred_long %>%
    unite(Id, vlogId, pers_axis) %>%
    rename(Expected = value)

# Check if we succeeded
head(test_data_pred_final)

# --- Notebook cell 56 ---
# Write to csv
write_csv(test_data_pred_final, file = file.path("results", "predictions_07.csv"))

# Check if the file was written successfully.
dir()
