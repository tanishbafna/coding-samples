# This script leverages a transformer-based model for few-shot named entity recognition (NER) on text data.
# It configures the model for efficient computation using quantization, processes textual data with a
# custom prompt structure, and generates entity outputs.

# Key Features:
# - Implements text generation pipelines with custom prompt templates for NER tasks.
# - Employs GPU acceleration and memory management to enhance performance.
# - Includes error handling and logging to monitor and debug the process.
# - Utilizes environmental variables and command-line arguments for flexible configurations.

# Highlights: Hugging Face, text generation, GPU acceleration, error handling

import os
import gc
import json
import datetime
import argparse
import pandas as pd
from tqdm import tqdm
from time import sleep
from dotenv import load_dotenv; load_dotenv()

import torch
import transformers
from datasets import load_from_disk
from transformers.pipelines.pt_utils import KeyDataset
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig

HUGGINGFACE_TOKEN = os.getenv('HF_KEY')

#----------------------------

# GPU settings
print('Setting GPU device...')

device = torch.device('cuda') if torch.cuda.is_available() else torch.device('cpu')
print(f'There are {torch.cuda.device_count()} GPU(s) available.', end='\n\n')

#----------------------------

def main(args):

    print('Loading the data...')
    
    # Load the data
    dataset = load_from_disk(args.data)
    
    if args.sample is not None:
        try:
            assert len(dataset) >= args.sample
        except argparse.ArgumentTypeError:
            raise argparse.ArgumentTypeError('Sample size must be less than the dataset size.')
        dataset = dataset.select(range(args.sample))

    #-------

    print('Setting up pipeline...')

    # Quantization
    quantization_config = BitsAndBytesConfig(load_in_8bit=True)

    # Load Model
    model = AutoModelForCausalLM.from_pretrained(args.model, token=HUGGINGFACE_TOKEN, quantization_config=quantization_config, device_map='cuda')
    model.eval()

    # Load tokenizer
    tokenizer = AutoTokenizer.from_pretrained(args.model, token=HUGGINGFACE_TOKEN, padding_side='left')

    # Load the model
    pipeline = transformers.pipeline(
        "text-generation",
        model=model,
        tokenizer=tokenizer,
        model_kwargs={"torch_dtype": torch.bfloat16},
        device_map="cuda"
    )

    # Set the tokenizer terminators
    terminators = [
        pipeline.tokenizer.eos_token_id,
        pipeline.tokenizer.convert_tokens_to_ids("<|eot_id|>")
    ]

    pipeline.tokenizer.pad_token_id = model.config.eos_token_id

    #-------

    print('Tokenizing the data...')

    # Load the system prompt
    with open(args.system_prompt, 'r') as file:
        systemPrompt = file.read().strip()

    def tokenizeChat(batch):
        # Embed user prompt in Llama 3's prompt format
        batch['excerpt'] = [f'<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n{systemPrompt}<|eot_id|>\n<|start_header_id|>user<|end_header_id|>\n\n{userPrompt.strip()}<|eot_id|>\n<|start_header_id|>assistant<|end_header_id|>\n\n' for userPrompt in batch['excerpt']]
        return batch

    # Apply chat template
    dataset = dataset.map(tokenizeChat, batched=True, batch_size=16, desc="Tokenizing")
    torch.cuda.empty_cache()

    #-------

    print('Performing Few-Shot NER...')

    # Set the generation kwargs
    generate_kwargs = {
        'max_new_tokens': 25,
        'eos_token_id': terminators,
        'do_sample': True,
        'temperature': 0.1,
        'top_p': 0.4,
        'return_full_text': False,
        'batch_size': args.batch_size
    }

    tries = 0
    completed = set()
    errors = set()
    dataNER = []

    # Pipeline batching
    while len(completed) + len(errors) < len(dataset) and tries < 32:
        try:
            datasetUnprocessed = dataset.filter(lambda x: (x['paperId'], x['excerptId']) not in completed and (x['paperId'], x['excerptId']) not in errors)

            fh = open(f'./progress-{args.logfile}.txt', 'w')
            with torch.no_grad():
                for output, entry in zip(tqdm(pipeline(KeyDataset(datasetUnprocessed, 'excerpt'), **generate_kwargs), total=len(datasetUnprocessed), desc='Batch', file=fh), datasetUnprocessed):
                    dataNER.append((entry['paperId'], entry['excerptId'], entry['dateRange'], output[0]['generated_text'].strip()))
                    completed.add((entry['paperId'], entry['excerptId']))
                    torch.cuda.empty_cache()
                    
        except Exception as e:
            tries += 1
            errors.add((entry['paperId'], entry['excerptId']))

            print(f'Error: {e}\nMemory: {torch.cuda.mem_get_info()}\n')
            torch.cuda.empty_cache()
            
            fh.close()
            sleep(3)

    del pipeline
    gc.collect()
    torch.cuda.empty_cache()

    #-------

    print('Saving the output...')
    
    # Save the data
    df = pd.DataFrame(dataNER, columns=['paperId', 'excerptId', 'dateRange', 'ner'])
    df.to_stata(args.save, write_index=False, version=118)

    # Save the logs
    errors = sorted(list(errors))
    completed = sorted(list(completed))
    with open(f'{args.save.replace(".dta", ".json")}', 'w') as file:
        json.dump({'errors': errors, 'completed': completed}, file, indent=2)

#----------------------------

if __name__ == "__main__":

    # Parse command line arguments
    parser = argparse.ArgumentParser()

    parser.add_argument('--data', type=str, required=True)
    parser.add_argument('--model', type=str, default='meta-llama/Meta-Llama-3-8B-Instruct')
    parser.add_argument("--system-prompt", type=str, default="./ner/systemPrompts/default.txt")
    parser.add_argument('--batch-size', type=int, default=4)
    parser.add_argument("--save", type=str, required=False, default=None)
    parser.add_argument("--sample", type=int, required=False, default=None)
    parser.add_argument("--logfile", type=str, required=True)

    args = parser.parse_args()
    if args.save is None:
        if '-dataset' in args.data:
            args.save = './data/ner/output/' + f'{os.path.basename(args.data.rstrip("/")).replace("-dataset", "")}-{datetime.datetime.now().strftime("%Y-%m-%d_%H-%M")}.dta'
        else:
            args.save = './data/ner/output/' + f'{os.path.basename(args.data.rstrip("/"))}-{datetime.datetime.now().strftime("%Y-%m-%d_%H-%M")}.dta'
    else:
        assert args.save.endswith('.dta')

    main(args)