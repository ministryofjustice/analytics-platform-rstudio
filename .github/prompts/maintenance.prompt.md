---
description: "Perform monthly maintenance for this repository: update to the latest rocker/rstudio base image and the pinned Quarto, GitHub CLI, GitHub Copilot CLI and Git LFS versions, update InSpec tests, and complete the manual maintenance Definition of Done"
tools:
  [
    "search/codebase",
    "search",
    "edit/editFiles",
    "execute/runInTerminal",
    "execute/getTerminalOutput",
  ]
---

# Maintenance

Perform monthly maintenance for this repository. This image is built on the upstream `rocker/rstudio` image (which also determines the R version and the Ubuntu release) and pins several tool versions in `Dockerfile`. Update each where needed, update the InSpec test expectations in `tests/controls/`, and prepare one pull request.

Note: Ubuntu is inherited from `rocker/rstudio`, so operating system maintenance here means updating to the latest available `rocker/rstudio` release and running `apt-get upgrade` at build time (already in `Dockerfile`).

Use the current values from `Dockerfile` and `tests/controls/*.rb`. Do not assume versions.

## Pinned values to maintain

| Item | Location | Related test |
| --- | --- | --- |
| `rocker/rstudio` tag | `FROM` line in `Dockerfile` | `tests/controls/python_spec.rb`, `tests/controls/pip_spec.rb` (only if Ubuntu release changes) |
| CRAN snapshot Ubuntu codename | `ENV CRAN` in `Dockerfile` (for example `.../__linux__/noble/latest`) | None |
| `QUARTO_VERSION` | `Dockerfile` | `tests/controls/quarto_spec.rb` (`quarto --version`) |
| `GITHUB_CLI_VERSION` | `Dockerfile` | `tests/controls/github_cli_spec.rb` (`gh --version`) |
| `GITHUB_COPILOT_CLI_VERSION` | `Dockerfile` | `tests/controls/github_cli_spec.rb` (`copilot --version`, major version only) |
| `GIT_LFS_VERSION` and `GIT_LFS_VERSION_SHA` | `Dockerfile` | None |
| Expiring CVE suppressions | `.trivyignore` | None |

## Prerequisite

- Check for open Dependabot pull requests that bump `rocker/rstudio` (the `docker` ecosystem in `.github/dependabot.yml`). If one exists, note it in the PR description so it can be closed once this maintenance PR is merged.
- Treat this as a manual pre-check by the user running the ticket.

## Objective

In one pull request:

1. Update the `FROM` line in `Dockerfile` to the latest stable `rocker/rstudio` release.
2. If the new base image uses a different Ubuntu release, update the codename in `ENV CRAN`.
3. Update `QUARTO_VERSION`, `GITHUB_CLI_VERSION`, `GITHUB_COPILOT_CLI_VERSION` and `GIT_LFS_VERSION` (with `GIT_LFS_VERSION_SHA`) if newer releases are available.
4. Update the matching version assertions in `tests/controls/` when a tested version changes.
5. Review `.trivyignore` for expired entries.
6. Keep everything else unchanged.

## Required Outcome

1. Create one maintenance branch.
2. Commit all required file updates with a Conventional Commit (`build:`).
3. Push and open one pull request.
4. Include a checklist aligned to the manual maintenance ticket Definition of Done.

## Execution Steps

1. Create a maintenance branch.

```bash
git checkout -b "chore/maintenance-rstudio-$(date +%Y%m%d-%H%M%S)"
```

2. Update the `rocker/rstudio` base image.

- Read the current `FROM` image reference from `Dockerfile`.
- Find the latest stable, fully qualified `rocker/rstudio` tag (semantic version `X.Y.Z` only; ignore `latest`, `devel`, date-suffixed and partial tags such as `4` or `4.6`).
- Update the `FROM` line to that tag. Keep the image repository (`rocker/rstudio`) unchanged and keep the existing pinning style (tag only).

