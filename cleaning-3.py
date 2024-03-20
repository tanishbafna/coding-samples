import numpy as np
import pandas as pd
from tqdm import tqdm

# Enable progress_apply in pandas using tqdm for progress bars
tqdm.pandas()

#------------------

# Reading state and county FIPS codes
StateFIPS = pd.read_csv('StateFIPS.csv')
CountyFIPS = pd.read_csv('CountyFIPS.csv')

# Standardize FIPS codes to 5 characters by padding with zeros
CountyFIPS['FIPS'] = CountyFIPS['FIPS'].astype(str).str.pad(width=5, fillchar='0')

#------------------

# Reading drug overdose data and preprocessing
df = pd.read_csv("DrugOverdose.csv")

# Selecting relevant columns and standardizing FIPS code format
df = df[['FIPS', 'Model-based Death Rate']]
df['FIPS'] = df['FIPS'].astype(str).str.pad(width=5, fillchar='0')

# Renaming columns for clarity
df.rename(columns={'Model-based Death Rate':'DeathRate'}, inplace=True)

#------------------

# Reading demographic data related to age, sex, and race
ageSexRace = pd.read_csv("AgeSexRace.csv")

# Convert STATE and COUNTY codes to strings and pad with zeros
ageSexRace['STATE'] = ageSexRace['STATE'].astype(str).str.pad(width=2, fillchar='0')
ageSexRace['COUNTY'] = ageSexRace['COUNTY'].astype(str).str.pad(width=3, fillchar='0')

# Concatenate STATE and COUNTY codes to form a FIPS code
ageSexRace['FIPS'] = ageSexRace['STATE'] + ageSexRace['COUNTY']
ageSexRace.rename(columns={'TOT_POP':'TotalPopulation'}, inplace=True)

#------------------

# Extracting age-related data and categorizing age groups
age = ageSexRace[['FIPS', 'AGEGRP', 'TotalPopulation']].copy(deep=True)
ageCategories = {0: 0, 1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 2, 7: 3, 8: 3, 9: 3, 10: 3, 11: 1, 12: 1, 13: 1, 14: 1, 15: 1, 16: 1, 17: 1, 18: 1}
age['AgeCategory'] = age['AGEGRP'].apply(lambda x: ageCategories[x])
age = age[age['AgeCategory'].isin([0, 2, 3])]

# Aggregating population by age categories
age = age.groupby(['FIPS', 'AgeCategory']).sum().reset_index()
age['AgeCategory'] = age['AgeCategory'].apply(lambda x: {0: 'AllAges', 2:'15-29Ages', 3:'30-49Ages'}[x])

# Creating a pivot table for easier analysis
age = age.pivot_table(index=['FIPS'], columns=['AgeCategory'], values=['TotalPopulation'], aggfunc='first').reset_index()
age.columns = ['FIPS', '15-29Ages', '30-49Ages', 'AllAges']

# Handling specific counties by summing their populations
county02261_all = age[age['FIPS'] == '02063']['AllAges'].item() + age[age['FIPS'] == '02066']['AllAges'].item()
county02261_1529 = age[age['FIPS'] == '02063']['15-29Ages'].item() + age[age['FIPS'] == '02066']['15-29Ages'].item()
county02261_3049 = age[age['FIPS'] == '02063']['30-49Ages'].item() + age[age['FIPS'] == '02066']['30-49Ages'].item()

# Removing and adding the aggregated county data
age = age[~age['FIPS'].isin(['02063', '02066'])]
age = pd.concat([age, pd.DataFrame(data={'FIPS': '02261', 'AllAges': county02261_all, '15-29Ages': county02261_1529, '30-49Ages': county02261_3049}, index=[0])], ignore_index=True)

# Calculating percentages for age groups
age['Age15-29Pct'] = age['15-29Ages'] * 100 / age['AllAges']
age['Age30-49Pct'] = age['30-49Ages'] * 100 / age['AllAges']
age = age[['FIPS', 'Age15-29Pct', 'Age30-49Pct']]

#------------------

# Processing racial composition data
race = ageSexRace[ageSexRace['AGEGRP']==0][['FIPS', 'TotalPopulation', 'WA_MALE', 'WA_FEMALE']].copy(deep=True)

# Combining male and female white population counts
race['White'] = race['WA_MALE'] + race['WA_FEMALE']

# Handling specific county data for racial composition
county02261_top = race[race['FIPS'] == '02063']['TotalPopulation'].item() + race[race['FIPS'] == '02066']['TotalPopulation'].item()
county02261_white = race[race['FIPS'] == '02063']['White'].item() + race[race['FIPS'] == '02066']['White'].item()

