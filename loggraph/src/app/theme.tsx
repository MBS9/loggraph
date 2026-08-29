"use client"
import { ThemeProvider, createTheme } from "@mui/material/styles"

const theme = createTheme({
  cssVariables: true,
})

function ThemeProviderWrapper({ children }: { children: React.ReactNode }) {
  return <ThemeProvider theme={theme}>{children}</ThemeProvider>
}

export default ThemeProviderWrapper
