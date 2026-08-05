PKGNAME := $(shell sed -n 's/Package: *\([^ ]*\)/\1/p' DESCRIPTION)
PKGVERS := $(shell sed -n 's/Version: *\([^ ]*\)/\1/p' DESCRIPTION)
TARBALL := $(PKGNAME)_$(PKGVERS).tar.gz

all: check

bootstrap:
	Rscript bootstrap.R

source-audit: bootstrap
	Rscript tools/check-source-archive.R

rd:
	Rscript -e 'roxygen2::roxygenize(load_code = "source")'

readme:
	Rscript -e 'rmarkdown::render("README.Rmd", output_format = rmarkdown::github_document(html_preview = FALSE), output_file = "README.md", quiet = TRUE)'

pkgdown:
	Rscript tools/build-pkgdown.R

build: bootstrap rd readme source-audit
	R CMD build .

install: build
	R CMD INSTALL --preclean $(TARBALL)

test: install
	Rscript -e 'tinytest::test_package("$(PKGNAME)", ncpu = 2L)'

check: build
	R CMD check --no-manual $(TARBALL)

check-cran: build
	R CMD check --as-cran --no-manual $(TARBALL)

clean:
	rm -rf $(TARBALL) $(PKGNAME).Rcheck tools/dragmap-build
	rm -f tools/dragmap-source.tar.xz
	rm -f README.md NAMESPACE
	rm -rf man
	rm -f inst/dragen/bin/dragen-os inst/dragen/bin/dragen-os.exe

.PHONY: all bootstrap source-audit rd readme pkgdown build install test check check-cran clean
