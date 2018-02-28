import unittest
import sys
import random

from pygravity.engine import Engine


class EngineTest(unittest.TestCase):

    def test_engineSimple(self):
        test_engine = Engine()
        test_engine.timerate = 0.01
        for i in range(100):
            index = test_engine.add_planet(
                pos_x=i * 2,
                pos_y=0,
                density=10000,
                mass=100,
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
