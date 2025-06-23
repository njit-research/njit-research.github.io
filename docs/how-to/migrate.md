---
title: Migration from on-prem Gitlab servers
hide: toc
---

The following instructions were developed for migrating repositories with their issues, merge requests, milestones and notes (i.e. issue and merge request comments) from self managed on premise gitlab server for academic use to  github enterprise cloud, njit-academics organization. It should work for migration from other gitlab servers to other github organizations.

Requirements:

1. Personal Access Tokens for [gitlab](https://docs.gitlab.com/user/profile/personal_access_tokens/) and [github](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) 

2. [Github CLI](https://cli.github.com/)

3. Python 3, python-gitlab and python-csv


Migration steps

* Download the [python](scripts/export_all_gitlab_repos.py) and [bash](scripts/import_to_github.sh) script.

    These scripts were developed on Microsoft Co-pilot based on input specific to repositories on the academic gitlab server and njit-academics organization.

* Extract all gitlab repo data that you have access to
```bash
python3 export_all_gitlab_repos.py --token "gitlab token"
```

* Import repository to your github team
```bash
bash import_to_github.sh "your team name"
```

* If you encounter errors in 3 with the github cli command, then 

   - comment lines 11 and 12 in the ```import_to_github script```

   - authenticate from the terminal by running
```bash
gh auth login
```

   - Optional: check is the gh command works
```bash
gh repo list njit-academics
```

   - run ```bash import_to_github.sh "your team name"```