```bash
curl --silent "https://hub.docker.com/v2/repositories/rocker/rstudio/tags?page_size=100&ordering=last_updated" \
  | jq -r '.results[].name' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
  | sort --version-sort \
  | tail -n 1
```

3. Check whether the Ubuntu release has changed.

- Compare the Ubuntu codename of the current and new base images.
- If it has changed, update the codename in `ENV CRAN` and review `tests/controls/python_spec.rb` (`Python 3.x`) and `tests/controls/pip_spec.rb` (`pip NN`), as the system Python and pip versions come from Ubuntu.

```bash
docker run --rm --platform linux/amd64 --entrypoint bash rocker/rstudio:<tag> -c '. /etc/os-release && echo "${VERSION_CODENAME}"; python3 --version; pip3 --version'
```

4. Check whether `QUARTO_VERSION` should be updated.

- Get the latest stable release tag from `quarto-dev/quarto-cli` (the `releases/latest` endpoint excludes pre-releases).
- Confirm the `quarto-<version>-linux-amd64.deb` asset exists for that release.
- If newer, update `QUARTO_VERSION`.
- If the major or minor version changed, update the `quarto --version` expectation in `tests/controls/quarto_spec.rb` (for example `/1.7/` becomes `/1.8/`).

```bash
curl --silent https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest | jq -r '.tag_name, (.assets[].name | select(test("linux-amd64.deb$")))'
```

5. Check whether `GITHUB_CLI_VERSION` should be updated.

- Get the latest release tag from `cli/cli` and strip the leading `v`.
- Confirm the version is published in the GitHub CLI apt repository, as `Dockerfile` installs `gh=${GITHUB_CLI_VERSION}` from there.
- If newer, update `GITHUB_CLI_VERSION`.
- Update the `gh --version` expectation in `tests/controls/github_cli_spec.rb` to the new major and minor version (for example `/gh version 2\.103/` becomes `/gh version 2\.104/`).

```bash
GH_VERSION=$(curl --silent https://api.github.com/repos/cli/cli/releases/latest | jq -r .tag_name | sed 's/^v//')
echo "${GH_VERSION}"
curl --silent https://cli.github.com/packages/dists/stable/main/binary-amd64/Packages | grep --line-regexp "Version: ${GH_VERSION}"
```

6. Check whether `GITHUB_COPILOT_CLI_VERSION` should be updated.

- Get the latest stable release tag from `github/copilot-cli` and strip the leading `v`.
- Confirm the `copilot-linux-x64.tar.gz` asset exists for that release.
- If newer, update `GITHUB_COPILOT_CLI_VERSION`.
- Only update the `copilot --version` expectation in `tests/controls/github_cli_spec.rb` if the major version changed (the test matches `GitHub Copilot CLI 1\.`).

```bash
curl --silent https://api.github.com/repos/github/copilot-cli/releases/latest | jq -r '.tag_name, (.assets[].name | select(. == "copilot-linux-x64.tar.gz"))'
```

7. Check whether `GIT_LFS_VERSION` and `GIT_LFS_VERSION_SHA` should be updated.

- First, identify which release asset the current `GIT_LFS_VERSION_SHA` belongs to by finding it in the current version's `sha256sums.asc` (expected to be `git-lfs-linux-amd64-v<version>.tar.gz`).
- Get the latest release tag from `git-lfs/git-lfs`.
- If newer, update `GIT_LFS_VERSION` and set `GIT_LFS_VERSION_SHA` to the checksum of the same asset for the new version. Always update both together.
- Note: these variables are not currently referenced by any `RUN` instruction. Keep them up to date but do not add or remove an installation step; mention this in the PR description instead.

```bash
CURRENT_LFS="<current-version>"
curl --silent --location "https://github.com/git-lfs/git-lfs/releases/download/v${CURRENT_LFS}/sha256sums.asc" | grep "<current-sha>"

LFS_VERSION=$(curl --silent https://api.github.com/repos/git-lfs/git-lfs/releases/latest | jq -r .tag_name | sed 's/^v//')
curl --silent --location "https://github.com/git-lfs/git-lfs/releases/download/v${LFS_VERSION}/sha256sums.asc" | grep "git-lfs-linux-amd64-v${LFS_VERSION}.tar.gz"
```

