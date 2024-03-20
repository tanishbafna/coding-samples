# Scraping Libraries
from urllib.parse import urlencode
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as ec

# Data Libraries
import pandas as pd

# Helper Libraries
import json
import warnings
import datetime
import traceback
from tqdm import tqdm
from multiprocessing import Pool

warnings.filterwarnings('ignore', category=DeprecationWarning) 

#================================

# Configuration
config = json.load(open('config.json'))

sdate = datetime.datetime.strptime(config['q']['sdate'], '%d-%m-%Y').date()
edate = datetime.datetime.strptime(config['q']['edate'], '%d-%m-%Y').date()

input_pools = config['selenium_pools']
chromedriverLocation = config['chromedriverLocation']

processingDirectory = config['q']['directories']['processing']
rawDirectory = config['q']['directories']['raw']

#================================

sdate_str = sdate.strftime('%d-%b-%Y')
edate_str = edate.strftime('%d-%b-%Y')

locations = json.load(open(f'setup/base_data/locations_states.json'))
stateReport = json.load(open(f'{processingDirectory}/stateReport.json'))
stateMapping = {locations[k]['name']:k for k in locations.keys()}

#================================

options_chrome = Options()
options_chrome.headless = True
options_chrome.add_argument('--incognito')
options_chrome.add_argument('--no-sandbox')
options_chrome.add_argument('--disable-gpu')
options_chrome.add_argument('--disable-infobars')
options_chrome.add_argument('--disable-dev-shm-usage')

URL = '' # Redacted

#================================

