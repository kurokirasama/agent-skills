# Manim Community Edition (ManimCE) Scene Templates

This document provides production-ready starter templates for common academic and algorithmic animation scenarios.

---

## Template 1: Calculus Tangent & Newton-Raphson Step

```python
from manim import *

class NewtonRaphsonTemplate(Scene):
    def construct(self):
        title = Title("Método de Newton-Raphson: Convergencia de Tangentes")
        self.add(title)
        
        axes = Axes(
            x_range=[-1, 4, 1],
            y_range=[-2, 8, 2],
            x_length=8,
            y_length=5,
            axis_config={"include_numbers": True, "color": GRAY}
        ).shift(DOWN * 0.3)
        
        # Function: f(x) = x^2 - 2 (Root at sqrt(2) approx 1.414)
        func = axes.plot(lambda x: x**2 - 2, color=BLUE)
        func_label = MathTex(r"f(x) = x^2 - 2", color=BLUE).next_to(axes.c2p(3, 7), LEFT)
        
        self.play(Create(axes), Create(func), Write(func_label))
        
        # Initial guess x_0 = 3.0
        x_curr = 3.0
        
        for i in range(2):
            y_curr = x_curr**2 - 2
            slope = 2 * x_curr
            x_next = x_curr - y_curr / slope
            
            p_curr = axes.c2p(x_curr, y_curr)
            p_axis = axes.c2p(x_curr, 0)
            p_next = axes.c2p(x_next, 0)
            
            dot = Dot(p_curr, color=RED)
            v_line = DashedLine(p_axis, p_curr, color=YELLOW)
            tangent = Line(
                axes.c2p(x_curr - 1, y_curr - slope),
                axes.c2p(x_curr + 1, y_curr + slope),
                color=GREEN
            )
            
            step_lbl = MathTex(f"x_{{{i}}} = {x_curr:.2f}").to_corner(UL).shift(DOWN * 0.8)
            
            self.play(Create(v_line), FadeIn(dot), Write(step_lbl))
            self.play(Create(tangent))
            self.wait(1)
            
            # Transition to next point
            self.play(FadeOut(v_line), FadeOut(tangent), FadeOut(step_lbl))
            x_curr = x_next
            
        self.wait(1)
```

---

## Template 2: Linear Algebra Basis Morphing & Transformations

```python
from manim import *

class LinearTransformationTemplate(LinearTransformationScene):
    def __init__(self, **kwargs):
        LinearTransformationScene.__init__(
            self,
            show_coordinates=True,
            leave_ghost_vectors=True,
            **kwargs
        )

    def construct(self):
        title = Title("Transformación Lineal: Matriz 2x2")
        self.add(title)
        
        # Transformation matrix [[2, 1], [0.5, 1.5]]
        matrix = [[2, 1], [0.5, 1.5]]
        
        matrix_tex = MathTex(
            r"A = \begin{bmatrix} 2 & 1 \\ 0.5 & 1.5 \end{bmatrix}"
        ).to_corner(UR).add_background_rectangle()
        self.add(matrix_tex)
        
        # Add vector to track
        v = self.add_vector([1, 1], color=YELLOW)
        
        self.wait(1)
        self.apply_matrix(matrix)
        self.wait(2)
```

---

## Template 3: Statistical Acceptance-Rejection Sampling

```python
from manim import *
import numpy as np

class AcceptRejectTemplate(Scene):
    def construct(self):
        title = Title("Muestreo por Aceptación y Rechazo")
        self.play(Write(title))
        
        axes = Axes(
            x_range=[0, 1, 0.2],
            y_range=[0, 2.5, 0.5],
            x_length=7,
            y_length=4.5,
            axis_config={"include_numbers": True}
        ).shift(DOWN * 0.4)
        
        # Target density: Beta(2, 2) -> f(x) = 6 * x * (1 - x)
        f_target = axes.plot(lambda x: 6 * x * (1 - x), color=BLUE, x_range=[0, 1])
        # Envelope: c * Uniform(0, 1) with c = 1.5 -> g(x) = 1.5
        c_env = axes.plot(lambda x: 1.5, color=YELLOW, x_range=[0, 1])
        
        f_lbl = MathTex(r"f(x) = 6x(1-x)", color=BLUE).next_to(axes.c2p(0.5, 1.5), UR)
        c_lbl = MathTex(r"c \cdot g(x) = 1.5", color=YELLOW).next_to(axes.c2p(0.5, 1.5), UL)
        
        self.play(Create(axes))
        self.play(Create(f_target), Create(c_env), Write(f_lbl), Write(c_lbl))
        
        np.random.seed(42)
        dots = []
        for _ in range(25):
            u_x = np.random.uniform(0, 1)
            u_y = np.random.uniform(0, 1.5)
            target_val = 6 * u_x * (1 - u_x)
            
            accepted = u_y <= target_val
            dot_color = GREEN if accepted else RED
            
            p = axes.c2p(u_x, u_y)
            dot = Dot(p, color=dot_color, radius=0.06)
            dots.append(dot)
            
        self.play(LaggedStart(*[FadeIn(d) for d in dots], lag_ratio=0.08), run_time=3)
        self.wait(2)
```

---

## Template 4: Neural Network Computational Graph & Backprop

```python
from manim import *

class NeuralNetBackpropTemplate(Scene):
    def construct(self):
        title = Title("Grafo Computacional y Flujo de Gradiente")
        self.play(Write(title))
        
        # Node positions
        layers = [2, 3, 1]
        node_groups = []
        
        for l_idx, num_nodes in enumerate(layers):
            layer_nodes = VGroup()
            for n_idx in range(num_nodes):
                x = (l_idx - 1) * 3
                y = (n_idx - (num_nodes - 1) / 2) * 1.5
                circle = Circle(radius=0.35, color=WHITE, fill_opacity=0.3, fill_color=BLUE)
                circle.move_to([x, y, 0])
                layer_nodes.add(circle)
            node_groups.append(layer_nodes)
            
        # Draw edges
        edges = VGroup()
        for i in range(len(layers) - 1):
            for n1 in node_groups[i]:
                for n2 in node_groups[i+1]:
                    edge = Line(n1.get_center(), n2.get_center(), stroke_width=1.5, color=GRAY)
                    edges.add(edge)
                    
        self.play(Create(edges), LaggedStart(*[FadeIn(g) for g in node_groups]))
        
        # Animate forward signal
        forward_pulse = node_groups[0].copy().set_color(YELLOW)
        self.play(Indicate(node_groups[0], color=YELLOW))
        self.play(Indicate(node_groups[1], color=YELLOW))
        self.play(Indicate(node_groups[2], color=YELLOW))
        
        # Animate backward gradient flow
        self.play(Indicate(node_groups[2], color=RED))
        self.play(Indicate(node_groups[1], color=RED))
        self.play(Indicate(node_groups[0], color=RED))
        
        self.wait(2)
```
