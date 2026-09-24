import { execFile } from "node:child_process"
import { Plugin } from "@opencode/plugin"
import { UsageRpc, type Quota, type Usage } from "./rpc.ts"

type Snapshot = {
  unlimited?: boolean
  entitlement?: number
  remaining?: number
  quota_remaining?: number
  percent_remaining?: number
  overage_count?: number
  overage_permitted?: boolean
}

function ghToken(): Promise<string | undefined> {
  return new Promise((resolve) => {
    execFile("gh", ["auth", "token"], { timeout: 5_000 }, (error, stdout) =>
      resolve(error ? undefined : stdout.trim() || undefined),
    )
  })
}

function pickToken(credential: unknown): string | undefined {
  if (!credential || typeof credential !== "object") return
  const value = credential as Record<string, unknown>
  // Copilot OAuth stores the GitHub token as `refresh` and the short-lived Copilot token as `access`.
  for (const key of ["refresh", "key", "token", "access"]) {
    const candidate = value[key]
    if (typeof candidate === "string" && candidate) return candidate
  }
}

function apiBase(credential: unknown) {
  const value = (credential ?? {}) as Record<string, unknown>
  const raw = value.enterpriseUrl ?? (value.metadata as Record<string, unknown> | undefined)?.enterpriseUrl
  if (typeof raw !== "string" || !raw) return "https://api.github.com"
  const host = raw.replace(/^https?:\/\//, "").replace(/\/.*$/, "")
  return `https://api.${host}`
}

export default Plugin.define({
  id: "jessul01.usage",
  async setup(ctx) {
    const candidates = async () => {
      const list: Array<{ source: string; token: string; base: string }> = []
      const connection = await ctx.integration.connection.active("github-copilot").catch(() => undefined)
      const credential = connection ? await ctx.integration.connection.resolve(connection).catch(() => undefined) : undefined
      const fromCredential = pickToken(credential)
      if (fromCredential) list.push({ source: "OpenCode Copilot login", token: fromCredential, base: apiBase(credential) })
      if (process.env.GITHUB_TOKEN)
        list.push({ source: "GITHUB_TOKEN", token: process.env.GITHUB_TOKEN, base: "https://api.github.com" })
      const gh = await ghToken()
      if (gh) list.push({ source: "gh CLI", token: gh, base: "https://api.github.com" })
      return list
    }

    await ctx.rpc.register(UsageRpc, {
      copilot: async (_input, context) => {
        const list = await candidates()
        if (list.length === 0) return context.error("failed", "No GitHub token", { reason: "No GitHub token found" })
        const errors: string[] = []
        for (const candidate of list) {
          const response = await fetch(`${candidate.base}/copilot_internal/user`, {
            signal: context.signal,
            headers: {
              Authorization: `token ${candidate.token}`,
              Accept: "application/json",
              "X-GitHub-Api-Version": "2025-04-01",
              "User-Agent": "opencode-usage",
            },
          }).catch((error: unknown) => error as Error)
          if (response instanceof Error) {
            errors.push(`${candidate.source}: ${response.message}`)
            continue
          }
          if (!response.ok) {
            errors.push(`${candidate.source}: HTTP ${response.status}`)
            continue
          }
          const body = (await response.json()) as {
            copilot_plan?: string
            quota_reset_date_utc?: string
            quota_reset_date?: string
            quota_snapshots?: Record<string, Snapshot>
          }
          const quotas: Quota[] = Object.entries(body.quota_snapshots ?? {}).map(([id, snapshot]) => ({
            id,
            unlimited: snapshot.unlimited === true,
            entitlement: snapshot.entitlement ?? 0,
            remaining: snapshot.quota_remaining ?? snapshot.remaining ?? 0,
            percentRemaining: snapshot.percent_remaining ?? 100,
            overageCount: snapshot.overage_count ?? 0,
            overagePermitted: snapshot.overage_permitted === true,
          }))
          quotas.sort((a, b) => Number(a.unlimited) - Number(b.unlimited))
          const usage: Usage = {
            source: candidate.source,
            plan: body.copilot_plan,
            resetDate: body.quota_reset_date_utc ?? body.quota_reset_date,
            quotas,
          }
          return usage
        }
        return context.error("failed", "Copilot usage request failed", { reason: errors.join("; ") })
      },
    })
  },
})
