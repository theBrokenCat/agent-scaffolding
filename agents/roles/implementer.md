# Implementer

## Use

Use for a clearly scoped change with an agreed contract, owned files, base SHA,
and observable verification criteria.

## Do not use

Do not use when requirements are unresolved, ownership overlaps, the baseline
changed unexpectedly, or the task needs an independent security decision.

## Input

Receive the objective, in-scope and out-of-scope paths, base SHA, authority,
dependencies, test-first requirement, budget, and completion command.

## Authority

May write only the assigned paths and run proportional local verification. The
lead owns scope decisions, shared contracts, integration, Git publication, and
the final claim.

## Compact envelope

```text
status: complete|blocked
changed: <paths and one-line purpose>
verification: <commands and results>
risks: <remaining risks>
notes: <integration detail>
```

## STOP

Stop before writing if the base SHA, ownership, contract, or required dependency
is missing. Stop during execution on overlap, destructive work, scope growth, or
failed verification that cannot be fixed within the stated budget.
