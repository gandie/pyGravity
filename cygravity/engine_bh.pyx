'''
Barnes-Hut n-body engine

Check README of this repo for links on how Barnes-Hut works in detail.
'''

import cython


@cython.freelist(100000)
cdef class Body():
    '''
    Object representing one body simulated by the Engine. Not much work
    done here but keeping body data, many thousand instances may be created via
    Engine's add_body method

    cog          -- double tuple, coordinates (x, y)
    vel          -- double tuple, velocity (vy, vy)
    mass         -- double, mass of the body
    remove       -- int flag, used by engine to mark a body to be removed
    collision    -- int flag, used by engine to mark a body which has collided
    fixed        -- int flag, used by engine to mark a body as fixed (does not move)
    next_force_x -- double, used during force calculation
    next_force_y -- double, used during force calculation
    '''
    cdef public (double, double) cog
    cdef (double, double) vel
    cdef double mass
    cdef public int remove
    cdef public int collision
    cdef public int fixed
    cdef double next_force_x
    cdef double next_force_y

    def __cinit__(self, (double, double) cog, (double, double) vel, double mass, int fixed):
        self.cog = cog
        self.vel = vel
        self.mass = mass
        self.collision = False
        self.remove = False
        self.fixed = fixed
        self.next_force_x = 0
        self.next_force_y = 0


@cython.cdivision(True)
@cython.freelist(10000000)
cdef class Node():
    '''
    Object representing one node of the Barnes-Hut tree created from
    root_node in init_children method of the Engine. One node may contain many
    bodies and must therefore be able to calculate its center of gravity. If a
    nodes contains more than one body it is further sliced during tree buildup.
    In order to distribute bodies on subnodes, nodes must be able to calculate
    wether a body has coordinates inside of a node.

    cog      -- double tuple, calculated using calc_cog method during tree buildup (x, y)
    pos      -- double tuple, representing position of node, left bottom corner (x, y)
    mass     -- double, sum of all body's masses calculated during calc_cog method
    size     -- double, size of a node
    children -- list, child nodes
    bodies   -- list, bodes inside of the node
    '''
    cdef (double, double) cog
    cdef public (double, double) pos
    cdef double mass
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

        # default cog if we have no bodies
        if len(self.bodies) == 0:
            self.cog = (self.pos[0] + self.size/2, self.pos[1] + self.size/2)
            return

        for body in self.bodies:
            self.mass += body.mass
            cog_x += body.cog[0] * body.mass
            cog_y += body.cog[1] * body.mass

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


