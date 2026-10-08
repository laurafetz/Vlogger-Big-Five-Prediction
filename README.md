# R Project 5 — Predicting Big Five Personality from YouTube Vlogs

**Natural language processing | Multivariate regression | Multimodal features | R**

## Overview
Can Big Five personality impressions be predicted from the language and audiovisual characteristics of YouTube vloggers? This 2023 Kaggle competition project uses the **YouTube Personality Dataset**, described in the original notebook as containing **404 vloggers**, to compare predictive models built from transcripts, speech-related measures, and gender. The five prediction targets are extraversion (`Extr`), agreeableness (`Agr`), conscientiousness (`Cons`), emotional stability (`Emot`), and openness (`Open`).

## Research question
**How well do transcript-derived lexical/emotion features and audiovisual features predict observers’ Big Five personality impressions? Which feature set provides the strongest predictive performance in this analysis?**

## Data
The included downloaded Kaggle data comprise:
- Transcript `.txt` files, keyed by `vlogId`.
- `YouTube-Personality-audiovisual_features.csv`, including pitch, energy, and related acoustic or visual descriptors.
- `YouTube-Personality-Personality_impression_scores_train.csv`, with available training labels.
- `YouTube-Personality-gender.csv`.

The notebook describes **80 vloggers with withheld personality scores** used for competition predictions. The original source dataset README is preserved under `data/`. The traits are **personality impressions/ratings**, not clinical assessments or directly observed stable personality.

## Analysis workflow
1. **Prepare data:** import the transcript, gender, personality-score, and audiovisual files; join on `vlogId`.
2. **Extract text features:** tokenize transcripts and visualize common words; use the NRC emotion lexicon to count emotion and sentiment terms; calculate sentence counts and counts of words of at least 11 characters.
3. **Fit predictive models:** compare multivariate linear regression specifications, including additive, interaction, feature-reduced, stepwise/AIC-informed, audiovisual-only, and text-only models.
4. **Evaluate:** calculate pooled training residual RMSE for each model and compare model complexity.
5. **Generate predictions:** use the selected text-only specification to predict held-out scores and format a Kaggle submission as `Id,Expected`.

## Main findings from the original notebook

| Model / finding | Reported RMSE | Evaluation source |
|---|---:|---|
| Initial additive model | 0.742 | Training |
| Revised additive model | 0.754 | Training |
| Interaction-rich model | 0.651 | Training |
| Interaction-rich model | 0.845 | Kaggle test submission, as described in notebook |
| Audiovisual-only model | 0.805 | Training |
| Text-only model (selected) | 0.776 | Training |

The complex interaction model achieved a lower training error but performed worse on the submitted test evaluation, consistent with overfitting. The project selected the text-only model (`mod_07`) for its final submission. **These are results reported in the supplied notebook, not newly verified benchmark scores.** The reported RMSE combines residuals across all five outcomes; interpretation should account for each trait's scale. The notebook does not document a comprehensive cross-validation study or a verified final test RMSE for the selected model.

## Repository structure

```text
R-Project-5-Vlogger-Big-Five-Prediction/
├── README.md
├── .gitignore
├── analysis/
│   └── vlogger_big_five.R
├── notebooks/
│   └── original_kaggle_notebook.ipynb
├── data/
│   └── bda-2023-profiling-personality/
│       └── youtube-personality/
│           ├── README.txt
│           ├── YouTube-Personality-audiovisual_features.csv
│           ├── YouTube-Personality-gender.csv
│           ├── YouTube-Personality-Personality_impression_scores_train.csv
│           └── transcripts/
└── results/
    └── .gitkeep
```

## Running the analysis

Requires R and the following packages: `tidyverse`, `tidytext`, `textdata`, `wordcloud`, and `caret`. Install these packages, then from the **repository root** run:

```r
install.packages(c("tidyverse", "tidytext", "textdata", "wordcloud", "caret"))
source("analysis/vlogger_big_five.R")
```

Or use `Rscript analysis/vlogger_big_five.R` in a terminal launched from the project root. The NRC lexicon may require a first-run download/acceptance of its use terms. Generated submission predictions are written to `results/predictions_07.csv`.

**Reproducibility caveat:** The standalone R script is an adapted extraction of the original Kaggle notebook, with explicit local data paths and a few compatibility fixes. It has **not been executed and validated end-to-end** in this delivery. Some source-notebook modelling decisions (including stepwise selection and training-only model comparison) are retained for transparency rather than presented as current best-practice validation. Consult the original notebook for the full narrative and model specifications.

## Skills demonstrated
- Data ingestion, joining, and feature engineering in **R**.
- **NLP / tidytext**, lexical sentiment and emotion features, tokenization, and text visualization.
- **Multivariate linear modelling**, interactions, feature selection, and AIC-guided exploration.
- **Predictive model assessment**, RMSE comparison, and reasoning about overfitting.
- Preparing and exporting competition predictions.

## Credits and provenance
This was a **collaborative 2023 competition project**, not a solo project. The original notebook attributes work as follows: **Laura** (data loading, test data, acknowledgments); **Roman and Laura** (features); **Bram and Laura** (predictive models and text/design/visualizations).

The notebook credits the transcript source to Biel, J.-I., Tsiminaki, V., Dines, J., & Gatica-Perez, D. (2013), *Hi YouTube!: Personality Impressions and Verbal Content in Social Video*, ACM International Conference on Multimodal Interaction. See the original notebook and source README for additional references and dataset details.

**Data publication:** These data were included in the user's Kaggle download. Before making the repository public, check the dataset’s redistribution/license terms; if they prohibit redistribution, omit `data/` from GitHub and instead provide instructions to download it from its original source.

## Author
**Laura Maria Fetz**, with original project contributions by **Roman** and **Bram** (see Credits).
