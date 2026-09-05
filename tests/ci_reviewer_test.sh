#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

# Exercise the shell block actually shipped in CI. The small extractor reads
# this workflow's literal run block; it is not a general YAML parser.
python3 - "$root/.github/workflows/ci.yml" <<'PY'
import os
import pathlib
import subprocess
import sys
import tempfile
import textwrap

workflow = pathlib.Path(sys.argv[1]).read_text()
name = "name: ${{ vars.AGENT_REVIEWER_ENABLED == 'true' && 'reviewer' || 'reviewer-disabled' }}"
assert name in workflow, 'disabled reviewer must not publish the required reviewer check'
# GitHub string comparisons ignore case; use the same predicate for the job
# name and its shell flag, rather than comparing the raw variable in bash.
assert "REVIEWER_ENABLED: ${{ vars.AGENT_REVIEWER_ENABLED == 'true' && 'true' || 'false' }}" in workflow
assert 'continue-on-error:' not in workflow.split('\n  reviewer:\n', 1)[1]
block = workflow.split('      - name: Run reviewer\n', 1)[1].split('        run: |\n', 1)[1]
lines = []
for line in block.splitlines():
    if line.strip() and not line.startswith('          '):
        break
    lines.append(line)
script = textwrap.dedent('\n'.join(lines))
assert script.strip(), 'reviewer command block is empty'

with tempfile.TemporaryDirectory(prefix='ci-reviewer-test-') as tmp:
    root = pathlib.Path(tmp)
    harness = root / 'scripts/ci-reviewer'
    harness.parent.mkdir()
    marker = root / 'called'
    env = os.environ.copy()
    env.update(GITHUB_STEP_SUMMARY=str(root / 'summary'), ANTHROPIC_API_KEY='fixture-only')
    def run(enabled, key='fixture-only'):
        env.update(REVIEWER_ENABLED=enabled, ANTHROPIC_API_KEY=key)
        return subprocess.run(['bash', '-eu', '-o', 'pipefail', '-c', script], cwd=root,
                              env=env, capture_output=True, text=True)
    harness.write_text('#!/bin/sh\ntouch called\nexit 0\n')
    harness.chmod(0o755)
    for value in ('', 'false'):
        result = run(value)
        assert result.returncode == 0, result.stderr
        assert 'DESACTIVADO' in result.stdout
        assert not marker.exists(), 'disabled reviewer executed the harness'
    result = run('true', '')
    assert result.returncode != 0, 'enabled reviewer without a key passed'
    assert not marker.exists(), 'missing-key reviewer executed the harness'
    harness.unlink()
    assert run('true').returncode != 0, 'enabled reviewer without a harness passed'
    harness.write_text('#!/bin/sh\ntouch called\nexit 7\n')
    harness.chmod(0o755)
    assert run('true').returncode == 7, 'reviewer failure was swallowed'
    assert marker.exists(), 'configured reviewer was never called'
    harness.write_text('#!/bin/sh\ntouch called\nexit 0\n')
    assert run('true').returncode == 0, 'successful review failed'
print('ok - disabled, misconfigured, failed and successful CI reviewer states')
PY
