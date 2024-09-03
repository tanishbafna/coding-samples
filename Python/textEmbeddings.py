# This script preprocesses textual data, tokenizes it, and computes embeddings using transformer models
# with adapters. It is designed to handle various configurations of input types and supports batch and
# GPU processing for efficiency.

# - Filters and processes datasets based on specified textual components (e.g., title, abstract).
# - Utilizes GPU for accelerated computation if available.
# - Supports splitting large datasets into manageable segments for efficient processing.
# - Computes embeddings using pretrained transformer models and pickles them for further use.
# - Configurable through command line arguments for flexibility in different research scenarios.

# Highlights: Hugging Face, PyTorch, GPU processing, command-line arguments

import os
import re
import gc
import pickle
import argparse
from tqdm import tqdm
from copy import deepcopy
from pprint import pprint

import torch
from datasets import load_from_disk
from adapters import AutoAdapterModel
from transformers import AutoTokenizer
from torch.utils.data import DataLoader

#----------------------------

# GPU settings
print('Setting GPU device...')

device = torch.device('cuda') if torch.cuda.is_available() else torch.device('cpu')
print(f'There are {torch.cuda.device_count()} GPU(s) available.\n')

#----------------------------

# Filter dataset based on input type availability
def filterDataset(paper, inputType):

    # Check if components of input type are available (not empty strings)
    match = True
    for key in inputType:
        if not paper[key]:
            match = False
            break
    
    return match

#-------

# Split dataset indices into parts
def splitIndices(total, splits):
    samples = total // splits
    splits = [0] + [i * samples for i in range(1, splits)]
    if splits[-1] != total:
        splits.append(total)
    return splits

#-------

def computeEmbeddings(name, splitIdx, model, dataset, args):

    # Create a data loader
    data_loader = DataLoader(dataset, batch_size=args.batch_size, shuffle=False)

    # Compute the embeddings
    ids = []
    embeddings = []

    with torch.no_grad():
        for batch in tqdm(data_loader, desc=f"{name} [Split {splitIdx}]"):

            # Move batch to the same device as model
            idBatch = deepcopy(batch['id'])
            batch = {k: v.to(model.device) for k, v in batch.items() if k != 'id'}

            # Generate embeddings
            outputs = model(**batch)

            # Save the IDs
            ids.extend(idBatch)

            # Move embeddings to CPU
            embeddings.append(outputs.last_hidden_state[:, 0, :].cpu())
            torch.cuda.empty_cache()

    # Concatenate all collected embeddings
    embeddings = torch.cat(embeddings, dim=0)
    embeddings = embeddings.numpy()

    # Map the IDs to embeddings
    embeddings = {id: emb for id, emb in zip(ids, embeddings)}

    #-------

    with open(f'{args.save}/{name}-emb{splitIdx}.pkl', 'wb') as f:
        pickle.dump(embeddings, f)

    return True

#-------

def main(args):

    print('\nLoading the data...\n')
    
    # Load the data
    dataset = load_from_disk(args.data + '/all')

    datasetByInputType = {
        inputType: deepcopy(dataset.filter(lambda x: filterDataset(x, inputTypeList), desc=f'Filtering {inputType}')) for inputType, inputTypeList in args.input_types.items()
    }

    pprint(datasetByInputType)

    del dataset
    gc.collect()

    #-------

    print('\nApplying prefixes...\n')

    # Set prefix
    prefix = {
        'references': 'References:',
        'fos': 'Fields of Study:'
    }

    for inputType in args.input_types.keys():
        for prefixKey in prefix.keys():
            if prefixKey in args.input_types[inputType]:
                datasetByInputType[inputType] = datasetByInputType[inputType].map(lambda x: {prefixKey: [f'{prefix[prefixKey]} {item}.' for item in x[prefixKey]]}, batched=True, batch_size=32, desc=f'Prefix for {prefixKey}')

    #-------

    print('\nSetting the tokenizer...\n')

    # Load tokenizer
    tokenizer = AutoTokenizer.from_pretrained(args.model)

    def tokenize(batch, inputType):
        texts = []
        for i in range(len(batch['id'])):
            text = ''
            for key in inputType:
                text += batch[key][i] + tokenizer.sep_token
            text = text.strip(tokenizer.sep_token).strip()
            text = re.sub(r'\s+', ' ', text)
            texts.append(text)
        
        return tokenizer(
            texts,
            padding=True,
            truncation=True,
            return_token_type_ids=False,
            max_length=512,
            return_tensors="pt"
        )

    #-------

    print('\nLoading the model...\n')

    # Load the model
    model = AutoAdapterModel.from_pretrained(args.model)
    model.load_adapter(args.adapter, source="hf", set_active=True)
    model.eval()
    model.to(device)

    #-------

    print('\nComputing the embeddings...\n')

    for name, inputType in args.input_types.items():

        dataset = datasetByInputType[name]

        # Find the split indices
        splits = splitIndices(len(dataset), args.splits)

        for splitIdx in range(1, len(splits)):
            datasetSplit = dataset.select(range(splits[splitIdx-1], splits[splitIdx]))

            # Apply the tokenizer to the dataset
            datasetInput = datasetSplit.map(tokenize, fn_kwargs={'inputType': inputType}, batched=True, batch_size=args.batch_size, desc=f'Tokenizing {name} [Split {splitIdx}]')
            datasetInput = datasetInput.remove_columns(['title', 'abstract', 'references', 'fos'])
            datasetInput.set_format('pt', columns=['input_ids', 'attention_mask'], output_all_columns=True)
            torch.cuda.empty_cache()

            # Compute the embeddings
            computeEmbeddings(name, splitIdx, model, datasetInput, args)
    
    print(f'Embeddings saved in {args.save}.\n')
    return True

#----------------------------

if __name__ == "__main__":

    # Defining input sequence orders
    inputTypes = {
        'titleAbstract': ['title', 'abstract'],
        'titleRefs': ['title', 'references'],
        'titleFOS': ['title', 'fos'],
        'titleAbstractRefs': ['title', 'abstract', 'references'],
        'titleRefsFOS': ['title', 'references', 'fos'],
        'titleAbstractFOS': ['title', 'abstract', 'fos'],
        'titleAbstractRefsFOS': ['title', 'abstract', 'references', 'fos']
    }

    # Parse command line arguments
    parser = argparse.ArgumentParser()

    parser.add_argument('--data', type=str, required=True)
    parser.add_argument('--model', type=str, default='allenai/specter2_base')
    parser.add_argument('--adapter', type=str, default='allenai/specter2')
    parser.add_argument('--batch-size', type=int, default=16)
    parser.add_argument('--splits', type=int, default=10)
    parser.add_argument('--input-types', type=str, required=True, choices=['all'] + list(inputTypes.keys()), nargs='+')

    args = parser.parse_args()

    args.data = args.data.rstrip('/')
    args.save = f"./data/embeddings/{os.path.basename(args.data)}"
    if not os.path.exists(args.save):
        os.mkdir(args.save)

    if 'all' in args.input_types:
        args.input_types = inputTypes
    else:
        args.input_types = {inputType: inputTypes[inputType] for inputType in args.input_types}

    main(args)
