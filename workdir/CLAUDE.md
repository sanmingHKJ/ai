# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## AI Workflow System to generate games for MiniWorld Studio

`./projects` store the generated games
`./workflow` stores all the files of a new kind of workflow to generate a game. There are different execution units to produce outputs from input data. These units are connected by inputs and outputs to form a graph. Each unit has its own execution .md document and may has tools for validation and conversion.
`./workflow/ExecUnits` stores all the execution units. 
    Each unit is stored in a subdir in which there is the execution instruction file: `exe-flow.md` and optional python tools specific to the unit.
`./workflow/Knowledges` stores the how-to-do-something documents.
`./workflow/SGF` stores the game framework for MiniWorld Studio
`./workflow/SystemTemplates` stores a library of game system templates which can be adapted by AI into a generated game.
`./workflow/Tools` stores the tools globally needed in the workflow except the tools specific to some ExecUnit.
    `setup_game_project.py` setup a game project before generating it with args: GAME_DIR