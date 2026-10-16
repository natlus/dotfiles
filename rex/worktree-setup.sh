#!/bin/sh
# Prepares a worktree created by the worktree_mirror Rex action. Every mirrored
# pane runs this before its command: the first one to get here installs
# dependencies, the others wait for it to finish.

git_dir=$(git rev-parse --absolute-git-dir) || exit 1
root=$(git rev-parse --show-toplevel) || exit 1
state="$git_dir/rex-setup"

if mkdir "$state.lock" 2>/dev/null; then
	cd "$root" || exit 1
	if [ -f pnpm-lock.yaml ]; then
		install="pnpm install"
	elif [ -f bun.lock ] || [ -f bun.lockb ]; then
		install="bun install"
	elif [ -f yarn.lock ]; then
		install="yarn install"
	elif [ -f package-lock.json ]; then
		install="npm install"
	else
		install=""
	fi
	if [ -z "$install" ] || { echo "→ $install" && $install; }; then
		touch "$state.ok"
	else
		touch "$state.failed"
	fi
elif [ ! -e "$state.ok" ] && [ ! -e "$state.failed" ]; then
	echo "Waiting for worktree setup in another pane…"
	while [ ! -e "$state.ok" ] && [ ! -e "$state.failed" ]; do
		sleep 1
	done
fi

if [ -e "$state.failed" ]; then
	echo "Worktree setup failed. Fix the problem, then run: rm -rf '$state'.* && $0"
	exit 1
fi
