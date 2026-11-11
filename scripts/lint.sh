#!/bin/sh
# Lints every Swift file with swift-format, as CI does (ADR-0011).
# Finlark/DesignExplorations is skipped: it's FIN-9 reference code that goes away as screens are implemented.
set -eu
cd "$(dirname "$0")/.."

find Finlark Packages -name '*.swift' \
    -not -path 'Finlark/DesignExplorations/*' \
    -not -path '*/.build/*' \
    -print0 | xargs -0 swift format lint --strict --configuration .swift-format
