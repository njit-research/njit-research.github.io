---
title: Migration from on-prem Gitlab servers
hide: toc
---

The following instructions were developed for migrating repositories with their issues, merge requests, milestones and notes (i.e. issue and merge request comments) from self managed on premise gitlab server for academic use to  github enterprise cloud, njit-academics organization, on Mac OSX 15.5. It has also been tested on a Ubuntu 24.04 LTS virtual image. It should work for migration from other gitlab servers to other github organizations on other OS's.

## Requirements:

1. Personal Access Tokens for [gitlab](https://docs.gitlab.com/user/profile/personal_access_tokens/) and [github](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) 

2. [Github CLI](https://cli.github.com/)
```bash
Mac: brew install gh
Linux: See instructions at https://github.com/cli/cli/blob/trunk/docs/install_linux.md 
```

3. Python 3, python-gitlab and python-csv
```bash
python3 -m pip install python-gitlab python-csv
```

## Migration steps

* Download the [python](scripts/export_all_gitlab_repos.py) and [bash](scripts/import_to_github.sh) script.

    These scripts were developed on Microsoft Co-pilot based on input specific to repositories on the academic gitlab server and njit-academics organization.

* Extract all gitlab repo data that you have access to
```bash
python3 export_all_gitlab_repos.py --token "gitlab token"
```
     - By default, this extracts data from http://git-acad.njit.edu. If you want to extract data from another site, say https://gitlab.com, then add `--url https://gitlab.com`

* Import repository to your github team
```bash
bash import_to_github.sh "your team name"
```
     - To find "your team name", you can run the command 
```bash
gh api \
   -H "Accept: application/vnd.github+json" \
   -H "X-GitHub-Api-Version: 2022-11-28" \
   /orgs/njit-academics/teams | \
   jq -c '[.[] | {name: .name, path: .slug, description: .description}]'
```
         and use the path output in the previous command.


### Known Issues 

1. If your repo on gitlab uses LFS, the `git push --mirror` command in the `import_to_github.sh` script will fail. You might need to clone the repo and track large files with lfs before pushing to github.
2. Issues, merge requests, milestones etc will be under your gitlab account i.e. njit ucid not your github handle.