# Removing and adding aggregated county data
race = race[~race['FIPS'].isin(['02063', '02066'])]
race = pd.concat([race, pd.DataFrame(data={'FIPS': '02261', 'TotalPopulation': county02261_top, 'White': county02261_white}, index=[0])], ignore_index=True)

# Calculating white population percentage
race['WhitePct'] = race['White'] * 100 / race['TotalPopulation']
race = race[['FIPS', 'TotalPopulation', 'WhitePct']]

#------------------

# Reading and processing education level data
education = pd.read_csv("Education.csv")
education['FIPS'] = education['GEO_ID'].apply(lambda x: x.split('US')[1])
education['remove'] = education['FIPS'].apply(lambda x: x[0:2] == '72')
education = education[education['remove'] == False]

# Selecting and renaming columns for clarity
education = education[['FIPS', '%Less than High School Graduate', '%High School Graduate', "%Some College or Associate's Degree", "%Bachelor's degree or higher"]]
education.rename(columns={'%Less than High School Graduate':'LessThanHighSchoolPct', '%High School Graduate':'HighSchoolPct', "%Some College or Associate's Degree":'AssociateDegreePct', "%Bachelor's degree or higher":'BachelorOrHigherPct'}, inplace=True)

# Converting percentages to a uniform format
for col in education.columns[1:]:
    education[col] = education[col] * 100

#------------------

# Reading and merging House of Representatives data with State FIPS codes
houseReps = pd.read_csv("HouseReps.csv")
houseReps = StateFIPS.merge(houseReps, on='State', how='right')

# Standardizing State FIPS code format
houseReps['StateFIPS'] = houseReps['FIPS'].astype(str).str.pad(width=2, fillchar='0')

# Selecting and renaming columns
houseReps = houseReps[['StateFIPS', 'Democatric', 'Republican']]
houseReps.rename(columns={'Democatric':'DemocratHouseReps', 'Republican':'RepublicanHouseReps'}, inplace=True)

#------------------

# Reading and processing political party votes data
votes = pd.read_csv("PartyVotes.csv")

# Calculating total votes and democrat vote share
votes['TotalVotes'] = votes['democratic'] + votes['independent'] + votes['other'] + votes['republican']
votes['DemocratVoteShare'] = votes['democratic'] * 100 / votes['TotalVotes']

# Selecting and renaming columns, standardizing FIPS code format
votes = votes[['county number', 'DemocratVoteShare']]
votes.rename(columns={'county number':'FIPS'}, inplace=True)
votes['FIPS'] = votes['FIPS'].astype(int).astype(str).str.pad(width=5, fillchar='0')

#------------------

# Reading and processing income and poverty data
incomePoverty = pd.read_csv("IncomePoverty.csv")

# Renaming columns for clarity and standardizing STATE and COUNTY codes
incomePoverty.rename(columns={'State FIPS Code': 'STATE', 'County FIPS Code': 'COUNTY', 'Poverty Estimate':'PovertyEstimate', 'Median Household Income': 'MedHHIncome'}, inplace=True)
incomePoverty['STATE'] = incomePoverty['STATE'].astype(str).str.pad(width=2, fillchar='0')
incomePoverty['COUNTY'] = incomePoverty['COUNTY'].astype(str).str.pad(width=3, fillchar='0')

# Concatenating STATE and COUNTY codes to form FIPS code
incomePoverty['FIPS'] = incomePoverty['STATE'] + incomePoverty['COUNTY']
incomePoverty['remove'] = incomePoverty['FIPS'].apply(lambda x: x[2:5] == '000')
incomePoverty = incomePoverty[incomePoverty['remove' == False]]

# Selecting relevant columns
incomePoverty = incomePoverty[['FIPS', 'PovertyEstimate', 'MedHHIncome']]

# Replacing '.' with '0', removing commas, and converting to integers
incomePoverty['PovertyEstimate'] = incomePoverty['PovertyEstimate'].replace('.', '0').str.replace(',', '').astype(int)
incomePoverty['MedHHIncome'] = incomePoverty['MedHHIncome'].replace('.', '0').str.replace(',', '').astype(int)

# Replacing zeros with NaN to handle missing or unspecified data
incomePoverty['PovertyEstimate'] = incomePoverty['PovertyEstimate'].replace(0, np.NaN)
incomePoverty['MedHHIncome'] = incomePoverty['MedHHIncome'].replace(0, np.NaN)

