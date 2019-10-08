'''
Barnes-Hut n-body engine
'''

import math


class Body(object):

    def __init__(self, cog, vel, mass):
        self.cog = cog
        self.vel = vel
        self.mass = mass


class Node(object):

    def __init__(self, pos, size):
        self.pos = pos
        self.size = size
        self.bodies = []
        self.children = []
        self.mass = 0
        self.cog = (pos[0] + size/2, pos[1] + size/2)

    def calc_cog(self):
        self.mass = sum(body.mass for body in self.bodies)
        if self.mass == 0:
            return
        cog_x = sum(body.cog[0] * body.mass for body in self.bodies) / self.mass
        cog_y = sum(body.cog[1] * body.mass for body in self.bodies) / self.mass
        self.cog = (cog_x, cog_y)

    def contains(self, body):
        match_x = body.cog[0] >= self.pos[0] and body.cog[0] < self.pos[0] + self.size
        match_y = body.cog[1] >= self.pos[1] and body.cog[1] < self.pos[1] + self.size
        return match_x and match_y


class Engine(object):

    def __init__(self, size):
        self.root_node = Node((0, 0), size)
        self.phi = .5  # 10

    def calc_distance(self, pos1, pos2):
        delta_x = pos1[0] - pos2[0]
        delta_y = pos1[1] - pos2[1]
        dist = math.sqrt(delta_x ** 2 + delta_y ** 2)
        return dist, delta_x, delta_y

    def slice_node(self, node):
        nw_node = Node(
            pos=(node.pos[0], node.pos[1] + node.size/2),
            size=node.size/2
        )
        ne_node = Node(
            pos=(node.pos[0] + node.size/2, node.pos[1] + node.size/2),
            size=node.size/2
        )
        se_node = Node(
            pos=(node.pos[0] + node.size/2, node.pos[1]),
            size=node.size/2
        )
        sw_node = Node(
            pos=(node.pos[0], node.pos[1]),
            size=node.size/2
        )
        children = [nw_node, ne_node, se_node, sw_node]

        delbodies = []
        for body in node.bodies:
            for child in children:
                if child.contains(body):
                    child.bodies.append(body)
                    break
            else:
                msg = 'Body %s does not fit into subnodes!' % (body.__dict__)
                #print(msg)
                delbodies.append(body)

        node.bodies = [b for b in node.bodies if b not in delbodies]
        return children

    def calc_force(self, body1, body2):
        dist, delta_x, delta_y = self.calc_distance(body1.cog, body2.cog)
        if dist == 0:
            dist = .1
        force = (body1.mass * body2.mass) / (dist ** 2)
        force_x = force * delta_x / dist
        force_y = force * delta_y / dist
        return force_x, force_y

    def force_traverse(self, body, node):

        if len(node.bodies) == 1 and node.bodies[0] != body:
            force_x, force_y = self.calc_force(body, node.bodies[0])
            body.next_force_x += force_x
            body.next_force_y += force_y
            return
        else:
            dist, delta_x, delta_y = self.calc_distance(body.cog, node.cog)
            if not dist:
                dist = 0.001
            phi = node.size / dist
            if phi < self.phi:
                force_x, force_y = self.calc_force(body, node)
                body.next_force_x += force_x
                body.next_force_y += force_y
                return
            else:
                for child in node.children:
                    self.force_traverse(body, child)

    def tick(self):
        self.init_children(self.root_node)
        for body in self.root_node.bodies:
            body.next_force_x = 0
            body.next_force_y = 0
            self.force_traverse(body, self.root_node)
            ax = -body.next_force_x / body.mass
            ay = -body.next_force_y / body.mass
            TIMERATIO = 1
            body.vel = (body.vel[0] + ax * TIMERATIO, body.vel[1] + ay * TIMERATIO)
            body.cog = (body.cog[0] + body.vel[0] * TIMERATIO, body.cog[1] + body.vel[1] * TIMERATIO)

    def init_children(self, node):
        node.calc_cog()
        if len(node.bodies) <= 1:
            return
        node.children = self.slice_node(node)
        for child in node.children:
            self.init_children(child)

    def add_body(self, cog, vel, mass):
        self.root_node.bodies.append(Body(cog, vel, mass))

    def print_children(self, node):
        print('node %s' % node.__dict__)
        for child in node.children:
            self.print_children(child)
