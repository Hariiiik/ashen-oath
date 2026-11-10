# Windows setup — Godot, Git, Codex

## Prerequisites
- Install Godot 4 standard from https://godotengine.org/download/windows/
- Install Git for Windows from https://git-scm.com/downloads/win
- Install VS Code optionally: https://code.visualstudio.com/

## Download and unzip
Extract `ashen_oath_starter.zip` into `C:\dev`. The ZIP already contains an `ashen-oath` folder.
The resulting path should be `C:\dev\ashen-oath\project.godot`.

## Verify Godot
Godot Project Manager -> Import -> select `project.godot` -> Edit -> F5.
The dark "ASHEN OATH" placeholder screen should appear.

## Install Codex CLI (PowerShell)
The current official standalone Windows installer command is:
```powershell
powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
```
Alternatively, if Node.js/npm is already installed:
```powershell
npm install -g @openai/codex
```
Verify:
```powershell
codex --version
```

## Sign in
```powershell
cd C:\dev\ashen-oath
codex
```
Choose **Sign in with ChatGPT** and use the intended ChatGPT account. Account access and usage limits depend on the active plan. `AGENTS.md` is automatically used as repository context by Codex.

## First safe task
Inside Codex enter:
```
Read AGENTS.md and tasks/001-foundation-audit.md. Perform the foundation audit only. Do not implement gameplay. Report the exact checks you ran and any changes made.
```

## Initialize local Git repository
```powershell
cd C:\dev\ashen-oath
git init
git add .
git commit -m "chore: initialize Ashen Oath Godot foundation"
```
If the commit asks for author identity:
```powershell
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```
Then retry the commit. These example identity values must be replaced with your own.

## Optional private GitHub remote
Create an empty PRIVATE repository named `ashen-oath` on https://github.com/new (do not pre-create README/gitignore if using this starter). Then:
```powershell
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/ashen-oath.git
git push -u origin main
```
Replace `YOUR_USERNAME`. GitHub login/credential flow may be prompted. Never paste personal access tokens into chats.

## Useful commands
```powershell
git status
git log --oneline -5
codex --version
```

## Troubleshooting
- `codex` not found: reopen PowerShell after installation and check installation PATH.
- Godot project not imported: make sure you selected `project.godot`, not only the folder.
- Git commit missing identity: set `user.name` and `user.email`.
- Do not use `--dangerously-bypass-approvals-and-sandbox` for routine work.
