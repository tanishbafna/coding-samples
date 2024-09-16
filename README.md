# coding-samples
This collection offers a detailed showcase of my expertise in Python, Stata, and R, spanning tasks relating to data cleaning, analysis, web scraping, and machine learning. The scripts and notebooks compiled in this repository are drawn from various research and personal projects I've undertaken.

## Stata (Data Processing and Analysis)

### [wageTechRegression.do](Stata/wageTechRegression.do)

This script performs a series of econometric analyses to examine the relationship between real wages and emerging technologies using regression models with various interacting fixed effects specifications and controls. The script also generates LaTeX tables for the regression results.

**Highlights: Interacting Fixed Effect, LaTeX Output**

### [surveyAnalysis.do](Stata/surveyAnalysis.do)

This script performs a series of econometric analyses of income, employment, and social characteristics using the CMIE (aspirations, income, and expenses survey). The analysis focuses on variables such as education, caste, religion, labor force participation, and time use, employing T-tests, summary statistics, regression models with survey weights to explore the relationships among these factors. The script also generates LaTeX tables for all the results.

**Highlights: Survey Data Analysis**

### [descriptiveStats.do](Stata/descriptiveStats.do)

This script creates generate descriptive statistics and matrices for different types of variables, saving them in a LaTeX format suitable for publication.

**Highlights: Summary Statistics, LaTeX Output**

### [panelCleaning.do](Stata/panelCleaning.do)

This script cleans and merges four survey datasets: People of India, Aspirational India, Income and Expenses (CMIE). It imports the data, drops unwanted observations, declares missing values, creates new variables, and puts everything together in a panel format for further analysis.

**Highlights: Data Cleaning, Panel Data**

## Python (Data Processing and Analysis)

### [academicPapersProcessing.py](Python/academicPapersProcessing.py)

This script processes academic papers, extracting and cleaning abstracts, detecting the language of the papers, and filtering them based on year, document type, and language. It is designed to handle large volumes of text data efficiently using multiprocessing.

- Utilizes the fasttext model for language detection to ensure the content is in the desired language.
- Processes text to reconstruct abstracts from an inverted index format, handling special characters and JSON structure to restore the original abstract text.
- Filters papers based on the specified year and excludes certain document types.
- Uses regular expressions and unicode normalization to clean and prepare text data for further analysis.
- Employs multiprocessing to process files concurrently, significantly speeding up the data processing pipeline.

**Highlights: fasttext, RegEx, pandas, multiprocessing, JSON parsing, command-line arguments**

### [textDataCleaning.py](Python/textDataCleaning.py)

This script is used to clean scraped textual data and standardize it for further analysis.

- Normalization of Unicode characters and removal of HTML tags to ensure text purity.
- Advanced regex operations to eliminate unwanted stopwords, abbreviations, and specific terms related to organizations and locations.
- Substitution of words and phrases based on predefined mappings, which help standardize variations of text expressions.
- Batch processing of data chunks in parallel to enhance performance.

**Highlights: pandas, RegEx, NLTK, Multiprocessing**

### [dataMerging.py](Python/dataMerging.py)

This script performs comprehensive preprocessing and merging of various demographic, economic, and health-related datasets to facilitate data analysis on factors influencing drug overdose rates in the United States.

- Reads and preprocesses demographic data (age, sex, race), political data (House of Representatives, voting patterns), economic data (income levels, poverty rates, unemployment rates), health data (opioid dispensing rates overdose death rates), and law enforcement data.
- Standardizes and formats FIPS codes across datasets to ensure consistent identifiers for geographic locations.
- Merges multiple datasets on county-level FIPS codes to create a unified database that includes a wide range of variables potentially relevant for modeling and analysis.

**Highlights: pandas, data preprocessing, data merging, data cleaning**

## Python (Machine Learning)

### [textEmbeddings.py](Python/textEmbeddings.py)

This script preprocesses textual data, tokenizes it, and computes embeddings using transformer models with adapters It is designed to handle various configurations of input types and supports batch and GPU processing for efficiency.

- Filters and processes datasets based on specified textual components.
- Utilizes GPU for accelerated computation if available.
- Supports splitting large datasets into manageable segments for efficient processing.
- Computes embeddings using pretrained transformer models and pickles them for further use.
- Configurable through command-line arguments for flexibility in different research scenarios.

**Highlights: Hugging Face, PyTorch, GPU processing, command-line arguments**

### [fewShotNER.py](Python/fewShotNER.py)

This script leverages a transformer-based model for few-shot named entity recognition (NER) on text data. It configures the model for efficient computation using quantization, processes textual data with a custom prompt structure, and generates entity outputs.

- Implements text generation pipelines with custom prompt templates for NER tasks.
- Employs GPU acceleration and memory management to enhance performance.
- Includes error handling and logging to monitor and debug the process.
- Utilizes environmental variables and command-line arguments for flexible configurations.

**Highlights: Hugging Face, text generation, GPU acceleration, error handling**

### [Can Special Token Augmentation Break the Reversal Curse?](https://github.com/JaiDoshi/reversing-reversal-curse/tree/main)

**Highlights: Fine-tuning LLMs and evaluating results of a text generation task.**

### [Going Bayesian: A Multi-class Classification Comparison of Logistic Regression, ANNs and Bayesian Neural Networks](https://github.com/tanishbafna/Going-Bayesian)

This project explores the performance of different machine learning models on a multi-class classification problem. The analysis compares the performance of traditional logistic regression, artificial neural networks (ANNs), and Bayesian neural networks (BNNs) on the MNIST dataset. The project aims to evaluate the classification accuracy and uncertainty estimation capabilities of these models.

**Highlights: Bayesian Neural Networks, Multi-class Classification**

## Python (Web Scraping)

### [commodityArrivalScraping.py](Python/commodityArrivalScraping.py)

The script is intended to automate the web scraping of commodity arrival data from a dynamic web interface ([Agmarknet](https://agmarknet.gov.in)). It uses a combination of Selenium and multiprocessing to efficiently extract data from the web pages, processes it into structured formats, and saves it in CSV files.

**Highlights: Selenium, Multiprocessing**

### [SHGDataScraping.py](Python/SHGDataScraping.py)

This script is designed to scrape and process village-level data on Self-Help Groups from the [National Rural Livelihood Mission](https://nrlm.gov.in/shgOuterReports.do?methodName=showShgreport) website and save it into structured CSV files. The process involves reading hierarchical web pages representing different administrative levels (state, district, block, and grampanchayat) to extract group level characteristics.

**Highlights: Requests, BeautifulSoup4**

## Python (Web Development)

### [Auction Voting](https://github.com/tanishbafna/auction-voting)

An interactive web app designed to facilitate group decision-making through an auction-style voting mechanism. This platform allows participants to create private voting rooms, suggest options, and distribute points to determine the most popular choices among a group.

**Highlights: Flask, SQLAlchemy, Heroku, CI/CD, JavaScript, HTML/CSS**

### [E-Travel Website](https://github.com/adiwajshing/ap-travel-website)

**Highlights: Fuzzy Search, Recommendation System, Autogenerated Emails, Cache-Control**

## R (Machine Learning)

### [The Merchants are in Business: A Comedy](https://github.com/tanishbafna/Digital-Humanities-NER)

A digital humanities project using sentiment analysis and Named-Entity Recognition in R to analyze trade themes in restoration literature. We analyze character portrayal by occupation in plays from the Stuart monarchy era, focusing on the depiction of the merchant class. It explores how merchants, particularly those from trade hubs outside England, are represented and compares early and late Restoration period plays to track shifts in their societal perception.
