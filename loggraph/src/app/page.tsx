'use client'
import styles from './page.module.css'
import * as Wasm from 'wasm'
import React from 'react'
import { Typography, AppBar, Toolbar, Paper, Grid } from '@mui/material'

type Request = {
  ext_id: string
  hash: string
}

function runClustering(graph: unknown) {
  return Wasm.cluster(graph)
}

function findRequestHash(requests: Request[], extId: string) {
  if (!Array.isArray(requests)) return null
  return requests.find((request: any) => request.ext_id === extId)?.hash ?? null
}

export default function Home() {
  const [wasmLoaded, setWasmLoaded] = React.useState(false)
  React.useEffect(() => {
    Wasm.default().then(() => setWasmLoaded(true))
  }, [])
  const [graph, setGraph] = React.useState<unknown>(null)
  const [requests, setRequests] = React.useState<Request[] | null>(null)
  React.useEffect(() => {
    const request = fetch(process.env.NEXT_PUBLIC_GRAPH_URL as string)
    request.then(response => response.json()).then(data => setGraph(data)).catch(error => console.error(error))

    const requestsRequest = fetch(process.env.NEXT_PUBLIC_REQUESTS_URL as string)
    requestsRequest.then(response => response.json()).then(data => setRequests(data)).catch(error => console.error(error))
  }, [wasmLoaded])

  const clusters = React.useMemo(() => {
    if (graph && wasmLoaded) {
      return runClustering(graph) as number[][]
    }
    return null
  }, [wasmLoaded, graph])

  const processedClusters = React.useMemo(() => {
    if (clusters && Array.isArray(clusters) && requests && Array.isArray(requests)) {
      return clusters.slice(0, 100).map((cluster: number[]) => cluster.map((node: number) => {
        const request = findRequestHash(requests, node.toString())
        return request
      }))
    }
    return null
  }, [requests, clusters])

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
      <main>
        <Typography variant='body1'>Welcome to Loggraph!</Typography>
        <Grid container sx={{ gap: '1rem', justifyContent: 'space-around', alignItems: 'space-around' }}>
          {processedClusters && (
            processedClusters.slice(0, 50).map((cluster, index) => (
              <Grid key={index}>
                <Paper variant='outlined' sx={{ height: '30vh', width: '21vw', overflow: 'scroll' }}>
                  <Typography variant='h6' component="h2">
                    Cluster {index + 1}
                  </Typography>
                  {cluster.map((node, nodeIndex) => (
                    <Typography key={nodeIndex} variant='body2' sx={{ overflow: 'wrap', wordBreak: 'break-word' }}>
                      Node {node ?? 'N/A'}
                    </Typography>
                  ))}
                </Paper>
              </Grid>
            ))
          )}
        </Grid>
      </main>
    </div>
  )
}
