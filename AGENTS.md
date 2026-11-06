# TypeNote Agent Guide

## Project Scope

TypeNote is the macOS keyboard sound app. See [README](README.md) for setup, SoundFont inputs, and the project map.

## Required Constraints

- Push only when the user explicitly requests it for the current change.
- Keep real team settings in the local configuration. Use the existing template for setup changes.
- Keep app changes separate from the screenshot generator and release pipeline.

## Verification

- Build the `TypeNote` scheme in `TypeNote.xcodeproj` for app changes. Select affected checks from the Xcode project and package.

## Read for This Task

- Local setup or SoundFont changes → README.
- Screenshot generator changes → [scoped instructions](screenshots-generator/AGENTS.md).
- Release or update feed changes → inspect `release.sh` and the current appcast before acting.
