import unittest
import sys

sys.path.append('../pygravity')

import engine
import random


class EngineTest(unittest.TestCase):

    def test_engineSimple(self):
        test_engine = engine.Engine()
        for i in range(1000):
            index = test_engine.add_planet(
                pos_x=i * 20,
                pos_y=i * 20,
                density=10000,
                mass=1,
                vel_x=0,
                vel_y=0,
                fixed=False
            )
        for i in range(1000):
            #print(i, len(test_engine.planets.keys()))
            test_engine.tick()
            print(i)

if __name__ == '__main__':
    unittest.main()
