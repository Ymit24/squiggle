use super::*;
use crate::document::Document;
use crate::editor::test_util::{ids, rect_at};
use crate::geom::Point;
use crate::group::Group;
use crate::ids::{Container, NodeId};
use crate::node::Node;

fn id(n: u32) -> NodeId {
    NodeId(n)
}

fn with_id(mut node: Node, n: u32) -> Node {
    node.set_id(id(n));
    node
}

fn doc_of(n: u32) -> Document {
    Document::from_nodes((1..=n).map(|i| with_id(rect_at(0.0, 0.0), i)))
}

fn origin(doc: &Document, n: u32) -> Point {
    doc.node(id(n)).unwrap().origin()
}

fn child_ids(doc: &Document, c: Container) -> Vec<NodeId> {
    doc.children(c).unwrap().iter().map(Node::id).collect()
}

fn pt(x: f64, y: f64) -> Point {
    Point::new(x, y)
}

mod transaction {
    use super::*;

    fn tx(doc: &Document) -> Transaction {
        Transaction::new(doc, "Edit", None).unwrap()
    }

    #[test]
    fn records_only_watched_nodes() {
        let mut doc = doc_of(2);
        let mut edit = tx(&doc);
        edit.watch(&doc, &[id(1)]).unwrap();
        doc.node_mut(id(1)).unwrap().set_origin(pt(40.0, 50.0));
        let change = edit.commit(&doc).unwrap().unwrap();

        assert_eq!(change.affected_node_count(), 1);
        assert!(!change.changes_order());
        change.undo(&mut doc).unwrap();
        assert_eq!(origin(&doc, 1), Point::ZERO);
        change.redo(&mut doc).unwrap();
        assert_eq!(origin(&doc, 1), pt(40.0, 50.0));
    }

    #[test]
    fn returns_none_when_watched_node_unchanged() {
        let doc = doc_of(1);
        let mut edit = tx(&doc);
        edit.watch(&doc, &[id(1)]).unwrap();
        assert!(edit.commit(&doc).unwrap().is_none());
    }

    #[test]
    fn cancel_restores_updates_and_removes_additions() {
        let mut doc = doc_of(1);
        let mut edit = tx(&doc);
        edit.watch(&doc, &[id(1)]).unwrap();
        doc.node_mut(id(1)).unwrap().set_origin(pt(30.0, 30.0));
        edit.add(&mut doc, rect_at(50.0, 50.0), None).unwrap();
        edit.cancel(&mut doc).unwrap();

        assert_eq!(ids(&doc), vec![id(1)]);
        assert_eq!(origin(&doc, 1), Point::ZERO);
    }

    #[test]
    fn undo_and_redo_structural_edits_preserve_order_and_ids() {
        let mut doc = doc_of(3);
        let mut edit = tx(&doc);
        edit.remove_all(&mut doc, &[id(2)]).unwrap();
        let added = edit.add(&mut doc, rect_at(0.0, 0.0), None).unwrap();
        edit.reorder(&mut doc, &[added, id(3), id(1)]).unwrap();
        let change = edit.commit(&doc).unwrap().unwrap();

        assert!(change.changes_order());
        assert_eq!(ids(&doc), vec![added, id(3), id(1)]);
        change.undo(&mut doc).unwrap();
        assert_eq!(ids(&doc), vec![id(1), id(2), id(3)]);
        change.redo(&mut doc).unwrap();
        assert_eq!(ids(&doc), vec![added, id(3), id(1)]);
    }

    #[test]
    fn update_captures_before_invoking_the_mutation() {
        let mut doc = doc_of(1);
        let mut edit = tx(&doc);
        edit.update(&mut doc, id(1), |n| n.set_origin(pt(5.0, 8.0))).unwrap();
        let change = edit.commit(&doc).unwrap().unwrap();
        change.undo(&mut doc).unwrap();
        assert_eq!(origin(&doc, 1), Point::ZERO);
    }

    #[test]
    fn captures_and_restores_groups() {
        let mut doc = Document::default();
        let group = Group::new(pt(10.0, 20.0), vec![with_id(rect_at(0.0, 0.0), 2)]);
        doc.insert(None, with_id(group.into(), 1), None).unwrap();
        let mut edit = tx(&doc);
        edit.update(&mut doc, id(1), |n| n.set_origin(pt(40.0, 50.0))).unwrap();
        let change = edit.commit(&doc).unwrap().unwrap();

        change.undo(&mut doc).unwrap();
        assert_eq!(origin(&doc, 1), pt(10.0, 20.0));
        let group = doc.node(id(1)).unwrap().as_group().unwrap();
        assert!(group.children[0].as_feature().is_some());
        assert_eq!(group.children[0].id(), id(2));
        change.redo(&mut doc).unwrap();
        assert_eq!(origin(&doc, 1), pt(40.0, 50.0));
    }

