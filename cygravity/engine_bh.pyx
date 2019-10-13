'''
Barnes-Hut n-body engine
'''

import cython

cdef class Body():

    cdef public (double, double) cog
    cdef public (double, double) vel
    cdef public double mass
    cdef public int remove
    cdef public int collision
    cdef public int fixed
    cdef public double next_force_x
    cdef public double next_force_y

    def __cinit__(self, (double, double) cog, (double, double) vel, double mass, int fixed):
        self.cog = cog
        self.vel = vel
        self.mass = mass
        self.collision = False
        self.remove = False
        self.fixed = fixed
        self.next_force_x = 0
        self.next_force_y = 0


@cython.freelist(1000000)
cdef class Node():
    cdef public (double, double) cog
    cdef public (double, double) pos
    cdef public double mass
    cdef public double size
    cdef public list children
    cdef public list bodies

    def __cinit__(self, (double, double) pos, double size):
        self.pos = pos
        self.size = size
        self.bodies = []
        self.children = []
        self.mass = 0
        self.cog = (pos[0] + size/2, pos[1] + size/2)

    def calc_cog(self):
        self._calc_cog()

    cdef void _calc_cog(self):
        cdef double cog_x, cog_y
        cdef Body body
        self.mass = 0
        cog_x = 0
        cog_y = 0

        for body in self.bodies:
            self.mass += body.mass
            cog_x += body.cog[0] * body.mass
            cog_y += body.cog[1] * body.mass

        if self.mass == 0:
            return
        cog_x = cog_x / self.mass
        cog_y = cog_y / self.mass
        self.cog = (cog_x, cog_y)

    def contains(self, body):
        return self._contains(body)

    cdef int _contains(self, Body body):
        cdef int match_x, match_y, result
        match_x = body.cog[0] >= self.pos[0] and body.cog[0] < self.pos[0] + self.size
        match_y = body.cog[1] >= self.pos[1] and body.cog[1] < self.pos[1] + self.size
        result = match_x and match_y
        return result


cdef class Engine():

    cdef public Node root_node
    cdef public double phi
    cdef public str collision_mode
    cdef public dict collision_modes


    def __init__(self, size, phi=0.5, collision_mode='elastic'):
        self.root_node = Node((0, 0), size)
        self.phi = phi  # 10
        self.collision_mode = collision_mode

        self.collision_modes = {
            'elastic': self.elastic_collision,
            'inelastic': self.inelastic_collision,
        }

    cdef (double, double, double) calc_distance(self, (double, double) pos1, (double, double) pos2):
        cdef double delta_x, delta_y, dist
        delta_x = pos1[0] - pos2[0]
        delta_y = pos1[1] - pos2[1]
        dist = (delta_x ** 2 + delta_y ** 2) ** 0.5
        return dist, delta_x, delta_y

    cdef list slice_node(self, Node node):
        cdef list children, delbodies
        cdef Node nw_node, ne_node, se_node, sw_node
        #cdef double size
        cdef double half_size
        half_size = node.size / 2.0
        nw_node = Node(
            pos=(node.pos[0], node.pos[1] + half_size),
            size=half_size
        )
        ne_node = Node(
            pos=(node.pos[0] + half_size, node.pos[1] + half_size),
            size=half_size
        )
        se_node = Node(
            pos=(node.pos[0] + half_size, node.pos[1]),
            size=half_size
        )
        sw_node = Node(
            pos=(node.pos[0], node.pos[1]),
            size=half_size
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
        self._elastic_collision(body1, body2)

    cdef void _elastic_collision(self, Body body1, Body body2):
        if body1.collision or body2.collision:
            return

        cdef double mass_sum, b1_vx, b1_vy, b2_vx, b2_vy

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
        self._inelastic_collision(body1, body2)

    cdef void _inelastic_collision(self, Body body1, Body body2):
        cdef Body kill, keep
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

    cdef (double, double) calc_force(self, object body1, object body2):
        cdef double dist, delta_x, delta_y, force, force_x, force_y
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

    cdef void force_traverse(self, Body body, Node node):

        cdef double dist, delta_x, delta_y, phi
        if body.remove or body.fixed:
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
        self._tick()

    cdef void _tick(self):
        cdef Body body
        cdef double ax, ay, TIMERATIO
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

    cdef void init_children(self, Node node):
        node.calc_cog()
        if len(node.bodies) <= 1:
            return
        node.children = self.slice_node(node)
        for child in node.children:
            self.init_children(child)

    def add_body(self, cog, vel, mass, fixed=False):
        self.root_node.bodies.append(Body(cog, vel, mass, fixed))

    def print_children(self, node):
        print('node %s' % node.__dict__)
        for child in node.children:
            self.print_children(child)

    def traverse_node(self, node):
        yield node
        for child in node.children:
            yield from self.traverse_node(child)
        #print('called!')
