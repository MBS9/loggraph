use wasm_bindgen::prelude::*;
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

    let mut edges: Vec<(usize, usize, f64)> = Vec::with_capacity(js_edges.len());
    for edge in js_edges {
        edges.push((edge.request_1, edge.request_2, edge.jaccard_index));
    }

    let n_nodes = edges
        .iter()
        .flat_map(|(request_1, request_2, _)| [*request_1, *request_2])
        .max()
        .map_or(0, |max_node| max_node + 1);

    let network = CSRNetwork::from_edges(n_nodes, &edges)
        .map_err(|e| JsValue::from_str(&format!("Failed to build graph: {e}")))?;

    let config = LeidenConfig {
        objective: ObjectiveKind::Rb { resolution: 1.0 },
        seed: Some(42),
        ..Default::default()
    };

    let clustering = leiden(&network, &config)
        .map_err(|e| JsValue::from_str(&format!("Failed to cluster graph: {e}")))?;

    Ok(serde_wasm_bindgen::to_value(&clustering.clusters())
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
