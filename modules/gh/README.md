# `gh branch` – GitHub Branch Commands (Nushell)

Manage GitHub branches via the GitHub CLI (`gh`) from within Nushell.

---

## Subcommands

### 🔹 `get` — Get a GitHub Branch

Retrieves information about a specific GitHub branch.

**Usage:**

```nu
gh branch get --repo=<string> --args=<list<string>> <branch>
```

**Parameters:**

* `branch` (string) – The name of the branch to retrieve.

**Flags:**

* `--repo=<string>` – The GitHub repository in the format `owner/name`.
* `--args=<list<string>>` – Additional arguments to pass to the `gh` command. *(default: `[]`)*
* `-h`, `--help` – Display help for this command.

**Input/output types:**

```
╭───┬───────┬────────╮
│ # │ input │ output │
├───┼───────┼────────┤
│ 0 │ any   │ any    │
╰───┴───────┴────────╯
```

---

### 🔹 `list` — List GitHub Branches

Lists all branches in the specified GitHub repository.

**Usage:**

```nu
gh branch list --repo=<string> --args=<list<string>>
```

**Flags:**

* `--repo=<string>` – The GitHub repository in the format `owner/name`.
* `--args=<list<string>>` – Additional arguments to pass to the `gh` command. *(default: `[]`)*
* `-h`, `--help` – Display help for this command.

**Input/output types:**

```
╭───┬───────┬────────╮
│ # │ input │ output │
├───┼───────┼────────┤
│ 0 │ any   │ any    │
╰───┴───────┴────────╯
```

---

# `gh pr` – GitHub PullRequest Commands (Nushell)

Manage GitHub Actions pull requests via the GitHub CLI (`gh`) from Nushell.

## Subcommands

### 🔹 `get` — Get a GitHub Pull Request by Number

Returns the pull request matching the specified number.

**Usage:**

```nu
gh pr get --repo=<string> --args=<list<string>> <pull_number>
```

**Parameters:**

* `pull_number` (int) – The pull request number to retrieve.

**Flags:**

* `--repo=<string>` – The GitHub repository.
* `--args=<list<string>>` – Additional CLI arguments. *(default: `[]`)*
* `-h`, `--help` – Display help for this command.

**Input/output types:**

```
╭───┬───────┬────────╮
│ # │ input │ output │
├───┼───────┼────────┤
│ 0 │ any   │ any    │
╰───┴───────┴────────╯
```

---

### 🔹 `list` — List GitHub Pull Requests

Lists pull requests in the repository. Supports filtering by `state`, `head`, `base`, etc.

**Usage:**

```nu
gh pr list --repo=<string> --filter=<record> --args=<list<string>>
```

**Flags:**

* `--repo=<string>` – The GitHub repository.
* `--filter=<record>` – Optional filters (e.g., `state`, `head`, `base`). *(default: `{}`)*
* `--args=<list<string>>` – Additional CLI arguments. *(default: `[]`)*
* `-h`, `--help` – Display help for this command.

**Useful filters:**

* `state` – `open`, `closed`, `all`. *(default: `open`)*
* `head` – Filter by source branch (`org:branch` format).
* `base` – Filter by target branch.

