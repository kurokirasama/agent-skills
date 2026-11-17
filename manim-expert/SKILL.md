---
name: manim-expert
description: Expert in creating educational mathematical, statistical, and algorithmic animations using Manim Community Edition (ManimCE). Use when creating, debugging, or rendering explanatory animations for mathematical concepts, linear algebra, calculus, statistical sampling, machine learning algorithms, neural networks, or computational pipelines.
metadata:
  version: "1.0.0"
  framework: "ManimCE v0.18+"
  python_env: "/home/username/workspace/Development/linux/python/manim/.venv"
---

# Manim Expert Skill

## Overview

The `manim-expert` skill provides comprehensive expertise in designing, coding, debugging, and rendering mathematical and algorithmic animations with the **Manim Community Edition (ManimCE)**. It covers the full lifecycle of an animation: pedagogical storyboarding, mathematical typesetting with LaTeX, 2D/3D coordinate transformations, dynamic algorithm state tracking, and headless CLI video rendering.

---

## Environment & Execution Setup

The user maintains a dedicated Manim Python virtual environment at:
```bash
/home/username/workspace/Development/linux/python/manim/.venv
```

### CLI Rendering Commands

To render scenes created with ManimCE, always invoke the venv's manim executable or activate the venv:

```bash
# Path to binary
MANIM="/home/username/workspace/Development/linux/python/manim/.venv/bin/manim"

# Fast preview rendering (480p, 15fps, opens default media player)
$MANIM -pql scene.py MySceneName

# Medium quality (720p, 30fps)
$MANIM -pqm scene.py MySceneName

# Production high quality (1080p, 60fps)
$MANIM -pqh scene.py MySceneName

# Transparent video background (overlay on slides or web presentations)
$MANIM -qh -t scene.py MySceneName

# Save last frame as image (PNG)
$MANIM -s scene.py MySceneName
```

---

## Core Workflows

### 1. Pedagogical Scene Scaffolding

When designing an educational animation, structure each scene following this 4-act progression:
1. **Preamble & Problem Setup**: Display title, context, and the static problem or formula via `MathTex`.
2. **Geometric / Spatial Anchoring**: Introduce the coordinate system (`Axes`, `NumberPlane`, or 3D coordinate frame) with clear bounds.
3. **Dynamic Algorithmic Transformation**: Use `ValueTracker`, `TransformMatchingTex`, or updaters to step through iterations, show state changes, or morph coordinate spaces.
4. **Intuition Crystallization & Conclusion**: Highlight invariant properties, convergence points, or geometric takeaways with color emphasis (`Indicate`, `Circumscribe`, or `Wiggle`).

---

### 2. Mathematical Typesetting (`MathTex`)

Always use LaTeX raw strings (`r"..."`) to prevent Python escape code syntax issues:

```python
from manim import *

class MathTypographyDemo(Scene):
    def construct(self):
        # Isolate substrings for granular color matching and transforms
        formula = MathTex(
            r"f(x)", r"=", r"\frac{1}{\sigma \sqrt{2\pi}}", 
            r"\exp\left(-\frac{(x - \mu)^2}{2\sigma^2}\right)"
        )
        formula.set_color_by_tex(r"\mu", BLUE)
        formula.set_color_by_tex(r"\sigma", YELLOW)
        
        self.play(Write(formula), run_time=2)
        self.wait(1)
```

---

### 3. Dynamic Tracking with `ValueTracker` and Updaters

To animate algorithmic parameters continuously (e.g., learning rates, tangent points, convergence tolerances):

```python
from manim import *

class ValueTrackerDemo(Scene):
    def construct(self):
        ax = Axes(x_range=[-3, 3, 1], y_range=[-1, 9, 2])
        parabola = ax.plot(lambda x: x**2, color=BLUE)
        
        x_val = ValueTracker(2.0)
        
        # Moving dot that tracks x_val
        dot = always_redraw(lambda: Dot(
            point=ax.c2p(x_val.get_value(), x_val.get_value()**2),
            color=RED
        ))
        
        # Moving tangent line
        tangent = always_redraw(lambda: ax.get_secant_slope_group(
            x=x_val.get_value(),
            graph=parabola,
            dx=0.001,
            secant_line_length=3,
            secant_line_color=YELLOW
        ))
        
        self.add(ax, parabola, dot, tangent)
        self.play(x_val.animate.set_value(-2.0), run_time=3)
        self.wait(1)
```

---

### 4. Advanced Reference Guides

For comprehensive API patterns, code templates, and styling guidelines, consult:
- `references/best_practices.md`: Scene classes, 2D/3D systems, updaters, color schemes, and CLI flags.
- `references/scene_templates.md`: Ready-to-use production templates for Calculus, Linear Algebra, Statistical Sampling, and Neural Networks.

---

## Common Pitfalls & Anti-Patterns

| Anti-Pattern | Correct ManimCE Pattern | Why |
| :--- | :--- | :--- |
| `from manimlib import *` | `from manim import *` | `manimlib` is Grant Sanderson's legacy 3b1b engine; ManimCE is the active community standard. |
| `ShowCreation(mob)` | `Create(mob)` | `ShowCreation` was deprecated in ManimCE v0.2+. |
| `mob.shift(...)` inside updater without copying | Redraw from scratch via `always_redraw(lambda: ...)` | Mutating MObjects in-place inside updaters causes compounding transformation drift. |
| Unescaped LaTeX backslashes `"\frac"` | Raw string `r"\frac"` | Python treats `\f` as form feed without raw string notation. |
| Hardcoding screen coordinates | Use `ax.c2p(x, y)` (coords to points) | Preserves math-to-screen scale independence. |

---

## When NOT to Use

- Do NOT use Manim for real-time interactive user dashboards (use Streamlit, Dash, or Shiny).
- Do NOT use Manim for 3D physics game engine simulations (use Blender, Unity, or Godot).
- Do NOT use Manim when a static PDF figure generated with Matplotlib or TikZ suffices for print publication.
