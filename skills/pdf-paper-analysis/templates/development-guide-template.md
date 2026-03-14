# Development Guide Template

## 1. Implementation Goal

- Target capability:
- Expected inputs:
- Expected outputs:

## 2. Recommended Software Architecture

- Geometry module:
- Material module:
- Solver module:
- Network assembly module:
- Validation module:
- Optimization module:

## 3. Data Model

### Core objects

- Material
- Geometry
- SolveOptions
- ResultSet

### Suggested fields

| Object | Fields |
|---|---|
| Material |  |
| Geometry |  |
| SolveOptions |  |
| ResultSet |  |

## 4. Solver Pipeline

1. Parse inputs.
2. Precompute static geometry terms.
3. Evaluate one frequency point.
4. Assemble matrices or sub-networks.
5. Solve port quantities.
6. Convert to target metrics.
7. Sweep frequency or design variables.

## 5. Pseudocode

```text
function solve_case(inputs):
    prepare_geometry()
    prepare_materials()
    for each frequency:
        evaluate_submodels()
        assemble_global_system()
        solve_ports()
        postprocess_metrics()
    return results
```

## 6. Numerical Considerations

- Required libraries:
- Special functions:
- Matrix conditioning issues:
- Convergence or truncation strategy:
- Caching opportunities:

## 7. Validation Strategy

- Unit tests:
- Regression cases:
- Comparison to simulation or measurement:
- Error metrics:

## 8. Optimization Strategy

- Sweep variables:
- Objective function:
- Constraints:
- Search method:

## 9. Risks and Known Gaps

- Formula transcription risk:
- Applicability risk:
- Numerical stability risk:

## 10. Suggested Next Implementation Steps

1. 
2. 
3. 