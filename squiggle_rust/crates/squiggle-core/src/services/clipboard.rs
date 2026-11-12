//! Copy/paste payload format for nodes (`squiggle-nodes:3:<json>`) and its image attachments.
//!
//! The payload is `{"nodes": [...], "images": {imageId: base64Png}}` and is self-contained:
//! each referenced PNG is embedded once. Editor-side steps (history, selection, centering,
//! building text features from plain text) are left to the editor.

use crate::node::Node;
use crate::repositories::ImageRepository;
use serde_json::{Map, Value, json};
use std::collections::{BTreeSet, HashMap};

pub const CLIPBOARD_FORMAT_PREFIX: &str = "squiggle-nodes:";
pub const CLIPBOARD_PREFIX: &str = "squiggle-nodes:3:";
/// Widest a pasted plain-text label gets before it wraps, in world units.
pub const MAX_PASTED_TEXT_WIDTH: f64 = 600.0;

/// Plain-text system clipboard.
pub trait ClipboardBackend {
    fn read_text(&mut self) -> Option<String>;
    /// Returns false when no clipboard is available.
    fn write_text(&mut self, text: &str) -> bool;
}

/// What a clipboard's text means for a paste.
#[derive(Clone, Debug, PartialEq)]
pub enum PasteContent {
    /// Detached nodes with fresh (`NO_ID`) identities.
    Nodes(Vec<Node>),
    /// Ordinary text to become a label (wrap at [`MAX_PASTED_TEXT_WIDTH`] if wider).
    Text(String),
    /// Nothing usable (invalid/unsupported Squiggle payload, empty text): try an image paste.
    Empty,
}

/// Writes `nodes` to the clipboard; `Ok(false)` when there is nothing to copy or no clipboard.
pub fn copy_nodes_to_clipboard(
    nodes: &[Node],
    images: &ImageRepository,
    backend: &mut dyn ClipboardBackend,
) -> Result<bool, String> {
    if nodes.is_empty() {
        return Ok(false);
    }
    let payload = encode_nodes_for_clipboard(nodes, images)?;
    Ok(backend.write_text(&format!("{CLIPBOARD_PREFIX}{payload}")))
}

/// Interprets the clipboard text for pasting.
pub fn read_paste_content(backend: &mut dyn ClipboardBackend, images: &ImageRepository) -> PasteContent {
    match backend.read_text() {
        Some(text) => paste_content_from_text(&text, images),
        None => PasteContent::Empty,
    }
}

pub fn paste_content_from_text(text: &str, images: &ImageRepository) -> PasteContent {
    if let Some(payload) = text.strip_prefix(CLIPBOARD_PREFIX) {
        return match decode_nodes_from_clipboard(payload, images) {
            Some(nodes) if !nodes.is_empty() => PasteContent::Nodes(nodes),
            _ => PasteContent::Empty,
        };
    }
    // Unsupported Squiggle payloads must not become canvas text.
    if text.starts_with(CLIPBOARD_FORMAT_PREFIX) || text.trim().is_empty() {
        return PasteContent::Empty;
    }
    PasteContent::Text(text.to_owned())
}

/// The payload includes each referenced PNG once, independent of local storage.
pub fn encode_nodes_for_clipboard(nodes: &[Node], images: &ImageRepository) -> Result<String, String> {
    let json_nodes: Vec<Value> = nodes.iter().map(Node::to_json).collect();
    let mut ids = BTreeSet::new();
    json_nodes.iter().for_each(|n| collect_image_ids(n, &mut ids));

    let mut attachments = Map::new();
    for id in ids {
        let bytes = images.read_png_bytes(&id).ok_or_else(|| format!("Missing clipboard image: {id}"))?;
        attachments.insert(id, Value::String(base64_encode(&bytes)));
    }
    Ok(json!({ "nodes": json_nodes, "images": attachments }).to_string())
}

/// Returns detached nodes with fresh identities, or `None` for an invalid payload.
/// Nothing is imported into `images` unless the nodes themselves parse.
pub fn decode_nodes_from_clipboard(payload: &str, images: &ImageRepository) -> Option<Vec<Node>> {
    decode(payload, images).ok()
}

fn decode(payload: &str, images: &ImageRepository) -> Result<Vec<Node>, String> {
    let json: Value = serde_json::from_str(payload).map_err(|e| e.to_string())?;
    let mut raw_nodes = json.get("nodes").and_then(Value::as_array).ok_or("nodes")?.clone();
    let attachments = json.get("images").and_then(Value::as_object).ok_or("images")?;
    raw_nodes.iter().try_for_each(|n| Node::from_json(n).map(drop))?;

    let mut imported = HashMap::new();
    for node in &mut raw_nodes {
        import_attachments(node, attachments, images, &mut imported)?;
    }
    raw_nodes
        .iter()
        .map(|n| Node::from_json(n).map(|node| node.copy_with(None, true)))
        .collect()
}

fn image_id_of(node: &Value) -> Option<&str> {
    let content = node.get("content")?;
    (content.get("type")?.as_str()? == "image").then(|| content.get("imageId")?.as_str()).flatten()
}

