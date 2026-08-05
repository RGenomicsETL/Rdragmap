# Construct a typed Rdragmap contract condition

Construct a typed Rdragmap contract condition

## Usage

``` r
rdragmap_contract_violation(
  message,
  call = NULL,
  code = "invalid_contract",
  details = list()
)
```

## Arguments

- message:

  Human-readable description.

- call:

  Call associated with the violation.

- code:

  Stable machine-readable code.

- details:

  Structured condition details.

## Value

An `rdragmap_contract_violation` condition.
