#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
REGISTRY=${REGISTRY:-"$ROOT/skills/registry.yaml"}
TMPDIR=${TMPDIR:-/tmp}
TMP_ROOT=$(mktemp -d "$TMPDIR/registry-test.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM

failures=0

fail() {
    printf '%s\n' "FAIL: $*" >&2
    failures=$((failures + 1))
}

validate_frontmatter() {
    awk '
        BEGIN { open = 0; closed = 0; name = 0; description = 0 }
        NR == 1 && $0 == "---" { open = 1; next }
        open && $0 == "---" { closed = 1; open = 0; next }
        open && $0 ~ /^name:[[:space:]]*[^[:space:]#].*$/ { name = 1; next }
        open && $0 ~ /^description:[[:space:]]*[^[:space:]#].*$/ { description = 1; next }
        END {
            if (!closed || open || !name || !description) exit 1
        }
    ' "$1"
}

validate_registry() {
    registry=$1
    root=$2
    parsed=$(mktemp "$TMP_ROOT/parsed.XXXXXX")

    if ! awk -v output="$parsed" '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }
        function value_of(value) {
            value = trim(value)
            if (value ~ /^".*"$/) {
                sub(/^"/, "", value)
                sub(/"$/, "", value)
            }
            return value
        }
        function finish(    key) {
            if (!in_item) return
            count++
            if (id == "") error("missing id")
            if (seen[id]++) error("duplicate id: " id)
            if (id !~ /^[a-z0-9]+([.-][a-z0-9]+)*$/) error("malformed id: " id)
            for (key in required) {
                if (!(key in fields) || fields[key] == "") error("missing or empty " key " for " id)
            }
            if (owner !~ /^[a-z0-9]+([.-][a-z0-9]+)*$/) error("malformed owner: " owner)
            if (managed != "true" && managed != "false") error("managed must be true or false for " id)
            if (hosts !~ /^\[[^][]+\]$/) error("hosts must be a simple list for " id)
            if (managed == "true") {
                if (owner != "core") error("managed capability must have core owner: " id)
                if (source ~ /^contract:/) {
                    target = substr(source, 10)
                    sub(/#.*/, "", target)
                    if (target !~ /^[^\/:][^:]*[.]md$/) error("contract source must be a repository-relative .md path: " id)
                } else if (source !~ /^[^\/:][^:]*\/SKILL[.]md$/) {
                    error("managed source must end in /SKILL.md or use contract:<path>: " id)
                }
            } else {
                if (owner == "core") error("unmanaged capability cannot have core owner: " id)
                if (owner == "external" || owner == "plugin") error("unmanaged capability needs its real owner family: " id)
                if (source != "external:" owner) error("source must be external:" owner " for " id)
            }
            printf "%s\t%s\t%s\t%s\n", id, source, managed, owner >> output
            delete fields
            id = owner = hosts = trigger = mode = cost = source = managed = ""
            in_item = 0
        }
        function error(message) {
            print "registry: " message > "/dev/stderr"
            bad = 1
        }
        BEGIN {
            required["id"] = 1
            required["owner"] = 1
            required["hosts"] = 1
            required["trigger"] = 1
            required["mode"] = 1
            required["cost"] = 1
            required["source"] = 1
            required["managed"] = 1
        }
        /^[[:space:]]*$/ || /^[[:space:]]*#/ { next }
        NR == 1 {
            if ($0 != "capabilities:") error("first key must be capabilities:")
            next
        }
        /^  - id:[[:space:]]*/ {
            finish()
            in_item = 1
            id = value_of(substr($0, index($0, ":") + 1))
            fields["id"] = id
            next
        }
        /^    [a-z][a-z0-9_-]*:[[:space:]]*/ {
            if (!in_item) { error("field outside capability item"); next }
            key = $0
            sub(/^[[:space:]]+/, "", key)
            sub(/:.*/, "", key)
            value = value_of(substr($0, index($0, ":") + 1))
            if (!(key in required)) error("unknown field: " key)
            if (key in fields) error("duplicate field " key " for " id)
            fields[key] = value
            if (key == "id") id = value
            if (key == "owner") owner = value
            if (key == "hosts") hosts = value
            if (key == "trigger") trigger = value
            if (key == "mode") mode = value
            if (key == "cost") cost = value
            if (key == "source") source = value
            if (key == "managed") managed = value
            next
        }
        { error("malformed YAML subset at line " NR) }
        END {
            finish()
            if (count == 0) error("registry contains no capabilities")
            exit bad
        }
    ' "$registry"; then
        rm -f "$parsed"
        return 1
    fi

    while IFS='	' read -r id source managed owner; do
        [ -n "$id" ] || continue
        if [ "$managed" = true ]; then
            case "$source" in
                contract:*)
                    source=${source#contract:}
                    source=${source%%#*}
                    ;;
            esac
            case "$source" in
                /*|*..*|external:*|contract:*|SKILL.md|'')
                    printf '%s\n' "registry: invalid managed path for $id: $source" >&2
                    rm -f "$parsed"
                    return 1
                    ;;
            esac
            path=$root/$source
            if [ ! -f "$path" ]; then
                printf '%s\n' "registry: managed path does not exist for $id: $source" >&2
                rm -f "$parsed"
                return 1
            fi
            if [ "${source##*/}" = SKILL.md ] && ! validate_frontmatter "$path"; then
                printf '%s\n' "registry: invalid SKILL.md frontmatter for $id: $source" >&2
                rm -f "$parsed"
                return 1
            fi
        fi
    done < "$parsed"
    rm -f "$parsed"
}

assert_rejects() {
    name=$1
    registry=$2
    fixture_root=$3
    if validate_registry "$registry" "$fixture_root"; then
        fail "$name was accepted"
    else
        printf '%s\n' "PASS: rejects $name"
    fi
}

if [ ! -f "$REGISTRY" ]; then
    fail "registry missing: $REGISTRY"
else
    if validate_registry "$REGISTRY" "$ROOT"; then
        printf '%s\n' "PASS: validates registry"
    else
        fail "registry is invalid"
    fi
fi

cat > "$TMP_ROOT/duplicate.yaml" <<'EOF'
capabilities:
  - id: duplicate
    owner: core
    hosts: [codex]
    trigger: "test"
    mode: "direct"
    cost: "fast"
    source: "external:test"
    managed: false
  - id: duplicate
    owner: core
    hosts: [codex]
    trigger: "test"
    mode: "direct"
    cost: "fast"
    source: "external:test"
    managed: false
EOF
assert_rejects "duplicate IDs" "$TMP_ROOT/duplicate.yaml" "$TMP_ROOT"

cat > "$TMP_ROOT/missing.yaml" <<'EOF'
capabilities:
  - id: missing-trigger
    owner: core
    hosts: [codex]
    mode: "direct"
    cost: "fast"
    source: "external:test"
    managed: false
EOF
assert_rejects "missing required fields" "$TMP_ROOT/missing.yaml" "$TMP_ROOT"

cat > "$TMP_ROOT/path.yaml" <<'EOF'
capabilities:
  - id: missing-path
    owner: core
    hosts: [codex]
    trigger: "test"
    mode: "direct"
    cost: "fast"
    source: "skills/missing/SKILL.md"
    managed: true
EOF
assert_rejects "invalid managed paths" "$TMP_ROOT/path.yaml" "$TMP_ROOT"

mkdir -p "$TMP_ROOT/skills/bad"
printf '%s\n' '---' 'name: bad-skill' '---' > "$TMP_ROOT/skills/bad/SKILL.md"
cat > "$TMP_ROOT/frontmatter.yaml" <<'EOF'
capabilities:
  - id: bad-frontmatter
    owner: core
    hosts: [codex]
    trigger: "test"
    mode: "direct"
    cost: "fast"
    source: "skills/bad/SKILL.md"
    managed: true
EOF
assert_rejects "invalid SKILL.md frontmatter" "$TMP_ROOT/frontmatter.yaml" "$TMP_ROOT"

cat > "$TMP_ROOT/generic-owner.yaml" <<'EOF'
capabilities:
  - id: generic-owner
    owner: external
    hosts: [codex]
    trigger: "test"
    mode: "direct"
    cost: "fast"
    source: "external:external"
    managed: false
EOF
assert_rejects "generic external owner" "$TMP_ROOT/generic-owner.yaml" "$TMP_ROOT"

mkdir -p "$TMP_ROOT/skills/local"
printf '%s\n' 'local content' > "$TMP_ROOT/skills/local/source.txt"
cat > "$TMP_ROOT/unmanaged-local.yaml" <<'EOF'
capabilities:
  - id: unmanaged-local
    owner: github
    hosts: [codex]
    trigger: "test"
    mode: "direct"
    cost: "fast"
    source: "skills/local/source.txt"
    managed: false
EOF
assert_rejects "unmanaged local source" "$TMP_ROOT/unmanaged-local.yaml" "$TMP_ROOT"

cat > "$TMP_ROOT/owner-source-mismatch.yaml" <<'EOF'
capabilities:
  - id: owner-source-mismatch
    owner: github
    hosts: [codex]
    trigger: "test"
    mode: "direct"
    cost: "fast"
    source: "external:ponytail"
    managed: false
EOF
assert_rejects "owner and source mismatch" "$TMP_ROOT/owner-source-mismatch.yaml" "$TMP_ROOT"

mkdir -p "$TMP_ROOT/skills/target"
printf '%s\n' '# not a skill' > "$TMP_ROOT/skills/target/README.md"
cat > "$TMP_ROOT/managed-non-skill.yaml" <<'EOF'
capabilities:
  - id: managed-non-skill
    owner: core
    hosts: [codex]
    trigger: "test"
    mode: "direct"
    cost: "fast"
    source: "skills/target/README.md"
    managed: true
EOF
assert_rejects "managed non-SKILL target" "$TMP_ROOT/managed-non-skill.yaml" "$TMP_ROOT"

cat > "$TMP_ROOT/contract-missing.yaml" <<'EOF'
capabilities:
  - id: contract-missing
    owner: core
    hosts: [codex]
    trigger: "test"
    mode: "orchestrate"
    cost: "standard"
    source: "contract:agents/MISSING.md#section"
    managed: true
EOF
assert_rejects "missing contract target" "$TMP_ROOT/contract-missing.yaml" "$TMP_ROOT"

cat > "$TMP_ROOT/contract-absolute.yaml" <<'EOF'
capabilities:
  - id: contract-absolute
    owner: core
    hosts: [codex]
    trigger: "test"
    mode: "orchestrate"
    cost: "standard"
    source: "contract:/etc/passwd.md"
    managed: true
EOF
assert_rejects "absolute contract target" "$TMP_ROOT/contract-absolute.yaml" "$TMP_ROOT"

mkdir -p "$TMP_ROOT/agents"
printf '%s\n' '# contract' > "$TMP_ROOT/agents/README.md"
cat > "$TMP_ROOT/contract-unmanaged.yaml" <<'EOF'
capabilities:
  - id: contract-unmanaged
    owner: github
    hosts: [codex]
    trigger: "test"
    mode: "orchestrate"
    cost: "standard"
    source: "contract:agents/README.md"
    managed: false
EOF
assert_rejects "contract source on unmanaged entry" "$TMP_ROOT/contract-unmanaged.yaml" "$TMP_ROOT"

cat > "$TMP_ROOT/contract-ok.yaml" <<'EOF'
capabilities:
  - id: contract-ok
    owner: core
    hosts: [codex]
    trigger: "test"
    mode: "orchestrate"
    cost: "standard"
    source: "contract:agents/README.md#orquestacion"
    managed: true
EOF
if validate_registry "$TMP_ROOT/contract-ok.yaml" "$TMP_ROOT"; then
    printf '%s\n' "PASS: accepts a contract pointer with a section fragment"
else
    fail "valid contract pointer was rejected"
fi

if [ "$failures" -ne 0 ]; then
    printf '%s\n' "registry tests failed: $failures" >&2
    exit 1
fi
printf '%s\n' 'registry tests passed'