#------------------

# Reading and processing law enforcement employment data
lawEmp = pd.read_csv("LawEnfEmployees.csv")

# Forward fill missing state names and format them
lawEmp['State'].ffill(inplace=True)
lawEmp['State'] = lawEmp['State'].str.title()

# Renaming columns for clarity
lawEmp.rename(columns={'Total officers': 'LawOfficers'}, inplace=True)

# Cleaning up and converting 'LawOfficers' to integers
lawEmp['LawOfficers'] = lawEmp['LawOfficers'].str.replace(',', '').astype(int)

# Standardizing county names for consistency
lawEmp['County'] = lawEmp['County'].str.split(' County').str[0].str.strip()
lawEmp['County'] = lawEmp['County'].str.split(' Police Department').str[0].str.strip()
lawEmp['County'] = lawEmp['County'].str.split(' Public Safety').str[0].str.strip()

# Aggregating law officers by state and county
lawEmp = lawEmp.groupby(['State', 'County']).sum().reset_index()

# Merging with County FIPS codes to standardize county identifiers
lawEmp = lawEmp.merge(CountyFIPS, on=['State', 'County'], how='left')
lawEmp = lawEmp[['FIPS', 'LawOfficers']]

#------------------

# Reading and processing opioid dispensing data
opioidDisp = pd.read_csv("OpioidDisp.csv")

# Selecting relevant columns and renaming for clarity
opioidDisp = opioidDisp[['County FIPS Code', 'Opioid Dispensing Rate per 100']]
opioidDisp.rename(columns={'County FIPS Code':'FIPS', 'Opioid Dispensing Rate per 100':'OpioidDispRate'}, inplace=True)

# Standardizing FIPS code format
opioidDisp['FIPS'] = opioidDisp['FIPS'].astype(str).str.pad(width=5, fillchar='0')

#------------------

# Reading and processing unemployment data
unemployment = pd.read_csv("Unemployment.csv")

# Standardizing State and County FIPS code formats
unemployment['State FIPS'] = unemployment['State FIPS'].astype(str).str.pad(width=2, fillchar='0')
unemployment['County FIPS'] = unemployment['County FIPS'].astype(str).str.pad(width=3, fillchar='0')

# Concatenating State and County FIPS codes to form a unified FIPS code
unemployment['FIPS'] = unemployment['State FIPS'] + unemployment['County FIPS']
unemployment['remove'] = unemployment['FIPS'].apply(lambda x: x[0:2] == '72')

# Removing data for Puerto Rico (FIPS code starting with '72')
unemployment = unemployment[unemployment['remove'] == False]

# Selecting relevant columns and converting strings to integers
unemployment = unemployment[['FIPS', 'Employed', 'Unemployed']]
unemployment['Employed'] = unemployment['Employed'].str.replace(',', '').astype(int)
unemployment['Unemployed'] = unemployment['Unemployed'].str.replace(',', '').astype(int)

#------------------

# Merging initial dataset with CountyFIPS to include State and County names
df = df.merge(CountyFIPS, on='FIPS', how='inner')

# Extracting State FIPS code from County FIPS code
df['StateFIPS'] = df['FIPS'].str.slice(0,2)

# Merging House of Representatives data
df = df.merge(houseReps, on='StateFIPS', how='left')
df = df.drop(columns=['StateFIPS'])

# Merging all the datasets together
datasets_to_merge = {'age': age, 'race': race, 'incomePoverty': incomePoverty, 'lawEmp': lawEmp, 
                     'opioidDisp': opioidDisp, 'unemployment': unemployment, 'education': education, 
                     'votes': votes}
for name, data in datasets_to_merge.items():
    df = df.merge(data, on='FIPS', how='left')

# Selecting and ordering the final set of columns
df = df[['FIPS', 'State', 'County', 'TotalPopulation', 'DeathRate', 
        'PovertyEstimate', 'MedHHIncome', 'Employed', 'Unemployed',
        'DemocratVoteShare', 'DemocratHouseReps', 'RepublicanHouseReps', 'LawOfficers', 'OpioidDispRate',
        'WhitePct', 'Age15-29Pct', 'Age30-49Pct',
        'LessThanHighSchoolPct', 'HighSchoolPct', 'AssociateDegreePct', 'BachelorOrHigherPct']]

# Sorting the dataset by State and County for better readability
df.sort_values(by=['State', 'County'], inplace=True, ignore_index=True)

# Exporting the final merged dataset to a DTA file
df.to_stata('FinalDataset.dta', write_index=False, version=118)
