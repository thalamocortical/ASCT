# ASCT
Atlantis Source Connectivity Toolbox for EEG/MEG

ASCT supports the existing singleverse pipeline and an optional multiverse mode.
Existing ExSetup scripts calling `sc_initAnalysis` continue to use singleverse.
To enable the new dispatcher, use `sc_runAnalysis` and set `multiverse.mode` to
`single` or `multi`. See [the multiverse guide](multiverse/README.md) and
[the ExSetup template](templates/EX_SETUP_multiverse_template.m).

The usual ASCT/FieldTrip/MMULTAR installation and experiment-specific settings
are required. The multiverse is an opt-in extension; this integration has not
been run or scientifically validated. See [integration notes](MULTIVERSE_INTEGRATION.md).
