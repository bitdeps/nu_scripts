# `github/dispatch.nu`

Nushell script for triggering GitHub Actions workflows based on configurable rules.

## Requirements
- **Nushell** (installed and in PATH)
- **GitHub CLI** (`gh`) authenticated
- **GitHub Token** (required for cross-repository operations)  
  *Note: Automatic `github.token` doesn't support operations on other repositories!*

---

# Usage

```bash
dispatch.nu [flags]
```

## Flags
| Short | Long          | Description                          | Default                     |
|-------|---------------|--------------------------------------|-----------------------------|
| `-c`  | `--config`    | Path to dispatch config              | `.github/.dispatch.yaml`    |
| `-i`  | `--inputs`    | Inputs as record or JSON             | `{}`                        |
| `-h`  | `--help`      | Show help message                    |                             |

---

# Configuration

## `dispatch.yaml` Structure
```yaml
default:
  dispatch:
    workflow: test-pr.yaml
    inputs:
      client: hello
      feature: pr
    match:
      type: pull_request
      pull_request:
        title_regex: '^ci\({{feature}} {{client}}\):'

dispatch:
  - repository: dennybaa/ghbar
  - repository: dennybaa/ghfoo
  - repository: dennybaa/testing
    match:
      fallback_ref: main
```

## Operation Flow
1. **Config Loading**  
   - Reads `--config` file (default: `.github/.dispatch.yaml`)
   - Merges configurations with priority:  
     `default.dispatch` < `dispatch[N]` < `--inputs`

2. **Rule Processing**  
   - Substitutes `{{input}}` placeholders in match rules
   - Executes matcher based on `match.type`

3. **Workflow Dispatch**  
   - Triggers workflow for each matched ref (branch/tag)

---

# GitHub Action Integration

## Example Workflow
```yaml
steps:
  - uses: hustcer/setup-nu@main
  
  - name: Checkout Code
    uses: actions/checkout@v4
    with: { path: code }

  - name: Checkout Nu Modules
    uses: actions/checkout@v4
    with:
      repository: bitdeps/nu_scripts
      path: nu

  - name: Dispatch Workflows
    env:
      GITHUB_TOKEN: ${{ secrets.MYPAT }}
      NU_LOG_LEVEL: info
      NU_MODULE_DIRS: |
        ${{ github.workspace }}/nu/modules;
        ${{ github.workspace }}/nu/scripts
    shell: nu {0}
    run: |
      const workspace = '${{ github.workspace }}'
      source $"($workspace)/nu/scripts/common/env.nu"
      
      cd code; nu -I (nu-include-dirs) $"($workspace)/nu/scripts/github/dispatch.nu"
```

## Key Environment Variables
- `GITHUB_TOKEN`: PAT with `workflow` scope
- `NU_MODULE_DIRS`: Paths to Nushell modules
- `NU_LOG_LEVEL`: Script verbosity (`debug`, `info`, `warning`, `error`)

---

# Pattern Matching
- Uses `{{key}}` placeholders in regex patterns
- Automatically substitutes values from `inputs`
- Example: `'^ci\({{feature}} {{client-id}}\):'` becomes `'^ci\(pr hello\):'`
