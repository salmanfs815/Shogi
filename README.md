# Shogi

A desktop application for Windows and Linux to play Shogi (Japanese chess)


## Features

* There are 4 game modes (varying board sizes and pieces used):
  * Mini (5x5)
  * Standard (9x9)
  * Chu (12x12)
  * Tenjiku (16x16)
* There are 5 AI difficulty levels:
  * Normal (AI will play with normal difficulty)
  * Hard (AI will play harder than normal difficulty)
  * Suicidal (AI will make worst possible move)
  * Protracted death (after ensuring the safety of the king, AI will make worst possible move)
  * Random (AI will make random moves)
* Timed mode
* Multiplayer
  * Same computer
  * Over email (email game file to other player to make move)
  * Over LAN

## Getting Started

Clone the repository in your local machine:

`$ git clone https://github.com/salmanfs815/Shogi.git`

## Prerequisites

* Julia v0.5

### Extra Libraries

The libraries used in this project are:

* GTK
* DataFranes
* SQLite

## Installation 

Run the script:

`$ ./shogi.sh`

Press Enter twice when prompted about requirements installations. 
We will now assume that Julia and the required libraries are installed on your machine.

## Running The Program

Run the program:
`$ ./Shogi_Linux/shogi/game.jl`

## Authors

Team: Null_ptr

Members:
* Salman Siddiqui
* Laura Guevara
* Haider Ilahi
* Daniel Korin
* Eddie Chiu

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
