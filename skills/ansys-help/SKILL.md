---
name: ansys-help
description: 'Searches local Ansys Help documentation by user-provided path and keywords, then returns high-relevance snippets quickly. Covers software names (HFSS, Q3D, Maxwell, Icepak, SIwave), feature modules (modeling, meshing, solving, post-processing, parallel computing), operation how-tos (fillet, mesh setup, material setup, ports/boundaries, S-parameters, radiation patterns), use-case names (microstrip antenna, via), and specific errors.'
---

# Ansys Help Search

Use this skill to quickly search local Ansys Help documentation and return actionable results.

This skill is optimized for EM and CAE users who need fast lookup for:

- Software names: HFSS, Q3D, Maxwell, Icepak, SIwave, Mechanical, Fluent, etc.
- Function modules: modeling, meshing, solver setup, post-processing, parallel/distributed computing
- How-to operations: fillet, mesh controls, material assignment, ports/boundary conditions, S-parameters, radiation patterns
- Use-case names: microstrip antenna, via, transformer, busbar, cable harness
- Specific issues: error messages, warnings, solver failures

## When to Use This Skill

- The user provides a local Ansys Help path and asks to search by keywords.
- The user asks where a feature is documented in Ansys Help.
- The user asks how to perform an operation in HFSS/Q3D/Maxwell.
- The user asks to find documentation for an Ansys error or warning.

## Input Contract

Required inputs:

1. `help_path`: local path to Ansys Help content (folder or file)
2. `query`: one or more keywords from software/module/how-to/use-case/error

Optional inputs:

- `top_k`: number of results to return (default: 10)
- `file_filter`: limit search to specific docs (for example HFSS-only)
- `version_hint`: for example 2023R2, 2024R1

Automation helper:

- PowerShell script: `skills/ansys-help/scripts/search-ansys-help.ps1`
- This script executes the same search strategy and returns ranked hits directly from local docs.

## Supported Local Content

Best supported:

- HTML/HTM help folders
- TXT/MD/XML/LOG files
- PDF manuals

Conditionally supported:

- CHM files: if only `.chm` exists, extract first, then search extracted files

If the path is inaccessible or unsupported, report the exact issue and provide a next action.

## Required Workflow

### Step 1: Validate Path and Determine Document Type

1. Confirm `help_path` exists.
2. Determine whether `help_path` is a folder, a single file, or mixed content.
3. Detect key file types (`.html`, `.htm`, `.pdf`, `.chm`, `.txt`, `.xml`, `.log`).
4. If only `.chm` is available, mark that extraction is needed before content search.

### Step 2: Normalize and Expand Query

Build an expanded query set from the original user text:

- Keep original keywords unchanged.
- Add normalized aliases and common variants.
- Preserve software tokens as high-priority anchors.

Recommended expansion examples:

- `建模` -> `modeling|geometry|3d modeler|layout`
- `网格` -> `mesh|meshing|mesh operation|adaptive`
- `求解` -> `solve|solver|analysis setup|solution setup`
- `后处理` -> `postprocess|results|field plot|report`
- `并行计算` -> `parallel|distributed|HPC|remote solve`
- `端口` -> `port|wave port|lumped port|terminal`
- `边界条件` -> `boundary|radiation|PEC|PMC|impedance`
- `S参数` -> `S parameter|S11|S21|network data`
- `方向图` -> `radiation pattern|far field|gain pattern`
- `Error` -> `error|failed|warning|exception|cannot`

### Step 3: Perform Layered Search

Use a fast layered strategy:

1. Exact phrase search for original query.
2. Case-insensitive multi-keyword search across expanded terms.
3. Restrict by software token when provided (HFSS/Q3D/Maxwell).
4. For error queries, add targeted search for sections like:
   - cause
   - reason
   - solution
   - workaround
   - troubleshooting

Prioritize speed and high-signal snippets over full-document dumping.

### Step 4: Rank and De-duplicate Results

Rank with this priority logic:

1. Exact match in title/heading
2. Same-software match (for example query contains HFSS and result is in HFSS docs)
3. Snippet includes operation verb and target object (for example fillet + edge)
4. Snippet includes error code + fix terms (solution/workaround)
5. Recent version match if version hint exists

Remove duplicate snippets that point to identical section text.

### Step 5: Return Fast, Structured Output

Return compact, practical results.

Required output shape:

1. Search Summary
   - normalized keywords
   - searched path
   - scanned file types
   - result count
2. Top Matches
   - rank index
   - source file path
   - optional line number or section title
   - 1-3 line snippet
   - relevance reason
3. Next-Step Tip
   - one short tip to refine search (for example add exact error text or module)

## Output Example (Format)

- Summary: path=..., keywords=..., results=...
- [1] source: ...
  snippet: ...
  why relevant: ...
- [2] source: ...
  snippet: ...
  why relevant: ...

## Script Quick Run

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\ansys-help\scripts\search-ansys-help.ps1 \
   -HelpPath "D:\AnsysHelp" \
   -Query "HFSS","wave port","S参数" \
   -TopK 10
```

## Accuracy and Safety Rules

- Do not fabricate document content.
- Do not claim a result without path evidence.
- Quote only short snippets needed for context.
- If nothing is found, return no-hit status and suggest refined keywords.
- Clearly separate doc facts from assistant inference.

## Troubleshooting

### Problem: No results for known keyword

Actions:

- Retry with software-specific prefix (for example HFSS + keyword).
- Expand Chinese/English synonyms.
- Search singular/plural and abbreviation variants.
- Check whether docs are compressed CHM and need extraction.

### Problem: Error text too generic

Actions:

- Ask user for exact error string or code.
- Search with 5-10 words around the error.
- Add solver stage keyword (mesh/solve/postprocess).

### Problem: Results are too broad

Actions:

- Add module constraint (for example mesh operation).
- Add object constraint (for example wave port, via, substrate).
- Limit to a single product doc set.

## Minimal Deliverable Standard

This skill is complete only when it returns evidence-based, ranked, and directly usable search hits from the user-provided local Ansys Help path.
