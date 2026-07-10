#!/bin/bash


# Optional
# python3 -m pip install python-gitlab python-csv


python3 export_all_gitlab_repos.py --token <"your gitlab token">

# Optional 
# brew install gh

bash import_to_github.sh <"your team name">


