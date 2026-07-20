# Branching Convention

All work happens on a feature branch and merges into `main` via pull request —
no direct commits to `main`.

## Naming rule

```
feature/<short-description>
fix/<short-description>
```

Examples used in this project:

- `feature/login` — authentication service (Week 1)
- `feature/database` — inventory/database schema and models
- `feature/prediction` — demand prediction engine
- `feature/payroll` — staff & payroll module
- `fix/<bug-description>` — bug fixes

## Workflow

1. Branch off the latest `main`: `git checkout -b feature/login`
2. Commit small, focused changes.
3. Push the branch and open a pull request into `main`.
4. At least one other group member reviews before merging.
5. Delete the branch after it's merged.
