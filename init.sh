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

if [[ -n ${USE_DEFAULT_CONFIG:-""} ]]; then
  echo "Writing default config"
  jq --null-input \
    --arg commitmsg "${SEMANTIC_RELEAE__COMMIT_MESSAGE:-'chore(release): \${nextRelease.version} [skip ci]\n\n\${nextRelease.notes}'}" \
    --argjson glabassets "${SEMANTIC_RELEASE__RELEASE_ASSETS:-"[]"}" '
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

      ["@semantic-release/git", {
        "assets": $glabassets,
        "message": $commitmsg
      }]
    ]
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

if [[ -n ${SEMANTIC_RELEASE__TRY_PUSH_TAGS:-""} ]]; then
  git push "https://gitlab-ci-token:${GITLAB_TOKEN:-"${CI_JOB_TOKEN}"}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" --tags
fi

if [[ -n ${SEMANTIC_RELEASE__TRY_PUSH_BRANCH:-""} ]]; then
  git push "https://gitlab-ci-token:${GITLAB_TOKEN:-"${CI_JOB_TOKEN}"}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" "$CI_COMMIT_REF_NAME"
fi
