package main

import rl "vendor:raylib"
import "core:math"
import "/game"




screen_width : i32 = 1000
screen_height : i32 = 1000

SHIP_SIZE : i32 = 30

BRUSH_SHAPE :: enum {
    SQUARE,
    CIRCLE
}

main :: proc()
{
    // Initialization
    //--------------------------------------------------------------------------------------
//    gridOffset := rl.Vector2{0,0}

//    gridInstance := grid.Make_Grid(
//     CELL_COUNT_X,
//     CELL_COUNT_Y,
//     f32(BRUSH_SIZE),
//     gridOffset,
//     CELL_SIZE,
//     rl.BLACK,
//    )

    ship := game.Make_ship(rl.Vector2{f32(screen_width/2), f32(screen_height/2)}, f32(SHIP_SIZE), rl.WHITE)
    
    update_time : f32 = 0
    rl.InitWindow(screen_width, screen_height, "raylib [core] example - basic window");
        
    asteroids := make([dynamic]^game.Asteroid, 0, 100)
    rl.SetTargetFPS(120) // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------
    rl.SetTraceLogLevel(rl.TraceLogLevel.ALL) // Show trace log messages (LOG_INFO, LOG_WARNING, LOG_ERROR, LOG_DEBUG)
    // Main game loop
    for !rl.WindowShouldClose()    // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        
        mouse_pos := rl.GetMousePosition()
        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            a := game.Make_asteroid(mouse_pos, 80, 45, rl.RED, 1)
            append(&asteroids, a)
        }
        update_time += rl.GetFrameTime()
        if update_time > 0.01{
            game.Update_ship(ship)
            game.Update_asteroids(asteroids)
            update_time = 0
        }
        game.Draw_ship(ship)
        for as in asteroids {      
            game.Draw_asteroid(as)
        }
        rl.EndDrawing()
    }

    rl.CloseWindow()
}