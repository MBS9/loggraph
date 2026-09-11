'use client'
import styles from './page.module.css'
import * as Wasm from 'wasm'
import React from 'react'
import { Typography, AppBar, Toolbar, Paper, Grid, Pagination, Divider } from '@mui/material'

const ITEMS_PER_PAGE = 12

type Request = {
  ext_id: string
  hash: string
}

function runClustering(graph: unknown) {
  return Wasm.cluster(graph)
}

function findRequestHash(requests: Request[], extId: string) {
  if (!Array.isArray(requests)) return null
  return requests[parseInt(extId, 1) - 1]?.hash ?? null
}

export default function Home() {
  const [wasmLoaded, setWasmLoaded] = React.useState(false)
  const [processedClusters, setProcessedClusters] = React.useState<(string | null)[][] | null>(null)
  const [page, setPage] = React.useState(1)
  const [loadError, setLoadError] = React.useState<string | null>(null)
  const graphUrl = process.env.NEXT_PUBLIC_GRAPH_URL
  const requestsUrl = process.env.NEXT_PUBLIC_REQUESTS_URL

  React.useEffect(() => {
    Wasm.default().then(() => setWasmLoaded(true))
  }, [])
  React.useEffect(() => {
    if (!graphUrl || !requestsUrl || !wasmLoaded) {
      return
    }

    const abortController = new AbortController()

    Promise.all([
      fetch(graphUrl, { signal: abortController.signal }).then(response => {
        if (!response.ok) {
          throw new Error(`Failed to fetch graph: ${response.status}`)
        }
        return response.json()
      })
        .then(data => runClustering(data) as number[][]),
      fetch(requestsUrl, { signal: abortController.signal }).then(response => {
        if (!response.ok) {
          throw new Error(`Failed to fetch requests: ${response.status}`)
        }
        return response.json()
      }),
    ])
      .then(([clusters, requestsData]) => {
        const processed = clusters.map((cluster: number[]) => cluster.map((node: number) => {
          const request = findRequestHash(requestsData, node.toString())
          return request
        }))
        setProcessedClusters(processed)
      })
      .catch((error: unknown) => {
        if (error instanceof DOMException && error.name === 'AbortError') return
        setLoadError(error instanceof Error ? error.message : 'Unknown fetch error')
      })

    return () => {
      abortController.abort()
    }
  }, [graphUrl, requestsUrl, wasmLoaded])

  const pageStart = (page - 1) * ITEMS_PER_PAGE
  const pageEnd = Math.min(pageStart + ITEMS_PER_PAGE, processedClusters?.length ?? 0)

  const pageClusterCards = React.useMemo(() => {
    if (!processedClusters) return null

    const cards: React.ReactElement[] = []
    for (let i = pageStart; i < pageEnd; i++) {
      const cluster = processedClusters[i]
      if (!cluster) continue

      cards.push(
        <Grid key={i}>
          <Paper variant='outlined' sx={{ height: '30vh', width: '21vw', overflow: 'scroll' }}>
            <Typography variant='h6' component="h2">
              Cluster {i + 1}
            </Typography>
            {cluster.map((node, nodeIndex) => (
              <React.Fragment key={nodeIndex}>
                <Divider key={`divider-${nodeIndex}`} />
                <Typography variant='body2' sx={{ overflow: 'wrap', wordBreak: 'break-word' }}>
                  {node}
                </Typography>
              </React.Fragment>
            ))}
          </Paper>
        </Grid>,
      )
    }

    return cards
  }, [processedClusters, pageStart, pageEnd])

  return (
    <div>
      <AppBar component='header' position='static'>
        <Toolbar sx={{
          display: 'flex',
          justifyContent: 'space-around',
          flexDirection: 'row',
        }}>
          <Typography variant='h1'>Loggraph</Typography>
        </Toolbar>
      </AppBar>
      <main style={{ display: 'flex', flexDirection: 'column', gap: '1rem', padding: '1rem' }}>
        {(loadError) && <Typography color='error'>{loadError}</Typography>}
        {!processedClusters && <Typography variant='body2'>Please wait while the clusters are being processed...</Typography>}
        <Grid key={page} container sx={{ gap: '1rem', justifyContent: 'space-around', alignItems: 'space-around' }}>
          {pageClusterCards}
        </Grid>
        <Pagination sx={{ alignSelf: 'center', flexGrow: 1 }} count={Math.ceil((processedClusters?.length ?? 0) / ITEMS_PER_PAGE)} page={page} onChange={(_, value) => setPage(value)} />
      </main>
    </div>
  )
}
