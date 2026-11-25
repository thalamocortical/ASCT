# ASCT multiverse

This MATLAB module is integrated into the existing ASCT source connectivity pipeline. It supports real-data multiverse analyses and controlled source-level simulations; it is not a separate processing pipeline.

## Real data

Use the existing ExSetup variables and add the following before the final call (replace `sc_initAnalysis` with `sc_runAnalysis`):

```matlab
multiverse.mode = 'multi';
multiverse.sourceAnalysis = 'ana1';
multiverse.outputName = 'ana1_mv';
multiverse.dryRun = true;
multiverse.maxRuns = 2;
multiverse.factors.con.varNorm = [0 1];
sc_runAnalysis;
```

Use `multiverse.mode='single'` or omit the struct to run the original pipeline. The original `sc_initAnalysis` entry point remains valid. See `templates/EX_SETUP_multiverse_template.m` for a complete example. Existing ASCT dependencies and data setup must be available on the MATLAB path. Configure FieldTrip with `multiverse.fieldtripPath` if needed. The dry run checks input folders and saves a plan/manifest; it does not run ASCT stages. Inspect it before setting `dryRun=false`. Select a fresh `outputName` to avoid collisions.

| Factor | Earliest stage | Required input |
| --- | --- | --- |
| `filter.HPfreq`, `LPfreq`, `bandHz`, `HPord`, `LPord`, `resampleTo` | 0 | raw recordings |
| `loc.norm`, `lambda`, `noiseLev`, `depthWeight`, `method` | 8 | baseline ICA2 |
| `con.decimate`, `lc`, `unc` | 9 | baseline ICA2 and ICLOC |
| `con.mvarOrd`, `orderSelection`, `maxMvarOrder`, `chanSel`, `varNorm`, `removeERP`, `useRange`, `timeRangeStart`, `timeRangeEnd` | 10 | baseline ROI signals |

All real-data factor combinations are enumerated; `maxRuns` limits the count. `filter.bandHz = {[2 48],[8 12]}` pairs cutoff frequencies and must not be combined with separate HPfreq/LPfreq factors. Only MNE localization is supported. Lambda is meaningful under `loc.norm='lambda'`; `noiseLev` must be suitable for your data. AIC order selection and ERP removal are optional. `runStatistics=true` enables STEP11 per variant; `multiverse.statistics` overrides only the STEP11 settings. This does not provide group-level multiverse inference.

`cacheStages=true` enables stage reuse when the plan identifies compatible earlier artifacts. `resume=true` requires an identical saved plan; `retryFailed=true` archives unfinished outputs before retries. `strictArtifacts=true` and `strictLocalization=true` enable additional validation. Use existing individual MRI/head/source models for isolated localization; STEP0 and other legacy stages may still write to shared data paths. Back up data before actual runs. STEP8 remains serial in the integrated ASCT baseline; STEP9 uses an explicit worker limit. Earlier pipeline stages still have their original parallel behavior.

Outputs: `<outputName>__mv_0001`, etc., and `<outputName>__multiverse/` (manifest, plan/checkpoint and optional metrics). `multiverse.metrics=struct('name','artifacts','fn',@asct_multiverse_metric_artifacts)` enables artifact metrics. `asct_multiverse_metric_truth` requires explicit ROI-aligned ground truth. Add the multiverse directory to the path before creating function handles. For historical details see [M1](M1_ENGINE.md), [M2](M2_LOCALIZATION.md) and [M3](M3_STAGE0_METRICS_PARALLEL.md).

## Simulation / reference benchmark

```matlab
addpath(fullfile(pwd,'multiverse'));
results = asct_multiverse_source_demo(fullfile(tempdir,'asct_oracle_demo'));
```

This benchmark uses controlled stable VAR sources, synthetic mixing and trial-level scoring, not a realistic EEG/MEG forward/inverse model. `asct_multiverse_run(study,setupFcn,outputDir)` uses the ASCT execution adapter; provide a full setup and a compatible dataset adapter. For simulated ITAB/MEG signals use `rc.simTemplateDataset` with matching channel order/count and sampling rate. F1 requires explicitly aligned `truthConnectivity(target,source)`. Neither benchmark nor artifact counts establish scientific validity on real recordings.

No tests or CI have been imported or run for this integration. Historical pilot/validation utilities specific to the experimental server are not part of the release workflow.