    #[test]
    fn adds_and_replays_groups() {
        let mut doc = Document::default();
        let mut edit = tx(&doc);
        let gid = edit.add(&mut doc, Group::new(Point::ZERO, vec![rect_at(0.0, 0.0)]).into(), None).unwrap();
        let change = edit.commit(&doc).unwrap().unwrap();
        change.undo(&mut doc).unwrap();
        assert!(doc.nodes().is_empty());
        change.redo(&mut doc).unwrap();
        assert!(doc.node(gid).unwrap().as_group().is_some());
    }

    #[test]
    fn closed_edits_reject_further_use() {
        let doc = doc_of(1);
        let mut edit = tx(&doc);
        edit.commit(&doc).unwrap();
        assert_eq!(edit.watch(&doc, &[id(1)]), Err(HistoryError::Closed));
        assert!(!edit.is_open());
    }

    #[test]
    fn duplicated_subtrees_receive_fresh_ids_and_replay_independently() {
        let mut doc = Document::default();
        let original = doc
            .insert(None, Group::new(Point::ZERO, vec![with_id(rect_at(0.0, 0.0), 12)]).into(), None)
            .unwrap();
        let mut edit = tx(&doc);
        let copy_node = doc.node(original).unwrap().copy_with(None, true);
        let copy = edit.add(&mut doc, copy_node, None).unwrap();
        let copied_child = doc.children(Some(copy)).unwrap()[0].id();
        assert_ne!(copied_child, id(12));
        let change = edit.commit(&doc).unwrap().unwrap();

        change.undo(&mut doc).unwrap();
        assert!(doc.node(copied_child).is_none());
        assert!(doc.node(id(12)).is_some());
        change.redo(&mut doc).unwrap();
        assert_eq!(doc.parent_of(copied_child), Some(Some(copy)));

        let mut loaded = Document::from_json(&doc.to_json()).unwrap();
        assert_eq!(loaded.parent_of(copied_child), Some(Some(copy)));
        assert!(loaded.generate_id().0 > copied_child.0);
    }

    #[test]
    fn group_edit_child_ungroup_and_replay_recreated_containers() {
        let mut doc = Document::from_nodes([
            with_id(rect_at(20.0, 30.0), 1),
            with_id(rect_at(0.0, 0.0), 3),
            with_id(rect_at(40.0, 50.0), 2),
        ]);
        // Group a(1) and b(2) at origin (10, 10).
        let mut grouping = tx(&doc);
        let mut removed = grouping.remove_all(&mut doc, &[id(1), id(2)]).unwrap();
        for n in &mut removed {
            n.set_origin(n.origin() - pt(10.0, 10.0));
        }
        let group = grouping.add(&mut doc, Group::new(pt(10.0, 10.0), removed).into(), None).unwrap();
        let grouped = grouping.commit(&doc).unwrap().unwrap();

        let mut mv = Transaction::new(&doc, "Move", Some(group)).unwrap();
        mv.update(&mut doc, id(1), |n| n.set_origin(pt(90.0, 90.0))).unwrap();
        let moved = mv.commit(&doc).unwrap().unwrap();

        let mut ungroup = tx(&doc);
        let removed = ungroup.remove_all(&mut doc, &[group]).unwrap();
        let Node::Group(g) = removed.into_iter().next().unwrap() else { panic!("group expected") };
        for mut child in g.children {
            child.set_origin(child.origin() + g.origin);
            ungroup.add(&mut doc, child, None).unwrap();
        }
        let ungrouped = ungroup.commit(&doc).unwrap().unwrap();

        for _ in 0..2 {
            ungrouped.undo(&mut doc).unwrap();
            assert_eq!(doc.parent_of(id(1)), Some(Some(group)));
            moved.undo(&mut doc).unwrap();
            assert_eq!(origin(&doc, 1), pt(10.0, 20.0));
            grouped.undo(&mut doc).unwrap();
            assert_eq!(ids(&doc), vec![id(1), id(3), id(2)]);
            assert_eq!(origin(&doc, 1), pt(20.0, 30.0));
            assert!(doc.node(group).is_none());
            grouped.redo(&mut doc).unwrap();
            moved.redo(&mut doc).unwrap();
            assert_eq!(origin(&doc, 1), pt(90.0, 90.0));
            ungrouped.redo(&mut doc).unwrap();
            assert_eq!(origin(&doc, 1), pt(100.0, 100.0));
            assert_eq!(doc.parent_of(id(1)), Some(None));
            assert!(doc.node(group).is_none());
        }
    }

