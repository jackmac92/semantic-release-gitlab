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

cd "$(git root-directory)"

if [[ -f "./package.json" ]] && [[ -n "$(jq .release package.json)" ]]; then
  echo "Using release config from package.json"
elif [[ -n ${USE_DEFAULT_CONFIG:-""} ]]; then
  echo "Using the following semantic release plugins..."
  echo "$SEM_BASE_PLUGINS"
  echo "Writing default config"
  jq --null-input \
    --argjson baseplugins "$(jq -s -c <<<"$SEM_BASE_PLUGINS")" \
    --argjson gitassets "${SEMANTIC_RELEASE__GIT_TAG_ASSETS:-"[]"}" '
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
      ]
    ])
  }
  ' | tee .releaserc
fi
# # ["@semantic-release/gitlab", { assets: $glabassets }],
# cd "${DIRECTORY_TO_SEMANTIC_RELEASE:-"."}"

if [[ -n ${NPM_TOKEN:-""} ]]; then
  echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" >.npmrc
fi

# set -x

echo "Running semantic release for $CI_COMMIT_REF_NAME from $(pwd)"
git checkout "$CI_COMMIT_REF_NAME"

npx semantic-release ${SEMANTIC_RELEASE__COMMAND_FLAGS:-}

if git status -sb | grep -q ahead; then
  git push "https://gitlab-ci-token:${GITLAB_TOKEN:-"${CI_JOB_TOKEN}"}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" "$CI_COMMIT_REF_NAME"
fi
