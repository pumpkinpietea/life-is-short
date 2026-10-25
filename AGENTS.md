# AGENTS.md

## Project Scope

This repository contains the Life Is Short iOS application.

Treat this repository as the primary working scope.

## Development

- Use Swift and SwiftUI.
- Prefer standard Apple frameworks over third-party dependencies.
- Follow specifications under `specs/`.
- Keep implementations simple and maintainable.
- Build and test changes whenever practical.

## Working Permissions

You may autonomously:

- Read, create, modify, and delete files inside this repository.
- Run builds and tests.
- Run Xcode command-line tools.
- Run Git read operations such as status, diff, log, and branch.
- Create local Git commits when appropriate.

## Outside This Repository

Files outside this repository may be read when necessary for development.

Do not modify files outside this repository unless the task genuinely
requires it.

If an external modification is required:

1. Explain why it is necessary.
2. Identify the exact file or directory.
3. Ask for user approval before modifying it.

Never modify unrelated repositories.

## Safety

Do not:

- Modify SSH keys or credentials.
- Modify global Git configuration.
- Modify macOS system settings.
- Execute destructive commands outside this repository.
- Store secrets or credentials in the repository.
- Force-push or rewrite Git history unless explicitly requested.

## Git

- Keep changes focused on the current task.
- Review `git diff` before committing.
- Never commit secrets.
- Do not push unless explicitly requested.