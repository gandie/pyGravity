import itertools
import math
import time
from Queue import Queue
from threading import Thread


class Planet(object):

    def __init__(self, pos_x, pos_y, density, mass, vel_x=0, vel_y=0, fixed=False):
        self.pos_x = pos_x
        self.pos_y = pos_y
        self.density = density
        self.mass = mass
        self.vel_x = vel_x
        self.vel_y = vel_y
        self.fixed = fixed
        self.calc_radius()

    def calc_radius(self):
        self.radius = math.sqrt((3 * self.mass) / (4 * 3.1427 * self.density))


class Engine(object):

    def __init__(self):
        self.cur_index = 0
        self.timerate = 1
        self.planets = {}

    def add_planet(self, *args, **kwargs):
        '''
        see Planet constructor for argument details
        '''
        self.cur_index += 1
        new_planet = Planet(*args, **kwargs)
        self.planets[self.cur_index] = new_planet
        return self.cur_index

    def remove_planet(self, index):
        del_planet = self.planets.get(index)
        if del_planet is not None:
            del self.planets[index]

    def calc_distance(self, planet1, planet2):
        delta_x = planet1.pos_x - planet2.pos_x
        delta_y = planet1.pos_y - planet2.pos_y
        dist = math.sqrt(delta_x ** 2 + delta_y ** 2)
        return dist, delta_x, delta_y

    def calc_force(self, planet1, planet2, dist):
        force = (planet1.mass * planet2.mass) / (dist ** 2)
        return force

    def check_collision(self, planet1, planet2, dist):
        if not (dist < (planet1.radius + planet2.radius)):
            return False
        impulse_x = planet1.vel_x * planet1.mass + planet2.vel_x * planet2.mass
        impulse_y = planet1.vel_y * planet1.mass + planet2.vel_y * planet2.mass
        if planet1.mass <= planet2.mass:
            update_planet, del_planet = planet2, planet1
        else:
            update_planet, del_planet = planet1, planet2

        update_planet.mass += del_planet.mass
        update_planet.vel_x = impulse_x / update_planet.mass
        update_planet.vel_y = impulse_y / update_planet.mass
        update_planet.calc_radius()
        return del_planet

    def tick(self):
        '''
        Calculate gravity for each body combination and check for collision.
        Then update body positions by their velocity
        '''

        del_indexes = []
        for index1, index2 in itertools.combinations(self.planets, 2):
            planet1 = self.planets[index1]
            planet2 = self.planets[index2]
            dist, delta_x, delta_y = self.calc_distance(planet1, planet2)
            force = self.calc_force(planet1, planet2, dist)
            del_planet = self.check_collision(planet1, planet2, dist)
            if del_planet == planet1:
                del_indexes.append(index1)
            elif del_planet == planet2:
                del_indexes.append(index2)

            force_x = force * (delta_x / dist)
            force_y = force * (delta_y / dist)

            planet1.vel_x -= force_x * self.timerate / planet1.mass
            planet1.vel_y -= force_y * self.timerate / planet1.mass

            planet2.vel_x += force_x * self.timerate / planet2.mass
            planet2.vel_y += force_y * self.timerate / planet2.mass

        for index in del_indexes:
            self.remove_planet(index)

        for planet in self.planets.values():
            planet.pos_x += planet.vel_x * self.timerate
            planet.pos_y += planet.vel_y * self.timerate


'''
DEACTIVATED MULTITHREADING PART
def gravity_worker(engine, index_que, del_que):
    while not index_que.empty():
        index1, index2 = index_que.get()
        planet1 = engine.planets[index1]
        planet2 = engine.planets[index2]
        dist, delta_x, delta_y = engine.calc_distance(planet1, planet2)
        force = engine.calc_force(planet1, planet2, dist)
        del_planet = engine.check_collision(planet1, planet2, dist)
        if del_planet == planet1:
            del_que.put(index1)
        elif del_planet == planet2:
            del_que.put(index2)

        force_x = force * (delta_x / dist)
        force_y = force * (delta_y / dist)

        planet1.vel_x -= force_x * engine.timerate / planet1.mass
        planet1.vel_y -= force_y * engine.timerate / planet1.mass

        planet2.vel_x += force_x * engine.timerate / planet2.mass
        planet2.vel_y += force_y * engine.timerate / planet2.mass
        index_que.task_done()
'''

'''
MULTITHREADING
index_que = Queue()
del_que = Queue()

workers = []
for _ in range(10):
    worker = Thread(target=gravity_worker, args=(self, index_que, del_que))
    worker.setDaemon(True)
    worker.start()

for index1, index2 in itertools.combinations(self.planets, 2):
    index_que.put((index1, index2))

index_que.join()
while not del_que.empty():
    del_index = del_que.get()
    del_que.task_done()
    self.remove_planet(del_index)

for worker in workers:
    # worker.join()
    del worker

del index_que
del del_que
'''
