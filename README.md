# CRF Ingredient Phrase Tagger

This repo contains scripts to extract the Quantity, Unit, Name, and Comments
from unstructured ingredient phrases. Given the following input:

    1 pound carrots, young ones if possible
    2 tablespoons honey
    2 tablespoons extra-virgin olive oil
    1/2 teaspoon fresh thyme leaves, finely chopped
    Black pepper, to taste

Our tool produces something like:

    {
        "qty":     "1",
        "unit":    "pound"
        "name":    "carrots",
        "other":   ",",
        "comment": "young ones if possible",
        "input":   "1 pound carrots, young ones if possible",
        "display": "<span class='qty'>1</span><span class='unit'>pound</span><span class='name'>carrots</span><span class='other'>,</span><span class='comment'>young ones if possible</span>",
    }

We use a conditional random field model (CRF) to extract tags from labelled
training data.

## Changes Made

This is an updated version of ingredient-phrase-tagger library from [nytimes][4]. 
* According to the README installation instructions, it only works for macOS

The library, at the time being over 7 years old has multiple dependency issues:
* Unsupported Python2.7
* The CRF library [CRF++][1] also being another dead library with missing header files

These issues were fixed following an article, [Resurrecting a Dead Library][2] by mtlynch, running
the library on Docker and using his fork of CRF++ library with support on Linux. All the commands for
the build are ran into a `Dockerfile` with few more changes to incorporate the shut down of Python2.7 and our version of this library.

Since we are adding more diverse train cases into the training data to train the mode over
multiple unit instances and quantity patterns, the code had to be modified as such so the following
improvements were made:

* More patterns were added to identify quantities other than just one number:

        100 g - Number
        1/2 tablespoon - Fraction
        4 2/3 cups - Mixed Fraction
        3 2 ounce packets - Multiplication
  
  These are a few examples that the model tags as a single quantity.

* The library had a script to singularize units to simplify outputs which is modified
to convert commonly used forms of units to their base form:
```json
{"name": "tablespoon",
             "forms": [
                 "tablespoon",
                 "tablespoons",
                 "T",
                 "tbl",
                 "tb",
                 "tb.",
                 "tbs"]}
```

* We added upon the training data provided with the library with more of
IIITD [RecipeDB][3] data from All-Recipes and FOOD.com, but it still did not cover all commonly used
units for which data augmentation was used to make artificial data to train the model for all the missing
units.

## Installation

1. As previously mentioned, the library needs to be run on Docker so the first step is to download it's desktop [client][5].
2. After the installation process, download the `Dockerfile` from the repo and open powershell in the directory with the file.
3. Run the following command to start the build process (this will take some time)

         docker build --tag phrase-tagger .
   
   This creates a local image on docker so you can start from step 4 from next time.
4. Finally run the following command to create and run the library container:

       docker run -it --rm phrase-tagger /bin/bash

## Quick Start

The most common usage is to train the model with a subset of our data, test the
model against a different subset, then visualize the results. We provide a shell
script to do this, at:

    ./roundtrip.sh

* You can edit this script to specify the size of your training and testing set and change the contents of the input file `ingredients-snapshot.csv`.
The default covers all training and test examples.
* If the shell script is modified it loses it's execution permission, for that run:

        chmod +x roundtrip.sh

See the top of this README for an example of the expected output.
* To visualize the accuracy of the model, you can open the `output.html` file in `ingredient-phrase-tagger/tmp`.

## Usage

### Training

To train the model, we must first convert our input data into a format which
`crf_learn` can accept:

    bin/generate_data --data-path=input.csv --count=1000 --offset=0 > tmp/train_file

The `count` argument specifies the number of training examples (i.e. ingredient
lines) to read, and `offset` specifies which line to start with.

The output of this step looks something like:

    1            I1      L8      NoCAP  NoPAREN  B-QTY
    cup          I2      L8      NoCAP  NoPAREN  B-UNIT
    white        I3      L8      NoCAP  NoPAREN  B-NAME
    wine         I4      L8      NoCAP  NoPAREN  I-NAME

    1/2          I1      L4      NoCAP  NoPAREN  B-QTY
    cup          I2      L4      NoCAP  NoPAREN  B-UNIT
    sugar        I3      L4      NoCAP  NoPAREN  B-NAME


Next, we pass this file to `crf_learn`, to generate a model file:

    crf_learn template_file tmp/train_file tmp/model_file


### Testing

The model takes quite some time to train over all the examples so a copy `model_file` is also
added in the library. You can skip the training step if you don't want to make any changes.

* To use the model to tag your own arbitrary ingredient lines (stored here in
`input.txt`), you must first convert it into the CRF++ format, then run against
the model file which we generated above. There is a helper script to do this:

        python bin/parse-ingredients.py input.txt > results.txt
  * The `input.txt` file needs to be uploaded in the `ingredient-phrase-tagger` directory in Docker container
    and values can be inputted with the following command:

          echo "1 pinch Garlic Powder" >> input.txt

* The output is also in CRF++ format. To convert it into JSON:

        python bin/convert-to-json.py results.txt > results.json

* The output file `results.json` can be found in the `ingredient-phrase-tagger` directory in JSON format
  as shown in the output example at the top.

## Accuracy

The library has a script to evaluate it's accuracy over the test data. The accuracy is calculated at word level and sentence level.
Since the library only extracts name, qty and unit, getting any other tags wrong doesn't affect the accuracy.

Our evaluation over default settings,

```
Sentence-Level Stats:
	correct:  1886
	total:  2058
	% correct:  91.64237123420797

Word-Level Stats:
	correct: 6929
	total: 7199
	% correct: 96.24947909431866
```





[1]:    https://taku910.github.io/crfpp/
[2]:    https://mtlynch.io/resurrecting-1/
[3]:    https://github.com/cosylabiiit/Recipedb-companion-data/tree/master
[4]:    https://github.com/nytimes/ingredient-phrase-tagger/tree/master
[5]:    https://www.docker.com/products/docker-desktop/

