# Repeated vlogger-level cross-validation with predefined feature sets.
# Rscript analysis/vlogger_big_five.R [path/to/authorized/youtube-personality]
# Uses base R only. All learned preprocessing is fitted within training folds.
args <- commandArgs(trailingOnly = TRUE)
data_dir <- if (length(args)) args[1] else file.path("data", "bda-2023-profiling-personality", "youtube-personality")
required <- file.path(data_dir, c("YouTube-Personality-audiovisual_features.csv", "YouTube-Personality-gender.csv", "YouTube-Personality-Personality_impression_scores_train.csv"))
if (!all(file.exists(required)) || !dir.exists(file.path(data_dir, "transcripts"))) {
  stop("Supply an authorized local dataset directory; see DATA_SOURCES.md. Data are not redistributed.")
}
dir.create("results", showWarnings = FALSE)
set.seed(20261008)
audio <- read.table(required[1], header = TRUE)
gender <- read.table(required[2], header = TRUE)
scores <- read.table(required[3], header = TRUE)
stopifnot(!anyDuplicated(audio$vlogId), !anyDuplicated(gender$vlogId), !anyDuplicated(scores$vlogId))
files <- sort(list.files(file.path(data_dir, "transcripts"), pattern = "\\.txt$", full.names = TRUE))
text_features <- t(vapply(files, function(file) {
  text <- paste(readLines(file, warn = FALSE, encoding = "UTF-8"), collapse = " ")
  words <- regmatches(tolower(text), gregexpr("[[:alpha:]]+", tolower(text)))[[1]]
  sentences <- sum(nzchar(trimws(unlist(strsplit(text, "[.!?]+")))))
  c(word_count = length(words), sentence_count = sentences,
    long_word_count = sum(nchar(words) >= 11),
    type_token_ratio = if (length(words)) length(unique(words))/length(words) else 0)
}, numeric(4)))
text_features <- data.frame(vlogId = sub("\\.txt$", "", basename(files)), text_features)
stopifnot(!anyDuplicated(text_features$vlogId))
data <- Reduce(function(x,y) merge(x,y,by="vlogId",all=TRUE), list(audio,gender,scores,text_features))
data <- data[order(data$vlogId),]
traits <- c("Extr", "Agr", "Cons", "Emot", "Open")
text_cols <- c("word_count", "sentence_count", "long_word_count", "type_token_ratio")
audio_cols <- grep("^mean\\.",names(audio),value=TRUE)
feature_sets <- list(mean_baseline=character(), text_ridge=text_cols,
                     audiovisual_ridge=audio_cols, combined_ridge=c(text_cols,audio_cols),
                     interaction_ridge=c(text_cols,audio_cols))
has_scores <- rowSums(!is.na(data[,traits])) == length(traits)
partial <- rowSums(!is.na(data[,traits])) %in% 1:4
if (any(partial)) stop("Partially labelled rows need explicit missing-data handling")
train <- data[has_scores,]; test <- data[!has_scores,]
if (nrow(train)<10 || !all(scores$vlogId %in% train$vlogId)) stop("Training labels lost during joins")
if (anyNA(data[,c(text_cols,audio_cols)])) stop("Missing features: inspect input joins")
y <- as.matrix(train[,traits])
k <- 5; repeats <- 5; lambda <- 10

