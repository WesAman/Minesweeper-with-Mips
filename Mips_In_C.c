#include <stdio.h>
#include <stdlib.h> //used for random function
#include <time.h> //used to seed random function


//------------------------------------------------Global Values-----------------------------------------------------------------------

// Character used to represent mine
#define MINE 'M'

// Character used to represent flag
#define FLAG 'F'

// Character used to represent empty tile
#define EMPTY '.'

// Character used to represent hidden tile
#define HIDDEN 'O'

// Maximum possible size of a board
#define MAX_SZ 480
char shownBoard[MAX_SZ];
char hiddenBoard[MAX_SZ];

// Global integers to keep track of dimensions of board and total mines on it
int maxRow, maxColumn, boardSize, mineCount, flagCount = 0;
//------------------------------------------------------------------------------------------------------------------------------------




//---------------------------------------------Function Declarations------------------------------------------------------------------

// Prompts user for difficulty level of game
void difficulty();

// Prints known board information to player
void printBoard();

// Generates random mine placement, uses first index chosen to avoid placing mine there (player could lose on first turn otherwise)
void generateBoard(int chosenIndex);

// Returns character representation of how many mines surround given tile
char nearbyMines(int row, int column);

// Returns character representation of how many flags surround given tile
char nearbyFlags(int row, int column);

// Returns 1D index given 2D components, "translates" player input for use in array
int getIndex(int row, int column);

// Returns true if given 2D components exist on current board size
int tileExists(int row, int column);

// Reveals tile
void dig(int row, int column);

// Reveals tiles surrounding given tile
void digAround(int row, int column);

// Toggles flag on tile
void flag(int index);

// Returns 1 if player won, -1 if player lost, 0 otherwise
int checkWin();
//------------------------------------------------------------------------------------------------------------------------------------



int main(void) {
  hiddenBoard[0] = '\0'; //set to null (prevents board from being re-created)
  
  difficulty(); //prompt difficulty
  
  int gameOver = 0;   

  while (!gameOver) {
    printBoard();
    char command = '\0';
    int row = -1, column = -1, index;
    
    while(command != 'd' && command != 'f'){
      printf("\nEnter 'd' to dig or 'f' to flag: ");
      printf("\nEx: d 1 4");
        printf("\n");
      scanf(" %c", &command);
    }
    
    while(row < 0 || row >= maxRow){
      printf("Enter valid row number: \n");
      scanf(" %d", &row);// this formerly had %[^' ']d
    }
  
    while(column < 0 || column >= maxColumn){
      printf("Enter valid column number: \n");
      scanf(" %d", &column);
    }

    index = getIndex(row, column);
    
    if(command == 'd'){
      if(hiddenBoard[0] == '\0' && shownBoard[index] != FLAG){
        generateBoard(index);
      }

      if(shownBoard[index] == nearbyFlags(row, column)){
        digAround(row, column);
      }
      
      dig(row, column);
    }
    else{
      flag(index);
    }

    //game will keep looping until false
    gameOver = checkWin();
  }

  printBoard();
  if (gameOver == 1) {
    printf("\nYou win! B)");
  } else {
    printf("\nYou lose! X(");
  }
}

void generateBoard(int chosenIndex) {
  srand(time(0));
  int assigned = 0;

  // Loop until all mines have been assigned tiles
  while (assigned < mineCount) {
    int index = rand() % boardSize;

    //reject if already a mine or player's first move
    if (hiddenBoard[index] != MINE && index != chosenIndex) {
      hiddenBoard[index] = MINE;
      assigned++;
    }
  }

  //fill rest of board
  for (int i = 0; i < maxRow; i++) {
    for (int j = 0; j < maxColumn; j++) {
      hiddenBoard[getIndex(i, j)] = nearbyMines(i, j);
    }
  }
}

int tileExists(int row, int column) {
  return (0 <= row && row < maxRow && 0 <= column && column < maxColumn);
}

