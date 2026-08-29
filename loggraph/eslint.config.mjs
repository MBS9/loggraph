import { defineConfig, globalIgnores } from 'eslint/config'
import nextVitals from 'eslint-config-next/core-web-vitals'
import pluginReact from 'eslint-plugin-react'
import tseslint from 'typescript-eslint'
import stylistic from '@stylistic/eslint-plugin'

const eslintConfig = defineConfig([
  ...nextVitals,
  pluginReact.configs.flat.recommended,
  //pluginReactHooks.configs["recommended-latest"],
  pluginReact.configs.flat['jsx-runtime'],
  {
    files: ['**/*.{ts}'],
    extends: [
      tseslint.configs.recommendedTypeChecked,
    ],
    languageOptions: {
      parserOptions: {
        projectService: true,
      },
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-unsafe-argument': 'warn',
      '@typescript-eslint/no-unsafe-member-access': 'warn',
      '@typescript-eslint/consistent-type-imports': 'error',
      '@typescript-eslint/no-unsafe-assignment': 'warn',
    },
  },
  {
    plugins: { stylistic },
  },
  {
    rules: {
      'stylistic/indent': ['error', 2],
      'stylistic/quotes': ['error', 'single', { avoidEscape: true }],
      'stylistic/semi': ['error', 'never'],
      'stylistic/comma-dangle': ['error', 'always-multiline'],
    },
  },
  {
    rules: {
      'react-hooks/rules-of-hooks': 'error', // For checking rules of hooks
      'react-hooks/exhaustive-deps': 'error', // For checking hook dependencies,
    },
  },
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    '.next/**',
    'out/**',
    'build/**',
    'next-env.d.ts',
  ]),
])

export default eslintConfig
