# Git usage

Use semantic commit whenever commiting

# General Rules
1. No more than one widget per file. (A stateful widget may have its two classes since they're just one widget)
2. Be concise, don't overcomplicate something if a simpler solution exists.

## Code organization

- Place code with the feature or responsibility that owns it. Keep related
  operations together; do not split files solely to satisfy a metric.
- Name helper files after their responsibility. Avoid introducing generic
  `helpers.dart`, `utils.dart`, or `common.dart` files.
- Inspect existing implementations and callers before adding a helper.
- Derive values selected by conditional branches in methods that return the
  result directly, rather than assigning a local variable in each branch.
- Theme code must not depend on application behavior or widgets. Persistence
  models in `packages/data_models` must remain independent of Flutter and the app.
- When extracting code, update all callers and move its tests with it.

## Comments

- Explain contracts, invariants, units, ownership, ordering requirements,
  workarounds, or non-obvious decisions. Omit comments that merely paraphrase a
  name or narrate obvious code; do not document every declaration by default.
- Update or remove affected comments when behavior changes. Do not invent
  explanations for existing behavior.
- TODOs must describe concrete unfinished behavior. Work deferred beyond the
  current change must reference a real issue; never invent issue references.
- Remove placeholder comments and vague improvement notes in code you change.

## Validation

- Run `flutter analyze` and
  `dart run dart_code_linter:metrics analyze lib packages/data_models/lib test`.
- Analyzer and DCL lint checks must pass. Fix findings without blanket
  suppressions; complexity metrics remain advisory review signals.
- Complexity 15, nesting 3, source lines 60, and methods per class 20 are review
  thresholds. Use 30 source lines as an additional review signal for logic-heavy
  methods; preserve cohesive declarative UI and field mappings.
- Run the tests relevant to the change.
