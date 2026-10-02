# GitHub attention — product requirements

- **Date:** 2026-10-02
- **Status:** requirements recorded. None of the work below is implemented by this document.
- **Product:** the public GitHub profile [Lingikaushikreddy](https://github.com/Lingikaushikreddy), with [yesterself](https://github.com/Lingikaushikreddy/yesterself) as the project a new visitor is asked to open.
- **Audit:** public GitHub API and this repository at `2440f82` (main, 2026-10-02).

## 1. Purpose

A stranger who opens the profile should see original work, understand one project in a few seconds, and have a concrete way to play it or change it. Stars and pull requests are the result of that visit. This document says what has to exist on the profile and in this repository before that visit can succeed.

The game design in [docs/superpowers/specs/2026-10-01-echoloop-design.md](../superpowers/specs/2026-10-01-echoloop-design.md) still owns how the game plays. This document owns how the repository and the profile present that game, and which other original repositories sit beside it.

## 2. Problem

The profile has 17 followers and 51 public repositories. Original projects sit at 0–2 stars: Yesterself 0, IndicOrderBench 0, Aegis 1, Settlement-Village 1, aegiseval 2. The profile README already explains the work (Thrill AI, two installable packages, upstream pull requests, Settlement). The pin row does not. Three of the six pins are forks:

| Pinned repository | REST `fork` | Parent | Stars on this fork | Stars the pin card shows |
|---|---|---|---|---|
| libredb-studio | true | libredb/libredb-studio | 1 | 1050 |
| tunarr | true | chrisbenincasa/tunarr | 1 | 2609 |
| dizzify | true | mlm-games/dizzify | 1 | 5 |

The pin card shows the upstream star count. A visitor reads those numbers as this account's. The other three pins (aegiseval, three-tier-devops, Settlement-Village) are original and small, which is an honest signal. IndicOrderBench and Aegis, the two packages the profile README calls "shipped this week," are not pinned.

Yesterself is the landing project and it does not yet give a visitor a reason to stay:

- The README leads with the Clocklands, includes [docs/clocklands.png](../clocklands.png), and asks for a star in one sentence. The first run command is still `brew install --cask godot`. Linux CI already installs Godot in [scripts/ci_install_godot.sh](../../scripts/ci_install_godot.sh) and writes templates to `~/.local/share/godot/export_templates/`. The README's web-template path is the macOS Application Support directory.
- There is no browser link. CI uploads `yesterself-web` as an Actions artifact on every push ([.github/workflows/ci.yml](../../.github/workflows/ci.yml)). Artifacts require a GitHub login and expire. The design spec's `v*` itch.io release is not in that workflow. There are no GitHub Releases. The repository homepage is empty.
- GitHub community health is 42%. Present: description, README, MIT license. Absent: `CONTRIBUTING.md`, code of conduct, issue templates, pull request template. `.github/` contains only the workflow. Discussions are off. Open issues: 0.
- Topics: none. The repository description is still "A Godot 4 platformer where your past attempts replay beside you." The README now describes an open world where R plants an echo and play continues. Search and the profile listing still show the old sentence.
- The design spec's success test is a stranger finishing ten levels from an itch.io page. The README's promise is the Clocklands, with hazards and enemies still ahead, and rooms 1–3 kept as the rewind mode. A contributor who reads both documents does not know which surface to extend.

## 3. Users

| User | What they need in the first minute | Done when |
|---|---|---|
| Godot learner | A picture of an echo, a sentence that says R plants the past, and a way to play without installing a toolchain | They star, or they clone and the tests pass on their OS |
| Contributor | A labeled issue that names the files, the test command, and the definition of done | They open a pull request that `scripts/test.sh` can run |
| Peer or recruiter | Original repositories in the pin row, matching the profile README | They can name two projects this account wrote, and neither is a fork |

## 4. Goals

1. This repository's community profile reports health above 80%.
2. A public URL in the README opens the Clocklands in a browser.
3. Every pinned repository is original (`fork: false` on the REST API), and the row includes IndicOrderBench, Aegis, and Settlement-Village.
4. At least one issue exists that a person who does not have write access can take, with the label `good first issue`.
5. The repository description and topics match the Clocklands README.

A star count is not a goal of this document. The document cannot cause a star. It can remove the reasons a visitor leaves.

## 5. Non-goals

- Star exchanges, star bots, follow-for-follow, and any pin whose job is to display another project's star count.
- Rewriting the other fifty repositories. Profile edits are limited to the pin row and the profile README in `Lingikaushikreddy/Lingikaushikreddy`.
- Replacing the game design spec, adding rooms 4–10, or building hazards inside this requirements change.
- A funding or sponsor button, unless the owner asks for one later.
- Publishing to itch.io. That remains the design spec's release path and still needs the owner's itch.io project and `BUTLER_API_KEY`. A GitHub play URL does not wait on that secret.

## 6. Requirements

Each requirement is done only when its acceptance checks pass. Requirements marked **later** are specified here and shipped in a follow-up change. This document does not perform them.

### 6.1 P0 — Discovery on this repository

**D1. README hook.** The top of [README.md](../../README.md) already states the Clocklands rule and shows `docs/clocklands.png`. Keep both. Add a short GIF beside the still: plant an echo, climb it. The GIF lives in `docs/` and is committed, the same way the PNG is.

Acceptance: the README shows the still and a GIF of a plant-and-climb, and the first screen of the file does not open with an install command.

**D2. Run steps for Linux and Windows.** Keep the Homebrew lines. Add a Linux path that points at `scripts/ci_install_godot.sh` (Godot 4.7.2, templates under `~/.local/share/godot/export_templates/4.7.2.stable`) and a Windows path that points at the Godot 4.7.2 download. The web-template example must not be macOS-only.

Acceptance: a reader on Ubuntu can copy the Linux block and reach `godot --path .` without translating a Homebrew command. The macOS block still works as written today.

**D3. Repository description and topics.** Set the description to the Clocklands sentence already used as the idea of the game: an open-world Godot 4 platformer where the trail you walk is planted as an echo. Add topics: `godot`, `godot-engine`, `gdscript`, `platformer`, `game`, `open-source`.

Acceptance: `gh api repos/Lingikaushikreddy/yesterself` shows that description and those topics.

**D4. Social preview.** Export a 1280×640 frame of the same Clocklands view as `docs/clocklands.png`. The owner uploads it as the repository social preview (repository Settings → Social preview). Commit the same file at `docs/social-preview.png` so the README can use it if the settings image is missing.

Acceptance: a Slack or Discord unfurl of the repository URL shows the Clocklands, and `docs/social-preview.png` is in the tree.

### 6.2 P0 — A way in for developers

**C1. CONTRIBUTING.md.** One page, written for someone who has Godot 4.7.2 and has never opened the project.

It must include:

- `scripts/test.sh` runs every unit, physics, and solution test. `scripts/test.sh -gselect=test_player` runs one file. The runner fails if a test script does not load.
- The Clocklands map is the `map` string in `world/clocklands.tscn`, parsed by `LevelMap`. Rooms 1–3 stay in `levels/level_0N.tscn`. In the Clocklands, R plants and time does not rewind. In a room, R commits and the attempt restarts. Link [docs/learning/03-open-world.md](../learning/03-open-world.md).
- A new Clocklands beat is a change to that map plus a solution test and an impossibility test, the same pair the README describes for the stars and the summit.
- `*` is a required star, `+` is the island star the exit ignores, `@` is a trailhead, `a`/`A` link a switch to a door. Those letters are already in the map.
- Pull requests need a passing `scripts/test.sh` on Linux, which is what CI runs.

Acceptance: a new contributor can find the test command, the map file, and the rewind-versus-plant rule without reading the design spec.

**C2. Issue templates.** Add `.github/ISSUE_TEMPLATE/bug.yml` and `.github/ISSUE_TEMPLATE/feature.yml`, plus a `config.yml` that links to CONTRIBUTING. The bug template asks for Godot version, room or Clocklands, and whether `scripts/test.sh` fails. The feature template asks which map character or prop changes, and which solution test will cover it.

Acceptance: the GitHub "New issue" screen offers Bug and Feature, and community profile `files.issue_template` is non-null.

**C3. Pull request template.** `.github/pull_request_template.md` with three checkboxes: tests run (`scripts/test.sh`), the change is a room rewind or a Clocklands plant (say which), and new art is CC0 and listed in `assets/CREDITS.md` when art changes.

Acceptance: a new pull request opens with that body, and community profile `files.pull_request_template` is non-null.

**C4. Seeded issues.** File the seven issues in section 7 after C1–C3 exist, so each issue can point at CONTRIBUTING. Label the four small ones `good first issue`. Label the two mechanic ones `help wanted`. Enable Discussions on the repository before filing, so a question that is not a task has a place to go.

Acceptance: `gh issue list` shows those seven titles, at least one carries `good first issue`, and `has_discussions` is true.

**C5. Community health from the P0 files.** C1–C3 are enough to move health from 42% (3 of 7 community files) to 86% (6 of 7). The code of conduct is the seventh file and is P2.

Acceptance: `community/profile` reports `health_percentage` greater than 80 after C1–C3 merge. Description, README, and license are already set.

### 6.3 P1 — Profile

These edits are in the profile repository `Lingikaushikreddy/Lingikaushikreddy` and in the pin settings. They are specified here so the next change does not re-audit the account. They are not commits in yesterself.

**P1. Pins are original work.** Unpin libredb-studio, tunarr, and dizzify. Pin IndicOrderBench and Aegis. Leave aegiseval and Settlement-Village pinned. Leave three-tier-devops pinned until Yesterself has a public play URL, then replace three-tier-devops with Yesterself.

Acceptance: every node from `pinnedItems` has REST `fork: false`. The set includes `indicorderbench`, `Aegis`, and `Settlement-Village`. After the play URL in section 6.4 exists, the set also includes `yesterself` and does not include `three-tier-devops`.

**P2. Profile README "Now".** The current "Now" line names IndicOrderBench, aegis-shred, and Settlement. Add Yesterself: one sentence that R plants an echo in the Clocklands, plus the repository link. Add the play URL once section 6.4 has one. Do not add the forked pins to this section. Upstream pull requests stay in the contributions table, where they already are.

Acceptance: the rendered profile README mentions Yesterself in "Now" and does not list libredb-studio, tunarr, or dizzify as projects this account owns.

### 6.4 P1 — A public play URL

**W1. Publish the web build CI already produces.** `scripts/export_web.sh` writes `build/web`. The workflow uploads it as `yesterself-web`. Add a publish step that puts that directory on GitHub Pages, or attaches it to a GitHub Release. The design spec's itch.io butler step can follow later; this URL must not depend on `BUTLER_API_KEY`.

The export already uses the Compatibility renderer with threads off, so the page does not need cross-origin isolation headers.

Acceptance: the README contains a URL a logged-out browser can open, and that page loads the Clocklands. `curl -I` on the URL returns 200 without a GitHub session cookie.

**W2. Pin Yesterself after W1.** This is the last step of P1 in section 6.3.

### 6.5 P2 — Trust files

**T1. Code of conduct.** Add a Contributor Covenant (or the owner's chosen text) at `CODE_OF_CONDUCT.md`. This is the remaining community-profile file after C5.

Acceptance: community profile `files.code_of_conduct` is non-null, and health can reach 100%.

**T2. Changelog.** A `CHANGELOG.md` entry per playable publish from W1. Skip it until the first play URL exists.

**T3. Sponsor button.** Out of scope until the owner asks.

## 7. Issues to file later

File these only after CONTRIBUTING.md and the templates are on main. Each body links to CONTRIBUTING and names the test command. Wording can change; the scope of each issue should not.

| # | Title | Label | Done when |
|---|---|---|---|
| 1 | Document Linux and Windows run steps next to Homebrew | `good first issue` | D2's acceptance checks pass |
| 2 | Update the GitHub description and topics to the Clocklands | `good first issue` | D3's acceptance checks pass |
| 3 | Add a plant-and-climb GIF next to `docs/clocklands.png` | `good first issue` | D1's acceptance checks pass |
| 4 | Publish the `yesterself-web` artifact to a public play URL | `help wanted` | W1's acceptance checks pass |
| 5 | Spikes or a saw in the Clocklands: the player dies, an echo shatters | `help wanted` | A map change, a solution test, and an impossibility test. Mechanics match the design spec's hazard and paradox rules. The echo's recording is kept for the next attempt in a room; in the Clocklands the shatter does not rewind the world |
| 6 | Paradox feedback: a short particle burst and a sound when an echo shatters | `help wanted` | Visible and audible in game, covered by a test or a documented manual check, art and audio CC0 and credited |
| 7 | One new reachable star on the meadow road | `good first issue` | Follows exercise 1 in `docs/learning/03-open-world.md`: a `*` the player can walk to, and `test_clocklands_can_be_cleared_with_two_planted_echoes` updated so the clear still holds |

Do not file "build room 4" until the design spec says rooms 4–10 are still the roadmap. The README a visitor sees is the Clocklands. Issues 5 and 6 carry the hazard and paradox work from milestones M3 in the design spec onto that map.

## 8. Sequence

Ship in this order. A later step that jumps ahead leaves the earlier gap in front of every visitor.

1. **D2, D3, C1, C2, C3.** README platforms, description, topics, and the contributor files. These are the P0 text changes. They move community health above 80% and give issues a place to point.
2. **C4.** The seven issues and Discussions.
3. **D1, D4.** GIF and social preview. The still image is already on main.
4. **W1, then the profile pin swap and the "Now" line.** The play URL is what makes the star line in the README true for someone who will not install Godot. Yesterself joins the pin row only after that URL works.
5. **T1, T2.** Code of conduct, then a changelog on the first public build.
6. **More Clocklands content** (issues 5–7, and anything beyond them). A new hazard on a repository that still opens with a macOS-only install and no play link does not change who finds the profile.

## 9. Success measures

Checked against the public API, not against a star graph.

| Measure | Now (2026-10-02) | Target |
|---|---|---|
| Community health | 42% | Above 80% after C1–C3. 100% after T1 |
| Public play URL in the README | none | One URL, HTTP 200 logged out |
| `good first issue` issues | 0 | At least 1 open |
| Discussions | off | on |
| Topics | none | the six in D3 |
| Pins with `fork: true` | 3 of 6 | 0 |
| External issue or pull request | 0 | at least 1 from an account without write access |

"External" means the author is not `Lingikaushikreddy`. A star total is recorded if someone wants a baseline (0 on this repository at audit time) and is not a pass/fail line for this PRD.

## 10. What this document does not do

It does not add templates, file issues, change pins, edit the profile README, or publish a release. Those are the requirements above, written so a later change can ship them without auditing the profile again.

## 11. Decisions

| Decision | Choice | Reason |
|---|---|---|
| Landing project | Yesterself | This is the repository a visitor of this PRD is already in, and it is the only original project with a picture of play |
| Flagships beside it | IndicOrderBench, Aegis, Settlement-Village, aegiseval | They match the profile README and the bio ("score, rank and verify"), and Settlement already has a browser build |
| Forks on the pin row | Remove all three | The card shows upstream star counts (1050, 2609, 5) on forks that have 1 star each |
| Contributor tasks | Clocklands hazards, not rooms 4–10, until the design spec says otherwise | The README promises the Clocklands. Two roadmaps would split the first contributors |
| Play URL | GitHub Pages or a GitHub Release | The web export already runs in CI. itch.io stays blocked on an owner secret |
| Star tactics | Excluded | A pin or a bot that borrows stars teaches the visitor the wrong account |
