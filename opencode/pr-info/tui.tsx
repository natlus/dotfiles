/** @jsxImportSource @opentui/solid */
import { execFile } from "node:child_process"
import { Plugin, usePlugin } from "@opencode/plugin/tui"
import { createEffect, createSignal, onCleanup, Show } from "solid-js"

type PullRequest = {
  number: number
  title: string
  url: string
  state: string
  isDraft: boolean
  reviewDecision: string
}

const FIELDS = "number,title,url,state,isDraft,reviewDecision"

function fetchPullRequest(directory: string): Promise<PullRequest | undefined> {
  return new Promise((resolve) => {
    execFile("gh", ["pr", "view", "--json", FIELDS], { cwd: directory, timeout: 15_000 }, (error, stdout) => {
      if (error) return resolve(undefined)
      try {
        resolve(JSON.parse(stdout) as PullRequest)
      } catch {
        resolve(undefined)
      }
    })
  })
}

function PullRequestInfo(props: { sessionID: string }) {
  const context = usePlugin()
  const [pr, setPr] = createSignal<PullRequest>()

  const directory = () =>
    context.data.session.get(props.sessionID)?.location?.directory ??
    context.location?.directory ??
    context.data.location.default()?.directory
  const branch = () => {
    const location = context.data.session.get(props.sessionID)?.location ?? context.location
    return location ? context.data.location.vcs.info(location)?.branch.current : undefined
  }

  const refresh = async () => {
    const dir = directory()
    if (!dir) return setPr(undefined)
    setPr(await fetchPullRequest(dir))
  }

  createEffect(() => {
    directory()
    branch()
    void refresh()
  })

  const interval = setInterval(refresh, 60_000)
  const stop = context.data.on("session.execution.succeeded", (event) => {
    if ((event.data as { sessionID?: string } | undefined)?.sessionID === props.sessionID) void refresh()
  })
  onCleanup(() => {
    clearInterval(interval)
    stop()
  })

  const theme = context.theme
  const stateLabel = (value: PullRequest) => {
    if (value.isDraft) return { text: "Draft", fg: theme.text.muted }
    if (value.state === "MERGED") return { text: "Merged", fg: theme.text.feedback.info.base }
    if (value.state === "CLOSED") return { text: "Closed", fg: theme.text.feedback.error.base }
    return { text: "Open", fg: theme.text.feedback.success.base }
  }
  const review = (value: PullRequest) =>
    ({ APPROVED: "Approved", CHANGES_REQUESTED: "Changes requested", REVIEW_REQUIRED: "Review required" })[
      value.reviewDecision
    ]

  return (
    <Show when={pr()}>
      {(value) => (
        <box flexDirection="column" paddingTop={1}>
          <text fg={theme.text.base}>
            <b>PR</b>
          </text>
          <text fg={theme.text.base}>
            #{value().number} {value().title}
          </text>
          <text fg={stateLabel(value()).fg}>
            {stateLabel(value()).text}
            {review(value()) ? ` · ${review(value())}` : ""}
          </text>
          <text fg={theme.text.muted}>{value().url}</text>
        </box>
      )}
    </Show>
  )
}

export default Plugin.define({
  id: "jessul01.pr-info",
  setup(context) {
    return context.ui.slot({
      append: "sidebar.content",
      render: ({ sessionID }) => <PullRequestInfo sessionID={sessionID} />,
    })
  },
})
