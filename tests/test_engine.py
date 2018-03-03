import unittest
import sys
import random
import time

#from pygravity.engine import Engine
from pygravity.engine_rk4 import Engine


class EngineTest(unittest.TestCase):

    def test_engineSimple(self):
        test_engine = Engine()
        test_engine.timerate = .1
        for i in range(1000):
            index = test_engine.add_planet(
                pos_x=2 * i,
                pos_y=0,
                density=1,
                mass=1,
                vel_x=0,
                vel_y=0,
                fixed=False
            )
        for i in range(1000):
            #print(i, len(test_engine.planets.keys()))
            test_engine.tick()
            print(len(test_engine.planets))

if __name__ == '__main__':
    unittest.main()
