---
name: hreview
description: Review a GitHub pull request in lumen's side-by-side diff viewer in a floating Rex pane, and post the annotations the user sends to the PR as review comments. Use when the user runs /hreview or asks to review a PR in lumen and post their comments to it.
---

# hreview

Open a pull request in `lumen diff` inside a floating Rex pane. When the user
sends their annotations from lumen, `scripts/lumen-pr-review.py` posts each one
to the PR on GitHub.

## Resolve the pull request

The user may pass a PR URL, a PR number, or nothing.

- **URL:** use it as is.
- **Number:** resolve it against the current repository.
- **Nothing:** use the PR for the current branch.

```sh
gh pr view [NUMBER_OR_URL] --json url,number,title -q '{url, number, title}'
```

If no PR is found, tell the user and stop.

## Open the floating pane

This needs Rex (`$REX_SESSION` set). If it isn't set, tell the user to run the
command below in a terminal themselves, then stop.

Add the floating layer to the window that contains your own pane, not
whichever window the app happens to have active. Set `script` to the absolute
path of `scripts/lumen-pr-review.py` in this skill's base directory, and
`pr_url` to the resolved URL:

```sh
win=$(rex block inspect "$REX_BLOCK" --json | jq -r '.block.window_id')
jq -n --arg w "$win" --arg cwd "$PWD" --arg s "$script" --arg url "$pr_url" --arg label "PR $pr_number review" '{
  window_id: $w,
  bounds: [0.05, 0.05, 0.9, 0.9],
  focus: true,
  layout: {block: {
    flavor: "com.superlogical.terminal.shell",
    label: $label,
    options: {cwd: $cwd, command: ["sh", "-c",
      "GH_TOKEN=$(gh auth token) python3 \"$0\" \"$1\"; echo; echo \"Press Enter to close\"; read _",
      $s, $url]}
  }}
}' | rex api call -s "$REX_SESSION" session.new_layer -
```

`GH_TOKEN` lets lumen and `gh api` reach private repositories.

Wait a few seconds, then capture the new block with
`rex capture -s "$REX_SESSION" -b BLOCK --trim | head` and confirm that lumen
shows the diff. If it shows an error instead, report it.

## Tell the user how to use it

Keep it short:

- Annotate with `i`: lines selected with the mouse, a hunk focused with `{` or
  `}`, or the whole file when nothing is selected. `I` lists all annotations.
- Press `s`, then Enter, to post everything. Press `q` to quit without posting.
- Annotations post only when sent, not as each one is saved. lumen keeps them
  in memory until it exits.
- Each annotation posts immediately as its own PR comment, not as a pending
  review. Annotations on lines outside GitHub's diff hunks are posted as a
  general PR comment that names the file and lines.
- When posting finishes, the pane lists a link for each comment. Enter closes
  it.

Don't post anything yourself. The user's comments are posted only when they
send them from lumen.