fn collect_image_ids(node: &Value, out: &mut BTreeSet<String>) {
    if let Some(id) = image_id_of(node) {
        out.insert(id.to_owned());
    }
    for child in node.get("children").and_then(Value::as_array).into_iter().flatten() {
        collect_image_ids(child, out);
    }
}

/// Rewrites image ids in the raw JSON to freshly imported ones (each attachment imported once).
fn import_attachments(
    node: &mut Value,
    attachments: &Map<String, Value>,
    images: &ImageRepository,
    imported: &mut HashMap<String, String>,
) -> Result<(), String> {
    if let Some(original) = image_id_of(node).map(str::to_owned) {
        let new_id = match imported.get(&original) {
            Some(id) => id.clone(),
            None => {
                let encoded = attachments
                    .get(&original)
                    .and_then(Value::as_str)
                    .ok_or_else(|| format!("Missing image attachment: {original}"))?;
                let bytes = base64_decode(encoded).ok_or("Invalid image attachment")?;
                let stored = images.import_png_bytes(&bytes).ok_or("Invalid image attachment")?;
                imported.insert(original, stored.image_id.clone());
                stored.image_id
            }
        };
        node["content"]["imageId"] = Value::String(new_id);
    }
    if let Some(children) = node.get_mut("children").and_then(Value::as_array_mut) {
        for child in children {
            import_attachments(child, attachments, images, imported)?;
        }
    }
    Ok(())
}

const B64: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

pub(crate) fn base64_encode(bytes: &[u8]) -> String {
    let mut out = String::with_capacity(bytes.len().div_ceil(3) * 4);
    for chunk in bytes.chunks(3) {
        let n = chunk.iter().enumerate().fold(0u32, |acc, (i, b)| acc | (*b as u32) << (16 - 8 * i));
        for i in 0..4 {
            if i <= chunk.len() {
                out.push(B64[(n >> (18 - 6 * i) & 63) as usize] as char);
            } else {
                out.push('=');
            }
        }
    }
    out
}