8. Review `.trivyignore`.

- List any entries whose `exp:` date is in the past.
- Do not silently extend expiry dates. Report expired entries in the PR description so the team can decide whether to remove them (CVE fixed or no longer present) or renew them with a justification.

9. Build and test locally where possible.

```bash
make build
make clean && make test
```

- `make test` runs the InSpec profile in `tests/` against the running container via `docker compose`. If it cannot run locally (for example, the `nginx-proxy` image cannot be pulled), say so in the PR description and rely on the `🧪 Test` workflow.
- If `make build` fails because a system package in the `apt-get install` list is no longer available in the new Ubuntu release, stop and report it rather than changing the package list.

10. Commit, push, and open a pull request.

- Use a Conventional Commit message with type `build`.
- Use a clear PR title, for example: `build: update rocker/rstudio base image and tool versions`.
- Create the PR description using the structure below.

Use this PR description template (replace placeholders with actual values, and remove rows for items that did not change):

```markdown
## Summary
Monthly maintenance: updates pinned dependencies in `Dockerfile` and aligns version assertions in `tests/controls/`.

### Base image
- `rocker/rstudio:<old-tag>` -> `rocker/rstudio:<new-tag>`
- Ubuntu release: `<codename>` (unchanged | changed from `<old>`)

### Tools
| Item | Before | After |
| --- | --- | --- |
| `QUARTO_VERSION` | `<old>` | `<new>` |
| `GITHUB_CLI_VERSION` | `<old>` | `<new>` |
| `GITHUB_COPILOT_CLI_VERSION` | `<old>` | `<new>` |
| `GIT_LFS_VERSION` | `<old>` | `<new>` |
| `GIT_LFS_VERSION_SHA` | `<old>` | `<new>` |

### Tests
| File | Before | After |
| --- | --- | --- |
| `tests/controls/<file>.rb` | `<old-pattern>` | `<new-pattern>` |

### Notes
- `.trivyignore`: <expired entries, or "no expired entries">
- `GIT_LFS_VERSION` and `GIT_LFS_VERSION_SHA` are defined but not used by any `RUN` instruction.
- Supersedes Dependabot PR: <link, or "none">

## Definition of Done
- [ ] `rocker/rstudio` updated to the latest stable release
- [ ] `ENV CRAN` codename matches the base image Ubuntu release
- [ ] Quarto, GitHub CLI, GitHub Copilot CLI and Git LFS checked and updated where newer
- [ ] InSpec test expectations updated for changed versions
- [ ] `.trivyignore` reviewed
- [ ] `make build` succeeds
- [ ] `make test` passes (locally or in CI)
- [ ] After merge, a new release tag is created to publish the image
```

If the base image does not change, replace the `### Base image` section with:

```markdown
### Base image
- `rocker/rstudio:<tag>` is already the latest stable release.
- No base image change in this PR.
```

## Guardrails

- Update to the latest stable `rocker/rstudio` release only; do not use pre-release, `devel` or `latest` tags.
- Keep the base image repository (`rocker/rstudio`) unchanged.
- Keep platform aligned to `linux/amd64` for any image inspection.
- Always update `GIT_LFS_VERSION` and `GIT_LFS_VERSION_SHA` together, and use the checksum from the official `sha256sums.asc`.
- Only change test expectations for versions that actually changed, and keep the existing pattern style.
- Do not change unrelated `Dockerfile` content, the `apt-get` package list, `entrypoint.sh`, `default_user.patch` or workflows.
- Do not change `IMAGE_TAG` in `Makefile`.
- Deliver all updates in the same branch and pull request.
- Use [Conventional Commits](https://www.conventionalcommits.org/) for both the commit message and the PR title (use the `build` type).
- Use British English, and use MOJ as the abbreviation for Ministry of Justice.