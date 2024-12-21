import curses
import time
import random

def main(stdscr):
    # Initialize the curses screen
    curses.curs_set(0)  # Hide cursor
    stdscr.nodelay(1)   # Non-blocking input
    stdscr.timeout(100)  # Refresh screen every 100ms

    # Set colors
    curses.start_color()
    curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)  # Green text on black background
    curses.init_pair(2, curses.COLOR_RED, curses.COLOR_BLACK)  # Red text on black background
    curses.init_pair(3, curses.COLOR_YELLOW, curses.COLOR_BLACK)  # Yellow text on black background
    curses.init_pair(4, curses.COLOR_WHITE, curses.COLOR_BLACK)  # White text on black background
    curses.init_pair(5, curses.COLOR_BLUE, curses.COLOR_BLACK)  # Blue text on black background

    # Game variables
    cphrase = "wubbalubbadubdub"
    ci = 0
    score = 0
    max_morties = 18
    morty_count = 0
    i = 1
    j = 1

    # Draw initial screen
    stdscr.clear()
    stdscr.refresh()

    # Display title
    stdscr.addstr(18, 15, "A game for the ONCE UPON A TIME, RICK AND MORTY Jam", curses.color_pair(5))
    stdscr.addstr(19, 15, "By Chompicore. Written in Python", curses.color_pair(5))
    stdscr.addstr(22, 28, "[DO NOT PRESS ANY KEY!!]", curses.color_pair(7))

    # Wait for 8 seconds
    time.sleep(8)

    # Game instructions
    stdscr.clear()
    stdscr.addstr(0, 0, "*** HOW TO PLAY ***", curses.color_pair(1))
    stdscr.addstr(2, 0, "You have to type Rick's catchphrase 'WUBBA LUBBA DUB DUB'.", curses.color_pair(1))
    stdscr.addstr(3, 0, "No spaces allowed. Every time you make a mistake, a new Morty will appear.", curses.color_pair(1))
    stdscr.addstr(4, 0, "With 18 Morties, it's game over. [ESC] = Quit game", curses.color_pair(1))
    stdscr.addstr(6, 0, "Good luck!", curses.color_pair(2))
    stdscr.refresh()

    # Wait for user to press a key
    stdscr.getch()

    # Game loop
    while True:
        stdscr.clear()
        stdscr.refresh()

        k = stdscr.getch()

        if k == 27:  # Escape key to quit
            break

        # Convert to lowercase
        k = chr(k).lower()

        # Check if the key matches the current letter of the phrase
        if k != cphrase[ci]:
            # Display mistake (new Morty appears)
            morty_count += 1
            if morty_count >= max_morties:
                break

            stdscr.addstr(i, j, "ÜÛÛÛÛÛÛÜ  ", curses.color_pair(2))
            stdscr.addstr(i+1, j, " ÛÛ±±±±±±  ", curses.color_pair(4))
            stdscr.addstr(i+2, j, " ±±ÜÜ±±ÜÜ±± ", curses.color_pair(4))
            stdscr.addstr(i+3, j, " Ü±±±±±±Û ", curses.color_pair(4))
            stdscr.addstr(i+4, j, " ÛÛ±±±±±± ", curses.color_pair(4))
            stdscr.addstr(i+5, j, " ßÛÛÛÛÛÛÛÛß", curses.color_pair(3))
            stdscr.refresh()

            i += 8
            if i > 18:
                break

        else:
            # Correct input, update game state
            ci += 1
            if ci >= len(cphrase):
                ci = 0
            score += 50

        stdscr.refresh()
        time.sleep(0.1)  # Game speed control

    # Game over
    stdscr.clear()
    stdscr.addstr(5, 30, "YOUR SCORE: ", curses.color_pair(2))
    stdscr.addstr(5, 40, str(score), curses.color_pair(4))
    stdscr.addstr(7, 30, "Game Over!", curses.color_pair(2))
    stdscr.refresh()
    stdscr.getch()

if __name__ == "__main__":
    curses.wrapper(main)
