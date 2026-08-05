# Construct a typed Rdragmap operational error

Construct a typed Rdragmap operational error

## Usage

``` r
rdragmap_error_value(
  message,
  kind = c("input", "output", "process"),
  code,
  details = list(),
  source = NULL,
  operation = character(),
  status = integer()
)
```

## Arguments

- message:

  Human-readable description.

- kind:

  Operational error category.

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

## Value

An `RdragmapErrorValue` subclass.
