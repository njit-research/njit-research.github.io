# How to Push Docker Images to GHCR and Use with Apptainer

This guide provides the standard workflow for container usage at NJIT: building a **Docker image** on your local system, pushing it to the GitHub Container Registry (GHCR), and then pulling it with Apptainer for use on a cluster environment like Wulver.

This approach uses GHCR as our central, private registry, avoiding the need for Docker Hub.

## Prerequisites

- **On your local machine:** Docker container runtume installed.
- A GitHub account with membership in the `njit-academics` organization.
- A `Dockerfile` for your application.

---

## Part 1: Authentication on Your Local Machine

Before you can push an image, you must authenticate your local Docker client with GHCR. This requires a Personal Access Token (PAT) authorized for Single Sign-On (SSO).

### 1.1 Generate a GitHub Personal Access Token (PAT)

1. Navigate to GitHub **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**.
2. Click **Generate new token (classic)**.
3. **Note:** Give the token a descriptive name (e.g., `docker-ghcr-njit`).
4. **Scope:** Select **`write:packages`**. This automatically includes `read:packages`.
5. Click **Generate token** and **copy the token immediately**. You will not be able to see it again.

### 1.2 Authorize the PAT for SSO (Critical Step)

1. On the Personal access tokens page, find the token you just created.
2. To the right of the token, click **Configure SSO** and **Authorize** it for the `njit-academics` organization.
3. This step is mandatory. Without it, you will receive "permission denied" errors.

### 1.3 Login with Docker

In your terminal on your local machine, use your PAT to log in to GHCR.

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

When prompted for Password, paste your Personal Access Token (PAT). Do not use your GitHub password.

You should see a "Login Succeeded" message. Your local machine is now ready to push images.

---

## Part 2: Building, Tagging, and Pushing Your Docker Image

This is the core workflow for getting your local container to the registry.

### 2.1 Build Your Docker Image

From the directory containing your Dockerfile, build your image as you normally would.

```bash
# This creates an image with the local name 'my-app'
docker build -t my-app .
```
### 2.2 Creating Repository
You will need to create a repository for storing your container images on github.
1. Go to the NJIT-Github organization
2. Scroll down and find repositories and click on New.
3. Make sure the owner is NJIT organization, choose visibility and click create.
4. Create the repository with the following convention your-UCID-Images, replace your UCID with your ID.



### 2.3 Tag the Image for GHCR

Docker needs to know where you intend to push the image. You do this by creating a new tag that includes the registry's address and your organization's path.
We will use our newly created repository to store the container images.

```bash
# Syntax: docker tag LOCAL_IMAGE_NAME ghcr.io/ORGANIZATION/REPOSITORY/IMAGE_NAME:TAG
docker tag my-app ghcr.io/njit-academics/YourRepositoryName/my-app:1.0
```

- `my-app`: The local name of the image you just built.
- `ghcr.io/njit-academics/YourRepositoryName/my-app:1.0`: The full path on GHCR where the image will be stored. You can change `my-app` and the `1.0` version tag as needed.

### 2.4 Push the Image to GHCR

Now, push the newly tagged image to the registry.

```bash
docker push ghcr.io/njit-academics/YourRepositoryName/my-app:1.0
```

Your Docker image is now stored securely on GHCR.

### 2.5 Verify Your Image on GHCR
You can try to pull the image by its tag to confirm it exists and is accessible.
# Example: Pulling by tag
```bash
docker pull ghcr.io/njit-academics/YourRepositoryName/my-app:1.0
```

The pull operation should succeed, indicating the image is available. You can also compare the digest shown during the push or on GHCR with the digest of the pulled image.





---