    #[test]
    fn nested_grouping_cancellation_restores_only_its_container() {
        let mut doc = Document::default();
        let parent = Group::new(
            Point::ZERO,
            vec![with_id(rect_at(0.0, 0.0), 1), with_id(rect_at(0.0, 0.0), 2)],
        );
        let parent = doc.insert(None, parent.into(), None).unwrap();
        let mut edit = Transaction::new(&doc, "Group", Some(parent)).unwrap();
        let removed = edit.remove_all(&mut doc, &[id(1), id(2)]).unwrap();
        let added = edit.add(&mut doc, Group::new(Point::ZERO, removed).into(), None).unwrap();
        edit.cancel(&mut doc).unwrap();

        assert_eq!(child_ids(&doc, Some(parent)), vec![id(1), id(2)]);
        assert!(doc.node(added).is_none());
        assert_eq!(doc.parent_of(id(1)), Some(Some(parent)));
        assert_eq!(ids(&doc), vec![parent]);
    }

    #[test]
    fn nested_stacking_and_deletion_restore_order() {
        let mut doc = Document::default();
        let kids = (1..=3).map(|i| with_id(rect_at(0.0, 0.0), i)).collect();
        let parent = doc.insert(None, Group::new(Point::ZERO, kids).into(), None).unwrap();
        let scope = Some(parent);

        let mut reorder = Transaction::new(&doc, "Front", scope).unwrap();
        reorder.reorder(&mut doc, &[id(2), id(3), id(1)]).unwrap();
        let order = reorder.commit(&doc).unwrap().unwrap();
        assert_eq!(order.affected_node_count(), 0);
        order.undo(&mut doc).unwrap();
        assert_eq!(child_ids(&doc, scope), vec![id(1), id(2), id(3)]);
        order.redo(&mut doc).unwrap();

        let mut delete = Transaction::new(&doc, "Delete", scope).unwrap();
        delete.remove_all(&mut doc, &[id(1), id(3)]).unwrap();
        let removed = delete.commit(&doc).unwrap().unwrap();
        assert!(doc.node(id(1)).is_none());
        removed.undo(&mut doc).unwrap();
        assert_eq!(child_ids(&doc, scope), vec![id(2), id(3), id(1)]);
        assert_eq!(doc.parent_of(id(3)), Some(scope));
        removed.redo(&mut doc).unwrap();
        assert_eq!(child_ids(&doc, scope), vec![id(2)]);
    }

    #[test]
    fn rejects_foreign_children_and_missing_containers() {
        let mut doc = Document::default();
        let group = Group::new(Point::ZERO, vec![with_id(rect_at(0.0, 0.0), 9)]);
        doc.insert(None, group.into(), None).unwrap();
        let mut edit = tx(&doc);
        assert_eq!(edit.watch(&doc, &[id(9)]), Err(HistoryError::NotDirectChild(id(9))));
        assert!(matches!(Transaction::new(&doc, "x", Some(id(77))), Err(HistoryError::NoSuchContainer(_))));
        // A removal of non-children is a no-op.
        assert!(edit.remove_all(&mut doc, &[id(9)]).unwrap().is_empty());
    }

    #[test]
    fn only_structural_edits_replay_into_recreated_container() {
        let mut doc = Document::default();
        let g = doc.insert(None, Group::new(Point::ZERO, vec![with_id(rect_at(0.0, 0.0), 5)]).into(), None).unwrap();
        let mut edit = Transaction::new(&doc, "Move", Some(g)).unwrap();
        edit.update(&mut doc, id(5), |n| n.set_origin(pt(1.0, 1.0))).unwrap();
        let change = edit.commit(&doc).unwrap().unwrap();
        doc.remove(g);
        assert_eq!(change.undo(&mut doc), Err(HistoryError::ContainerGone(g)));
    }
}

mod history {
    use super::*;

    struct Fixture {
        doc: Document,
        history: History,
    }

    fn fixture() -> Fixture {
        Fixture { doc: doc_of(1), history: History::new() }
    }

    impl Fixture {
        fn mv(&mut self, x: f64) {
            self.history
                .run(&mut self.doc, "Move", None, |tx| tx.update(id(1), |n| n.set_origin(pt(x, 0.0))))
                .unwrap();
        }

