use gpui::*;
use std::time::{Duration, Instant};

use crate::colors;

pub struct FpsCounter {
    last_frame: Option<Instant>,
    frame_times: Vec<f64>,
    current_fps: f64,
    animation_started: bool,
}

impl FpsCounter {
    pub fn new() -> Self {
        Self {
            last_frame: None,
            frame_times: Vec::with_capacity(60),
            current_fps: 0.0,
            animation_started: false,
        }
    }

    pub fn update(&mut self) {
        let now = Instant::now();
        if let Some(last) = self.last_frame {
            let dt = now.duration_since(last).as_secs_f64();
            self.frame_times.push(dt);
            if self.frame_times.len() > 60 {
                self.frame_times.remove(0);
            }
            let avg_dt = self.frame_times.iter().sum::<f64>() / self.frame_times.len() as f64;
            if avg_dt > 0.0 {
                self.current_fps = 1.0 / avg_dt;
            }
        }
        self.last_frame = Some(now);
    }

    pub fn fps(&self) -> f64 {
        self.current_fps
    }
}

impl Render for FpsCounter {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        // Start an animation loop that notifies this view at ~60 Hz.
        // This ensures the FPS counter keeps sampling frame times even when
        // the rest of the app is idle, so the average stays accurate.
        if !self.animation_started {
            self.animation_started = true;
            cx.spawn(async move |this, cx| {
                loop {
                    cx.background_executor()
                        .timer(Duration::from_secs_f64(1.0 / 60.0))
                        .await;
                    this.update(cx, |_, cx| cx.notify()).ok();
                }
            })
            .detach();
        }

        self.update();
        let fps = self.fps();

        let (color, label) = if fps >= 55.0 {
            (colors::green(), "Smooth")
        } else if fps >= 30.0 {
            (colors::yellow(), "OK")
        } else {
            (colors::red(), "Slow")
        };

        div()
            .absolute()
            .top_2()
            .right_2()
            .px_3()
            .py_1()
            .rounded_md()
            .bg(colors::base())
            .border_1()
            .border_color(colors::surface1())
            .shadow_md()
            .flex()
            .flex_col()
            .items_end()
            .gap_0p5()
            .child(
                div()
                    .text_sm()
                    .text_color(color)
                    .font_weight(FontWeight::BOLD)
                    .child(format!("{:.1} FPS", fps)),
            )
            .child(
                div()
                    .text_xs()
                    .text_color(colors::overlay0())
                    .child(label),
            )
    }
}
