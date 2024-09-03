# This Python script processes academic papers, extracting and cleaning abstracts, detecting the language of the papers, 
# and filtering them based on year, document type, and language. It is designed to handle large volumes of text data 
# efficiently using multiprocessing.

# - Utilizes the fasttext model for language detection to ensure the content is in the desired language.
# - Processes text to reconstruct abstracts from an inverted index format, handling special characters and JSON structure 
#   to restore the original abstract text.
# - Filters papers based on the specified year and excludes certain document types (e.g., patents).
# - Uses regular expressions and unicode normalization to clean and prepare text data for further analysis or storage.
# - Employs multiprocessing to process files concurrently, significantly speeding up the data processing pipeline.

# Highlights: fasttext, RegEx, pandas, multiprocessing, JSON parsing, command-line arguments

import os
import re
import json
import argparse
import fasttext
from tqdm import tqdm
import unicodedata as ud
from multiprocessing import Pool

#---------------

def initializer():
    global model
    model = fasttext.load_model('./data/models/lid.176.bin')

def build_abstract(inverted_index):

    # Escape backslashes
    inverted_index = re.sub(r'\\', r'\\\\', inverted_index)

    # Convert all double quotes specifying keys to special char !#$*
    inverted_index = re.sub(r'":\[', r'!#$*:[', inverted_index)
    inverted_index = re.sub(r'\],"', r'],!#$*', inverted_index)

    # Convert the first double quotes to special char !#$*
    inverted_index = re.sub(r',"InvertedIndex":{"', r',!#$*InvertedIndex!#$*:{!#$*', inverted_index)
    inverted_index = re.sub(r'{"IndexLength":', r'{!#$*IndexLength!#$*:', inverted_index)

    # Replace all double quotes with single quotes
    inverted_index = re.sub(r'"', r"'", inverted_index)

    # Convert special char !#$* back to double quotes
    inverted_index = re.sub(r'!#\$\*', r'"', inverted_index)

    try:
        inverted_index = json.loads(inverted_index, strict=False)
    except Exception as e:
            return False

    total_length = inverted_index['IndexLength']
    inverted_index = inverted_index['InvertedIndex']
    
    # Initialize the list to store the result
    text = [''] * total_length
    
    # Place each word at the correct indices
    for word, positions in inverted_index.items():
        for position in positions:
            text[position] = word
    
    # Join words
    return ' '.join(text).strip()

#-----

def detectLang(title, abstract):

    # Combine title and abstract
    full_text = f"{title}: {abstract}".strip().strip(':').strip()

    # Clean up
    full_text = full_text.replace(u"\u2022", '')
    full_text = ud.normalize('NFKC', full_text)

    # Try to convert to UTF-8
    try:
        full_text = full_text.encode('utf-8').decode('utf-8')
    except Exception as e:
        print(e)
        return False

    # If the text is empty, exlude the paper
    if not full_text:
        return 'nan'
    
    # Detect language
    try:
        labels, scores = model.predict(full_text)
        return labels[0].replace("__label__", '')
    except Exception as e:
        print(e)
        return False

#-----

def main(tup):

    # Unpack tuple
    file, args = tup

    # File index
    idx = file.split('_')[-1].split('.')[0]

    # Title mapping
    id2title = {}

    # Abstract errors
    errs = []

    # Output file
    with open(f'./data/subset/{idx}.jsonl', 'w') as j:
    
        # Load data
        with open(f'./data/raw/{file}', 'r') as f:
            for lineIx, line in enumerate(f):
                paper = json.loads(line)

                # Check year and document type
                if paper.get('year', args.year + 1) <= args.year and paper.get('doc_type') != args.exclude_doc:

                    # Build abstract
                    if 'indexed_abstract' in paper:
                        temp_abstract = build_abstract(paper['indexed_abstract'])
                        if temp_abstract == False:
                            errs.append({
                                'error': 'abstract',
                                'file': idx,
                                'paper': lineIx,
                                'indexed_abstract': paper['indexed_abstract']
                            })
                            temp_abstract = ''
                    else:
                        temp_abstract = ''

                    paper['abstract'] = temp_abstract
                    paper.pop('indexed_abstract', None)

                    # Remove whitespaces like \n, \t, etc.
                    paper['title'] = re.sub(r'\s+', ' ', paper.get('title', '')).strip()
                    paper['abstract'] = re.sub(r'\s+', ' ', paper.get('abstract', '')).strip()

                    # Check language
                    lang = detectLang(paper.get('title', ''), paper.get('abstract', ''))

                    if lang == False:
                        errs.append({
                            'error': 'langdetect',
                            'file': idx,
                            'paper': lineIx,
                            'title': paper.get('title', ''),
                            'abstract': paper.get('abstract', '')
                        })

                    elif lang == args.lang:
                        
                        # Write to file
                        json.dump(paper, j)
                        j.write('\n')

                        # Update title mapping
                        id2title[paper['id']] = paper.get('title', '')
        
    return id2title, errs

#---------------

if __name__ == '__main__':

    # Parse command line arguments
    parser = argparse.ArgumentParser()

    parser.add_argument('--year', type=int, default=1980)
    parser.add_argument('--exclude-doc', type=str, default='Patent')
    parser.add_argument('--lang', type=str, default='en')
    args = parser.parse_args()

    # Title mapping
    id2titleList = []

    # Abstract errors
    allErrors = []

    # Raw data files
    files = sorted([(f, args) for f in os.listdir('./data/raw') if f.endswith('.txt')])
    with Pool(processes=16, initializer=initializer) as pool, tqdm(total=len(files), desc=f'Subsetting', position=0) as pbar:
        for out, errsOut in pool.imap_unordered(main, files):
            id2titleList.append(out)
            allErrors.extend(errsOut)
            pbar.update()

    print(f'Errors: {len(allErrors)}')

    # Save title mapping
    id2titleDict = {k: v for d in id2titleList for k, v in d.items()}
    with open(f'./data/id2title.json', 'w') as f:
        json.dump(id2titleDict, f)

    # Save errors
    with open(f'./data/subsetErrors.json', 'w') as f:
        json.dump(allErrors, f, indent=2)