def scrape(splitTup):

    tqdmPosition = splitTup[0]
    commodityArr = splitTup[1]

    browser = webdriver.Chrome(chromedriverLocation, options=options_chrome)
    params = {'Tx_Commodity':None, 'Tx_State':None, 'Tx_District':0, 'Tx_Market':0, 'DateFrom':sdate_str, 'DateTo':edate_str,
                'Fr_Date':sdate_str, 'To_Date':edate_str, 'Tx_Trend':1, 'Tx_CommodityHead':None, 'Tx_StateHead':None, 
                'Tx_DistrictHead':'--Select--', 'Tx_MarketHead':'--Select--'}
    
    errors = {}

    #===============

    for ccode in tqdm(commodityArr, position=tqdmPosition+1, leave=False, desc=f'Commodity Pool {tqdmPosition+1}'):
        
        try:

            info = stateReport[ccode]

            params['Tx_Commodity'] = ccode
            params['Tx_CommodityHead'] = info['name']

            data = []
            stateCheck = [i for i in info["states"]]
            commodityErrors = {"name":info['name'], "errors":{}, "states":stateCheck}
            
            for state in info["states"]:

                scode = stateMapping[state]
                params['Tx_State'] = scode
                params['Tx_StateHead'] = state
                customURL = URL + urlencode(params)

                stateErrorLog = []
                tries = 2

                while tries != 0:
                    
                    stateData = []
                    browser.get(customURL)

                    #===============

                    try:
                        WebDriverWait(browser, 60).until(ec.visibility_of_element_located((By.XPATH, '//*[@id="middlepnl"]/h1')))
                        if ' error' in browser.find_element(By.XPATH, '//*[@id="middlepnl"]/h1').text:
                            raise TimeoutError

                    except: 
                        
                        tries -= 1
                        stateErrorLog.append('Server Error')

                        if tries == 0:
                            commodityErrors["errors"][state] = ' >>> '.join(stateErrorLog)

                        browser.close()
                        browser.quit()

                        browser = webdriver.Chrome(chromedriverLocation, options=options_chrome)
                        continue
                
                    #===============

                    # Click State Level Plus Sign
                    try:
                        browser.execute_script("arguments[0].click();", browser.find_element(By.XPATH, '//*[@id="cphBody_GridArrivalData_imgOrdersShow_0"]'))
                    except:

                        tries -= 1
                        stateErrorLog.append('State Button Press Error')

                        if tries == 0:
                            commodityErrors["errors"][state] = ' >>> '.join(stateErrorLog)

                        continue
                
                    #===============

                    # Capture District Table
                    dTableHtml = '<table>' + browser.find_element(By.ID, 'cphBody_GridArrivalData_gvOrders_0').get_attribute('innerHTML') + '</table>'
                    dDF = pd.read_html(dTableHtml, header=0)[0]
                    districts = dDF['District'].to_list()

                    forLoopErr = ''

                    for dIDX, district in enumerate(districts):
                
                        # Click District Level Plus Sign
                        try:
                            browser.execute_script("arguments[0].click();", browser.find_element(By.XPATH, f'//*[@id="cphBody_GridArrivalData_gvOrders_0_imgProductsShow_{dIDX}"]'))
                        except:
                            forLoopErr = 'District Button Press Error'
                            break
                        
                        #===============

                        # Wait for Market Level Table
                        try:
                            WebDriverWait(browser, 60).until(ec.visibility_of_element_located((By.XPATH, f'//*[@id="cphBody_GridArrivalData_gvOrders_0_gvProducts_{dIDX}"]')))
                        except:
                            forLoopErr = 'Market Table Error'
                            break
                        
                        mTable = browser.find_element(By.ID, f"") # Redacted
                        dcode = mTable.get_attribute('title').split(',')[1]
                        mTableHtml = '<table>' + mTable.get_attribute('innerHTML') + '</table>'
                        mDF = pd.read_html(mTableHtml, header=0)[0]

                        # Convert to DataFrame
                        mDF.insert(0, 'State', state)
                        mDF.insert(1, 'State Code', scode)
                        mDF.insert(2, 'District', district)
                        mDF.insert(3, 'District Code', dcode)
                        # 4 -> market
                        mDF.insert(5, 'Commodity', info['name'])
                        mDF.insert(6, 'Commodity Code', ccode)
                        # 7 -> arrival quantity

                        stateData.append(mDF)

                        #===============
                    
                    if forLoopErr != '':

                        tries -= 1
                        stateErrorLog.append(forLoopErr)

                        if tries == 0:
                            commodityErrors["errors"][state] = ' >>> '.join(stateErrorLog)
                        
                        continue
                    
                    #===============

                    data += stateData
                    commodityErrors["states"].remove(state)
                    tries = 0

            errors[ccode] = commodityErrors
            
        except:

            errors[ccode] = commodityErrors
            errors[ccode]["traceback"] = traceback.format_exc()

            browser.close()
            browser.quit()
            browser = webdriver.Chrome(chromedriverLocation, options=options_chrome)

        if len(data) > 0:
            df = pd.concat(data, ignore_index=True)
            df.insert(0, 'Start', sdate_str)
            df.insert(1, 'End', edate_str)
            df.rename(columns={'Arrivall':'Arrival'}, inplace=True)
            df.to_csv(f'{rawDirectory}/{ccode}.csv', index=False)

    browser.close()
    browser.quit()

    return errors

#================================

if __name__ == '__main__':

    commodityKeys = list(stateReport.keys())
    if len(commodityKeys) == 0:
        with open('q/2-report.log', 'w') as f:
            f.write('DONE')
        quit()

    commodityInput = [(i, commodityKeys[i::input_pools]) for i in range(input_pools)]
    allErrors = {}

    with Pool(processes=input_pools) as pool, tqdm(total=input_pools, position=0, leave=False, desc='Report Pools') as pbar:

        for returnValue in pool.imap_unordered(scrape, commodityInput):

            allErrors.update(returnValue)
            pbar.update()
    
    #===============

    popKeys = []
    for key, err in allErrors.items():
        if len(err["states"]) == 0:
            popKeys.append(key)
    
    for key in popKeys:
        allErrors.pop(key)
    
    #===============

    with open(f'q/2-reruns.json', 'w') as file:
        json.dump(allErrors, file, indent=2)
    
    with open('q/2-report.log', 'w') as f:
        f.write('DONE')
