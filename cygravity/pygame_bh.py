import pygame
from engine_bh import Engine
import random
import math

FPS = 60

LEFT = 1  # left mouse button
MIDDLE = 2
RIGHT = 3  # ...
WHEELUP = 4
WHEELDOWN = 5

RESOLUTION = (1000, 1000)


def main():

    pygame.init()

    screen = pygame.display.set_mode(RESOLUTION)

    pygame.display.set_caption("BH_Engine")
    pygame.mouse.set_visible(1)

    # frame limiter
    clock = pygame.time.Clock()

    draw_boxes = False
    engine = Engine(size=10000, phi=.5, collision_mode='elastic')

    SCALE = engine.size / RESOLUTION[0]
    SUNMASS = 1000000

    def add_bodies(engine, bodies=1000):
        for i in range(bodies // 4):
            x = i * (2 * engine.size / bodies)
            cog_left = (x, engine.size / 2)
            cog_right = (engine.size - x, engine.size / 2)
            cog_up = (engine.size / 2, x)
            cog_down = (engine.size / 2, engine.size - x)
            dist = engine.size / 2 - x
            vel_y = math.sqrt(SUNMASS / dist)
            # mass = random.random() * 5
            mass = 1
            engine.add_body(
                cog=cog_left,
                vel=(0, vel_y),
                mass=mass
            )
            engine.add_body(
                cog=cog_right,
                vel=(0, -vel_y),
                mass=mass
            )
            engine.add_body(
                cog=cog_up,
                vel=(-vel_y, 0),
                mass=mass
            )
            engine.add_body(
                cog=cog_down,
                vel=(vel_y, 0),
                mass=mass
            )

    add_bodies(engine)
    engine.add_body(
        cog=(engine.size / 2, engine.size / 2),
        vel=(0, 0),
        mass=SUNMASS,
        fixed=True
    )

    '''
    for i in range(10):
        for j in range(10):
            engine.add_body(
                cog=(i * 100, j * 100),
                vel=(0, 0),
                mass=100
            )
    '''

    running = True
    run_engine = False
    while running:

        clock.tick(FPS)
        background = pygame.Surface(RESOLUTION)
        background.fill((0, 0, 0, 0))
        background = background.convert_alpha()

        # temporary surface to draw things to
        display = pygame.Surface(RESOLUTION)
        display.fill((0, 0, 0, 0))
        display = display.convert_alpha()

        display.blit(background, (0, 0))

        if run_engine:
            engine.tick()

        if draw_boxes:
            for node in engine.traverse_node(engine.root_node):
                node_surface = pygame.Surface((node.size, node.size))
                pygame.draw.rect(
                    node_surface,
                    (255, 0, 0, 0),
                    (0, 0, node.size, node.size)
                )
                pygame.draw.rect(
                    node_surface,
                    (0, 0, 0, 0),
                    (1, 1, node.size - 2, node.size - 2)
                )
                node_surface = node_surface.convert_alpha()
                display.blit(node_surface, node.pos)

        for body in engine.root_node.bodies:
            body_surface = pygame.Surface((1, 1))
            pygame.draw.rect(
                body_surface,
                (255, 255, 255, 0),
                (0, 0, 1, 1)
            )
            body_surface = body_surface.convert_alpha()
            display.blit(
                body_surface,
                (body.cog[0] / SCALE, body.cog[1] / SCALE)
            )

        screen.blit(display, (0, 0))

        # look for events
        for event in pygame.event.get():

            # quit game
            if event.type == pygame.QUIT:
                running = False

            if event.type == pygame.MOUSEBUTTONDOWN and event.button == LEFT:
                add_bodies(engine)
                print('left mouse buttondown')

            if event.type == pygame.MOUSEBUTTONUP and event.button == LEFT:
                print('left mouse buttonup')

            if event.type == pygame.MOUSEBUTTONDOWN and event.button == RIGHT:
                draw_boxes = not draw_boxes
                print('right mouse button')

            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_UP:
                    run_engine = True

                if event.key == pygame.K_DOWN:
                    run_engine = False

        pygame.display.flip()


if __name__ == '__main__':
    # run main programm
    main()
