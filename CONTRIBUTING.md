# Contributing

## Workflow

1. Create an issue describing the problem or feature.
2. Create a branch such as `feature/event-log-triage`.
3. Keep diagnostic commands read-only unless the change belongs to the future repair module.
4. Return structured objects from collection functions.
5. Add or update Pester tests.
6. Run PSScriptAnalyzer and Pester before opening a pull request.
7. Document security and privilege implications.

## Commit examples

- `feat: add DNS cache collection`
- `fix: handle systems without BitLocker cmdlets`
- `docs: explain TCP connection states`
- `test: validate report folder creation`
