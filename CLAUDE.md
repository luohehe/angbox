# CLAUDE.md

This file provides guidance for AI assistants working with this repository.

## Project Overview

**angbox** is a personal playground repository for experimentation and testing. It currently serves as an open canvas for various coding experiments.

## Repository Structure

```
angbox/
├── README.md          # Project description
└── CLAUDE.md          # AI assistant guidance (this file)
```

## Current State

This repository is minimal by design - it's a playground for experimentation. There are currently:
- No source code files
- No build system configured
- No dependencies or package management
- No CI/CD pipelines

## Development Guidelines

When adding new experiments or code to this repository:

### General Conventions
- Keep experiments self-contained when possible
- Document any new tools or frameworks added
- Use descriptive names for files and directories

### Git Workflow
- Create feature branches for new experiments
- Write clear commit messages describing changes
- The main branch should remain stable

### Adding New Projects

When adding a new project/experiment:
1. Create a dedicated directory if the experiment has multiple files
2. Include a README or comments explaining the experiment's purpose
3. Update this CLAUDE.md if new build tools or conventions are introduced

## Commands

Currently no build commands are configured. When projects are added, document their commands here:

```bash
# Placeholder for future build commands
# npm install / npm run build
# python -m pip install -r requirements.txt
# make build
```

## Testing

No testing framework is currently configured. When tests are added:
- Document the testing framework used
- Include instructions for running tests
- Note any test coverage requirements

## Dependencies

No dependencies are currently managed. When package management is added:
- Document the package manager (npm, pip, cargo, etc.)
- Keep dependency files (package.json, requirements.txt, etc.) up to date
- Note any system-level dependencies required

## Notes for AI Assistants

- This is a playground repository - experimentation is encouraged
- When adding code, follow best practices for the language being used
- Keep changes focused and well-documented
- If introducing new tools or frameworks, update this file accordingly
- Be mindful that experiments here may be temporary or incomplete
