# A typed Rdragmap operational error value

Invalid API calls signal
[`rdragmap_contract_violation()`](https://rgenomicsetl.github.io/Rdragmap/reference/rdragmap_contract_violation.md)
conditions. Expected unavailable inputs, occupied outputs, unavailable
executables, and native child-process failures are returned as values.

## Usage

``` r
RdragmapErrorValue(
  message = character(0),
  code = character(0),
  details = list(),
  source = NULL,
  operation = character(0),
  status = integer(0)
)

RdragmapInputErrorValue(
  message = character(0),
  code = character(0),
  details = list(),
  source = NULL,
  operation = character(0),
  status = integer(0)
)

RdragmapOutputErrorValue(
  message = character(0),
  code = character(0),
  details = list(),
  source = NULL,
  operation = character(0),
  status = integer(0)
)

RdragmapProcessErrorValue(
  message = character(0),
  code = character(0),
  details = list(),
  source = NULL,
  operation = character(0),
  status = integer(0)
)
```

## Arguments

- message:

  Human-readable description.

- code:

  Stable machine-readable code.

- details:

  Structured error details.

- source:

  Optional source condition or backend value.

- operation:

  Empty or one stable child-process operation identifier.

- status:

  Empty or one child-process exit status.
