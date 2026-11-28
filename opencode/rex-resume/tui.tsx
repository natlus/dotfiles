/** @jsxImportSource @opentui/solid */
import { createHash } from "node:crypto"
import { closeSync, openSync, writeSync } from "node:fs"
import { Plugin, usePlugin } from "@opencode/plugin/tui"
import { createEffect } from "solid-js"

// Program Resume Protocol (OSC 7577): tells the terminal to run
// `opencode --session <id>` for the open session, so Rex brings it back after a
// server restart. Rex trusts this with its built-in `opencode` rule.

const global = globalThis as { __osc7577Token?: string }
global.__osc7577Token ??= process.env.OSC7577_TOKEN
// Programs the TUI starts, such as an editor, must not report in its place.
delete process.env.OSC7577_TOKEN

const base64 = (value: string) => Buffer.from(value).toString("base64")

function send(token: string, fields: string) {
	const body = `pid=${process.pid}:time=${Math.floor(Date.now() / 1000)}:${fields}`
	const mac = createHash("sha256").update(`${body}:${token}`).digest("hex")
	try {
		const fd = openSync("/dev/tty", "w")
		try {
			writeSync(fd, `\x1b]7577;${body}:mac=${mac}\x1b\\`)
		} finally {
			closeSync(fd)
		}
	} catch { }
}

function Reporter(props: { token: string }) {
	const context = usePlugin()
	let reported: string | undefined
	createEffect(() => {
		const route = context.ui.router.current()
		const sessionID =
			route.type === "session" ? (context.data.session.root(route.sessionID) ?? route.sessionID) : undefined
		if (sessionID === reported) return
		reported = sessionID
		if (!sessionID) return send(props.token, "clear=1")
		const argv = ["opencode", "--session", sessionID].map(base64).join(",")
		send(props.token, `argv=${argv}:cwd=${base64(process.cwd())}`)
	})
	return null
}

export default Plugin.define({
	id: "jessul01.rex-resume",
	setup(context) {
		const token = global.__osc7577Token
		if (!token) return
		return context.ui.slot({ append: "app", render: () => <Reporter token={token} /> })
	},
})
