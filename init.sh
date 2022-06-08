#! /usr/bin/env bash
set -euo pipefail

if [ -n "${DEBUG_RELEASE:-""}" ] || [ -n "${DEBUG:-""}" ]; then
  set -x
fi

if [ -n "${DEBUG_RELEASE:-""}" ]; then
  export DEBUG="semantic-release:*"
fi

if [[ -n ${USE_DEFAULT_CONFIG:-""} ]]; then
  jq --null-input --argjson glabassets "${SEMANTIC_RELEASE__RELEASE_ASSETS:-"[]"}" '
  {
    plugins: [
      "@semantic-release/commit-analyzer",
      "@semantic-release/release-notes-generator",
      [
        "@semantic-release/exec",
        {
          prepareCmd: "/home/releaser/scripts/semantic-release-prepare ${nextRelease.version}"
        }
      ],
      ["@semantic-release/gitlab", { assets: $glabassets }]
    ]
  }
  ' >.releaserc
fi

cd "${DIRECTORY_TO_SEMANTIC_RELEASE:-"."}"

if [[ -n ${NPM_TOKEN:-""} ]]; then
  echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" >.npmrc
fi

npx semantic-release ${SEMANTIC_RELEASE__COMMAND_FLAGS:-""}

git push "https://gitlab-ci-token:${GITLAB_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" --tags
git push "https://gitlab-ci-token:${GITLAB_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" "$CI_COMMIT_REF_NAME"
