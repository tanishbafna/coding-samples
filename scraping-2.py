import os
import re
import json
import requests
import pandas as pd
from tqdm import tqdm
from bs4 import BeautifulSoup
from urllib.parse import quote
from multiprocessing import Pool

#----------

pattern = r"javascript:SHGList\('(\d+)','(.*?)','(.*?)'\)"

def scrape(row):

    stateName = row['State']
    districtName = row['District']
    blockName = row['Block']
    gramName = row['Grampanchayat']

    if os.path.exists('data/villageLevel/' + f'{stateName}_{districtName}_{blockName}_{gramName.replace("_","")}.csv'.replace('/','')):
        return {}

    try:
        r = requests.post(row['URL'])
        villageLevel = pd.read_html(r.content)[0]

        villageLevel.columns = ['Sr No.', 'Village', 'New', 'Revived', 'PreNRLM', 'Total', 'Members']
        villageLevel.drop(columns=['Sr No.'], inplace=True)

        villageLevel.dropna(how='all', inplace=True)
        villageLevel = villageLevel[~villageLevel.Village.str.contains('Total')]

        villageLevel['Village'] = villageLevel['Village'].apply(lambda y: ' '.join(y.title().strip().split()))
        villageLevel[['New', 'Revived', 'PreNRLM', 'Total', 'Members']] = villageLevel[['New', 'Revived', 'PreNRLM', 'Total', 'Members']].apply(pd.to_numeric, errors='coerce')

        villageLevel['State'] = stateName
        villageLevel['District'] = districtName
        villageLevel['Block'] = blockName
        villageLevel['Grampanchayat'] = gramName
        villageLevel = villageLevel[['State', 'District', 'Block', 'Grampanchayat', 'Village', 'New', 'Revived', 'PreNRLM', 'Total', 'Members']]

        #----------

        soup = BeautifulSoup(r.content, 'html.parser')
        hrefs = soup.find('table', {'id':'example'}).findAll('a')

        links = {}
        for href in hrefs:
            jsFunc = href['href']
            match = re.search(pattern, jsFunc)
            if match is None:
                match = re.search(pattern, str(href).replace('\n','').replace('\t','').replace('\r',''))

            encd = match.group(1)
            srtName = match.group(2)
            villageName = match.group(3)
            
            links[' '.join(villageName.title().strip().split())] = f'' # Redacted

        villageLevel['URL'] = villageLevel['Village'].apply(lambda x: links[x])
        villageLevel.to_csv('data/villageLevel/'+f'{stateName}_{districtName}_{blockName}_{gramName.replace("_","")}.csv'.replace('/',''), index=False)
            
    except Exception as e:
        return {f'{stateName}_{districtName}_{blockName}_{gramName}': str(e)}

    return {}

#----------

if __name__ == '__main__':

    stateLevel = pd.read_csv('data/stateLevel.csv')

    gramLevelRows = []

    for idx_state, row_state in stateLevel.iterrows():

        stateName = row_state['State']
        districtLevel = pd.read_csv(f'data/districtLevel/{stateName}.csv')

        for idx_district, row_district in districtLevel.iterrows():

            districtName = row_district['District']
            blockLevel = pd.read_csv(f'data/blockLevel/{stateName}_{districtName}.csv')

            for idx_block, row_block in blockLevel.iterrows():
                
                blockName = row_block['Block']

                try:
                    gramLevel = pd.read_csv(f'data/gramLevel/{stateName}_{districtName}_{blockName}.csv')
                except FileNotFoundError:
                    continue

                gramLevelRows += gramLevel.to_dict(orient='records')

    #----------

    errors = {}

    with Pool(processes=12) as pool, tqdm(total=len(gramLevelRows), desc=f'Scraping Grampanchayats') as pbar:
        for retDict in pool.imap_unordered(scrape, gramLevelRows):
            errors.update(retDict)
            pbar.update()

    with open('villageErrors.json', 'w') as f:
        json.dump(errors, f, indent=2)
