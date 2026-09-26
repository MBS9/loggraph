import * as Wasm from 'wasm'
import { WorkerMessageSchema } from './schemas'

type Request = {
  ext_id: number
  hash: string
}

interface Cluster {
  heterogeneity_score: number
  nodes: number[]
}

function runClustering(graph: unknown) {
  const startTime = performance.now()
  const cluster = Wasm.cluster(graph) as Cluster[]
  const endTime = performance.now()
  console.info(`WASM clustering took ${endTime - startTime} ms`)
  return cluster
}

function sendMessage(message: WorkerMessageSchema) {
  self.postMessage(message)
}

function findRequestHash(requests: Request[], extId: number) {
  if (!Array.isArray(requests)) return null
  let top = 0
  let bottom = requests.length - 1
  while (top <= bottom) {
    const mid = Math.floor((top + bottom) / 2)
    const midExtId = requests[mid].ext_id
    if (midExtId === extId) {
      return requests[mid].hash
    } else if (midExtId < extId) {
      top = mid + 1
    } else {
      bottom = mid - 1
    }
  }
  return null
}

const guaranteeWasmPromise = Wasm.default()

self.onmessage = async (event: MessageEvent<{ graphUrl: string, requestsUrl: string }>) => {
  const abortController = new AbortController()
  try {
    const { graphUrl, requestsUrl } = event.data
    await guaranteeWasmPromise
    const [clusters, requestsData] = await Promise.all([
      new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest()
        xhr.open('GET', graphUrl)
        xhr.responseType = 'json'
        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            resolve(xhr.response)
          } else {
            reject(new Error(`Failed to fetch graph: ${xhr.status}`))
          }
        }
        xhr.onerror = () => reject(new Error('Network error'))
        xhr.onprogress = (event) => {
          if (event.lengthComputable) {
            const percent = (event.loaded / event.total) * 100
            sendMessage({ type: 'status_update', status: 'Fetching graph...', percent })
          } else {
            sendMessage({ type: 'status_update', status: 'Fetching graph... ' + Number((event.loaded / 1_000_000).toFixed(2)) + ' MB loaded' })
          }
        }
        abortController.signal.addEventListener('abort', () => {
          xhr.abort()
          sendMessage({ type: 'status_update', status: 'aborted', percent: 0 })
          reject(new Error('Fetch aborted'))
        })
        sendMessage({ type: 'status_update', status: 'Fetching graph...' })
        xhr.send()
      })
        .then(data => {
          sendMessage({ type: 'status_update', status: 'Clustering...' })
          return runClustering(data)
        }),
      fetch(requestsUrl, { signal: abortController.signal }).then(response => {
        if (!response.ok) {
          throw new Error(`Failed to fetch requests: ${response.status}`)
        }
        return response.json()
      }),
    ])

    sendMessage({ type: 'status_update', status: 'Processing clusters...' })

    const now = performance.now()
    const processed = clusters.map((cluster) => ({
      nodes: cluster.nodes.map((node) => {
        const request = findRequestHash(requestsData, node)
        return request
      }),
      heterogeneity_score: cluster.heterogeneity_score,
    }))
    const endTime = performance.now()
    console.info(`JS processing took ${endTime - now} ms`)
    sendMessage({ type: 'processed_clusters', clusters: processed.filter(cluster => cluster.nodes.some(node => node !== null)) })
  } catch (error: unknown) {
    console.error(error)
    sendMessage({ type: 'error', error: error instanceof Error ? error.message : 'Unknown error' })
  }
}
