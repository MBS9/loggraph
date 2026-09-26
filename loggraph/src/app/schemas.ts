import { z } from 'zod'

const processedClusterSchema = z.object({
  nodes: z.array(z.string().nullable()),
  heterogeneity_score: z.number(),
})

export type ProcessedClusterSchema = z.infer<typeof processedClusterSchema>

export const workerMessageSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('status_update'), status: z.string(), percent: z.number().optional() }),
  z.object({ type: z.literal('error'), error: z.string() }),
  z.object({ type: z.literal('processed_clusters'), clusters: z.array(processedClusterSchema) }),
])

export type WorkerMessageSchema = z.infer<typeof workerMessageSchema>

export const inputMessageSchema = z.object({
  graphUrl: z.url(),
  requestsUrl: z.url(),
  resolution: z.number(),
  maxScore: z.number(),
})

export type InputMessageSchema = z.infer<typeof inputMessageSchema>
