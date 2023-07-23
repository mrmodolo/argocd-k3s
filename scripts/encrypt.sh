#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${scriptDir}/.." || exit 1

export SOPS_AGE_RECIPIENTS=$(<public-age-keys.txt)
exec 3<<< "$(cat $1)"
sops --encrypt --input-type json --output-type json --age ${SOPS_AGE_RECIPIENTS} --encrypted-regex "^(user|password)$" /dev/fd/3
