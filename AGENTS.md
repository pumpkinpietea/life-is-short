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

## Language and Specifications

- Communicate with the developer in Japanese.
- Write repository documents, specifications, code comments, issues, and PRs in English.
- Localize user-facing app and widget text into Japanese, English, and Indonesian.
- Maintain requirements, design, tasks, acceptance criteria, and verification evidence under `specs/`.
- Keep private conversational planning out of public repository and GitHub content.
- Use synthetic milestones and images for tests and shared evidence.

## Current Development Authority

- The developer authorized autonomous v0.1 implementation, issue creation, scoped branches and PRs, and relevant verification on 2026-10-25.
- Resolve routine implementation choices within the accepted specifications and record decisions without repeated confirmation.
- Scoped branch pushes needed for the requested PR workflow are authorized. Do not push directly to `main` or bypass branch protection.
- App Store submission and new external service provisioning remain separate from development verification.

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
