#!/bin/bash
helm upgrade --install classic ./cmangos/ -f ./cmangos/values_classic_testing.yaml \
  --set cmangos.type=classic \
  --set registration.expansion=0 \
  --namespace wow \
  --create-namespace

helm upgrade --install tbc ./cmangos/ -f ./cmangos/values_tbc_testing.yaml \
  --set cmangos.type=tbc \
  --set registration.expansion=1 \
  --namespace wow \
  --create-namespace

helm upgrade --install wotlk ./cmangos/ -f ./cmangos/values_wotlk_testing.yaml \
  --set cmangos.type=wotlk \
  --set registration.expansion=2 \
  --namespace wow \
  --create-namespace