---
description: Generate conventional commit message from staged changes
allowed-tools: Bash(git diff:*), Bash(git status:*), Bash(git log:*), Bash(git commit:*), Bash(git add:*), AskUserQuestion
---

Analyze staged changes and propose a commit message.

1. Run `git diff --staged` to see changes
2. Run `git status` to see staged files
3. Run `git log --oneline -5` to match repo's commit style
4. Generate commit message following conventional commits:
   - Format: `<type>[optional scope]: <description>`
   - Types: feat, fix, docs, style, refactor, test, chore, build, ci, perf
   - Keep subject line under 72 chars
   - Add body if changes are complex
5. Present message to user for review
6. Use AskUserQuestion tool to ask if they want to proceed, modify, or cancel
7. Only commit after user approval
