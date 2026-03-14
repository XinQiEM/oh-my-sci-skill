---
name: pdf-paper-analysis
description: 'Extracts PDF literature, derives core algorithms and implementation principles, and writes principle documents and development guides. Use when asked to analyze a PDF paper, read a PDF article, infer formulas or algorithm workflows from literature, explain implementation details, or generate technical documentation from research papers.'
---

# PDF Paper Analysis

Use this skill to turn a PDF paper into engineering-ready documentation.

The skill is designed for technical literature such as signal integrity papers, EM modeling papers, optimization papers, numerical methods papers, and other research documents that contain formulas, modeling assumptions, algorithm steps, or implementation hints.

## When to Use This Skill

- The user asks to analyze a PDF paper or literature.
- The user wants core algorithms or formulas extracted from a paper.
- The user wants implementation principles inferred from a research article.
- The user wants a principle document, technical note, or development guide generated from PDF literature.
- The user wants a paper converted into software design guidance.

## Output Contract

Default output artifacts:

1. `<pdf-stem>-principle-analysis.md`
2. `<pdf-stem>-development-guide.md`

If the user explicitly asks for a single document, merge both outputs into one file. Otherwise keep the two-document structure.

## Prerequisites

- A target PDF must exist in the workspace, or the user must provide a path/URL.
- Prefer machine-readable PDFs.
- Python is the default extraction path.
- Preferred extraction package: `pypdf`.

If the PDF is scan-only and OCR tooling is unavailable:

- State that equation extraction quality is limited.
- Continue with structure, captions, headings, and readable paragraphs.
- Do not invent unreadable formulas.
- Recommend OCR or user-provided text as the fallback.

## Required Workflow

### Step 1: Identify the Source PDF

1. Search the workspace for PDF files.
2. If only one PDF exists, use it.
3. If multiple PDFs exist and the target is unclear, ask the user which one to analyze.
4. Record the PDF stem because it will be used in output file names.

### Step 2: Extract Text Safely

1. Configure the Python environment before any Python execution.
2. Install `pypdf` if needed.
3. Extract text page by page.
4. Capture page numbers in notes because later derivation must trace back to the source.
5. If equations are garbled in extracted text, read surrounding explanatory text and references to reconstruct the algorithm structure.

Do not copy long passages from the paper into the output. Summarize and transform into original technical writing.

### Step 3: Build an Evidence Map

Before deriving the algorithm, create a compact evidence map from the paper:

- Title, authors, venue, year
- Problem statement
- Claimed contribution
- Modeling assumptions
- Core variables and symbols
- Equations or formula groups
- Validation method
- Design variables or optimization variables
- Reported conclusions

If formulas are partially unreadable, explicitly mark them as:

- `confirmed from text`
- `structure inferred from context`
- `requires source-paper verification`

### Step 4: Derive the Core Algorithm

Turn the paper into an implementation-oriented algorithm by answering these questions:

1. What physical or mathematical problem is being solved?
2. What are the model inputs and outputs?
3. What sub-models or stages compose the method?
4. Which terms are analytical, numerical, empirical, or fitted?
5. What assumptions make the method computationally efficient?
6. What parts dominate accuracy and bandwidth?

When deriving the algorithm:

- Separate facts from inference.
- Prefer normalized notation over broken OCR notation.
- Preserve original symbol meaning when it is clear.
- If exact constants are unreadable, describe the computational role of the term instead of fabricating it.
- Highlight where cited references are needed to recover exact closed forms.

### Step 5: Infer the Implementation Principle

Translate the paper into a software architecture:

- Input parameter schema
- Geometry/material/model objects
- Frequency-domain or time-domain solver structure
- Matrix assembly steps
- Special function dependencies
- Numerical stability requirements
- Validation flow against simulation or measurement
- Optimization loop if the paper includes parameter sweeps

Preferred implementation outputs:

- module breakdown
- data classes or structs
- solver pipeline
- pseudocode
- convergence or truncation strategy
- error metrics

### Step 6: Write the Principle Analysis Document

Create `<pdf-stem>-principle-analysis.md` using `templates/principle-analysis-template.md` as the structure baseline.

The principle document must explain:

- what the paper studies
- why the method works
- how the equations chain together conceptually
- what the key approximations are
- which claims are directly supported by the paper
- which details still need source verification

### Step 7: Write the Development Guide

Create `<pdf-stem>-development-guide.md` using `templates/development-guide-template.md` as the structure baseline.

The development guide must explain:

- how to implement the model in software
- how to structure modules
- how to solve one frequency point or one simulation case
- how to perform sweeps or optimization
- how to validate against reference data
- where formula uncertainty remains

### Step 8: Quality Bar

Before finishing, check that the outputs satisfy all of the following:

- The output is not a generic summary.
- The algorithm is decomposed into executable stages.
- The implementation guidance is concrete enough to start coding.
- Uncertain equations are clearly labeled.
- Long copyrighted excerpts are not reproduced.
- Page-level evidence is retained in notes or prose where useful.

## Recommended File-Naming Rules

For a PDF named `my-paper.pdf`, use:

- `my-paper-principle-analysis.md`
- `my-paper-development-guide.md`

If the file stem is too long, shorten it conservatively while preserving uniqueness.

## Troubleshooting

### Problem: Extracted formulas are corrupted

Actions:

- Read the surrounding explanatory text.
- Compare with figure captions and validation plots.
- Inspect cited references for the exact equation source.
- Write the algorithm structure first, then mark exact formula transcription as pending verification.

### Problem: The PDF is image-only

Actions:

- Try OCR if tools are available.
- If OCR is not available, state the limitation clearly.
- Still produce a partial analysis from headings, captions, tables, and readable text.

### Problem: The paper mixes derivation and experiment

Actions:

- Split the analysis into model derivation, implementation implications, and validation findings.
- Do not confuse empirical observations with the actual core algorithm.

### Problem: The paper contains only a high-level method

Actions:

- Infer the implementation boundary carefully.
- Mark inferred software design choices as engineering recommendations, not paper facts.

## Minimal Deliverable Standard

The skill is only complete when it produces documentation that a developer can use to begin implementation without reopening the paper for every paragraph.

## Bundled Templates

- `templates/principle-analysis-template.md`
- `templates/development-guide-template.md`