# Data Libraries
import numpy as np
import pandas as pd

# Helper Libraries
import os
from tqdm import tqdm
from bs4 import BeautifulSoup
from multiprocessing import Pool

# Text Libraries
import re
import nltk
import unicodedata
from nltk.corpus import stopwords

# Configurations
nltk.data.path.append("nltk_data")

import warnings
warnings.filterwarnings("ignore")
pd.options.mode.chained_assignment = None

#---------------------------

#Cleaning Functions

def multipleReplace(dict, text):
    replacePattern = re.compile('\\b(%s)\\b' % '|'.join(map(re.escape, dict.keys())), re.IGNORECASE)
    return replacePattern.sub(lambda mo: dict[mo.string[mo.start():mo.end()].lower()], text) 

#--------

#Removing Certain Words

#Removing org abbrevations
removeOrgAbbs = re.compile(r'\b(' + r'|'.join(['pvt', 'ltd', 'inc', 'lc', 'llc', 'pc', 'corp', 'co']) + r')\b\s*', re.IGNORECASE)

#Removing stopwords
stopWords = stopwords.words('english')
stopWordsPattern = re.compile(r'\b(' + r'|'.join(stopWords) + r')\b\s*', re.IGNORECASE)

#--------

#Proper Nouns

def locationCleaning(s):
    
    # Removing extra spaces
    s = s.strip()
    s = re.sub('\s+', ' ', s)

    #Keep only certain characters
    s = re.sub(r'[^A-Za-z\-]+', ' ', s)

    # Removing extra spaces
    s = s.strip()
    s = re.sub('\s+', ' ', s)

    if s == '':
        return np.NaN

    return s

#Locations
indiaLocations = pd.read_csv('raw_data/indiaLocations.csv')
indiaLocations['location_cleaned'] = indiaLocations['location'].apply(locationCleaning)
indiaLocations.dropna(subset=['location_cleaned'], inplace=True)
indiaLocations = list(indiaLocations['location_cleaned'].unique())

surveyLocations_set = set(indiaLocations)
removeLocationsPattern = re.compile(r'\b(' + r'|'.join(surveyLocations_set) + r')\b\s*', re.IGNORECASE)

#--------

#Abbrevations#

#Abbrevations
word_substitutes = pd.read_csv('raw_data/word_substitutes.csv', encoding='latin1', header=None)
phrase_substitutes = pd.read_csv('raw_data/phrase_substitutes.csv', encoding='latin1', header=None)

#Making dicts with key -> value as substitute_this -> by_this_word
word_substitutesArr = [[y for y in x if pd.notna(y)] for x in word_substitutes.values.tolist()]
word_substitutesDict = {k:l[0] for l in word_substitutesArr for k in l[1:]}

phrase_substitutesArr = [[y for y in x if pd.notna(y)] for x in phrase_substitutes.values.tolist()]
phrase_substitutesDict = {k:l[0] for l in phrase_substitutesArr for k in l[1:]}

#--------

#Main Cleaning Functions#

def nameCleaning(s):

    #Removing links or unicodes
    try:
        s = unicodedata.normalize("NFKD", s)
        s = BeautifulSoup(s, 'lxml').get_text()
        s = s.decode('utf-8-sig').replace(u'\ufffd', '?')
    except:
        pass
    
    if s in ['', np.NaN, None]:
        return ''
    
    # Removing extra spaces
    s = s.strip()
    s = re.sub('\s+', ' ', s)

    #Keep only certain characters
    s = re.sub(r'!+', '. ', s)
    s = re.sub(r'\?+', '. ', s)
    s = re.sub(r'[^A-Za-z.,\'+&()\-/:;]+', ' ', s)
    s = re.sub(',', ', ', s)

    #Stopwords
    s = stopWordsPattern.sub(' ', s)

    # Removing extra spaces
    s = s.strip()
    s = re.sub('\s+', ' ', s)

    s = removeLocationsPattern.sub(' ', s)
    s = removeOrgAbbs.sub(' ', s)

    s = re.sub(r'(\.\s+\.|\.+)', '.', s)
    s = re.sub('\s+', ' ', s.strip())

    #Standardizing Abbrevations
    s = multipleReplace(phrase_substitutesDict, s)
    s = multipleReplace(word_substitutesDict, s)

    s = re.sub(r'(\.\s+\.|\.+)', '.', s)
    s = re.sub('\s+', ' ', s.strip())

    return s

def mainCleaning(df):

    df['name_clean'] = df['name'].apply(nameCleaning)
    df['desc_clean'] = df['desc'].apply(nameCleaning)
    
    df['name_clean'] = df['name_clean'].apply(lambda s: '' if s in [np.NaN, None] or s.lower() in ['other', 'not mentioned'] else s)
    df['desc_clean'] = df['desc_clean'].apply(lambda s: '' if s in [np.NaN, None] or s.lower() in ['other', 'not mentioned'] else s)

    df['nameDesc_clean'] = df[['name_clean', 'desc_clean']].agg('. '.join, axis=1)
    df['nameDesc_clean'] = df['nameDesc_clean'].apply(lambda s: re.sub('\s+', ' ', re.sub(r'(\.\s+\.|\.+)', '.', s).strip()))
    df['nameDesc_clean'] = df['nameDesc_clean'].apply(lambda s: '' if s.strip() == '.' else s)

    df.drop(columns=['name', 'desc', 'name_clean', 'desc_clean'], inplace=True)
    return df

#---------------------------

if __name__ == '__main__':

    for file in tqdm(sorted([x for x in os.listdir('raw_data/surveyData_chunks') if x.endswith('.dta')]), position=0, desc='Data Chunks'):

        num = int(file.replace('.dta', ''))

        # Load data
        raw = pd.read_stata(f'raw_data/surveyData_chunks/{file}', columns=['uniqueId', 'name', 'desc'])
        raw.sort_values(by=['uniqueId'], inplace=True, ignore_index=True)
        raw['desc'] = raw['desc'].astype(str)

        # Chunk data
        chunks = np.array_split(raw, 32)
        data = []

        with Pool(processes=32) as pool, tqdm(total=len(raw), position=num, desc=f'Cleaning Data [{num}]') as pbar:

            for clean_df in pool.imap_unordered(mainCleaning, chunks):
                data.append(clean_df)
                pbar.update(len(clean_df))
            
        df = pd.concat(data, ignore_index=True)
        df.sort_values(by=['uniqueId'], inplace=True, ignore_index=True)
        df.to_stata(f'nameData_chunks/names_clean_{num}.dta', version=118, write_index=False)
