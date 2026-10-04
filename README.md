# pikopod GitHub Actions

Two actions. Both download a pinned [pikopod](https://github.com/Pikopod/pikopod) release for the runner, verify `SHA256SUMS` with cosign against the release workflow's identity, and only then run the binary. Nothing else is installed.

## spec-diff

Fail the build when the provider's spec changed in a way that breaks you, with every finding annotated on the pull request diff.

```yaml
- uses: Pikopod/spec-diff-action@v1
  with: { old: "git:origin/main:openapi.yaml", new: openapi.yaml }
```

The job needs `fetch-depth: 0` on checkout when `old` is a git ref.

| Input | Default | Meaning |
|---|---|---|
| `old` | required | Path, `http(s)` URL, or `git:<ref>:<path>`. |
| `new` | required | Path, `http(s)` URL, or `git:<ref>:<path>`. |
| `fail-on` | `ERR` | `ERR`, `WARN` or `INFO`: exit 1 when findings at or above it exist. |
| `format` | `githubactions` | `githubactions` annotates the diff; `text`, `json`, `markdown` also work. |
| `handoff` | runner temp | Where the JSON report is written. Always written. |
| `version` | `0.1.2` | The pikopod release to download and verify. |

| Output | Meaning |
|---|---|
| `findings` | Number of findings at any level. |
| `report` | Path of the JSON report, for `pikopod pr comment` or your own tooling. |
| `exit-code` | `0` clean, `1` breaking at or above `fail-on`, `2` a document could not be loaded. Never collapse the last two. |

To post the report on the pull request, add the `pr comment` step after it:

```yaml
- uses: Pikopod/spec-diff-action@v1
  id: gate
  with: { old: "git:origin/main:openapi.yaml", new: openapi.yaml }
- if: always()
  env: { GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}" }
  run: pikopod pr comment --handoff "${{ steps.gate.outputs.report }}"
```

## scenario-check

Build a sandbox from the provider's spec and run failure scenarios against it. No server, no account, deterministic by seed.

```yaml
- uses: Pikopod/spec-diff-action/scenario-check@v1
  with: { sandbox: examplepay, spec: specs/examplepay.json, scenarios: "declines retry_storm timeouts" }
```

| Input | Default | Meaning |
|---|---|---|
| `sandbox` | required | Sandbox name. |
| `spec` | required | Path or `http(s)` URL of the spec. |
| `scenarios` | required | Space-separated archetypes or committed packs. Packs under `./scenarios` are found first. |
| `seed` | `ci-fixed` | Run seed. |
| `version` | `0.1.2` | The pikopod release to download and verify. |

Output `status` is `passed` or `failed`; the step exits `1` on a failed scenario and `2` on a tool error.

## Verification

`install.sh` is the whole supply chain: download the archive and `SHA256SUMS` with its certificate and signature from the release, check the digest, verify the signature with `cosign verify-blob` against `^https://github.com/Pikopod/pikopod/.github/workflows/release.yml@refs/tags/` issued by GitHub's OIDC, then extract. The same command is documented at https://docs.pikopod.com/getting-started/installation.
