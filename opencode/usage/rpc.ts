import { Rpc } from "@opencode/plugin/rpc"

export type Quota = {
  id: string
  unlimited: boolean
  entitlement: number
  remaining: number
  percentRemaining: number
  overageCount: number
  overagePermitted: boolean
}

export type Usage = {
  source: string
  plan?: string
  resetDate?: string
  quotas: Quota[]
}

export const UsageRpc = Rpc.define({
  id: "usage",
  methods: {
    copilot: {
      input: { type: "object" },
      output: { type: "object" },
      errors: {
        failed: {
          type: "object",
          properties: { reason: { type: "string" } },
          required: ["reason"],
        },
      },
    },
  },
  events: {},
})
