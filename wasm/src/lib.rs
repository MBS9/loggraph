use wasm_bindgen::prelude::*;
use std::{collections::HashSet, panic};
use std::panic::PanicHookInfo;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Serialize, Deserialize)]
pub struct GraphEdge {
    request_1: String,
    request_2: String,
    jaccard_index: f64,
}

type GraphEdges = Vec<GraphEdge>;
type AdjacencyList = HashMap<String, Vec<(String, f64)>>;
type Cluster = HashMap<String, String>; // Key: node, Value: cluster ID
type Membership = HashMap<String, Vec<String>>; // Key: super-node, Value: original nodes

#[derive(Serialize)]
pub struct LouvainResult {
    node_to_cluster: HashMap<String, String>,
    clusters: HashMap<String, Vec<String>>,
}

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console)]
    pub fn error(s: &str);
}

fn create_adjacency_list(edges: &GraphEdges) -> AdjacencyList {
    let mut adjacency_list: AdjacencyList = HashMap::with_capacity(edges.len());
    for edge in edges {
        adjacency_list.entry(edge.request_1.clone()).or_default().push((edge.request_2.clone(), edge.jaccard_index));
        adjacency_list.entry(edge.request_2.clone()).or_default().push((edge.request_1.clone(), edge.jaccard_index));
    }
    adjacency_list
}

fn initialize_singleton_cluster(graph: &AdjacencyList) -> Cluster {
    let mut cluster: Cluster = HashMap::with_capacity(graph.len());
    for node in graph.keys() {
        cluster.insert(node.clone(), node.clone());
    }
    cluster
}

fn node_weight_sums(graph: &AdjacencyList) -> HashMap<String, f64> {
    let mut sums: HashMap<String, f64> = HashMap::with_capacity(graph.len());
    for (node, neighbors) in graph {
        let total: f64 = neighbors.iter().map(|(_, weight)| *weight).sum();
        sums.insert(node.clone(), total);
    }
    sums
}

fn compute_modularity(graph: &AdjacencyList, cluster: &Cluster) -> f64 {
    let total_weight: f64 = graph
        .values()
        .flat_map(|neighbors| neighbors.iter().map(|(_, weight)| *weight))
        .sum();

    if total_weight <= f64::EPSILON {
        return 0.0;
    }

    let k = node_weight_sums(graph);
    let mut modularity = 0.0;

    for (node, neighbors) in graph {
        let k_i = *k.get(node).unwrap_or(&0.0);
        for (neighbor, weight) in neighbors {
            let k_j = *k.get(neighbor).unwrap_or(&0.0);
            if cluster.get(node) == cluster.get(neighbor) {
                modularity += *weight - (k_i * k_j) / total_weight;
            }
        }
    }

    modularity / total_weight
}

fn move_nodes(graph: &AdjacencyList, cluster: &mut Cluster) -> bool {
    let mut modularity = compute_modularity(graph, cluster);
    let mut improved = false;

    for (node, edges) in graph {
        let Some(old_community) = cluster.get(node).cloned() else {
            continue;
        };

        let mut candidate_communities: HashSet<String> = HashSet::new();
        candidate_communities.insert(old_community.clone());
        for (neighbor, _) in edges {
            if let Some(community) = cluster.get(neighbor) {
                candidate_communities.insert(community.clone());
            }
        }

        let mut best_community = old_community.clone();
        let mut best_modularity = modularity;

        for community in candidate_communities {
            cluster.insert(node.clone(), community);
            let new_modularity = compute_modularity(graph, cluster);
            if new_modularity > best_modularity + 1e-12 {
                best_modularity = new_modularity;
                best_community = cluster.get(node).cloned().unwrap_or_else(|| old_community.clone());
            }
        }

        cluster.insert(node.clone(), best_community);
        if best_modularity > modularity + f64::EPSILON {
            modularity = best_modularity;
            improved = true;
        }
    }

    improved
}

fn is_node_in_cluster(node: &String, cluster: &Cluster, cluster_id: &String) -> bool {
    cluster.get(node) == Some(cluster_id)
}

