import gitlab
import csv
import argparse
import os

# --- Parse command-line arguments ---
parser = argparse.ArgumentParser(description="Export all GitLab data (repos, issues, comments, MRs, milestones) into CSVs")
parser.add_argument("--token", required=True, help="GitLab personal access token")
parser.add_argument("--url", default="http://git-acad.njit.edu", help="GitLab instance URL")
args = parser.parse_args()

# --- Connect to GitLab ---
gl = gitlab.Gitlab(args.url, private_token=args.token)
gl.auth()

def clean(text):
    return text.replace("\r", "").replace("\n", "\\n").strip() if isinstance(text, str) else text

seen_project_ids = set()
projects_list = []

# === Collect group and user-owned projects ===
print("📦 Fetching projects from groups and users...")

# Group projects
groups = gl.groups.list(all=True)
for group in groups:
    try:
        projects = group.projects.list(include_subgroups=True, all=True)
        projects_list.extend(projects)
    except Exception as e:
        print(f"⚠️  Skipped group '{group.full_path}': {e}")

# User-owned projects
users = gl.users.list(all=True)
for user in users:
    try:
        projects = gl.users.get(user.id).projects.list(all=True)
        projects_list.extend(projects)
    except Exception as e:
        print(f"⚠️  Skipped user '{user.username}': {e}")

projects_unique = []
for proj in projects_list:
    if proj.id not in seen_project_ids:
        seen_project_ids.add(proj.id)
        projects_unique.append(gl.projects.get(proj.id))

print(f"✅ Found {len(projects_unique)} unique projects.")

# === Export repos ===
with open("repos.csv", "w", newline="") as f:
    writer = csv.writer(f, delimiter="|", quoting=csv.QUOTE_MINIMAL)
    writer.writerow(["id", "name", "path", "http_url_with_token"])
    for proj in projects_unique:
        url = f"http://oauth2:{args.token}@{args.url.strip('https://').strip('/')}/{proj.path_with_namespace}.git"
        writer.writerow([proj.id, clean(proj.name), clean(proj.path), url])

# === Export issues ===
with open("issues.csv", "w", newline="") as f:
    writer = csv.writer(f, delimiter='|', quoting=csv.QUOTE_MINIMAL)
    writer.writerow(["project_id", "issue_iid", "title", "description", "state", "author"])
    for proj in projects_unique:
        issues = proj.issues.list(all=True)
        for issue in issues:
            writer.writerow([
                proj.id,
                issue.iid,
                clean(issue.title),
                clean(issue.description or ""),
                clean(issue.state),
                issue.author['username'] if issue.author else "unknown"
            ])

# === Export issue comments ===
with open("issue_comments.csv", "w", newline="") as f:
    writer = csv.writer(f, delimiter='|', quoting=csv.QUOTE_MINIMAL)
    writer.writerow(["project_id", "issue_iid", "author", "created_at", "body"])
    for proj in projects_unique:
        issues = proj.issues.list(all=True)
        for issue in issues:
            notes = proj.issues.get(issue.iid).notes.list(all=True)
            for note in notes:
                if not note.system:
                    writer.writerow([
                        proj.id,
                        issue.iid,
                        note.author['username'] if note.author else "unknown",
                        note.created_at,
                        clean(note.body)
                    ])

# === Export merge requests ===
with open("merge_requests.csv", "w", newline="") as f:
    writer = csv.writer(f, delimiter='|', quoting=csv.QUOTE_MINIMAL)
    writer.writerow(["project_id", "iid", "title", "description", "source_branch", "target_branch", "state", "author"])
    for proj in projects_unique:
        mrs = proj.mergerequests.list(all=True)
        for mr in mrs:
            writer.writerow([
                proj.id,
                mr.iid,
                clean(mr.title),
                clean(mr.description or ""),
                clean(mr.source_branch),
                clean(mr.target_branch),
                clean(mr.state),
                mr.author['username'] if mr.author else "unknown"
            ])

# --- Export merge request notes (comments) ---
with open("merge_request_comments.csv", "w", newline="") as f:
    writer = csv.writer(f, delimiter="|", quoting=csv.QUOTE_MINIMAL)
    writer.writerow(["project_id", "mr_iid", "author", "created_at", "body"])
    for proj in projects:
        try:
            full = gl.projects.get(proj.id)
            mrs = full.mergerequests.list(all=True)
            for mr in mrs:
                notes = full.mergerequests.get(mr.iid).notes.list(all=True)
                for note in notes:
                    if not note.system:
                        writer.writerow([
                            proj.id,
                            mr.iid,
                            note.author["username"] if note.author else "unknown",
                            note.created_at,
                            clean(note.body)
                        ])
        except Exception as e:
            print(f"⚠️  Failed MR notes for project {proj.id}: {e}")

# === Export milestones ===
with open("milestones.csv", "w", newline="") as f:
    writer = csv.writer(f, delimiter='|', quoting=csv.QUOTE_MINIMAL)
    writer.writerow(["project_id", "id", "title", "description", "state"])
    for proj in projects_unique:
        milestones = proj.milestones.list(all=True)
        for m in milestones:
            writer.writerow([
                proj.id,
                m.id,
                clean(m.title),
                clean(m.description or ""),
                clean(m.state)
            ])

print("\n📁 Export complete. CSV files saved to current directory.")

