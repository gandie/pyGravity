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
