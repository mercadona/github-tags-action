# github-tag-action

A Github Action to automatically bump and tag master, on merge, with the latest formatted version. In addition it also deletes the las tags as they are not needed.

This is a copy of https://github.com/anothrNick/github-tag-action, modified to comply with our versioning format instead of using SemVer

### Usage

```Dockerfile
name: Bump version
on:
  push:
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
      with:
        fetch-depth: '0'
    - name: Bump version and push tag
      uses: mercadona/github-tags-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

_NOTE: set the fetch-depth for `actions/checkout@v2` to be sure you retrieve all commits to look for the semver commit message._

#### Options

**Environment Variables**

* **GITHUB_TOKEN** ***(required)*** - Required for permission to tag the repo.

### Workflow

* Add this action to your repo
* Commit some changes
* Either push to master or open a PR
* On push (or merge), the action will:
  * Get latest tag
  * Bump tag with major version in our format
  * Pushes tag to github
  * Deletes old tags
