'''
Barnes-Hut n-body engine
'''

import math


cdef class Body(object):

    cdef public (double, double) cog
    cdef public (double, double) vel
    cdef public double mass
    cdef public int remove
    cdef public int collision
    cdef public double next_force_x
    cdef public double next_force_y

    def __cinit__(self, cog, vel, mass):
        self.cog = cog
        self.vel = vel
        self.mass = mass
        self.collision = False
        self.remove = False
        self.next_force_x = 0
        self.next_force_y = 0


cdef class Node(object):
    cdef public (double, double) cog
    cdef public (double, double) pos
    cdef public double mass
    cdef public double size
    cdef public list children
    cdef public list bodies

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
        cdef double cog_x, cog_y
        cog_x = sum(body.cog[0] * body.mass for body in self.bodies) / self.mass
        cog_y = sum(body.cog[1] * body.mass for body in self.bodies) / self.mass
        self.cog = (cog_x, cog_y)

    def contains(self, body):
        cdef int match_x, match_y
        match_x = body.cog[0] >= self.pos[0] and body.cog[0] < self.pos[0] + self.size
        match_y = body.cog[1] >= self.pos[1] and body.cog[1] < self.pos[1] + self.size
        return match_x and match_y


cdef class Engine(object):

    cdef public object root_node
    cdef public double phi
    cdef public str collision_mode
    cdef public object collision_modes


    def __init__(self, size, phi=0.5, collision_mode='elastic'):
        self.root_node = Node((0, 0), size)
        self.phi = phi  # 10
        self.collision_mode = collision_mode

        self.collision_modes = {
            'elastic': self.elastic_collision,
            'inelastic': self.inelastic_collision,
        }

    cdef (double, double, double) calc_distance(self, pos1, pos2):
        cdef double delta_x, delta_y, dist
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
                # Body does not fit into subnodes
                delbodies.append(body)

        node.bodies = [b for b in node.bodies if b not in delbodies]
        return children

    def elastic_collision(self, body1, body2):
        if body1.collision or body2.collision:
            return
        mass_sum = body1.mass + body2.mass
        b1_vx = ((body1.mass - body2.mass)/mass_sum)*body1.vel[0] + ((2*body2.mass)/mass_sum)*body2.vel[0]
        b1_vy = ((body1.mass - body2.mass)/mass_sum)*body1.vel[1] + ((2*body2.mass)/mass_sum)*body2.vel[1]

        b2_vx = ((body2.mass - body1.mass)/mass_sum)*body2.vel[0] + ((2*body1.mass)/mass_sum)*body1.vel[0]
        b2_vy = ((body2.mass - body1.mass)/mass_sum)*body2.vel[1] + ((2*body1.mass)/mass_sum)*body1.vel[1]

        body1.vel = (b1_vx, b1_vy)
        body2.vel = (b2_vx, b2_vy)

        body1.collision = True
        body2.collision = True

    def inelastic_collision(self, body1, body2):
        if body1.remove or body2.remove:
            # Collision already done
            return
        if body1.mass > body2.mass:
            keep = body1
            kill = body2
        else:
            keep = body2
            kill = body1
        kill.remove = True
        keep.vel = (
            (keep.vel[0]*keep.mass + kill.vel[0]*kill.mass) / (keep.mass + kill.mass),
            (keep.vel[1]*keep.mass + kill.vel[1]*kill.mass) / (keep.mass + kill.mass),
        )
        keep.mass += kill.mass

    def calc_force(self, body1, body2):
        dist, delta_x, delta_y = self.calc_distance(body1.cog, body2.cog)
        both_bodies = isinstance(body1, Body) and isinstance(body2, Body)
        if isinstance(body2, Body) and body2.remove:
            # early abort: body2 has been removed!
            return 0, 0
        if not dist and not both_bodies:
            dist = 1
            return 0, 0
        if dist <= 2 and both_bodies:
            self.collision_modes[self.collision_mode](body1, body2)
            # Collision done
            return 0, 0
        force = (body1.mass * body2.mass) / (dist ** 2)
        force_x = force * delta_x / dist
        force_y = force * delta_y / dist
        return force_x, force_y

    def force_traverse(self, body, node):

        if body.remove:
            # Traverse abort: body has been removed'
            return

        if len(node.bodies) == 1 and node.bodies[0] != body:
            force_x, force_y = self.calc_force(body, node.bodies[0])
            body.next_force_x += force_x
            body.next_force_y += force_y
            return
        else:
            dist, delta_x, delta_y = self.calc_distance(body.cog, node.cog)
            if not dist:
                dist = .5
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
            body.collision = False
            body.next_force_x = 0
            body.next_force_y = 0
            self.force_traverse(body, self.root_node)
            ax = -body.next_force_x / body.mass
            ay = -body.next_force_y / body.mass
            TIMERATIO = .1
            body.vel = (
                body.vel[0] + ax * TIMERATIO,
                body.vel[1] + ay * TIMERATIO
            )
            body.cog = (
                body.cog[0] + body.vel[0] * TIMERATIO,
                body.cog[1] + body.vel[1] * TIMERATIO
            )

        self.root_node.bodies = [
            b for b in self.root_node.bodies if not b.remove
        ]

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

    def traverse_node(self, node):
        yield node
        for child in node.children:
            yield from self.traverse_node(child)
        #print('called!')
