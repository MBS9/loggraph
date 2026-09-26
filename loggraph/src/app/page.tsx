'use client'
import { ConfigurationForm, useConfiguration } from './configuration'
import { useEffect, useRef, useState, useCallback } from 'react'
import Analysis from './analysis'
import { Button, CircularProgress, Stack, Typography } from '@mui/material'
import type { Configuration, ProcessedCluster } from './types'
import { workerMessageSchema } from './schemas'


export default function Page() {
  const [processedClusters, setProcessedClusters] = useState<ProcessedCluster[] | null>(null)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [currentStatus, setCurrentStatus] = useState<string | null>(null)
  const [currentPercent, setCurrentPercent] = useState<number | null>(null)
  const [loading, setLoading] = useState(false)
  const worker = useRef<Worker | null>(null)

  const showResult = processedClusters && processedClusters.length > 0

  const onSubmit = useCallback((form: Configuration) => {
    setLoading(true)
    setLoadError(null)
    setProcessedClusters(null)
    worker.current?.postMessage({ graphUrl: form.graphUrl, requestsUrl: form.requestUrl, resolution: form.resolution, maxScore: form.maxHeterogeneityScore })
  }, [])

  const form = useConfiguration({
    resolution: 1,
    maxHeterogeneityScore: 0.7,
    graphUrl: process.env.NEXT_PUBLIC_GRAPH_URL as string,
    requestUrl: process.env.NEXT_PUBLIC_REQUESTS_URL as string,
  }, onSubmit)

  useEffect(() => {
    worker.current = new Worker(new URL('./worker.ts', import.meta.url))
    worker.current.onmessage = (event) => {
      const parsed = workerMessageSchema.parse(event.data)
      if (parsed.type === 'status_update') {
        setCurrentStatus(parsed.status)
        setCurrentPercent(parsed.percent ?? null)
      } else if (parsed.type === 'processed_clusters') {
        setProcessedClusters(parsed.clusters)
        setLoading(false)
        setCurrentStatus(null)
      } else if (parsed.type === 'error') {
        setLoadError(parsed.error)
        setLoading(false)
      }
    }
    return () => {
      worker.current?.terminate()
      worker.current = null
    }
  }, [form.configuration.graphUrl, form.configuration.requestUrl])

  return (
    <>
      {showResult && <Analysis processedClusters={processedClusters ?? []} />}
      {!showResult && (
        <>
          <header>
            <Typography variant="h4" component="h1" sx={{ textAlign: 'center' }}>Loggraph</Typography>
          </header>
          <ConfigurationForm
            configuration={form.configuration}
            onChange={form.onChange}
            onSubmit={form.onSubmit}
          >
            {(submit: () => void) => (
              <>
                <Stack direction="row" spacing={2}>
                  <Button variant='contained' onClick={submit} disabled={loading}>Build clusters</Button>
                  {loading &&
                    <CircularProgress value={currentPercent ?? undefined} variant={currentPercent ? 'determinate' : 'indeterminate'} />
                  }
                </Stack>
                {loading && currentStatus && (
                  <Typography>Status: {currentStatus}</Typography>
                )}
                {loadError && (
                  <Typography color="error">Error: {loadError}</Typography>
                )}
              </>
            )}
          </ConfigurationForm>
        </>
      )}
    </>
  )
}
