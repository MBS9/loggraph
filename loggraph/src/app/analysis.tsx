'use client'
import styles from './page.module.css'
import React from 'react'
import { Typography, AppBar, Toolbar, Paper, Grid, Pagination, Divider } from '@mui/material'
import type { ProcessedCluster } from './types'

const ITEMS_PER_PAGE = 12

export default function Analysis({ processedClusters }: { processedClusters: ProcessedCluster[] }) {
  const [page, setPage] = React.useState(1)

  const pageStart = (page - 1) * ITEMS_PER_PAGE
  const pageEnd = Math.min(pageStart + ITEMS_PER_PAGE, processedClusters?.length ?? 0)

  const pageClusterCards = React.useMemo(() => {
    if (!processedClusters) return null

    const cards: React.ReactElement[] = []
    for (let i = pageStart; i < pageEnd; i++) {
      const cluster = processedClusters[i]
      const nonEmpty = cluster.nodes.filter(node => node)
      if (!nonEmpty.length) continue

      cards.push(
        <Grid key={i}>
          <Paper variant='outlined' sx={{ height: '30vh', width: '21vw', overflow: 'scroll' }}>
            <Typography variant='h6' component="h2">
              Score: {cluster.heterogeneity_score.toFixed(4)}
            </Typography>
            {nonEmpty.map((node, nodeIndex) => (
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
      <AppBar component='header' position='sticky'>
        <Toolbar sx={{
          display: 'flex',
          justifyContent: 'space-around',
          flexDirection: 'row',
        }}>
          <Typography variant='h1'>Loggraph</Typography>
        </Toolbar>
      </AppBar>
      <main style={{ display: 'flex', flexDirection: 'column', gap: '1rem', padding: '1rem' }}>
        <Grid key={page} container sx={{ gap: '1rem', justifyContent: 'space-around', alignItems: 'space-around' }}>
          {pageClusterCards}
        </Grid>
        <Pagination sx={{ alignSelf: 'center', flexGrow: 1 }} count={Math.ceil((processedClusters?.length ?? 0) / ITEMS_PER_PAGE)} page={page} onChange={(_, value) => setPage(value)} />
      </main>
    </div>
  )
}