> See full filter options in the [GitHub API reference](https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28#list-pull-requests--parameters).

**Input/output types:**

```
╭───┬───────┬────────╮
│ # │ input │ output │
├───┼───────┼────────┤
│ 0 │ any   │ any    │
╰───┴───────┴────────╯
```

---

# `gh workflow` – GitHub Workflow Commands (Nushell)

Manage GitHub Actions workflows via the GitHub CLI (`gh`) from Nushell.

---

## Subcommands

### 🔹 `list` — List GitHub Workflows

Returns the list of workflows in the specified repository.

**Usage:**

```nu
gh workflow list --repo=<string> --args=<list<string>>
```

**Flags:**

* `--repo=<string>` – The GitHub repository.
* `--args=<list<string>>` – Additional arguments to pass to the `gh` command. *(default: `[]`)*
* `-h`, `--help` – Display help for this command.

**Input/output types:**

```
╭───┬───────┬────────╮
│ # │ input │ output │
├───┼───────┼────────┤
│ 0 │ any   │ any    │
╰───┴───────┴────────╯
```

---

### 🔹 `run` — Run a Workflow

Dispatches a workflow using the `workflow_dispatch` event.

**Usage:**

```nu
gh workflow run --repo=<string> --ref=<string> --inputs=<record> --args=<list<any>> <workflow>
```

**Parameters:**

* `workflow` (string) – Workflow name or filename to run.

**Flags:**

* `--repo=<string>` – The GitHub repository.
* `--ref=<string>` – Git ref/branch. *(default: `'main'`)*
* `--inputs=<record>` – Input parameters for the workflow.
* `--args=<list<any>>` – Additional CLI arguments. *(default: `[]`)*
* `-h`, `--help` – Display help for this command.

**Returns:**

* `{ workflow: record, error?: record }`

**Input/output types:**

```
╭───┬───────┬────────╮
│ # │ input │ output │
├───┼───────┼────────┤
│ 0 │ any   │ any    │
╰───┴───────┴────────╯
```

---

### 🔹 `run get` — Get Workflow Run by ID

Fetches a workflow run by its ID.

**Usage:**

```nu
gh workflow run get --repo=<string> <run_id>
```

**Parameters:**

* `run_id` (int) – The workflow run ID.

**Flags:**

* `--repo=<string>` – The GitHub repository.
* `-h`, `--help` – Display help for this command.

**Input/output types:**

```
╭───┬───────┬────────╮
│ # │ input │ output │
├───┼───────┼────────┤
│ 0 │ any   │ any    │
╰───┴───────┴────────╯
```

---

### 🔹 `run get-dispatched` — Run and Wait for Dispatch

Runs a workflow and waits until it is registered on the current SHA.

**Usage:**

```nu
gh workflow run get-dispatched --repo=<string> --ref=<string> --inputs=<record> --interval=<duration> --timeout=<duration> --args=<list<any>> <workflow>
```

**Parameters:**

* `workflow` (string) – Workflow name or filename.

**Flags:**

* `--repo=<string>` – The GitHub repository.
* `--ref=<string>` – Git ref/branch. *(default: `'main'`)*
* `--inputs=<record>` – Input parameters.
* `--interval=<duration>` – Polling interval. *(default: `5sec`)*
* `--timeout=<duration>` – Timeout duration. *(default: `15sec`)*
* `--args=<list<any>>` – Additional CLI arguments. *(default: `[]`)*
* `-h`, `--help` – Display help for this command.

**Returns:**

* `{ run: record, error?: record }`

**Input/output types:**

```
╭───┬───────┬────────╮
│ # │ input │ output │
├───┼───────┼────────┤
│ 0 │ any   │ any    │
╰───┴───────┴────────╯
```

---

### 🔹 `run list` — List Workflow Runs

Returns the list of runs for a given workflow.

**Usage:**

```nu
gh workflow run list --repo=<string> --filter=<record> --args=<list<string>> <workflow>
```

**Parameters:**

* `workflow` (any) – Workflow ID or filename.

**Flags:**

* `--repo=<string>` – The GitHub repository.
* `--filter=<record>` – Optional filters (e.g., `status`, `branch`). *(default: `{}`)*
* `--args=<list<string>>` – Additional CLI arguments. *(default: `[]`)*
* `-h`, `--help` – Display help for this command.

**Input/output types:**

```
╭───┬───────┬────────╮
│ # │ input │ output │
├───┼───────┼────────┤
│ 0 │ any   │ any    │
╰───┴───────┴────────╯
```

---

### 🔹 `run wait` — Wait for Workflow Run Completion

Waits until the given workflow run reaches a specific status.

**Usage:**

```nu
gh workflow run wait --repo=<string> --interval=<duration> --timeout=<duration> --status=<list<string>> <run_id>
```

**Parameters:**

* `run_id` (int) – The workflow run ID.

**Flags:**

* `--repo=<string>` – The GitHub repository.
* `--interval=<duration>` – Polling interval. *(default: `5sec`)*
* `--timeout=<duration>` – Wait timeout. *(default: `1min`)*
* `--status=<list<string>>` – Desired statuses to wait for. *(default: `['completed']`)*
* `-h`, `--help` – Display help for this command.

**Valid statuses:**

```
completed, action_required, cancelled, failure, neutral, skipped,
stale, success, timed_out, in_progress, queued, requested,
waiting, pending
```

**Input/output types:**

```
╭───┬───────┬────────╮
│ # │ input │ output │
├───┼───────┼────────┤
│ 0 │ any   │ any    │
╰───┴───────┴────────╯
```
