# gh

## gh branch

### `get`
Get a GitHub branch.

**Usage**:
```nu
get {flags} <branch>
```

**Flags**:
- `--repo <string>`: Repository name (format: `owner/repo`)
- `--args <list<string>>`: Additional arguments (default: `[]`)
- `-h, --help`: Display help message

**Parameters**:
- `branch <string>`: Branch name to retrieve

**Input/Output**:
| Input | Output |
|-------|--------|
| any   | any    |

**Example**:
```nu
get main --repo octocat/Hello-World
```

---

### `list`
List GitHub branches.

**Usage**:
```nu
list {flags}
```

**Flags**:
- `--repo <string>`: Repository name (format: `owner/repo`)
- `--args <list<string>>`: Additional arguments (default: `[]`)
- `-h, --help`: Display help message

**Input/Output**:
| Input | Output |
|-------|--------|
| any   | any    |

**Example**:
```nu
list --repo octocat/Hello-World
```

## Notes
- Both commands require repository specification via `--repo` flag
- The `--args` parameter accepts a list of strings for additional API parameters
- Output format depends on GitHub API response
```

## gh workflow

### `list`
List GitHub workflows.

**Usage**:
```nu
list {flags}
```

**Flags**:
- `--repo <string>`: Repository name
- `--args <list<string>>` (default: `[]`)
- `-h, --help`: Display help message

**Input/Output**:
| Input | Output |
|-------|--------|
| any   | any    |

---

### `run`
Run a workflow (create the workflow_dispatch event).

**Usage**:
```nu
run {flags} <workflow>
```

**Subcommands**:
- `run get` - Get workflow run by id
- `run get-dispatched` - Run a workflow and wait for dispatch
- `run list` - List workflow runs
- `run wait` - Wait for a workflow run

**Flags**:
- `--repo <string>`: Repository (e.g., `dennybaa/foobar`)
- `--ref <string>`: Branch/tag (default: `main`)
- `--inputs <record>`: Workflow input parameters
- `--args <list<any>>` (default: `[]`)
- `-h, --help`: Display help message

**Parameters**:
- `workflow <string>`: Workflow name or filename

**Input/Output**:
| Input | Output |
|-------|--------|
| any   | any    |

---

### `run get`
Get workflow run by id.

**Usage**:
```nu
run get {flags} <run_id>
```

**Flags**:
- `--repo <string>`: Repository
- `-h, --help`: Display help message

**Parameters**:
- `run_id <int>`: Workflow run ID

**Input/Output**:
| Input | Output |
|-------|--------|
| any   | any    |

---

### `run get-dispatched`
Run a workflow and wait for dispatch.

**Usage**:
```nu
run get-dispatched {flags} <workflow>
```

**Flags**:
- `--interval <duration>`: Poll interval (default: `5sec`)
- `--timeout <duration>`: Timeout (default: `15sec`)
- `--repo <string>`: Repository
- `--ref <string>`: Branch/tag (default: `main`)
- `--inputs <record>`: Workflow inputs
- `--args <list<any>>` (default: `[]`)
- `-h, --help`: Display help message

**Parameters**:
- `workflow <string>`: Workflow name or filename

**Input/Output**:
| Input | Output |
|-------|--------|
| any   | any    |

---

### `run list`
List workflow runs.

**Usage**:
```nu
run list {flags} <workflow>
```

**Flags**:
- `--repo <string>`: Repository
- `--filter <record>`: Filter parameters (default: `{}`)
- `--args <list<string>>` (default: `[]`)
- `-h, --help`: Display help message

**Parameters**:
- `workflow <any>`: Workflow ID or filename

**Input/Output**:
| Input | Output |
|-------|--------|
| any   | any    |

---

### `run wait`
Wait for a workflow run to complete.

**Usage**:
```nu
run wait {flags} <run_id>
```

**Flags**:
- `--repo <string>`: Repository
- `--interval <duration>`: Poll interval (default: `5sec`)
- `--timeout <duration>`: Timeout (default: `1min`)
- `--status <list<string>>`: Wait for specific status (default: `['completed']`)
- `-h, --help`: Display help message

**Parameters**:
- `run_id <int>`: Workflow run ID

**Status Values**:
`completed`, `action_required`, `cancelled`, `failure`, `neutral`, `skipped`, `stale`, `success`, `timed_out`, `in_progress`, `queued`, `requested`, `waiting`, `pending`

**Input/Output**:
| Input | Output |
|-------|--------|
| any   | any    |
```
