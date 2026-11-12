pub mod edit;
pub mod history;

pub use edit::{Commit, HistoryError, Transaction, Tx};
pub use history::History;

#[cfg(test)]
mod tests;
