use gpui::*;

use crate::{
    document::{Command, Document},
    feature_id::FeatureId,
    shape_canvas::ShapeCanvas,
    toolbar::{bind_tool_keys, ActivateCreateRectTool, ActivateSelectTool, Toolbar},
    tool::Tool,
    tool_store::ToolStore,
};

pub struct SelectionState {
    pub selected_features: Vec<FeatureId>,
}

impl SelectionState {
    pub fn new() -> Self {
        Self {
            selected_features: Vec::new(),
        }
    }
}

actions!(editor, [DeleteSelected]);

pub struct Editor {
    shape_canvas: Entity<ShapeCanvas>,
    toolbar: Entity<Toolbar>,
    tool_store: Entity<ToolStore>,
    document: Entity<Document>,
    selection_state: Entity<SelectionState>,
    focus_handle: FocusHandle,
}

impl Editor {
    pub fn new(
        document: Entity<Document>,
        cx: &mut Context<Self>,
    ) -> Self {
        let selection_state = cx.new(|_cx| SelectionState::new());
        let tool_store = cx.new(|_cx| ToolStore::new(selection_state.clone()));

        bind_tool_keys(cx);

        let shape_canvas = cx.new(|_cx| {
            ShapeCanvas::new(
                document.clone(),
                selection_state.clone(),
                tool_store.clone(),
            )
        });

        let focus_handle = cx.focus_handle();
        cx.bind_keys([
            KeyBinding::new("delete", DeleteSelected, None),
            KeyBinding::new("backspace", DeleteSelected, None),
        ]);

        let toolbar = cx.new(|_cx| Toolbar::new(tool_store.clone()));

        Self {
            shape_canvas,
            toolbar,
            tool_store,
            document,
            selection_state,
            focus_handle,
        }
    }

    pub fn request_focus(&self, window: &mut Window, cx: &mut App) {
        window.focus(&self.focus_handle, cx);
    }

    pub fn delete_selected(&mut self, cx: &mut Context<Self>) {
        let selected_ids = self.selection_state.read(cx).selected_features.clone();
        if selected_ids.is_empty() {
            return;
        }

        self.document.update(cx, |document, _cx| {
            document.execute_command(Command::RemoveFeatures(selected_ids));
        });

        self.selection_state.update(cx, |selection_state, _cx| {
            selection_state.selected_features.clear();
        });

        cx.notify();
    }
}

impl Render for Editor {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .track_focus(&self.focus_handle)
            .relative()
            .size_full()
            .on_action(cx.listener(|this, _: &ActivateSelectTool, _, cx| {
                this.tool_store.update(cx, |tool_store, cx| {
                    tool_store.set_tool(Tool::new_selection(), cx);
                });
            }))
            .on_action(cx.listener(|this, _: &ActivateCreateRectTool, _, cx| {
                this.tool_store.update(cx, |tool_store, cx| {
                    tool_store.set_tool(Tool::new_create_rect(), cx);
                });
            }))
            .on_action(cx.listener(|this, _: &DeleteSelected, _, cx| {
                this.delete_selected(cx);
            }))
            .child(self.shape_canvas.clone())
            .child(self.toolbar.clone())
    }
}
