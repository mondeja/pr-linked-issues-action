# pr-linked-issues-action

[![Tests][tests-image]][tests-link]

This action returns which issues will be closed by a pull request.

<p align="center">
  <img src="https://raw.githubusercontent.com/mondeja/pr-linked-issues-action/master/graphic-explanation.png" alt="Graphic explanation"></a>
</p>

## Disclaimer

Currently [is not possible][support-ref-closed-issues], even with the
[GraphQL v4 Github API][graphql-api], get those issues that will be closed by a
pull request, so this action uses HTML parsing of the Github UI to retrieve
this information.

**USE IT AT YOUR OWN RISK**

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
        uses: mondeja/pr-linked-issues-action@v1.0.0
      - name: Print issue numbers
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
        uses: mondeja/pr-linked-issues-action@v1.0.0
        with:
          repository_owner: rajednom
          repository_name: gh-actions-webhooks
          pull_request: 5
      - name: Print issue numbers
        run: echo ${{ steps.get-issues.outputs.issues }}
```

[support-ref-closed-issues]: https://github.community/t/support-for-discovering-referenced-and-to-be-closed-issues-from-a-pr/14354/4
[graphql-api]: https://docs.github.com/en/graphql
[tests-image]: https://img.shields.io/github/workflow/status/mondeja/pr-linked-issues-action/CI?logo=github&label=tests
[tests-link]: https://github.com/mondeja/pr-linked-issues-action/actions?query=workflow%3ACI
