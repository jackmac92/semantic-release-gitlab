# Semantic Releaser for Gitlab

## Example usage in `.gitlab-ci.yml`

```yaml
semantic-releaser:
  image: jackzzz92/semantic-release-gitlab
  variables:
    USE_DEFAULT_CONFIG: 1
    CI_BRANCH_NAME: $CI_COMMIT_REF_NAME
  stage: publish
  only:
    - branches
  needs:
    - build
  dependencies:
    - build
  before_script: []
  script:
    - /home/releaser/init.sh
```
