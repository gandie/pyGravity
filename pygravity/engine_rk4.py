import itertools
import math
import time


class State(object):

    def __init__(self, pos_x, pos_y, vel_x=0, vel_y=0):
        self.pos_x = pos_x
        self.pos_y = pos_y
        self.vel_x = vel_x
        self.vel_y = vel_y


class Derivative(object):

    def __init__(self, dx, dy, dvx, dvy):
        self.dx = dx
        self.dy = dy
        self.dvx = dvx
        self.dvy = dvy


class Planet(object):

    def __init__(self, engine, pos_x, pos_y, density, mass, vel_x=0, vel_y=0, fixed=False):

        self.engine = engine

        self.state = State(
            pos_x=pos_x,
            pos_y=pos_y,
            vel_x=vel_x,
            vel_y=vel_y
        )

        self.density = density
        self.mass = mass
        self.fixed = fixed
        self.calc_radius()

    def calc_radius(self):
        self.radius = math.sqrt((3 * self.mass) / (4 * 3.1427 * self.density))

    def calc_acceleration(self, state, unused_curtime):
        ax = 0.0
        ay = 0.0
        for other_planet in self.engine.planets.values():
            if other_planet == self:
                continue
            dist, delta_x, delta_y = self.calc_distance(state, other_planet)
            force = self.calc_force(other_planet, dist)
            ax += force * delta_x / dist / self.mass
            ay += force * delta_y / dist / self.mass
        return ax, ay

    def calc_distance(self, state, planet2):
        delta_x = planet2.state.pos_x - state.pos_x
        delta_y = planet2.state.pos_y - state.pos_y
        dist = math.sqrt(delta_x ** 2 + delta_y ** 2)
        return dist, delta_x, delta_y

    def calc_force(self, planet2, dist):
        force = (self.mass * planet2.mass) / (dist ** 2)
        return force

    def initialDerivative(self, state, curtime):
        ax, ay = self.calc_acceleration(state, curtime)
        return Derivative(
            dx=state.vel_x,
            dy=state.vel_y,
            dvx=ax,
            dvy=ay
        )

    def nextDerivative(self, initialState, derivative, curtime, dt):
        nextState = State(
            pos_x=0.0,
            pos_y=0.0,
            vel_x=0.0,
            vel_y=0.0
        )
        nextState.pos_x = initialState.pos_x + derivative.dx * dt
        nextState.pos_y = initialState.pos_y + derivative.dy * dt
        nextState.vel_x = initialState.vel_x + derivative.dvy * dt
        nextState.vel_y = initialState.vel_y + derivative.dvy * dt
        ax, ay = self.calc_acceleration(nextState, curtime+dt)
        return Derivative(
            dx=nextState.vel_x,
            dy=nextState.vel_y,
            dvx=ax,
            dvy=ay
        )

    def update(self, curtime, delta_time):
        initial_D = self.initialDerivative(self.state, curtime)
        second_D = self.nextDerivative(self.state, initial_D, curtime, delta_time * 0.5)
        third_D = self.nextDerivative(self.state, second_D, curtime, delta_time * 0.5)
        fourth_D = self.nextDerivative(self.state, third_D, curtime, delta_time)
        delta_x_dt = 1.0 / 6.0 * (initial_D.dx + 2 * (second_D.dx + third_D.dx) + fourth_D.dx)
        delta_y_dt = 1.0 / 6.0 * (initial_D.dy + 2 * (second_D.dy + third_D.dy) + fourth_D.dy)
        delta_vx_dt = 1.0 / 6.0 * (initial_D.dvx + 2 * (second_D.dvx + third_D.dvx) + fourth_D.dvx)
        delta_vy_dt = 1.0 / 6.0 * (initial_D.dvy + 2 * (second_D.dvy + third_D.dvy) + fourth_D.dvy)
        self.state.pos_x += delta_x_dt * delta_time
        self.state.pos_y += delta_y_dt * delta_time
        self.state.vel_x += delta_vx_dt * delta_time
        self.state.vel_y += delta_vy_dt * delta_time
        #print(self.state.pos_x, self.state.pos_y, self.radius)


class Engine(object):

    def __init__(self):
        self.cur_index = 0
        self.curtime = 0
        self.timerate = 1
        self.planets = {}

    def add_planet(self, *args, **kwargs):
        '''
        see Planet constructor for argument details
        '''
        self.cur_index += 1
        new_planet = Planet(self, *args, **kwargs)
        self.planets[self.cur_index] = new_planet
        return self.cur_index

    def remove_planet(self, index):
        del_planet = self.planets.get(index)
        if del_planet is not None:
            del self.planets[index]

    def check_collision(self, planet1, planet2):
        dist, delta_x, delta_y = planet1.calc_distance(planet1.state, planet2)
        if not (dist < (planet1.radius + planet2.radius)):
            return False
        impulse_x = planet1.state.vel_x * planet1.mass + planet2.state.vel_x * planet2.mass
        impulse_y = planet1.state.vel_y * planet1.mass + planet2.state.vel_y * planet2.mass
        if planet1.mass <= planet2.mass:
            update_planet, del_planet = planet2, planet1
        else:
            update_planet, del_planet = planet1, planet2

        update_planet.mass += del_planet.mass
        update_planet.state.vel_x = impulse_x / update_planet.mass
        update_planet.state.vel_y = impulse_y / update_planet.mass
        update_planet.calc_radius()
        return del_planet

    def tick(self):

        del_indexes = []
        self.curtime += self.timerate

        for planet in self.planets.values():
            planet.update(self.curtime, self.timerate)

        for index1, index2 in itertools.combinations(self.planets, 2):
            planet1 = self.planets[index1]
            planet2 = self.planets[index2]
            del_planet = self.check_collision(planet1, planet2)
            if del_planet == planet1:
                del_indexes.append(index1)
            elif del_planet == planet2:
                del_indexes.append(index2)

        for index in del_indexes:
            self.remove_planet(index)
