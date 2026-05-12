# Push AFRICAD QUANT 001 to GitHub

This folder has its **own** Git repository (nested under `C:\Users\hp`). Always run `git` **from inside** `AFRICAD_QUANT_001` so you only publish this project.

## 1. Create an empty repo on GitHub

GitHub → **New repository** → name e.g. `africad-quant-001` → **no** README/license (avoids merge conflicts) → Create.

Copy the HTTPS URL, e.g. `https://github.com/YOUR_USER/africad-quant-001.git`

## 0. Fix commit author (recommended)

A first commit was created with placeholder author **Your Name / you@example.com**. Set your real identity for this repo, then fix the last commit:

```powershell
cd C:\Users\hp\AFRICAD_QUANT_001
git config user.name "Your Real Name"
git config user.email "your-github-email@example.com"
git commit --amend --reset-author --no-edit
```

Use the same email as your GitHub account (or your GitHub **noreply** address from Settings → Emails).

## 2. In PowerShell (from this folder)

If the repo is already initialized and committed, you only need:

```powershell
cd C:\Users\hp\AFRICAD_QUANT_001

git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git push -u origin main
```

If you are starting from scratch on another machine:

```powershell
cd C:\Users\hp\AFRICAD_QUANT_001
git init
git branch -M main
git add .
git commit -m "Initial commit: AFRICAD QUANT 001 MT5 EA and website"
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git push -u origin main
```

Replace `YOUR_USER/YOUR_REPO` with your real URL.

## 3. Authentication

- **HTTPS:** GitHub may require a **Personal Access Token (classic)** instead of your password.  
  GitHub → Settings → Developer settings → Personal access tokens.
- **SSH:** use `git@github.com:YOUR_USER/YOUR_REPO.git` and set up SSH keys on this PC.

## 4. GitHub Pages (optional, for the website)

Repo → **Settings** → **Pages** → Build: **Deploy from a branch** → Branch `main`, folder `/website` (or `/ (root)` if you move `index.html` to root).  
Your site URL will look like: `https://YOUR_USER.github.io/africad-quant-001/` (exact path depends on your Pages setup).

## Do not push your whole `C:\Users\hp` profile

If you ever run `git` from `C:\Users\hp` with the parent repo, you could add personal files by mistake. Work only in `C:\Users\hp\AFRICAD_QUANT_001` for this project.
