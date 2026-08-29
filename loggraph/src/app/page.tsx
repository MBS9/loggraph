'use client'
import styles from './page.module.css'
import * as Wasm from 'wasm'
import React from 'react'
import { Typography, AppBar, Toolbar } from '@mui/material'

export default function Home() {
  React.useEffect(() => {
    Wasm.default()
  }, [])
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
      </main>
    </div>
  )
}
