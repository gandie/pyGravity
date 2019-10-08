import pygame
from pygravity.engine_bh import Engine
import random
import math

FPS = 100

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

    engine = Engine(size=1000)
    for i in range(125):
        engine.add_body(
            cog=(i * 4, 500),
            vel=(0, 10),
            mass=1
        )
    '''
    '''
    for i in range(100):
        engine.add_body(
            cog=(random.randint(1, 1000), random.randint(1, 1000)),
            vel=(random.randint(0, 5), random.randint(0, 5)),
            mass=1
        )


    engine.add_body(
        cog=(500, 500),
        vel=(0, 0),
        mass=10000
    )
    '''
    '''

    '''
    for i in range(100):
        for j in range(100):
            engine.add_body(
                cog=(i * 10, j * 10),
                vel=(0, 0),
                mass=1
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

        for body in engine.root_node.bodies:
            body_surface = pygame.Surface((1, 1))
            pygame.draw.rect(
                body_surface,
                (255, 255, 255, 0),
                (0, 0, 1, 1)
            )
            body_surface = body_surface.convert_alpha()
            display.blit(body_surface, body.cog)

        screen.blit(display, (0, 0))

        # look for events
        for event in pygame.event.get():

            # quit game
            if event.type == pygame.QUIT:
                running = False

            if event.type == pygame.MOUSEBUTTONDOWN and event.button == LEFT:
                #fieldhandler.click(event.pos)
                print('left mouse button')

            if event.type == pygame.MOUSEBUTTONDOWN and event.button == RIGHT:
                #fieldhandler.right_click(event.pos)
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
