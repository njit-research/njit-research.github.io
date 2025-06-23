#!/bin/bash

TEAM_NAME="$1"
if [[ -z "$TEAM_NAME" ]]; then
  echo "Usage: $0 <team-name>"
  exit 1
fi

# === Configuration ===
GITHUB_ORG="njit-academics"
GITHUB_TOKEN="Enter your Github Personal Access Token"
export GH_TOKEN="$GITHUB_TOKEN"

# Optional check auth status and list of repos in org
#gh auth status
#gh repo list njit-academics --limit 100

# === Helper: Trim carriage returns and whitespace ===
clean() {
  echo "$1" | tr -d '\r' | xargs
}

# === Step 1: Create GitHub Repos and Push Code ===
echo "📦 Creating GitHub repositories and pushing code..."
tail -n +2 repos.csv | while IFS='|' read -r id name path http_url; do
  repo_name=$(clean "$path")
  repo_url=$(clean "$http_url")
  full_repo="$GITHUB_ORG/$repo_name"

  echo "🔧 Creating repo: $full_repo"
  gh repo create "$full_repo" --private

  echo "👥 Adding $full_repo to team $TEAM_NAME..."
  gh api -X PUT "orgs/$GITHUB_ORG/teams/$TEAM_NAME/repos/$full_repo" -f permission=push

  echo "📤 Cloning and pushing: $repo_url"
  git clone --mirror "$repo_url"
  cd "$repo_name.git" || continue
  git remote add github "git@github.com:$full_repo.git"
  git push --mirror github
  cd ..
  rm -rf "$repo_name.git"
done

# === Step 2: Import Issues ===
echo "🐞 Importing issues..."
tail -n +2 issues.csv | while IFS='|' read -r project_id issue_iid title description state author; do
  repo_path=$(awk -F'|' -v id="$project_id" '$1 == id {print $3}' repos.csv | tr -d '\r' | xargs)
  [[ -z "$repo_path" ]] && continue
  full_repo="$GITHUB_ORG/$repo_path"

  if ! gh repo view "$full_repo" >/dev/null 2>&1; then
    echo "⚠️  Skipping: $full_repo not found."
    continue
  fi

  body="**Original Author:** $(clean "$author")"$'\n\n'"$(clean "$description")"
  gh issue create --repo "$full_repo" --title "$(clean "$title")" --body "$body"

  if [[ "$state" == "closed" ]]; then
    issue_number=$(gh issue list --repo "$full_repo" --state all --limit 1 --json number --jq '.[0].number')
    [[ -n "$issue_number" ]] && gh issue close "$issue_number" --repo "$full_repo"
  fi
done

# === Step 3: Import Milestones ===
echo "📅 Importing milestones..."
tail -n +2 milestones.csv | while IFS='|' read -r project_id milestone_id title description state author; do
  repo_path=$(awk -F'|' -v id="$project_id" '$1 == id {print $3}' repos.csv | tr -d '\r' | xargs)
  [[ -z "$repo_path" ]] && continue
  full_repo="$GITHUB_ORG/$repo_path"

  # Normalize state
  state=$(clean "$state" | sed 's/active/open/i' | sed 's/expired/closed/i')
  body="**Original Author:** $(clean "$author")"$'\n\n'"$(clean "$description")"

  gh api repos/"$full_repo"/milestones \
    --method POST \
    --field title="$(clean "$title")" \
    --field description="$body" \
    --field state="$state"
done

# === Step 4: Import Merge Requests as Pull Requests ===
echo "🔀 Importing merge requests..."
tail -n +2 merge_requests.csv | while IFS='|' read -r project_id mr_iid title description source_branch target_branch state author; do
  repo_path=$(awk -F'|' -v id="$project_id" '$1 == id {print $3}' repos.csv | tr -d '\r' | xargs)
  [[ -z "$repo_path" ]] && continue
  full_repo="$GITHUB_ORG/$repo_path"

  source_branch=$(clean "$source_branch")
  target_branch=$(clean "$target_branch")

  # Validate repo and branches
  if ! gh repo view "$full_repo" >/dev/null 2>&1; then
    echo "⚠️  Skipping: $full_repo not found."
    continue
  fi
  if ! gh api repos/"$full_repo"/branches/"$source_branch" >/dev/null 2>&1 || \
     ! gh api repos/"$full_repo"/branches/"$target_branch" >/dev/null 2>&1; then
    echo "⚠️  Skipping MR $mr_iid: missing branch in $full_repo"
    continue
  fi

  echo "🔧 Creating PR: $title [$source_branch → $target_branch]"
  body="**Original Author:** $(clean "$author")"$'\n\n'"$(clean "$description")"
  gh pr create --repo "$full_repo" \
               --title "$(clean "$title")" \
               --body "$body" \
               --base "$target_branch" \
               --head "$source_branch"

  if [[ "$state" == "closed" ]]; then
    pr_number=$(gh pr list --repo "$full_repo" --state open --json number --jq '.[0].number')
    [[ -n "$pr_number" ]] && gh pr close "$pr_number" --repo "$full_repo"
  fi
done

# === Step 4: Import Issue Comments ===
echo "💬 Importing issue comments..."
tail -n +2 issue_comments.csv | while IFS='|' read -r project_id issue_iid author created_at body; do
  repo_path=$(awk -F'|' -v id="$project_id" '$1 == id {print $3}' repos.csv | tr -d '\r' | xargs)
  [[ -z "$repo_path" ]] && continue
  full_repo="$GITHUB_ORG/$repo_path"

  # Match issue by GitLab IID tag if included in title
  gh_issues=$(gh issue list --repo "$full_repo" --state all --json number,title)
  match=$(echo "$gh_issues" | jq --arg iid "$issue_iid" '.[] | select(.title | test("(^|[^0-9])" + $iid + "([^0-9]|$)")) | .number' | head -n1)
  [[ -z "$match" ]] && continue

  comment="**Original Comment by @$author on $created_at**"$'\n\n'"$body"
  gh issue comment "$match" --repo "$full_repo" --body "$comment"

done

# === Step 6: Import Merge Request Comments ===
echo "💬 Importing merge request comments..."
tail -n +2 merge_request_comments.csv | while IFS='|' read -r project_id mr_iid author created_at body; do
    repo_path=$(awk -F'|' -v id="$project_id" '$1 == id {print $3}' repos.csv | xargs)
    [[ -z "$repo_path" ]] && continue
    full_repo="$GITHUB_ORG/$repo_path"

    # Match PR by MR IID in title
    pr_number=$(gh pr list --repo "$full_repo" --state all --json number,title --jq \
        --arg mrid "$mr_iid" '.[] | select(.title | test("(^|[^0-9])" + $mrid + "([^0-9]|$)")) | .number')

    [[ -z "$pr_number" ]] && continue

    comment="**Original Comment by @$author on $created_at**"$'\n\n'"$body"
    gh pr comment "$pr_number" --repo "$full_repo" --body "$comment"
done

echo "✅ GitHub import complete."


