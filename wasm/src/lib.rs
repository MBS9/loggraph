use wasm_bindgen::prelude::*;
use std::collections::HashMap;
use std::panic;
use std::panic::PanicHookInfo;
use serde::{Deserialize, Serialize};
use single_clustering::network::CSRNetwork;
use single_clustering::community_search::leiden::{leiden, LeidenConfig, ObjectiveKind};

#[derive(Serialize, Deserialize)]
pub struct GraphEdge {
    request_1: usize,
    request_2: usize,
    jaccard_index: f64,
}

#[derive(Serialize, Deserialize)]
pub struct Cluster {
    heterogeneity_score: f64,
    nodes: Vec<usize>,
}

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console)]
    pub fn error(s: &str);
}

type GraphEdges = Vec<GraphEdge>;

#[wasm_bindgen]
pub fn cluster(json: JsValue) -> Result<JsValue, JsValue> {
    let js_edges: GraphEdges = serde_wasm_bindgen::from_value(json)
        .map_err(|e| JsValue::from_str(&format!("Invalid input JSON: {e}")))?;

    let mut edges: HashMap<(usize, usize), f64> = HashMap::with_capacity(js_edges.len());
    let mut node_largest = 0;
    for mut edge in js_edges {
        if edge.request_1 > edge.request_2 {
            std::mem::swap(&mut edge.request_1, &mut edge.request_2);
        }
        edges.insert((edge.request_1, edge.request_2), edge.jaccard_index);
        node_largest = node_largest.max(edge.request_2);
    }

    let n_nodes = node_largest + 1;

    let network_edges: Vec<(usize, usize, f64)> = edges
        .iter()
        .map(|(&(a, b), &score)| (a, b, score))
        .collect();

    let network = CSRNetwork::from_edges(n_nodes, &network_edges)
        .map_err(|e| JsValue::from_str(&format!("Failed to build graph: {e}")))?;

    let config = LeidenConfig {
        objective: ObjectiveKind::Rb { resolution: 1.0 },
        seed: Some(42),
        ..Default::default()
    };

    let clustering = leiden(&network, &config)
        .map_err(|e| JsValue::from_str(&format!("Failed to cluster graph: {e}")))?;


    let mut heterogeneity_score: Vec<f64> = Vec::with_capacity(clustering.clusters().len());
    for cluster_nodes in clustering.clusters().iter() {
        let mut sum = 0.0;
        let mut count = 0;
        for (i, node1) in cluster_nodes.iter().enumerate() {
            for node2 in &cluster_nodes[i + 1..] {
                let key = if node1 <= node2 { (*node1, *node2) } else { (*node2, *node1) };
                if let Some(&jaccard_index) = edges.get(&key) {
                    sum += jaccard_index;
                    count += 1;
                }
            }
        }
        heterogeneity_score.push(if count > 0 { 1.0 - sum / count as f64 } else { 1.0 });
    }
    
    
    let mut clusters: Vec<Cluster> = clustering.clusters().iter().zip(heterogeneity_score.iter()).map(|(nodes, &het_score)| Cluster {
        heterogeneity_score: het_score,
        nodes: nodes.clone(),
    }).collect();

    clusters.sort_unstable_by(|a, b| a.heterogeneity_score.partial_cmp(&b.heterogeneity_score).unwrap_or(std::cmp::Ordering::Equal));

    Ok(serde_wasm_bindgen::to_value(&clusters)
        .map_err(|e| JsValue::from_str(&format!("Failed to serialize result: {e}")))?)
}

#[wasm_bindgen(start)]
pub fn start() {
    panic::set_hook(Box::new(|panic_info: &PanicHookInfo| {
        if let Some(message) = panic_info.payload().downcast_ref::<&str>() {
            error(message);
        } else if let Some(message) = panic_info.payload().downcast_ref::<String>() {
            error(message);
        } else {
            error("panic occurred");
        }

        if let Some(location) = panic_info.location() {
            error(location.to_string().as_str());
        }
    }));
}
