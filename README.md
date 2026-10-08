# Predicting Big Five impressions from YouTube vlogs

I studied whether transcripts and audiovisual features predict observers' Big Five personality impressions. The coursework data contain 324 labelled vloggers and 80 with withheld scores. I compared predefined feature sets with ridge regression, using five-fold cross-validation repeated five times and a fixed penalty of 10. The text model had a pooled RMSE of 0.827 across the five traits, compared with 0.834 for the training-fold mean baseline.

## Results

| Specification | Pooled CV RMSE |
| --- | ---: |
| Simple text features + ridge | 0.827 |
| Text + audiovisual features + ridge | 0.830 |
| Training-fold mean baseline | 0.834 |
| Audiovisual features + ridge | 0.836 |
| Combined features with quadratic terms + ridge | 1.507 |

I ran this comparison on 8 October 2026. The table comes from [cv_comparison.csv](results/cv_comparison.csv). I report each trait separately in [cv_by_trait.csv](results/cv_by_trait.csv).

![Repeated cross-validation RMSE](results/cv_comparison.png)

I assign each vlogger to one fold per repeat. I fit scaling and constant-feature removal within training folds. The text features are word count, sentence count, count of words with at least eleven letters, and type-token ratio. I use the supplied `mean.*` audiovisual features.

This is a new comparison with simpler features. My original group notebook used NRC emotion counts and stepwise selection. It reported training RMSE of 0.651 for an interaction model and a competition score of 0.845. Those scores come from a different workflow and are not the CV estimates above.

<details>
<summary>Code and files</summary>

The current analysis requires base R only and a local copy of the dataset obtained with permission.

```bash
Rscript analysis/vlogger_big_five.R /path/to/youtube-personality
```

The input directory must contain `YouTube-Personality-audiovisual_features.csv`, `YouTube-Personality-gender.csv`, `YouTube-Personality-Personality_impression_scores_train.csv`, and the transcript `.txt` files in `transcripts/`. The three CSV files are whitespace-delimited with headers. I do not distribute these files because I could not establish redistribution permission. The [Idiap source page](https://www.idiap.ch/dataset/youtube-personality) has retired its download.

The script saves aggregate CV results, a figure, and the R session. It also creates local predictions and fold assignments that are excluded from Git. I removed cached outputs from the original notebook to keep transcript excerpts out of the repository.

```text
Vlogger-Big-Five-Prediction/
├── .gitattributes
├── .gitignore
├── README.md
├── analysis/
│   └── vlogger_big_five.R
├── notebooks/
│   └── original_kaggle_notebook.ipynb
└── results/
    ├── cv_by_trait.csv
    ├── cv_comparison.csv
    ├── cv_comparison.png
    ├── cv_fold_metrics.csv
    ├── input_checksums.json
    ├── run_summary.txt
    └── session_info.txt
```

</details>

## Limitations

The text model's improvement over the mean baseline is small, and I have no independent test score for this comparison. The fixed ridge penalty may not suit each feature set. Observer impressions do not measure clinical personality traits.

## Credits

Project authors: **Laura Maria Fetz**, **Roman Esseveld**, and **Bram le Fèbre**. I loaded the data and prepared the test predictions. Roman and I worked on features; Bram and I worked on models, text, and figures.

The dataset and transcripts are credited to Biel and colleagues: [The YouTube Lens](https://doi.org/10.1109/TMM.2012.2225032) and [Hi YouTube!](https://doi.org/10.1145/2522848.2522894).
