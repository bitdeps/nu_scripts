# Environment variable name for module directories, multiple directories should be separated by `;`
const LIB_ENV = 'NU_MODULE_DIRS'

# Get the specified env key's value or ''
export def 'get-env' [
  key: string       # The key to get it's env value
  default?: string  # The default value for an empty env
] {
  $env | get -i $key | default $default
}


def --env setup-lib-dirs [] {
  let module_dirs = ($env | get -i $LIB_ENV | default '' | str trim)
  if ($module_dirs | is-empty) { return }
  let dirs = (
    $module_dirs
      | split row ';'
      | each {|p| ($p | str trim | path expand) }
      | filter {|p| ($p | path exists) }
  )
  $env.NU_LIB_DIRS = ($env.NU_LIB_DIRS | append $dirs)
#   print 'Current NU_LIB_DIRS: '
#   print $env.NU_LIB_DIRS
#   # open $nu.env-path
#   #   | str replace -s '$env.NU_LIB_DIRS = [' $'$env.NU_LIB_DIRS = [(char nl)($env.NU_LIB_DIRS | str join (char nl))'
#   #   | save -f $nu.env-path
}

setup-lib-dirs
