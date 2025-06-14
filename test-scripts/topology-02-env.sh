#!/bin/bash
set -euo pipefail

docker-compose -f ../docker-compose-build-top02.yaml down --v --remove-orphans

docker-compose -f ../docker-compose-build-top02.yaml up
