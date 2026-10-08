# YouTube Personality Dataset

The coursework download contains transcripts, audiovisual features, binary gender labels, and observer-rated Big Five personality impressions for 404 vloggers. Training labels cover 324 vloggers; 80 labels are withheld.

The [original Idiap dataset page](https://www.idiap.ch/dataset/youtube-personality) currently states that the dataset is no longer available for download (checked 8 October 2026). The source README in the course download gives citations but does not grant an explicit redistribution licence. This repository therefore does not distribute the dataset or individual-level prediction files. No open redistribution permission is asserted.

If you already have an authorized copy of the course data, use its `youtube-personality` directory directly:

```bash
Rscript analysis/vlogger_big_five.R /path/to/youtube-personality
```

The directory must contain:

```text
youtube-personality/
├── YouTube-Personality-audiovisual_features.csv
├── YouTube-Personality-gender.csv
├── YouTube-Personality-Personality_impression_scores_train.csv
└── transcripts/*.txt
```

The three `.csv` files are whitespace-delimited text with header rows. Obtain access from the dataset rights holder or course provider under their current terms; the retired source page is not presented as an active download.

References:

- Biel, J.-I., & Gatica-Perez, D. (2013). *The YouTube Lens: Crowdsourced Personality Impressions and Audiovisual Analysis of Vlogs.* IEEE Transactions on Multimedia, 15(1), 41–55. [DOI](https://doi.org/10.1109/TMM.2012.2225032).
- Biel, J.-I., Tsiminaki, V., Dines, J., & Gatica-Perez, D. (2013). *Hi YouTube!: Personality Impressions and Verbal Content in Social Video.* ICMI, 119–126. [DOI](https://doi.org/10.1145/2522848.2522894).
