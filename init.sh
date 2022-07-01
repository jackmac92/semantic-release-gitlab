#! /usr/bin/env bash
set -euo pipefail

if [ -n "${DEBUG_RELEASE:-""}" ] || [ -n "${DEBUG:-""}" ]; then
  set -x
fi

if [ -n "${DEBUG_RELEASE:-""}" ]; then
  export DEBUG="semantic-release:*"
fi

git fetch "https://gitlab-ci-token:${GITLAB_TOKEN:-"${CI_JOB_TOKEN}"}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"
git fetch "https://gitlab-ci-token:${GITLAB_TOKEN:-"${CI_JOB_TOKEN}"}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" --tags

SEM_BASE_PLUGINS="\"@semantic-release/commit-analyzer\" \"@semantic-release/release-notes-generator\""

if [[ -f "./package.json" ]] && [[ -z ${NO_NPM_PLUGIN:-""} ]]; then
  SEM_BASE_PLUGINS="$SEM_BASE_PLUGINS \"@semantic-release/npm\""
fi

if [[ -n ${USE_DEFAULT_CONFIG:-""} ]]; then
  echo "Using the following semantic release plugins..."
  echo "$SEM_BASE_PLUGINS"
  echo "Writing default config"
  jq --null-input \
    --argjson baseplugins "$(jq -s -c <<<"$SEM_BASE_PLUGINS")" \
    --argjson glabassets "${SEMANTIC_RELEASE__RELEASE_ASSETS:-"[]"}" '
  {
    plugins: ($baseplugins + [
      [
        "@semantic-release/exec",
        {
          prepareCmd: "/home/releaser/scripts/semantic-release-prepare ${nextRelease.version}"
        }
      ],
      ["@semantic-release/gitlab", {
        "assets": $glabassets,
      }]
    ])
  }
  ' | tee .releaserc
fi
# ["@semantic-release/gitlab", { assets: $glabassets }],
cd "${DIRECTORY_TO_SEMANTIC_RELEASE:-"."}"

if [[ -n ${NPM_TOKEN:-""} ]]; then
  echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" >.npmrc
fi

set -x

npx semantic-release ${SEMANTIC_RELEASE__COMMAND_FLAGS:-}

if [[ -n ${SEMANTIC_RELEASE__PUSH_BRANCH:-""} ]]; then
  git push "https://gitlab-ci-token:${GITLAB_TOKEN:-"${CI_JOB_TOKEN}"}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" "$CI_COMMIT_REF_NAME"
fi
