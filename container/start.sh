#!/bin/bash
set -e

# GITHUB_TOKEN here, provided by Secrets Manager, is a PAT with access to the repo
runner_registration_token=$(curl -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "X-GitHub-Api-RUNNER_Version: 2022-11-28" https://api.github.com/orgs/${ORG}/actions/runners/registration-token | jq -r .token)

./config.sh --url https://github.com/${ORG} --token $runner_registration_token --labels $ENVIRONMENT

./run.sh