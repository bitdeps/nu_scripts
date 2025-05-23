# store result
$env.GIT_ROOT = ^git rev-parse --show-toplevel

def git_root [] { $env.GIT_ROOT }
