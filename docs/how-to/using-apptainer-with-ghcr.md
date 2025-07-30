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
```bash
-----------------------------------------------------------------------------------------------------------------------------
### Core Workflow: From Base Image to GHCR
This workflow allows you to pull any public base image (e.g., from Docker Hub), add your own software and configurations, and push the final, self-contained Apptainer image to the njit-academics GHCR for storage and sharing.
2.1 Create a Definition File Based on a Public Image
Create an Apptainer definition file (e.g., my-app.def) that uses a public image as its base.
Example my-app.def:

Bootstrap: docker
From: ubuntu:22.04

%post
    # This section runs during the build to install software
    # Add your modifications here
    apt-get update && apt-get install -y --no-install-recommends your-custom-software
    # Clean up apt cache to reduce image size
    apt-get clean && rm -rf /var/lib/apt/lists/*

%runscript
    # This is the default command that runs when the container is executed
    echo "Running the modified container..."
    exec your-custom-software

2.2 Build Your Modified SIF Image
Apptainer will automatically pull the base image from Docker Hub and execute the build steps defined in your file.
'''bash
# Sudo is often required for the build process to manage permissions
sudo apptainer build my-app.sif my-app.def
'''bash
This command produces a single, executable file: my-app.sif.

2.3 Push the SIF Image to GHCR
Push your final image to the njit-academics organization repository using the oras:// prefix.
'''bash
# Push to the 'container-images' repository within the organization
apptainer push my-app.sif oras://ghcr.io/njit-academics/container-images/my-app:1.0
'''bash

Note: This example pushes to an image named my-app:1.0 inside the container-images repository. You may need to replace container-images or my-app with the correct names for your project. Pushing directly to the organization requires appropriate permissions.

### Running the Deployed Image
Anyone with read access can now pull and run your image:
'''bash
# Pull and build the SIF file
apptainer build my-app.sif docker://ghcr.io/njit-academics/container-images/my-app:1.0

# Run the container's default command
./my-app.sif

# Or get an interactive shell inside it
apptainer shell my-app.sif
'''bash

### Troubleshooting
Error: FATAL: ... forbidden: denied
This is an authentication error. Check the following in order:
SSO Authorization: Did you successfully "Configure SSO" and "Authorize" the PAT for njit-academics? This is the #1 cause.
PAT Scope: Does your PAT have the write:packages scope?
Credentials: Did you use your GitHub username and the PAT (not your password) when running apptainer remote login?
URI Prefixes Reminder:
docker://: Use when pulling an image or as the From: line in a definition file.
oras://: Use when pushing a local .sif file to a registry.



