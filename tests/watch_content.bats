# -*- mode: bash-ts -*-

function setup {
  load "util"

  _common_setup
}

function teardown {
  _common_teardown
}

# Make a file look newer than the cache without changing its content.
function bump_mtime {
  touch -d "@$(($(date +%s) + 60))" "$1"
}

function load_env {
  run --separate-stderr direnv exec "$TESTDIR" true
  assert_success
}

function assert_content_watch {
  local watched=$1

  load_env
  assert_stderr -p "Renewed cache"

  bump_mtime "$watched"
  load_env
  assert_stderr -p "newer than cache but unchanged"
  assert_stderr -p "Using cached dev shell"

  echo "# changed" >>"$watched"
  bump_mtime "$watched"
  load_env
  assert_stderr -p "Renewed cache"

  load_env
  assert_stderr -p "Using cached dev shell"
}

function watch_content_use_nix { # @test
  write_envrc $'nix_direnv_watch_content\nuse nix'
  assert_content_watch "$TESTDIR/shell.nix"
}

function watch_content_use_flake { # @test
  write_envrc $'nix_direnv_watch_content\nuse flake'
  assert_content_watch "$TESTDIR/flake.nix"
}

function watch_content_default_is_mtime { # @test
  write_envrc "use nix"
  load_env
  assert_stderr -p "Renewed cache"

  bump_mtime "$TESTDIR/shell.nix"
  load_env
  assert_stderr -p "Renewed cache"
  refute [ -e "$(echo "$TESTDIR"/.direnv/nix-profile-*.rc).hashes" ]
}

function watch_content_force_reload { # @test
  write_envrc $'nix_direnv_watch_content\nuse nix'
  load_env
  assert_stderr -p "Renewed cache"

  bump_mtime "$TESTDIR/shell.nix"
  run --separate-stderr env _nix_direnv_force_reload=1 direnv exec "$TESTDIR" true
  assert_success
  assert_stderr -p "Renewed cache"
}
