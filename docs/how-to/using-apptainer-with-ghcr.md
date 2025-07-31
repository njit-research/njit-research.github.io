# How to Push Docker Images to GHCR and Use with Apptainer

This guide provides the standard workflow for container usage at NJIT: building a **Docker image** on your local system, pushing it to the GitHub Container Registry (GHCR), and then pulling it with Apptainer for use on a cluster environment like Wulver.

This approach uses GHCR as our central, private registry, avoiding the need for Docker Hub.

## Prerequisites

- **On your local machine:** Docker Desktop (or another Docker-compatible environment) installed.
- **On the cluster:** Access to Apptainer (or Singularity).
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

### 2.2 Tag the Image for GHCR

Docker needs to know where you intend to push the image. You do this by creating a new tag that includes the registry's address and your organization's path.

```bash
# Syntax: docker tag LOCAL_IMAGE_NAME ghcr.io/ORGANIZATION/REPOSITORY/IMAGE_NAME:TAG
docker tag my-app ghcr.io/njit-academics/container-images/my-app:1.0
```

- `my-app`: The local name of the image you just built.
- `ghcr.io/njit-academics/container-images/my-app:1.0`: The full path on GHCR where the image will be stored. You can change `my-app` and the `1.0` version tag as needed.

### 2.3 Push the Image to GHCR

Now, push the newly tagged image to the registry.

```bash
docker push ghcr.io/njit-academics/container-images/my-app:1.0
```

Your Docker image is now stored securely on GHCR.

---

## Part 3: Using the Image on the Cluster with Apptainer

Once the image is in GHCR, anyone with read access can pull it onto a cluster (like Wulver) using Apptainer.

1. **Log in to the cluster.**

2. **Authenticate Apptainer** (if not done already): You will need to perform the same PAT/SSO authentication for Apptainer on the cluster as you did for Docker locally.

   ```bash
   # On the cluster, run this once:
   apptainer remote login --username YOUR_GITHUB_USERNAME ghcr.io
   # Paste your PAT when prompted for a password.
   ```

3. **Pull the image**: Use `apptainer build` to pull the Docker image from GHCR and convert it into a single Apptainer (.sif) file.

   ```bash
   # Apptainer uses the docker:// prefix to fetch from OCI registries
   apptainer build my-app.sif docker://ghcr.io/njit-academics/container-images/my-app:1.0
   ```

4. **Run your container**: You can now run your application using the generated `my-app.sif` file.

   ```bash
   ./my-app.sif
   # Or
   apptainer exec my-app.sif <your-command>
   ```

---

## Alternative: Pushing an Existing Apptainer (SIF) Image

If you built your image directly with Apptainer (using a `.def` file) instead of Docker, you can push the `.sif` file using the `oras://` prefix.

```bash
# Ensure you are logged in with Apptainer first
apptainer remote login ghcr.io

# Push the SIF file
apptainer push my-app.sif oras://ghcr.io/njit-academics/container-images/my-app:1.0
```