char nearbyMines(int row, int column) {
  // return if tile is assigned MINE
  if (hiddenBoard[getIndex(row, column)] == MINE) {
    return MINE;
  }
  
  // used to keep track of number of surrounding mines
  int count = 0;
  
  for(int i = -1; i <= 1; i++){ //tracks above and below 
    for(int j = -1; j <= 1; j++){ // tracks left and right
      count += tileExists(row + i, column + j) && hiddenBoard[getIndex(row + i, column + j)] == MINE;
    }
  }

  // return empty tile character if no mines are nearby
  if (count == 0) {
    return EMPTY;
  }

  // else return character representation of number of mines surrounding a tile
  return count + '0';
}


char nearbyFlags(int row, int column){
  if (shownBoard[getIndex(row, column)] == HIDDEN || shownBoard[getIndex(row, column)] == FLAG) {
    return '\0';
  }

  // used to keep track of number of surrounding flags
  int count = 0;
  
  for(int i = -1; i <= 1; i++){
    for(int j = -1; j <= 1; j++){
      count += tileExists(row + i, column + j) && shownBoard[getIndex(row + i, column + j)] == FLAG;
    }
  }
  
  // else return character representation of number of flags surrounding a tile
  return count + '0';
}

void flag(int index) {
  // change to flag if tile is hidden
  if (shownBoard[index] == HIDDEN) {
    shownBoard[index] = FLAG;
    flagCount++;
  }
  // change to hidden if tile is flagged
  else if (shownBoard[index] == FLAG) {
    shownBoard[index] = HIDDEN;
    flagCount--;
  }
}

void dig(int row, int column) {
  int index = getIndex(row, column);

  // do not reveal tile if flagged
  if (shownBoard[index] != FLAG) {
    shownBoard[index] = hiddenBoard[index];
  }
  
  // if tile is empty, dig around it
  if (hiddenBoard[index] == EMPTY) {
    digAround(row, column);
  }
}

void digAround(int row, int column) {

  for(int i = -1; i <= 1; i++){
    int rowOffset = row + i;
    for(int j = -1; j <= 1; j++){
      int columnOffset = column + j;
      if(tileExists(rowOffset, columnOffset) && shownBoard[getIndex(rowOffset, columnOffset)] != EMPTY){
        dig(rowOffset, columnOffset);
      }
    }
  }

}

int checkWin() {
  // used to keep track of tiles not dug
  int uncovered = 0;

  // iterate over all of shown board
  for (int i = 0; i < boardSize; i++) {

    // if a mine has been dug, return -1
    if (shownBoard[i] == MINE) {
      return -1;
    }

    // increment uncovered if tile is hidden or flagged
    uncovered += shownBoard[i] == HIDDEN || shownBoard[i] == FLAG;
  }

  // return true if only mines are left uncoverd
  return uncovered == mineCount;
}

void printBoard() {
  printf("\n\n   ");
  for (int i = 0; i < maxColumn; i++) {
    printf("%2d ", i);
  }

  printf("\n  ");
  for (int i = 0; i < maxColumn; i++) {
    printf("  |");
  }

  for (int i = 0; i < boardSize; i++) {
    if (i % maxColumn == 0) {
      printf("\n\n%2d-", i / maxColumn);
    }

    printf(" %c ", shownBoard[i]);
  }
  printf("\nMines Left: %d\n\n", mineCount - flagCount);
}

int getIndex(int row, int column) { return (row * maxColumn) + column; }

// function to get difficulty level
void difficulty() {
  char diff = '0';

  while((diff != '1') && (diff != '2') && (diff != '3')){
    printf("\n\n\nPlease select your difficulty:");
    printf("\n1: Easy Peasy Lemon Squeezy.");
    printf("\n2: Intermediate, watch your step!");
    printf("\n3: Expert, be sure to not sneeze!");
    printf("\nEnter here 'ONLY ONE CHARACTER': ");
    scanf(" %c", &diff);
  }
  
  // beginner
  if (diff == '1') {
    maxRow = 10;
    maxColumn = 10;
    boardSize = 100;
    mineCount = 10;
  }
  // intermediate
  else if (diff == '2') {
    maxRow = 16;
    maxColumn = 16;
    boardSize = 256;
    mineCount = 40;
  }
  // expert
  else if (diff == '3') {
    maxRow = 16;
    maxColumn = 30;
    boardSize = 480;
    mineCount = 99;
  }

  for (int i = 0; i < boardSize; i++) {
    shownBoard[i] = HIDDEN;
  }
}