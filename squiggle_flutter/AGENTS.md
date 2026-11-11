# General Idea

This application is a infinite canvas diagramming tool. I want to design it in a modular way such that the core application is pretty agnostic to what nodes exist and what properties they have. So when we design new features we should avoid adding them to core root primitives like nodes or base tools, etc... unless they're truely core and general. One general rule on this: if you can only think of one case the behavior would be needed, it probably doesnt go in the core of the app. This lets us eventually pull out core app code into a core package that we can then build lots of different kinds of tools onto really easily. Sometimes we really do need to add a new primitive to the codebase, but often that isn't needed.

# Git usage

Use semantic commit whenever commiting

# Some codebase style guide rules

1. No more than one widget per file. (A stateful widget may have its two classes since they're just one widget)
2. Be concise, don't overcomplicate something if a simpler solution exists.
3. Place code with the feature or responsibility that owns it. Keep related
  operations together; do not split files solely to satisfy a metric.
4. Derive values selected by conditional branches in methods that return the
  result directly, rather than assigning a local variable in each branch.
5. Prefer shorter simpler methods with low nesting.
6. If you are writing a method and own the caller/callee side, then dont be overly defensive if you already have reasonable gaurentees.

## Validation

- Run `flutter analyze` and
  `dart run dart_code_linter:metrics analyze lib packages/data_models/lib test`.
- Analyzer and DCL lint checks must pass. Fix findings without blanket
  suppressions; complexity metrics are to be followed unless you strongly disagree, in which case, present your justification as appropraite in chat/PR comment/PR body.