fit_predict <- function(training, testing, cols, interaction=FALSE) {
  target <- as.matrix(training[,traits])
  if (!length(cols)) return(matrix(colMeans(target),nrow(testing),length(traits),byrow=TRUE))
  x <- as.matrix(training[,cols]); new_x <- as.matrix(testing[,cols])
  centers <- colMeans(x); scales <- apply(x,2,sd)
  keep <- is.finite(scales) & scales > 1e-10
  x <- sweep(sweep(x[,keep,drop=FALSE],2,centers[keep]),2,scales[keep],"/")
  new_x <- sweep(sweep(new_x[,keep,drop=FALSE],2,centers[keep]),2,scales[keep],"/")
  if (interaction && ncol(x)>0) {
    pairs <- which(upper.tri(matrix(0,ncol(x),ncol(x)),diag=TRUE),arr.ind=TRUE)
    expand <- function(z) do.call(cbind,lapply(seq_len(nrow(pairs)),function(i) z[,pairs[i,1]]*z[,pairs[i,2]]))
    x <- cbind(x,expand(x)); new_x <- cbind(new_x,expand(new_x))
  }
  x <- cbind(intercept=1,x); new_x <- cbind(intercept=1,new_x)
  penalty <- diag(c(0,rep(lambda,ncol(x)-1)))
  coefficients <- solve(crossprod(x)+penalty,crossprod(x,target))
  new_x %*% coefficients
}

records <- list(); folds <- list(); counter <- 1
for (repeat_id in seq_len(repeats)) {
  fold <- sample(rep(seq_len(k),length.out=nrow(train)))
  folds[[repeat_id]] <- data.frame(vlogId=train$vlogId,repeat_id=repeat_id,fold=fold)
  for (fold_id in seq_len(k)) {
    fit_rows <- fold!=fold_id; holdout <- fold==fold_id
    for (model in names(feature_sets)) {
      prediction <- fit_predict(train[fit_rows,],train[holdout,],feature_sets[[model]],model=="interaction_ridge")
      errors <- prediction-y[holdout,,drop=FALSE]
      records[[counter]] <- data.frame(model=model,repeat_id=repeat_id,fold=fold_id,
                                      trait=traits,n_vloggers=sum(holdout),
                                      squared_error=colSums(errors^2))
      counter <- counter+1
    }
  }
}
details <- do.call(rbind,records)
by_trait <- aggregate(cbind(squared_error,n_vloggers)~model+trait,details,sum)
by_trait$rmse <- sqrt(by_trait$squared_error/by_trait$n_vloggers)
pooled <- aggregate(cbind(squared_error,n_vloggers)~model,details,sum)
pooled$cv_rmse <- sqrt(pooled$squared_error/pooled$n_vloggers)
pooled <- pooled[order(pooled$cv_rmse),]
pooled$training_vloggers <- nrow(train); pooled$folds <- k; pooled$repeats <- repeats
write.csv(pooled,"results/cv_comparison.csv",row.names=FALSE)
write.csv(by_trait,"results/cv_by_trait.csv",row.names=FALSE)
write.csv(details,"results/cv_fold_metrics.csv",row.names=FALSE)
write.csv(do.call(rbind,folds),"results/local_cv_assignments.csv",row.names=FALSE)
selected <- pooled$model[1]
predictions <- fit_predict(train,test,feature_sets[[selected]],selected=="interaction_ridge")
submission <- data.frame(Id=as.vector(t(outer(test$vlogId,traits,paste,sep="_"))),Expected=as.vector(t(predictions)))
stopifnot(nrow(submission)==nrow(test)*length(traits), all(is.finite(submission$Expected)))
write.csv(submission,"results/local_predictions.csv",row.names=FALSE)
png("results/cv_comparison.png",width=1400,height=800,res=150)
par(mar=c(5,11,4,2))
barplot(rev(pooled$cv_rmse),names.arg=rev(pooled$model),horiz=TRUE,las=1,
        col="#347681",border=NA,xlab="Repeated 5-fold CV RMSE (five traits pooled)",
        main="Vlogger personality impressions: validation comparison")
dev.off()
capture.output(sessionInfo(),file="results/session_info.txt")
writeLines(c(paste("Training vloggers:",nrow(train)),paste("Unlabelled vloggers:",nrow(test)),
             paste("Selected specification:",selected),"Seed: 20261008", "Ridge lambda: 10", "5 folds x 5 repeats"),"results/run_summary.txt")
print(pooled[,c("model","cv_rmse","training_vloggers","folds","repeats")])
cat("Generated",nrow(submission),"submission rows from",nrow(test),"unlabelled vloggers.\n")
