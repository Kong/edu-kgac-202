#!/usr/bin/env bash

# Remove DP
helm uninstall kong-dp -n kong-dp

# Remove CP
helm uninstall kong -n kong