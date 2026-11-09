# GitHub workflow

`main` ships Wallflow Core and `rice` ships Wallflow Rice. Both stay active.
Shared UI changes should be implemented on one branch and cherry-picked or reproduced on the other, then tested on both. Do not merge Rice-specific integrations into Core.

## Before publishing anything

Run `./Scripts/verify-repo.sh` and `./Scripts/build-app.sh` on each branch. The CI workflow also builds both branches when pushed. Check for source, art, licenses, secrets and machine-specific paths.

## First remote

Create a **private** repository from `main`, then push `rice` explicitly:

```sh
git switch main
gh repo create wallflow --private --source=. --remote=origin --push
git push -u origin rice
```

Do not use `--add-readme`, `--gitignore`, or `--license` with a pre-existing Git repository. The remote can be made public after the release checklist is satisfied.

## Issue to file

`Rice: Ghostty reload briefly opens application menu`

Expected: theme reload without menus or focus changes.
Current: the Accessibility adapter expands Ghostty's app menu and presses its reload item. This is functional but visually disruptive.

Do not tag a public binary release until the issue has a verified resolution on macOS.
