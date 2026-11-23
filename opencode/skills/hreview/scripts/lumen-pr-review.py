#!/usr/bin/env python3
"""Run `lumen diff --pr` and post the annotations sent with `s` as PR comments."""

import json
import re
import subprocess
import sys

HEADER = re.compile(r"^\*\*(?P<path>.+?)\*\*(?: lines? (?P<start>\d+)(?:-(?P<end>\d+))? \((?P<side>LEFT|RIGHT)\))?$")


def gh_api(endpoint, payload):
    result = subprocess.run(
        ["gh", "api", "--method", "POST", endpoint, "--input", "-"],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
    )
    return result.returncode == 0, (result.stdout or result.stderr).strip()


def parse(output):
    comments = []
    blocks = re.split(r"\n---\n\n", output)
    for block in blocks:
        lines = block.strip().splitlines()
        # In --pr mode lumen also prints progress output (spinners, "# PR ..." heading)
        # to stdout before the annotations, so skip ahead to the first header.
        while lines and not HEADER.match(lines[0]):
            lines = lines[1:]
        if not lines:
            continue
        match = HEADER.match(lines[0])
        body = "\n".join(lines[1:]).strip()
        if body:
            comments.append({**match.groupdict(), "body": body})
    return comments


def main():
    url = sys.argv[1]
    repo, number = re.search(r"github\.com/([^/]+/[^/]+)/pull/(\d+)", url).groups()

    output = subprocess.run(["lumen", "diff", "--pr", url], stdout=subprocess.PIPE, text=True).stdout
    comments = parse(output)
    if not comments:
        print("No annotations sent. Nothing posted.")
        return

    head_sha = subprocess.run(
        ["gh", "pr", "view", number, "--repo", repo, "--json", "headRefOid", "-q", ".headRefOid"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()

    for c in comments:
        payload = {"body": c["body"], "commit_id": head_sha, "path": c["path"]}
        if c["start"] is None:
            payload["subject_type"] = "file"
            where = c["path"]
        else:
            start, end = int(c["start"]), int(c["end"] or c["start"])
            payload.update(line=end, side=c["side"])
            if start != end:
                payload.update(start_line=start, start_side=c["side"])
            where = f"{c['path']}:{start}" + (f"-{end}" if start != end else "")

        ok, response = gh_api(f"repos/{repo}/pulls/{number}/comments", payload)
        if ok:
            print(f"✓ inline comment on {where}: {json.loads(response)['html_url']}")
            continue

        # Lines outside GitHub's diff hunks can't take inline comments; fall back to a PR comment.
        ok, response = gh_api(
            f"repos/{repo}/issues/{number}/comments",
            {"body": f"**{where}**\n\n{c['body']}"},
        )
        if ok:
            print(f"✓ PR comment for {where} (not in GitHub's diff): {json.loads(response)['html_url']}")
        else:
            print(f"✗ failed to post comment for {where}: {response}")


if __name__ == "__main__":
    main()
