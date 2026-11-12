//! Undo/redo stacks over [`Commit`]s, with at most one active [`Transaction`].

use super::edit::{Commit, HistoryError, Transaction, Tx};
use crate::document::Document;
use crate::ids::Container;

#[derive(Debug, Default)]
pub struct History {
    active: Option<Transaction>,
    undo_stack: Vec<Commit>,
    redo_stack: Vec<Commit>,
    revision: u64,
}

impl History {
    pub fn new() -> Self {
        History::default()
    }

    /// Bumped whenever the stacks change; replaces Dart's `notifyListeners`.
    pub fn revision(&self) -> u64 {
        self.revision
    }

    pub fn is_active(&self) -> bool {
        self.active.is_some()
    }

    pub fn active(&self) -> Option<&Transaction> {
        self.active.as_ref()
    }

    /// The active transaction paired with `doc`.
    pub fn edit<'a>(&'a mut self, doc: &'a mut Document) -> Result<Tx<'a>, HistoryError> {
        let tx = self.active.as_mut().ok_or(HistoryError::NoActiveTransaction)?;
        Ok(Tx::new(tx, doc))
    }

    pub fn can_undo(&self) -> bool {
        !self.undo_stack.is_empty()
    }

    pub fn can_redo(&self) -> bool {
        !self.redo_stack.is_empty()
    }

    pub fn undo_label(&self) -> Option<&str> {
        self.undo_stack.last().map(Commit::label)
    }

    pub fn redo_label(&self) -> Option<&str> {
        self.redo_stack.last().map(Commit::label)
    }

    pub fn begin(&mut self, doc: &Document, label: &str, container: Container) -> Result<(), HistoryError> {
        if self.active.is_some() {
            return Err(HistoryError::AlreadyActive);
        }
        self.active = Some(Transaction::new(doc, label, container)?);
        Ok(())
    }

    pub fn clear(&mut self) -> Result<(), HistoryError> {
        if self.active.is_some() {
            return Err(HistoryError::ActiveTransaction);
        }
        self.undo_stack.clear();
        self.redo_stack.clear();
        self.revision += 1;
        Ok(())
    }

    pub fn undo(&mut self, doc: &mut Document) -> Result<(), HistoryError> {
        if self.undo_stack.is_empty() {
            return Err(HistoryError::NothingToUndo);
        }
        if self.active.is_some() {
            return Err(HistoryError::ActiveTransaction);
        }
        self.undo_stack.last().expect("checked").undo(doc)?;
        let commit = self.undo_stack.pop().expect("checked");
        self.redo_stack.push(commit);
        self.revision += 1;
        Ok(())
    }

    pub fn redo(&mut self, doc: &mut Document) -> Result<(), HistoryError> {
        if self.redo_stack.is_empty() {
            return Err(HistoryError::NothingToRedo);
        }
        if self.active.is_some() {
            return Err(HistoryError::ActiveTransaction);
        }
        self.redo_stack.last().expect("checked").redo(doc)?;
        let commit = self.redo_stack.pop().expect("checked");
        self.undo_stack.push(commit);
        self.revision += 1;
        Ok(())
    }

    /// Commits the active transaction; returns whether a history entry was added.
    pub fn commit(&mut self, doc: &Document) -> Result<bool, HistoryError> {
        let mut tx = self.active.take().ok_or(HistoryError::NoActiveTransaction)?;
        let Some(commit) = tx.commit(doc)? else { return Ok(false) };
        self.undo_stack.push(commit);
        self.redo_stack.clear();
        self.revision += 1;
        Ok(true)
    }

    pub fn cancel(&mut self, doc: &mut Document) -> Result<(), HistoryError> {
        let mut tx = self.active.take().ok_or(HistoryError::NoActiveTransaction)?;
        tx.cancel(doc)?;
        self.revision += 1;
        Ok(())
    }

    /// Runs `action` as one edit scoped to `container`. On `Err` the edit is rolled back and the
    /// error returned. Fails without calling `action` when a transaction is already active.
    pub fn run<R>(
        &mut self,
        doc: &mut Document,
        label: &str,
        container: Container,
        action: impl FnOnce(&mut Tx<'_>) -> Result<R, HistoryError>,
    ) -> Result<R, HistoryError> {
        self.begin(doc, label, container)?;
        let result = action(&mut self.edit(doc)?);
        match result {
            Ok(value) => self.commit(doc).map(|_| value),
            Err(error) => {
                self.cancel(doc)?;
                Err(error)
            }
        }
    }
}
