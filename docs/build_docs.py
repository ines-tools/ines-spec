#!/usr/bin/env python

# activate the (python) environment in which you (pip) installed sphinx
# execute this script with python path/to/build_docs.py

import os.path

print("Building Ines spec documentation")

script_dir = os.path.dirname(os.path.realpath(__file__))
make_docs_dir = os.path.join(script_dir, os.path.pardir, "docs")
current_working_dir = os.getcwd()
os.chdir(make_docs_dir)
status = os.system("make html")
os.chdir(current_working_dir)
exit(status)
