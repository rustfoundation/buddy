# Docs: https://just.systems/man/en/quick-start.html

# `just` displays all available recipes when run without arguments.
# If false, `just` runs the first recipe when run without arguments.
set default-list := true

vm := "buddy"
config_dir := "$HOME/.config/buddy"

host:
    mkdir -p "{{ env('HOME') / 'buddy' }}"

create: host
    limactl start --progress --name "{{ vm }}" buddy.yaml

start:
    limactl start --progress "{{ vm }}"

# "-" tells just to ignore command failure
stop:
    -limactl stop "{{ vm }}"

# Reboots the guest OS without recreating the VM or deleting its disk data.
restart: stop start

delete: stop
    limactl delete --force "{{ vm }}"

delete-file path:
    limactl shell "{{ vm }}" bash -lc 'rm -f "{{ path }}"'

login: login-codex login-claude login-datadog login-fastly

login-codex:
    limactl shell "{{ vm }}" bash -lc 'codex login --device-auth'

login-claude:
    limactl shell "{{ vm }}" bash -lc 'claude auth login'

login-datadog:
    cargo run --quiet -- login-datadog "{{ vm }}"

logout-datadog: (delete-file (config_dir / "datadog.env"))

dump-datadog-permissions:
    cargo run --quiet -- datadog-permissions dump "{{ vm }}"

assert-datadog-credentials:
    cargo run --quiet -- datadog-permissions assert "{{ vm }}"

login-fastly:
    cargo run --quiet -- login-fastly "{{ vm }}"

logout-fastly: (delete-file (config_dir / "fastly.env"))

# Upgrade manually. Upgrades are not done in `system.sh` because
# a full upgrade would make startup slower, less predictable, and could install kernel updates requiring another reboot.
upgrade:
    limactl shell "{{ vm }}" sudo apt-get update
    limactl shell "{{ vm }}" sudo apt-get upgrade
    limactl shell "{{ vm }}" bash -lc 'brew update && brew upgrade --yes'
    limactl shell "{{ vm }}" bash -lc 'curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh'
    limactl shell "{{ vm }}" bash -o pipefail -lc 'curl -fsSL https://claude.ai/install.sh | bash'
    # stop the old running app-server and start it again using the newly installed binary.
    limactl shell "{{ vm }}" bash -lc \
        'pkill -x codex || true; exec codex app-server daemon bootstrap'

rebuild: delete create

validate:
    limactl template validate buddy.yaml
    shellcheck provision/*.sh scripts/*.sh
    cargo fmt --check
    cargo clippy --all-targets -- -D warnings
    cargo test

shell *command:
    limactl shell "{{ vm }}" {{ command }}
