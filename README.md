# pr-linked-issues-action

[![Tests][tests-image]][tests-link]

This action returns which issues will be closed by a pull request using
[GraphQL v4 Github API][graphql-api].

<p align="center">
  <img src="https://raw.githubusercontent.com/mondeja/pr-linked-issues-action/master/graphic-explanation.png" alt="Graphic explanation"></a>
</p>

## Examples

### Get linked issues for current pull request

```yaml
name: Get linked issues
on:
  pull_request_target:
    types:
      - opened
      - reopened
      - edited

jobs:
  get-linked-issues:
    name: Get linked issues
    runs-on: ubuntu-latest
    steps:
      - name: Get issue numbers separated by commas
        id: get-issues
        uses: mondeja/pr-linked-issues-action@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Print linked issue numbers
        run: echo ${{ steps.get-issues.outputs.issues }}
```

### Get linked issues for specified pull request

```yaml
name: Get linked issues
on:
  workflow_dispatch:

jobs:
  get-linked-issues:
    name: Get linked issues
    runs-on: ubuntu-latest
    steps:
      - name: Get issue numbers separated by commas
        id: get-issues
        uses: mondeja/pr-linked-issues-action@v1
        with:
          repository_owner: <your-username>
          repository_name: <your-repository>
          pull_request: <pull-request-number>
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Print linked issue numbers
        run: echo ${{ steps.get-issues.outputs.issues }}
```

[support-ref-closed-issues]: https://github.community/t/support-for-discovering-referenced-and-to-be-closed-issues-from-a-pr/14354/4
[graphql-api]: https://docs.github.com/en/graphql
[tests-image]: https://img.shields.io/github/workflow/status/mondeja/pr-linked-issues-action/CI?logo=github&label=tests
[tests-link]: https://github.com/mondeja/pr-linked-issues-action/actions?query=workflow%3ACI