fn aggregate_graph(graph: &AdjacencyList, cluster: &Cluster) -> AdjacencyList {
    let cluster_ids: HashSet<String> = cluster.values().cloned().collect();
    let mut new_graph: AdjacencyList = HashMap::with_capacity(cluster_ids.len());

    for cluster_id in &cluster_ids {
        let mut neighbors: HashMap<String, f64> = HashMap::new();
        for (node, _) in cluster {
            if is_node_in_cluster(node, cluster, cluster_id) {
                let Some(edges) = graph.get(node) else {
                    continue;
                };
                for (neighbor, weight) in edges {
                    if let Some(neighbor_cluster) = cluster.get(neighbor) {
                        *neighbors.entry(neighbor_cluster.clone()).or_insert(0.0) += *weight;
                    }
                }
            }
        }
        new_graph.insert(cluster_id.clone(), neighbors.into_iter().collect());
    }

    new_graph
}

fn initialize_membership(graph: &AdjacencyList) -> Membership {
    let mut membership: Membership = HashMap::with_capacity(graph.len());
    for node in graph.keys() {
        membership.insert(node.clone(), vec![node.clone()]);
    }
    membership
}

fn aggregate_membership(membership: &Membership, cluster: &Cluster) -> Membership {
    let mut aggregated: Membership = HashMap::new();

    for (node, originals) in membership {
        let Some(cluster_id) = cluster.get(node) else {
            continue;
        };
        let entry = aggregated.entry(cluster_id.clone()).or_default();
        entry.extend(originals.iter().cloned());
    }

    for nodes in aggregated.values_mut() {
        nodes.sort();
        nodes.dedup();
    }

    aggregated
}

fn finalize_result(membership: &Membership) -> LouvainResult {
    let mut groups: Vec<Vec<String>> = membership.values().cloned().collect();
    for members in &mut groups {
        members.sort();
        members.dedup();
    }
    groups.sort_by(|a, b| a.first().cmp(&b.first()));

    let mut node_to_cluster: HashMap<String, String> = HashMap::new();
    let mut clusters: HashMap<String, Vec<String>> = HashMap::new();

    for (index, members) in groups.into_iter().enumerate() {
        let cluster_id = format!("cluster_{}", index + 1);
        for node in &members {
            node_to_cluster.insert(node.clone(), cluster_id.clone());
        }
        clusters.insert(cluster_id, members);
    }

    LouvainResult {
        node_to_cluster,
        clusters,
    }
}

#[wasm_bindgen]
pub fn louvain(json: JsValue) -> Result<JsValue, JsValue> {
    let edges: GraphEdges = serde_wasm_bindgen::from_value(json)
        .map_err(|e| JsValue::from_str(&format!("Invalid input JSON: {e}")))?;

    let mut current_graph = create_adjacency_list(&edges);
    if current_graph.is_empty() {
        let empty = LouvainResult {
            node_to_cluster: HashMap::new(),
            clusters: HashMap::new(),
        };
        return serde_wasm_bindgen::to_value(&empty)
            .map_err(|e| JsValue::from_str(&format!("Failed to serialize result: {e}")));
    }

    let mut membership = initialize_membership(&current_graph);
    const MAX_LEVELS: usize = 32;

    for _ in 0..MAX_LEVELS {
        let mut cluster = initialize_singleton_cluster(&current_graph);
        let improved = move_nodes(&current_graph, &mut cluster);

        let next_membership = aggregate_membership(&membership, &cluster);
        if !improved {
            membership = next_membership;
            break;
        }

        let next_graph = aggregate_graph(&current_graph, &cluster);
        if next_graph.len() >= current_graph.len() {
            membership = next_membership;
            break;
        }

        membership = next_membership;
        current_graph = next_graph;
    }

    let result = finalize_result(&membership);
    serde_wasm_bindgen::to_value(&result)
        .map_err(|e| JsValue::from_str(&format!("Failed to serialize result: {e}")))
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
