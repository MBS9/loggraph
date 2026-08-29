"use client"
import styles from "./page.module.css"
import * as Wasm from "wasm"
import React from "react"
import { Typography } from "@mui/material"

export default function Home() {
  React.useEffect(() => {
    Wasm.default()
  }, [])
  return (
    <div>
      <header>
        <Typography variant='h1'>Loggraph</Typography>
      </header>
    </div>
  )
}
