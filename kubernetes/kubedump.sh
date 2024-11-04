#!/usr/bin/env bash

set -e

NAMESPACES=$(kubectl get ns -o jsonpath="{.items[*].metadata.name}")
RESOURCES=$(kubectl api-resources --namespaced -o name | tr "\n" " ")

for ns in ${NAMESPACES};do
  for resource in ${RESOURCES};do
    rsrcs=$(kubectl -n ${ns} get -o json ${resource}|jq '.items[].metadata.name'|sed "s/\"//g")
    for r in ${rsrcs};do
      dir="${ns}/${resource}"
      mkdir -p "${dir}"
      kubectl -n ${ns} get -o yaml ${resource} ${r} > "${dir}/${r}.yaml"
    done
  done
done