@cython.cdivision(True)
cdef class Engine():
    '''
    Main module class exposing most API to non-cython code consuming this
    module. This class implements the Barnes-Hut algorith using the recursive
    methods init_children and force_traverse. Use the phi attribute to play
    with the algorithm's accuracy, while values close to 0 will by more
    expensive but return more accurate results.

    root_node       -- Node, root node object, new bodies are added here
    phi             -- double, the engines accuracy (default 0.5)
    size            -- double, the engines space size
    collision_mode  -- string, the current collision_mode (default 'elastic')
    collision_modes -- dict, mapping modes against collsion methods
    '''
    cdef public Node root_node
    cdef public double phi
    cdef public double size
    cdef public str collision_mode
    cdef public dict collision_modes


    def __init__(self, size, phi=0.5, collision_mode='elastic'):
        self.root_node = Node((0, 0), size)
        self.phi = phi  # 10
        self.size = size

        self.collision_modes = {
            'elastic': self.elastic_collision,
            'inelastic': self.inelastic_collision,
        }

        assert collision_mode in self.collision_modes, 'Invalid collision_mode!'
        self.collision_mode = collision_mode

    cdef (double, double, double) calc_distance(self, (double, double) pos1, (double, double) pos2):
        cdef double delta_x, delta_y, dist
        delta_x = pos1[0] - pos2[0]
        delta_y = pos1[1] - pos2[1]
        dist = (delta_x ** 2 + delta_y ** 2) ** 0.5
        return dist, delta_x, delta_y

    cdef list slice_node(self, Node node):
        '''
        Slice given node into 4 equal sized subnodes, then put bodies into
        subnodes according to their position

        Slicing looks like:

        +--+--+
        |nw|ne|
        +--+--+
        |sw|se|
        +--+--+

        '''
        cdef list children, delbodies
        cdef Node nw_node, ne_node, se_node, sw_node, child
        cdef double half_size
        half_size = node.size / 2.0
        # north-west, north-east, ...
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
                if child._contains(body):
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
        '''
        Both bodies survive collision, kinetic energy/impulse is shared
        '''
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
        '''
        The heavier body "eats" the other one, heavier body gets all kinetic
        energy
        '''
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

    cdef (double, double) calc_force(self, Body body1, Body body2):
        cdef double dist, delta_x, delta_y, force, force_x, force_y
        dist, delta_x, delta_y = self.calc_distance(body1.cog, body2.cog)
        if body2.remove:
            # early abort: body2 has been removed!
            return 0, 0
        # collision check
        if dist <= 2:
            self.collision_modes[self.collision_mode](body1, body2)
            # Collision done, no forces to be applied here
            return 0, 0
        force = (body1.mass * body2.mass) / (dist ** 2)
        force_x = force * delta_x / dist
        force_y = force * delta_y / dist
        return force_x, force_y

    cdef (double, double) calc_force_node(self, Body body, Node node, double dist, double delta_x, double delta_y):
        cdef double force, force_x, force_y
        force = (body.mass * node.mass) / (dist ** 2)
        force_x = force * delta_x / dist
        force_y = force * delta_y / dist
        return force_x, force_y

    def force_traverse(self, body, node):
        self._force_traverse(body, node)

    cdef void _force_traverse(self, Body body, Node node):
        '''
        Forces to be applied to a body are calculated here by recursively
        walking through the Barnes-Hut tree created before. Three major steps:

        1) Check if given node has only one body and body is NOT given body
        If so, calculate force and return.

        2) Calculcate body's distance to the node. If the nodes size is small
        compared to its distance (phi), calculate force by node and return.

        3) First and second step did not match, we must traverse deeper into
        nodes children by calling this method recursively on all child nodes.
        '''
        cdef double dist, delta_x, delta_y, phi
        cdef Body second_body

        # early abort if possible
        if body.remove or body.fixed:
            return

        # check for leaf node
        if len(node.bodies) == 1:
            second_body = node.bodies[0]
            # do not call python rich comparison
            if body is not second_body:
                force_x, force_y = self.calc_force(body, second_body)
                body.next_force_x += force_x
                body.next_force_y += force_y
            return
        else:
            # check if calculation can be done using the node
            dist, delta_x, delta_y = self.calc_distance(body.cog, node.cog)
            if not dist:
                dist = .5
            phi = node.size / dist
            if phi < self.phi:
                force_x, force_y = self.calc_force_node(
                    body,
                    node,
                    dist,
                    delta_x,
                    delta_y
                )
                body.next_force_x += force_x
                body.next_force_y += force_y
                return
            else:
                # calculation by node not possible, traverse down the tree
                for child in node.children:
                    self._force_traverse(body, child)

    def tick(self):
        self._tick()

    cdef void _tick(self):
        '''
        Calculcate new body positions by calling force_traverse method for
        each body and apply resulting forces to them for one timestep
        '''
        cdef Body body
        cdef double ax, ay, TIMERATIO
        self.init_children(self.root_node)
        for body in self.root_node.bodies:
            body.collision = False
            body.next_force_x = 0
            body.next_force_y = 0
            self._force_traverse(body, self.root_node)
            ax = -body.next_force_x / body.mass
            ay = -body.next_force_y / body.mass
            TIMERATIO = 1
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
        '''
        Build up Barnes-Hut tree recursively starting from root_node. The tree
        must be rebuilt each tick as bodies are moving. The tree is complete
        when each body resides in its own node
        '''
        node._calc_cog()
        if len(node.bodies) <= 1:
            return
        node.children = self.slice_node(node)
        for child in node.children:
            self.init_children(child)

    def add_body(self, cog, vel, mass, fixed=False):
        '''
        Method to be called from extern to add more bodies to the simulation
        '''
        self.root_node.bodies.append(Body(cog, vel, mass, fixed))

    def print_children(self, node):
        '''
        Recursively print tree - debugging
        '''
        print('node %s' % node.__dict__)
        for child in node.children:
            self.print_children(child)

    def traverse_node(self, node):
        '''
        Recursive iterator exposing all node objects, to be called from extern
        to fetch node informations
        '''
        yield node
        for child in node.children:
            yield from self.traverse_node(child)
