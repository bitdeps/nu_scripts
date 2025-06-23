# Environment variable name for module directories, multiple directories should be separated by `;`
const LIB_ENV = 'NU_MODULE_DIRS'

# Get the specified env key's value or ''
def 'get-env' [
    key: string       # The key to get it's env value
    default?: string  # The default value for an empty env
] {
    $env | get -i $key | default $default
}

# Split NU_MODULE_DIRS (; separated) helper variable
def nu-module-dirs [] {
    let module_dirs = ($env | get -i $LIB_ENV | default '' | str trim)
    if ($module_dirs | is-empty) { return [] }
    $module_dirs
      | split row ';'
      | each {|p| ($p | str trim | path expand) }
      | where {|p| ($p | path exists) }
}

# Return include line (for nu -I) from NU_MODULE_DIRS
def nu-include-dirs [] {
    nu-module-dirs | str join (char -i 0x1e)
}

# Populate env NU_LIB_DIRS from NU_MODULE_DIRS
def --env setup-lib-dirs [] {
    $env.NU_LIB_DIRS = ($env.NU_LIB_DIRS | append (nu-module-dirs))
}
