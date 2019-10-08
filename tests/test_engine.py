import unittest
import time

from pygravity.engine_rk4 import Engine as RK4Engine
from pygravity.engine_bh import Engine as BHEngine


class RK4_EngineTest(unittest.TestCase):

    def notest_engineSimple(self):
        test_engine = RK4Engine()
        print('RK4 Engine created, starting test loop...')
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
        for i in range(3):
            start = time.time()
            test_engine.tick()
            end = time.time() - start
            print('One tick took %s seconds using %s bodies' % (
                end, len(test_engine.planets))
            )


class BH_EngineTest(unittest.TestCase):

    def notest_engineSimple(self):
        test_engine = BHEngine(size=1000)
        test_engine.add_body(
            pos=(10, 10),
            vel=(0, 0),
            mass=1
        )

        test_engine.add_body(
            pos=(20, 20),
            vel=(0, 0),
            mass=1
        )

        test_engine.tick()
        test_engine.print_children(test_engine.root_node)
        print('RK4 Engine created, starting test loop...')

    def test_enginePerformace(self):
        test_engine = BHEngine(size=10000)
        for i in range(1000):
            test_engine.add_body(
                cog=(i, i),
                vel=(0, 0),
                mass=1
            )
        for i in range(10):
            start = time.time()
            test_engine.tick()
            end = time.time() - start
            print('One tick took %s seconds using %s bodies' % (
                end, len(test_engine.root_node.bodies))
            )


if __name__ == '__main__':
    unittest.main()
