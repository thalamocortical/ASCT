# Integration notes

Base: supplied ASCT-main.zip (singleverse). Source: supplied asct_experimental.zip,
checked-out feature/multiverse_analysis, commit 46041b6 (M1–M3 engine plus M4 validation tooling in source archive).
The newer M5–M10 branches visible in the embedded Git history were not merged.

- New dispatcher `sc_runAnalysis.m` and unified ExSetup template. Existing `sc_initAnalysis` remains the original entry point with two field-default corrections (`deep_weight`, `useRange`).
- Imported the multiverse MATLAB functions, including source-level reference benchmarks and optional verification helpers. Did not import tests/, CI workflows, demo fixtures, nested ZIP files, .git, Mac metadata, or server-specific root Flanker setups/audits and M4 validation directory.
- STEP8 guards shared source-model/leadfield writes, retaining ASCT-main's serial localization loop; STEP9 adds separate ICA2/ICLOC inputs, MRI-write guard and explicit worker limit; STEP10 fixes alternate ROI path, supports optional ERP/AIC and fixes the simulation bootstrap input filename. Baseline `mv.diagnost=0` retained.
- `sc_arstat.m` uses the actual ROI donor and retains full residual variance precision; this also affects reports in singleverse. `sc_preproc_meg_itab.m` supports explicit simulation header templates and checks signal dimensions.
- Preserved all existing singleverse files, libraries, classification, artifact rejection, segmentation, newer cprintf, and unrelated code. No wholesale replacement by experimental tree; no baseline files deleted.
- No MATLAB, FieldTrip or MMULTAR execution, tests, git push or scientific validation performed. Some inherited limitations remain: STEP0/shared MRI realignment side effects, dataset-subset/donor matching, non-source-stage parallel behavior, and machine-specific dependency setup need validation on real data. The existing multiverse cache/resume logic is not a guarantee of scientific equivalence.

This is a reviewable development integration, not a validated release.
