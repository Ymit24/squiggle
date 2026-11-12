/// Document-wide node identifier. `NO_ID` marks a node not yet registered in a document.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct NodeId(pub u32);

pub const NO_ID: NodeId = NodeId(0);

/// A node container: `None` is the document root, `Some(id)` is the group with that id.
pub type Container = Option<NodeId>;
