#! /usr/bin/env bash
set -xeuo pipefail

if [ -n "${DEBUG_RELEASE:-""}" ] || [ -n "${DEBUG:-""}" ]; then
  set -x
fi

if [ -n "${DEBUG_RELEASE:-""}" ]; then
  export DEBUG="semantic-release:*"
fi

if [ -n "${RELEASE_REWRITE_REMOTE:-""}" ]; then
  git config --global url."https://gitlab-ci-token:$CI_JOB_TOKEN@gitlab.com/".insteadOf "git@gitlab.com:"
fi

SEM_BASE_PLUGINS="\"@semantic-release/commit-analyzer\" \"@semantic-release/release-notes-generator\""

if [[ -f "./package.json" ]] && [[ -z ${NO_NPM_PLUGIN:-""} ]]; then
  SEM_BASE_PLUGINS="$SEM_BASE_PLUGINS \"@semantic-release/npm\""
fi

if [[ -f "./info.rkt" ]]; then
  SEMANTIC_RELEASE__GIT_TAG_ASSETS="$(jq --null-input --argjson base "${SEMANTIC_RELEASE__GIT_TAG_ASSETS:-"[]"}" '$base + ["info.rkt"]')"
fi

if [[ -f "./README.md" ]]; then
  SEMANTIC_RELEASE__GIT_TAG_ASSETS="$(jq --null-input --argjson base "${SEMANTIC_RELEASE__GIT_TAG_ASSETS:-"[]"}" '$base + ["README.md"]')"
fi

if [[ -n ${USE_DEFAULT_CONFIG:-""} ]]; then
  echo "Using the following semantic release plugins..."
  echo "$SEM_BASE_PLUGINS"
  echo "Writing default config"
  jq --null-input \
    --argjson baseplugins "$(jq -s -c <<<"$SEM_BASE_PLUGINS")" \
    --argjson gitassets "${SEMANTIC_RELEASE__GIT_TAG_ASSETS:-"[]"}" \
    --argjson glabassets "${SEMANTIC_RELEASE__GITLAB_RELEASE_ASSETS:-"[]"}" '
  {
    plugins: ($baseplugins + [
      [
        "@semantic-release/exec",
        {
          prepareCmd: "/home/releaser/scripts/semantic-release-prepare ${nextRelease.version}"
        }
      ],
      ["@semantic-release/git",
        {
          assets: $gitassets,
          "message": "chore(release): ${nextRelease.version} \n\n${nextRelease.notes}"
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

# set -x

# npx semantic-release ${SEMANTIC_RELEASE__COMMAND_FLAGS:-}
