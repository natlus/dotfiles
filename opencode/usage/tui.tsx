/** @jsxImportSource @opentui/solid */
import { Plugin, usePlugin } from "@opencode/plugin/tui"
import { createResource, For, Match, Switch } from "solid-js"
import { UsageRpc, type Quota, type Usage } from "./rpc.ts"

const LABELS: Record<string, string> = {
  premium_interactions: "Premium requests",
  chat: "Chat",
  completions: "Completions",
}

const BAR_WIDTH = 30

function formatNumber(value: number) {
  return Math.round(value).toLocaleString("en-US")
}

function formatReset(date?: string) {
  if (!date) return
  const reset = new Date(date)
  if (Number.isNaN(reset.getTime())) return date
  const days = Math.max(0, Math.ceil((reset.getTime() - Date.now()) / 86_400_000))
  return `${reset.toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" })} (in ${days} day${days === 1 ? "" : "s"})`
}

function QuotaRow(props: { quota: Quota }) {
  const context = usePlugin()
  const theme = context.theme
  const used = () => Math.min(100, Math.max(0, 100 - props.quota.percentRemaining))
  const filled = () => Math.round((used() / 100) * BAR_WIDTH)
  const color = () =>
    used() >= 90 ? theme.text.feedback.error : used() >= 70 ? theme.text.feedback.warning : theme.text.feedback.success
  const label = LABELS[props.quota.id] ?? props.quota.id

  return (
    <box flexDirection="column" paddingTop={1}>
      <text fg={theme.text.base}>
        <b>{label}</b>
      </text>
      <Switch>
        <Match when={props.quota.unlimited}>
          <text fg={theme.text.muted}>Unlimited</text>
        </Match>
        <Match when={true}>
          <text>
            <span style={{ fg: color() }}>{"█".repeat(filled())}</span>
            <span style={{ fg: theme.text.muted }}>{"░".repeat(BAR_WIDTH - filled())}</span>
            <span style={{ fg: theme.text.base }}> {used().toFixed(1)}% used</span>
          </text>
          <text fg={theme.text.muted}>
            {formatNumber(props.quota.entitlement - props.quota.remaining)} / {formatNumber(props.quota.entitlement)}{" "}
            used · {formatNumber(props.quota.remaining)} remaining
            {props.quota.overageCount > 0 ? ` · ${formatNumber(props.quota.overageCount)} overage` : ""}
            {props.quota.overagePermitted ? "" : " · overage disabled"}
          </text>
        </Match>
      </Switch>
    </box>
  )
}

function UsageDialog() {
  const context = usePlugin()
  const theme = context.theme
  const [usage] = createResource(async (): Promise<Usage | { error: string }> => {
    try {
      return (await context.client.rpc(UsageRpc).copilot({})) as Usage
    } catch (error) {
      const data = (error as { data?: { reason?: string } }).data
      return { error: data?.reason ?? (error instanceof Error ? error.message : String(error)) }
    }
  })

  return (
    <box flexDirection="column" paddingLeft={2} paddingRight={2} paddingBottom={1}>
      <text fg={theme.text.base}>
        <b>GitHub Copilot usage</b>
      </text>
      <Switch>
        <Match when={usage.loading}>
          <text fg={theme.text.muted}>Loading…</text>
        </Match>
        <Match when={usage() && "error" in usage()!}>
          <text fg={theme.text.feedback.error}>{(usage() as { error: string }).error}</text>
          <text fg={theme.text.muted}>Log in to GitHub Copilot with /connect or run `gh auth login`.</text>
        </Match>
        <Match when={usage() as Usage | undefined}>
          {(value) => (
            <box flexDirection="column">
              <text fg={theme.text.muted}>
                Plan: {value().plan ?? "unknown"}
                {formatReset(value().resetDate) ? ` · Resets ${formatReset(value().resetDate)}` : ""}
              </text>
              <For each={value().quotas}>{(quota) => <QuotaRow quota={quota} />}</For>
              <text fg={theme.text.muted} paddingTop={1}>
                Source: {value().source}
              </text>
            </box>
          )}
        </Match>
      </Switch>
    </box>
  )
}

export default Plugin.define({
  id: "jessul01.usage.tui",
  setup(context) {
    return context.ui.slot({
      append: "app",
      render: () => {
        context.keymap.layer(() => ({
          mode: "global",
          commands: [
            {
              id: "jessul01.usage.show",
              title: "Show usage limits",
              group: "Usage",
              palette: true,
              slash: { name: "usage" },
              run: () => {
                context.ui.dialog.set({ size: "medium" })
                context.ui.dialog.show(() => <UsageDialog />)
              },
            },
          ],
        }))
        return null
      },
    })
  },
})
