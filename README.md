# Minesweeper-with-Mips
Minesweeper game built with MIPS assembly language
Minesweeper by Wessal Aman, Jaden Keller, and Anh Le

after assembling and running program you will be prompted to choose a difficulty.
Enter the character 1 for easy,
Enter the character 2 for medium,
Enter the character 3 for hard.

Once difficulty is chosen the game begins.
You will be prompted to enter a command: 'd' or 'f'
d will mean you want to dig/reveal a tile
f will mean you want to flag a tile

Once the command is chosen you will be prompted to ender numbers for a valid row and column, check the shown board output for the combination for the tile you choose.

If a number tile is surrounded by the same number of flags as it represents (e.g. a 2 tile has 2 flags next to it), you can dig that tile to automatically dig the remaining surrounding tiles (if you flagged wrong this can dig a mine, be careful!).