        fn x(&self) -> Point {
            origin(&self.doc, 1)
        }
    }

    #[test]
    fn clears_undo_and_redo_stacks() {
        let mut f = fixture();
        assert!(!f.history.can_undo() && !f.history.can_redo());
        f.mv(10.0);
        f.mv(20.0);
        f.history.undo(&mut f.doc).unwrap();
        assert!(f.history.can_undo() && f.history.can_redo());
        f.history.clear().unwrap();
        assert!(!f.history.can_undo() && !f.history.can_redo());
    }

    #[test]
    fn clear_fails_when_transaction_active() {
        let mut f = fixture();
        f.mv(10.0);
        f.mv(20.0);
        f.history.undo(&mut f.doc).unwrap();
        f.history.begin(&f.doc, "Pending", None).unwrap();
        f.history.edit(&mut f.doc).unwrap().update(id(1), |n| n.set_origin(pt(30.0, 0.0))).unwrap();

        assert_eq!(f.history.clear(), Err(HistoryError::ActiveTransaction));
        assert!(f.history.active().unwrap().is_open());
        assert_eq!(f.x(), pt(30.0, 0.0));

        f.history.cancel(&mut f.doc).unwrap();
        assert_eq!(f.x(), pt(10.0, 0.0));
        assert!(f.history.can_undo() && f.history.can_redo());
    }

    #[test]
    fn commits_multiple_actions_and_replays_in_order() {
        let mut f = fixture();
        f.mv(10.0);
        f.mv(20.0);
        assert!(!f.history.is_active());
        assert_eq!(f.x(), pt(20.0, 0.0));

        f.history.undo(&mut f.doc).unwrap();
        assert_eq!(f.x(), pt(10.0, 0.0));
        f.history.undo(&mut f.doc).unwrap();
        assert_eq!(f.x(), Point::ZERO);
        assert!(!f.history.can_undo() && f.history.can_redo());

        f.history.redo(&mut f.doc).unwrap();
        assert_eq!(f.x(), pt(10.0, 0.0));
        f.history.redo(&mut f.doc).unwrap();
        assert_eq!(f.x(), pt(20.0, 0.0));
        assert!(f.history.can_undo() && !f.history.can_redo());
    }

    #[test]
    fn new_change_after_undo_discards_redo_branch() {
        let mut f = fixture();
        f.mv(10.0);
        f.history.undo(&mut f.doc).unwrap();
        f.mv(20.0);
        assert!(!f.history.can_redo());
        f.history.undo(&mut f.doc).unwrap();
        assert_eq!(f.x(), Point::ZERO);
        f.history.redo(&mut f.doc).unwrap();
        assert_eq!(f.x(), pt(20.0, 0.0));
    }

    #[test]
    fn empty_and_unchanged_transactions_preserve_redo() {
        let mut f = fixture();
        f.mv(10.0);
        f.history.undo(&mut f.doc).unwrap();
        f.history.run(&mut f.doc, "Empty", None, |_| Ok(())).unwrap();
        f.mv(0.0);
        assert!(!f.history.is_active());
        assert!(!f.history.can_undo());
        assert!(f.history.can_redo());
        f.history.redo(&mut f.doc).unwrap();
        assert_eq!(f.x(), pt(10.0, 0.0));
    }

    #[test]
    fn cancel_restores_mutations_without_touching_stacks() {
        let mut f = fixture();
        f.mv(10.0);
        f.history.undo(&mut f.doc).unwrap();
        f.history.begin(&f.doc, "Cancelled move", None).unwrap();
        f.history.edit(&mut f.doc).unwrap().update(id(1), |n| n.set_origin(pt(30.0, 0.0))).unwrap();
        f.history.cancel(&mut f.doc).unwrap();
        assert_eq!(f.x(), Point::ZERO);
        assert!(!f.history.is_active());
        assert!(!f.history.can_undo());
        assert!(f.history.can_redo());
        f.history.redo(&mut f.doc).unwrap();
        assert_eq!(f.x(), pt(10.0, 0.0));
    }

