'use client'
import type { Configuration } from './types'
import React, { useCallback } from 'react'
import { TextField, Typography, Box, Slider, Divider, Chip } from '@mui/material'

export function useConfiguration(initialConfiguration: Configuration, submitAction: (form: Configuration) => void) {
  const [configuration, setConfiguration] = React.useState(initialConfiguration)
  const [submitted, setSubmitted] = React.useState(false)
  const handleChange = (newConfiguration: Configuration) => {
    setConfiguration(newConfiguration)
  }
  const onSubmit = useCallback(() => {
    setSubmitted(true)
    submitAction(configuration)
  }, [configuration, submitAction])
  return { configuration, onChange: handleChange, submitted, onSubmit }
}

export function ConfigurationForm({ configuration, onChange, children, onSubmit }: { configuration: Configuration, onChange: (configuration: Configuration) => void, children: (submit: () => void) => React.ReactNode, onSubmit: () => void }) {
  return (
    <Box sx={{ display: 'flex', justifyContent: 'center', minHeight: '100vh', minWidth: '100vw', flexDirection: 'row' }}>
      <Box sx={{ p: 2, display: 'flex', flexDirection: 'column', gap: 2, mx: '3rem', alignContent: 'center', alignItems: 'center', width: '50vw' }}>
        <main style={{ display: 'flex', flexDirection: 'column', gap: '1rem', width: '100%', alignContent: 'center', alignItems: 'center' }}>
          <Divider flexItem><Chip label="Data Source URLs" size="small" /></Divider>
          <TextField
            label="Graph URL"
            type="url"
            value={configuration.graphUrl}
            onChange={(e) => onChange({ ...configuration, graphUrl: e.target.value })}
            margin="normal"
            sx={{ flexGrow: 1, flexShrink: 1 }}
          />
          <TextField
            label="Request URL"
            type="url"
            value={configuration.requestUrl}
            onChange={(e) => onChange({ ...configuration, requestUrl: e.target.value })}
            margin="normal"
            sx={{ flexGrow: 1, flexShrink: 1 }}
          />
          <Divider flexItem><Chip label="Analysis parameters" size="small" /></Divider>
          <TextField
            label="Resolution"
            type="number"
            value={configuration.resolution}
            onChange={(e) => onChange({ ...configuration, resolution: Number(e.target.value) })}
            margin="normal"
            sx={{ flexGrow: 1, flexShrink: 1 }}
          />
          <Typography variant="body1">Max Heterogeneity Score: {configuration.maxHeterogeneityScore}</Typography>
          <Slider
            value={configuration.maxHeterogeneityScore}
            onChange={(e, newValue) => onChange({ ...configuration, maxHeterogeneityScore: newValue as number })}
            step={0.01}
            min={0}
            max={1}
            valueLabelDisplay="auto"
            sx={{ flexGrow: 1, flexShrink: 1 }}
          />
          {children(onSubmit)}
        </main>
      </Box>
    </Box>
  )
}
