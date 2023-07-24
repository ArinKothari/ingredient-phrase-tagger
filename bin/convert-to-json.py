#!/usr/bin/env python
from __future__ import print_function

import sys
import json

from ingredient_phrase_tagger.training import utils


if len(sys.argv) < 2:
    sys.stderr.write('Usage: make-data.py FILENAME')
    sys.exit(1)

json_object = json.dumps(utils.import_data(open(sys.argv[1])), indent=4)
print(json_object)
with open("tmp/output.txt", "w") as outfile:
  outfile.write(json_object)
