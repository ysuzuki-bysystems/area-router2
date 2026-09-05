#!/bin/bash

set -e

source dev-container-features-test-lib

check "mkosi exists" mkosi --version

reportResults
