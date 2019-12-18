# PyGravity

Some experimental gravity engines using Newton's formula to calculate forces
between bodies.

The intention of this code is NOT to use it in prduction as python is not knwon
for doing such calculation in a fast manner. It was rather written to understand
the underlying algorithms and to have a working sketch for transposing into a
more performant language, namely C.

Currently implemented:
+ [Runge Kutta](https://en.wikipedia.org/wiki/Runge%E2%80%93Kutta_methods)
+ [Barnes-Hut](https://en.wikipedia.org/wiki/Barnes%E2%80%93Hut_simulation)

More links!
+ [RK Engine Code stolen here](http://ttsiodras.github.com/gravity.html)
+ [Great explanation of Barnes-Hut algorithm](http://arborjs.org/docs/barnes-hut)
+ [Cython docs, which were extremely helpful to write/optimize CyGravity](https://cython.readthedocs.io/en/latest/index.html)

## Installation

Requirements and module itself:

```bash
pip install -r requirements.txt
python setup.py install
```

# CyGravity

Cythonzied versions of PyGravity engine(s). Runs much faster due to static typing
and less calls into python. Still not really production capable but rather easy
to write.

# Pygame visuals

Simple visualization using pygame for Barnes-Hut, run after installation:

```
pygravity
```

...or much faster...

```
cygravity
```

+ `LEFT CLICK`  more bodies
+ `RIGHT CLICK` show Barnes-Hut tree
