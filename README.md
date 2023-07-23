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

This is an updated version of ingredient-phrase-tagger library from nytimes. 
* According to the README installation instructions, it only works for macOS

The library, at the time being over 7 years old has multiple dependency issues:
* Unsupported Python2.7
* The CRF library CRF++ also being another dead library with missing header files

These issues were fixed following an article, Resurrecting a Dead Library by mtlynch, running
the library on Docker and using his fork of CRF++ library with support on Linux. All the commands for
the build are ran into a `Dockerfile` with few more changes to incorporate the shut down of Python2.7.


## Quick Start

The most common usage is to train the model with a subset of our data, test the
model against a different subset, then visualize the results. We provide a shell
script to do this, at:

    ./roundtrip.sh

You can edit this script to specify the size of your training and testing set.
The default is 20k training examples and 2k test examples.


## Usage

### Training

To train the model, we must first convert our input data into a format which
`crf_learn` can accept:

    bin/generate_data --data-path=input.csv --count=1000 --offset=0 > tmp/train_file

The `count` argument specifies the number of training examples (i.e. ingredient
lines) to read, and `offset` specifies which line to start with. There are
roughly 180k examples in our snapshot of the New York Times cooking database
(which we include in this repo), so it is useful to run against a subset.

The output of this step looks something like:

    1            I1      L8      NoCAP  NoPAREN  B-QTY
    cup          I2      L8      NoCAP  NoPAREN  B-UNIT
    white        I3      L8      NoCAP  NoPAREN  B-NAME
    wine         I4      L8      NoCAP  NoPAREN  I-NAME

    1/2          I1      L4      NoCAP  NoPAREN  B-QTY
    cup          I2      L4      NoCAP  NoPAREN  B-UNIT
    sugar        I3      L4      NoCAP  NoPAREN  B-NAME

    2            I1      L8      NoCAP  NoPAREN  B-QTY
    tablespoons  I2      L8      NoCAP  NoPAREN  B-UNIT
    dry          I3      L8      NoCAP  NoPAREN  B-NAME
    white        I4      L8      NoCAP  NoPAREN  I-NAME
    wine         I5      L8      NoCAP  NoPAREN  I-NAME

Next, we pass this file to `crf_learn`, to generate a model file:

    crf_learn template_file tmp/train_file tmp/model_file


### Testing

To use the model to tag your own arbitrary ingredient lines (stored here in
`input.txt`), you must first convert it into the CRF++ format, then run against
the model file which we generated above. We provide another helper script to do
this:

    python bin/parse-ingredients.py input.txt > results.txt

The output is also in CRF++ format, which isn't terribly helpful to us. To
convert it into JSON:

    python bin/convert-to-json.py results.txt > results.json

See the top of this README for an example of the expected output.


## Authors

* Erica Greene
* Adam Mckaig



[crfpp]:    https://taku910.github.io/crfpp/

