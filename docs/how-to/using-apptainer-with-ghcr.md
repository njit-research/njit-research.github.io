# Using Apptainer with GitHub Container Registry (GHCR) at NJIT Academics

A streamlined guide for authenticating with and using GitHub Container Registry (ghcr.io) for Apptainer images, specifically tailored for the `njit-academics` GitHub organization.

### Prerequisites

*   Apptainer (or Singularity) installed on your local machine or cluster.
*   A GitHub account with membership in the `njit-academics` organization.

---

## Part 1: Authentication (Critical Step)

Accessing organization resources requires a Personal Access Token (PAT) that has been explicitly authorized for Single Sign-On (SSO).

### 1.1 Generate a GitHub Personal Access Token (PAT)

1.  Navigate to GitHub **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**.
2.  Click **Generate new token (classic)**.
3.  **Note:** Give the token a descriptive name (e.g., `apptainer-ghcr-njit`).
4.  **Scope:** Select **`write:packages`**. This will automatically include `read:packages`.
5.  Click **Generate token** and **copy the token immediately**. You will not see it again.

### 1.2 Authorize the PAT for SSO (The Most Commonly Missed Step)

1.  On the Personal access tokens page, find the token you just created.
2.  To the right of the token, click **Configure SSO** and then **Authorize** for the `njit-academics` organization.
3.  This step is mandatory. Without it, you will receive "permission denied" errors when accessing organization packages.

### 1.3 Login with Apptainer

In your terminal, authenticate Apptainer with GHCR.

```bash
apptainer remote login --username YOUR_GITHUB_USERNAME ghcr.io

When prompted for a password, paste your PAT, not your GitHub account password.