    #[test]
    fn run_rolls_back_partial_changes_and_returns_the_original_error() {
        let mut f = fixture();
        let error = HistoryError::Custom("Failed action".into());
        let result: Result<(), _> = f.history.run(&mut f.doc, "Fail", None, |tx| {
            tx.update(id(1), |n| n.set_origin(pt(30.0, 0.0)))?;
            tx.add(rect_at(0.0, 0.0), None)?;
            Err(error.clone())
        });
        assert_eq!(result, Err(error));
        assert_eq!(f.doc.nodes().len(), 1);
        assert_eq!(f.x(), Point::ZERO);
        assert!(!f.history.is_active());
        assert!(!f.history.can_undo());
        f.history.run(&mut f.doc, "Next action", None, |tx| tx.add(rect_at(0.0, 0.0), None)).unwrap();
        assert!(f.history.can_undo());
    }

    #[test]
    fn nested_begin_and_run_leave_the_original_transaction_active() {
        let mut f = fixture();
        f.history.begin(&f.doc, "Original", None).unwrap();
        assert_eq!(f.history.begin(&f.doc, "Nested", None), Err(HistoryError::AlreadyActive));
        let mut ran = false;
        let nested = f.history.run(&mut f.doc, "Nested", None, |_| {
            ran = true;
            Ok(())
        });
        assert_eq!(nested, Err(HistoryError::AlreadyActive));
        assert!(!ran);
        assert_eq!(f.history.active().unwrap().label(), "Original");
        assert!(f.history.active().unwrap().is_open());
        f.history.cancel(&mut f.doc).unwrap();
    }

    #[test]
    fn undo_and_redo_reject_active_transactions_without_consuming_history() {
        let mut f = fixture();
        f.mv(10.0);
        f.mv(20.0);
        f.history.undo(&mut f.doc).unwrap();
        f.history.begin(&f.doc, "Pending", None).unwrap();
        assert_eq!(f.history.undo(&mut f.doc), Err(HistoryError::ActiveTransaction));
        assert_eq!(f.history.redo(&mut f.doc), Err(HistoryError::ActiveTransaction));
        assert_eq!(f.x(), pt(10.0, 0.0));
        f.history.cancel(&mut f.doc).unwrap();
        f.history.redo(&mut f.doc).unwrap();
        assert_eq!(f.x(), pt(20.0, 0.0));
        f.history.undo(&mut f.doc).unwrap();
        f.history.undo(&mut f.doc).unwrap();
        assert_eq!(f.x(), Point::ZERO);
    }

    #[test]
    fn operations_without_transaction_or_commit_fail() {
        let mut f = fixture();
        assert_eq!(f.history.commit(&f.doc), Err(HistoryError::NoActiveTransaction));
        assert_eq!(f.history.cancel(&mut f.doc), Err(HistoryError::NoActiveTransaction));
        assert_eq!(f.history.undo(&mut f.doc), Err(HistoryError::NothingToUndo));
        assert_eq!(f.history.redo(&mut f.doc), Err(HistoryError::NothingToRedo));
        assert!(!f.history.is_active());
    }

    #[test]
    fn begin_and_run_forward_the_container_and_share_one_stack() {
        let mut f = fixture();
        let group = f.doc.insert(None, Group::new(Point::ZERO, vec![with_id(rect_at(0.0, 0.0), 50)]).into(), None).unwrap();
        let scope = Some(group);
        f.history.begin(&f.doc, "Move child", scope).unwrap();
        f.history.edit(&mut f.doc).unwrap().update(id(50), |n| n.set_origin(pt(5.0, 0.0))).unwrap();
        assert!(f.history.commit(&f.doc).unwrap());
        f.mv(10.0);
        f.history
            .run(&mut f.doc, "Move child again", scope, |tx| tx.update(id(50), |n| n.set_origin(pt(15.0, 0.0))))
            .unwrap();

        let child = |f: &Fixture| origin(&f.doc, 50);
        f.history.undo(&mut f.doc).unwrap();
        assert_eq!(child(&f), pt(5.0, 0.0));
        f.history.undo(&mut f.doc).unwrap();
        assert_eq!(f.x(), Point::ZERO);
        f.history.undo(&mut f.doc).unwrap();
        assert_eq!(child(&f), Point::ZERO);
        for _ in 0..3 {
            f.history.redo(&mut f.doc).unwrap();
        }
        assert_eq!(child(&f), pt(15.0, 0.0));
        assert_eq!(f.x(), pt(10.0, 0.0));
        assert_eq!(f.history.undo_label(), Some("Move child again"));
    }

    #[test]
    fn revision_advances_on_changes() {
        let mut f = fixture();
        let r0 = f.history.revision();
        f.mv(10.0);
        let r1 = f.history.revision();
        assert!(r1 > r0);
        f.history.undo(&mut f.doc).unwrap();
        assert!(f.history.revision() > r1);
    }
}
