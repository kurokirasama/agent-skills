# Manim Community Edition (ManimCE) Best Practices & Architecture Guide

## 1. Scene Architectures & Lifecycle

ManimCE provides several specialized scene classes:

### `Scene`
The standard 2D canvas. Used for 90% of instructional videos.
- Canvas dimensions: 16:9 aspect ratio (default width = 14.22 Manim units, height = 8 Manim units).
- Origin `[0, 0, 0]` is at the exact center of the screen.
- Screen edges: `UP`, `DOWN`, `LEFT`, `RIGHT`, `UL`, `UR`, `DL`, `DR`.

### `MovingCameraScene`
Enables dynamic panning, zooming, and following moving objects.
```python
from manim import *

class ZoomCameraDemo(MovingCameraScene):
    def construct(self):
        # Save current camera state
        self.camera.frame.save_state()
        
        dot = Dot(point=[3, 2, 0], color=RED)
        self.play(Create(dot))
        
        # Zoom into dot
        self.play(
            self.camera.frame.animate.set(width=3).move_to(dot),
            run_time=2
        )
        self.wait(1)
        # Restore camera
        self.play(Restore(self.camera.frame), run_time=1.5)
```

### `ThreeDScene`
Provides a 3D coordinate system with arbitrary camera rotation and lighting.
```python
from manim import *

class ThreeDExample(ThreeDScene):
    def construct(self):
        axes = ThreeDAxes()
        surface = Surface(
            lambda u, v: np.array([u, v, np.sin(u) * np.cos(v)]),
            u_range=[-PI, PI],
            v_range=[-PI, PI],
            resolution=(30, 30)
        )
        self.set_camera_orientation(phi=75 * DEGREES, theta=30 * DEGREES)
        self.add(axes, surface)
        self.begin_ambient_camera_rotation(rate=0.2)
        self.wait(4)
        self.stop_ambient_camera_rotation()
```

---

## 2. LaTeX Typography & Formula Morphing

### Substring Granularity
To animate mathematical equation transformations cleanly using `TransformMatchingTex`:
```python
from manim import *

class EquationTransformDemo(Scene):
    def construct(self):
        # Break formulas into matching logical substrings
        eq1 = MathTex(r"a^2", r"+", r"b^2", r"=", r"c^2")
        eq2 = MathTex(r"c^2", r"=", r"a^2", r"+", r"b^2")
        eq3 = MathTex(r"c", r"=", r"\sqrt{", r"a^2", r"+", r"b^2", r"}")
        
        self.play(Write(eq1))
        self.wait(0.5)
        self.play(TransformMatchingTex(eq1, eq2))
        self.wait(0.5)
        self.play(TransformMatchingTex(eq2, eq3))
        self.wait(1)
```

---

## 3. Coordinate Systems & Graphing

### `Axes` Best Practices
- Always configure `x_range=[min, max, step]` and `y_range=[min, max, step]`.
- Use `add_coordinates()` for numeric labels on ticks.
- Use `ax.c2p(x, y)` to convert mathematical coordinates to screen points.
- Use `ax.p2c(point)` to convert screen points to mathematical coordinates.
- Use `ax.get_graph_label(graph, label=r"f(x)")` for anchored annotations.

### Plotting Functions & Areas
```python
ax = Axes(x_range=[-2, 5], y_range=[-1, 10])
graph = ax.plot(lambda x: x**2 - 2*x + 1, color=BLUE)

# Shaded area under curve (Riemann integration)
area = ax.get_area(graph, x_range=[0, 3], color=GREEN, opacity=0.4)
riemann_rects = ax.get_riemann_rectangles(graph, x_range=[0, 3], dx=0.5, stroke_width=0.5)
```

---

## 4. Algorithmic State Tracking & Updaters

Updaters execute on every animation frame. There are two primary paradigms:

### Paradigm A: `always_redraw(func)`
Reconstructs the object cleanly on each frame based on external parameters (`ValueTracker`).
- **Advantage**: Prevents cumulative transformation and rotation errors.
- **Use case**: Dynamic lines, labels displaying numeric values, moving tangent vectors.

### Paradigm B: Object Updaters (`mob.add_updater(func)`)
Modifies the object continuously based on delta time `dt`.
```python
# Rotate continuously at 45 degrees per second
dot.add_updater(lambda mob, dt: mob.rotate(45 * DEGREES * dt))
```

---

## 5. Visual Hierarchy, Color Palettes & Pacing

### Recommended Color Schemes
- Background: Default dark gray (`#1e1e1e` / `BLACK`) provides superior contrast for technical diagrams.
- Primary Math Elements: `YELLOW` (`#FFFF00`), `BLUE` (`#58C4DD`), `GREEN` (`#83C167`).
- Highlights & Warnings: `RED` (`#FC6255`), `GOLD` (`#F9B539`).
- Axis & Gridlines: `GRAY_B` or `GRAY_C` with low stroke width (1.5 - 2.0).

### Pacing Guidelines
- Entrance animations: 1.0 – 1.5 seconds.
- State transitions / step iterations: 0.8 – 1.2 seconds.
- Cognitive pause (`self.wait(...)`): Always pause 1.0 to 2.0 seconds after introducing a new concept so students can absorb the visual state.
