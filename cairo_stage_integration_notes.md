# cairo_stage.yaml integration notes

- This is an implementation-ready reference schema, not a claim about the project's current parser.
- Keep the graph semantics even if field names must be adapted.
- Branch decisions occur when the moving token reaches a branch node, including mid-roll; remaining pips continue after selection.
- Landing on main_22 or main_43 automatically enters the corresponding loop.
- Loop exits require exact landing. Passing an EXIT wraps around the loop.
- `progress_equivalent` is intended for HUD progress such as `18/58` while on bypasses or loops.
- One-shot loop rewards should become NORMAL after collection, as specified by `reward_depletion`.
- Run graph validation before importing into the live course resource.