/// Strict standard-alphabet base64 with padding; `None` on any invalid input.
pub(crate) fn base64_decode(text: &str) -> Option<Vec<u8>> {
    let bytes = text.as_bytes();
    if bytes.len() % 4 != 0 {
        return None;
    }
    let mut out = Vec::with_capacity(bytes.len() / 4 * 3);
    for (index, quad) in bytes.chunks(4).enumerate() {
        let last = index == bytes.len() / 4 - 1;
        let pad = quad.iter().rev().take_while(|&&b| b == b'=').count();
        if pad > 2 || (pad > 0 && !last) {
            return None;
        }
        let mut n = 0u32;
        for &b in &quad[..4 - pad] {
            n = n << 6 | B64.iter().position(|&c| c == b)? as u32;
        }
        n <<= 6 * pad as u32;
        out.extend_from_slice(&n.to_be_bytes()[1..4 - pad]);
    }
    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::feature::Feature;
    use crate::feature_kind::FeatureKind;
    use crate::feature_kinds::image::ImageKind;
    use crate::feature_kinds::text::TextKind;
    use crate::geom::{Point, Size};
    use crate::group::Group;
    use crate::ids::{NO_ID, NodeId};
    use crate::repositories::test_util::{TempDir, test_png};

    struct Setup {
        _a: TempDir,
        _b: TempDir,
        source: ImageRepository,
        target: ImageRepository,
        target_dir: std::path::PathBuf,
    }

    fn setup() -> Setup {
        let (a, b) = (TempDir::new("clip_source"), TempDir::new("clip_target"));
        let source = ImageRepository::new(&a.0);
        let target = ImageRepository::new(&b.0);
        source.initialize().unwrap();
        target.initialize().unwrap();
        let target_dir = b.0.clone();
        Setup { _a: a, _b: b, source, target, target_dir }
    }

    fn file_count(dir: &std::path::Path) -> usize {
        std::fs::read_dir(dir).unwrap().count()
    }

    fn image_feature(id: u32, image_id: &str) -> Feature {
        let kind = ImageKind::from_json(&json!({"type": "image", "imageId": image_id, "strokeWidth": 3.0})).unwrap();
        let mut f = Feature::new(Point::new(5.0, 7.0), Size::new(8.0, 6.0), FeatureKind::Image(kind));
        f.id = NodeId(id);
        f
    }

    fn image_id_in(node: &Node) -> String {
        image_id_of(&node.to_json()).unwrap().to_owned()
    }

    #[test]
    fn nested_groups_transfer_a_shared_png_once_with_fresh_node_ids() {
        let s = setup();
        let png = test_png(8, 6);
        let imported = s.source.import_png_bytes(&png).unwrap();
        let image = image_feature(12, &imported.image_id);
        let mut nested = Group::new(Point::new(20.0, 30.0), vec![Node::Feature(image.clone())]);
        nested.id = NodeId(11);
        let mut second = image.clone();
        second.id = NodeId(13);
        let mut group = Group::new(Point::new(100.0, 200.0), vec![Node::Group(nested.clone()), Node::Feature(second)]);
        group.id = NodeId(10);
        let group = Node::Group(group);

        let before = group.to_json();
        let payload = encode_nodes_for_clipboard(std::slice::from_ref(&group), &s.source).unwrap();
        let parsed: Value = serde_json::from_str(&payload).unwrap();
        assert_eq!(parsed["images"].as_object().unwrap().len(), 1);

        let decoded = decode_nodes_from_clipboard(&payload, &s.target).unwrap();
        let Node::Group(dg) = &decoded[0] else { panic!("group") };
        let Node::Group(dn) = &dg.children[0] else { panic!("nested") };
        let first_image = &dn.children[0];
        let second_image = &dg.children[1];

        for n in [&decoded[0], &dg.children[0], first_image, second_image] {
            assert_eq!(n.id(), NO_ID);
        }
        assert_eq!(dg.origin, Point::new(100.0, 200.0));
        assert_eq!(dn.origin, nested.origin);
        assert_eq!(first_image.origin(), image.origin);
        assert_eq!(first_image.to_json()["content"]["strokeWidth"], json!(3.0));
        let new_id = image_id_in(first_image);
        assert_ne!(new_id, imported.image_id);
        assert_eq!(image_id_in(second_image), new_id);
        assert_eq!(s.target.read_png_bytes(&new_id).unwrap(), png);
        assert_eq!(file_count(&s.target_dir), 1);
        assert_eq!(group.to_json(), before);
    }

    #[test]
    fn text_round_trips_without_image_attachments() {
        let s = setup();
        let mut feature = Feature::new(
            Point::new(10.0, 20.0),
            Size::new(120.0, 80.0),
            FeatureKind::Text(TextKind::default()),
        );
        feature.id = NodeId(42);
        let node = Node::Feature(feature);
        let payload = encode_nodes_for_clipboard(std::slice::from_ref(&node), &s.source).unwrap();
        let decoded = decode_nodes_from_clipboard(&payload, &s.target).unwrap();
        assert_eq!(decoded[0].to_json(), node.copy_with(None, true).to_json());
        assert_eq!(file_count(&s.target_dir), 0);
    }

    #[test]
    fn rejects_malformed_nodes_and_missing_or_invalid_images() {
        let s = setup();
        let image = Node::Feature(image_feature(0, "missing.png"));
        let nodes = json!([image.to_json()]);
        let payloads = [
            "not json".to_owned(),
            json!({"nodes": [{"type": "unknown"}], "images": {}}).to_string(),
            json!({"nodes": nodes, "images": {}}).to_string(),
            json!({"nodes": nodes, "images": {"missing.png": "%%%"}}).to_string(),
            json!({"nodes": nodes, "images": {"missing.png": base64_encode(&[1, 2, 3])}}).to_string(),
        ];
        for payload in &payloads {
            assert!(decode_nodes_from_clipboard(payload, &s.target).is_none(), "{payload}");
        }
        assert_eq!(file_count(&s.target_dir), 0);
        assert!(encode_nodes_for_clipboard(&[image], &s.source).is_err());
    }

    #[test]
    fn base64_round_trips_and_rejects_garbage() {
        for len in 0..8u8 {
            let data: Vec<u8> = (0..len).map(|i| i.wrapping_mul(91)).collect();
            assert_eq!(base64_decode(&base64_encode(&data)).unwrap(), data);
        }
        assert_eq!(base64_encode(b"Man"), "TWFu");
        assert_eq!(base64_encode(b"Ma"), "TWE=");
        assert!(base64_decode("%%%").is_none());
        assert!(base64_decode("TW=u").is_none());
    }

    struct MemClipboard(Option<String>);

    impl ClipboardBackend for MemClipboard {
        fn read_text(&mut self) -> Option<String> {
            self.0.clone()
        }
        fn write_text(&mut self, text: &str) -> bool {
            self.0 = Some(text.to_owned());
            true
        }
    }

    #[test]
    fn copy_then_paste_through_backend_and_text_classification() {
        let s = setup();
        let mut clip = MemClipboard(None);
        assert_eq!(copy_nodes_to_clipboard(&[], &s.source, &mut clip), Ok(false));
        let node = Node::Feature(Feature::new(
            Point::new(1.0, 2.0),
            Size::new(3.0, 4.0),
            FeatureKind::Text(TextKind::default()),
        ));
        assert_eq!(copy_nodes_to_clipboard(&[node], &s.source, &mut clip), Ok(true));
        assert!(clip.0.as_deref().unwrap().starts_with(CLIPBOARD_PREFIX));
        assert!(matches!(read_paste_content(&mut clip, &s.target), PasteContent::Nodes(n) if n.len() == 1));

        assert_eq!(paste_content_from_text("hello", &s.target), PasteContent::Text("hello".into()));
        assert_eq!(paste_content_from_text("  \n", &s.target), PasteContent::Empty);
        assert_eq!(paste_content_from_text("squiggle-nodes:9:{}", &s.target), PasteContent::Empty);
        assert_eq!(paste_content_from_text("squiggle-nodes:3:garbage", &s.target), PasteContent::Empty);
        assert_eq!(read_paste_content(&mut MemClipboard(None), &s.target), PasteContent::Empty);
    }
}
