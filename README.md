# pr-linked-issues-action

[![Tests][tests-image]][tests-link]

This action returns which issues may be be closed by a pull request using
[Github GraphQL v4 API][graphql-api].

<p align="center">
  <img src="https://raw.githubusercontent.com/mondeja/pr-linked-issues-action/master/graphic-explanation.png" alt="Graphic explanation"></a>
</p>

## Documentation

Without specifying inputs, you should run it on `pull_request` or
`pull_request_target` events and the pull request for which linked issues will
be obtained will be the pull request that triggered the action.

In other contexts you can use `repository_owner`, `repository_name` and
`pull_request` inputs to specify a pull request.

This action o does not provide a way to check if the outputted linked issues
are in other repositories than the repository where the pull request is triggered,
just outputs issue numbers.

### Inputs

All are optional.

- <a name="input-repository_owner" href="#input-repository_owner">#</a>
 <b>repository_owner</b> ⇒ Organization or user owner of the repository against
 which the pull request with linked issues to retrieve is opened.
- <a name="input-repository_name" href="#input-repository_name">#</a>
 <b>repository_name</b> ⇒ Name of the repository against which the pull request
 with linked issues to retrieve is opened.
- <a name="input-pull_request" href="#input-pull_request">#</a>
 <b>pull_request</b> ⇒ Number of the pull request to retrieve.
- <a name="input-owners" href="#input-owners">#</a> <b>owners</b> ⇒ Indicates
 if you want to retrieve linked issues owners. If `true`, the outputs
 [`opener`](#output-opener) and [`others`](#output-others) will be added.
- <a name="add_links_by_content" href="#add_links_by_content">#</a> <b>add_links_by_content</b> ⇒ Add other links to issues numbers defined in the
 body of the pull request. Specify inside a `{issue_number}` placeholder
 a content matcher for additional issues that will be linked. Multiple can be
 defined separating them by newlines. Keep in mind that the existence of the
 issues discovered by this feature is not guaranteed, it just discovers
 numbers giving the provided placeholders. If you pass
 [`owners` input](#input-owners) as `true`, you'll be able to check if not
 exist checking if are contained by [`null` output](#output-null).

### Outputs

- <a name="output-issues" href="#output-issues">#</a> <b>issues</b> ⇒ Linked
 issues for the pull request, separated by commas.

If [`owners` input](#input-owners) is `true`, the next outputs will be added:

- <a name="output-opener" href="#output-opener">#</a> <b>opener</b> ⇒ Linked
 issues that have been opened by the pull request opener.
- <a name="output-others" href="#output-others">#</a> <b>others</b> ⇒ Linked
 issues that haven't been opened by the pull request opener.

If `add_links_by_content` feature discovers issues that doesn't exists
[`owners` input](#input-owners) is `true`, their numbers will be added to the
next output:

- <a name="output-null" href="#output-null">#</a> <b>null</b> ⇒ Linked
 issues that doesn't exists, so they don't have owner.

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
      - name: Get issues
        id: get-issues
        uses: mondeja/pr-linked-issues-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Print linked issue numbers
        run: echo ${{ steps.get-issues.outputs.issues }}
```

### Check if pull request has linked issues

```yaml
name: Has linked issues
on:
  pull_request_target:
    types:
      - opened
      - reopened
      - edited

jobs:
  check-linked-issues:
    name: Check if pull request has linked issues
    runs-on: ubuntu-latest
    steps:
      - name: Get issues
        id: get-issues
        uses: mondeja/pr-linked-issues-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Print has linked issues
        id: has-linked-issues
        if: join(steps.get-issues.outputs.issues) != ''
        run: echo "Has linked issues"
      - name: Print has not linked issues
        if: steps.has-linked-issues.conclusion == 'skipped'
        run: echo "Has not linked issues"
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
      - name: Get issues
        id: get-issues
        uses: mondeja/pr-linked-issues-action@v2
        with:
          repository_owner: <your-username>
          repository_name: <your-repository>
          pull_request: <pull-request-number>
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Print linked issue numbers
        run: echo ${{ steps.get-issues.outputs.issues }}
```

### Check if pull request resolves other users' issues

```yaml
name: Is generous contributor
on:
  pull_request_target:
    types:
      - opened
      - reopened
      - edited

jobs:
  check-others-linked-issues:
    name: Has linked issues opened by others
    runs-on: ubuntu-latest
    steps:
      - name: Get issues
        id: get-issues
        uses: mondeja/pr-linked-issues-action@v2
        with:
          owners: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Print is generous contributor
        if: join(steps.get-issues.outputs.others) != ''
        run: echo "You are a generous developer!"
```

### Output linked issues by pull request body content

```yaml
name: I report linked issues that are not really linked
on:
  pull_request_target:
    types:
      - opened
      - reopened
      - edited

jobs:
  check-linked-issues-by-content:
    name: Has "linked issues" defined by PR content
    runs-on: ubuntu-latest
    steps:
      - name: Get issues
        id: get-issues
        uses: mondeja/pr-linked-issues-action@v2
        with:
          add_links_by_content: |
            **Closes**: #{issue_number}
            :wrench: the problem #{issue_number} like a boss
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Print linked issue numbers
        run: echo ${{ steps.get-issues.outputs.issues }}
```

### All outputted issues by pull request body content exist

```yaml
name: I report linked issues that are not really linked
on:
  pull_request_target:
    types:
      - opened
      - reopened
      - edited

jobs:
  check-linked-issues-by-content:
    name: Has "linked issues" defined by PR content
    runs-on: ubuntu-latest
    steps:
      - name: Get issues
        id: get-issues
        uses: mondeja/pr-linked-issues-action@v2
        with:
          add_links_by_content: |
            **Closes**: #{issue_number}
            :wrench: {issue_number}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Linked issues by pull request body content exist
        if: join(steps.get-issues.outputs.null) != ''
        run: echo "All are existing issues!"
```

[support-ref-closed-issues]: https://github.community/t/support-for-discovering-referenced-and-to-be-closed-issues-from-a-pr/14354/4
[graphql-api]: https://docs.github.com/en/graphql
[tests-image]: https://img.shields.io/github/workflow/status/mondeja/pr-linked-issues-action/CI?logo=github&label=tests
[tests-link]: https://github.com/mondeja/pr-linked-issues-action/actions?query=workflow%3ACI
