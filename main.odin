package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"
import "core:strings"
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
    rl.SetConfigFlags(rl.ConfigFlags{rl.ConfigFlag.WINDOW_TRANSPARENT});
    update_time : f32 = 0
    rl.InitWindow(screen_width, screen_height, "raylib [core] example - basic window");
    rl.HideCursor()
        
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

        st_mouse_pos :=  fmt.tprintf( "%v, %v", mouse_pos.x ,mouse_pos.y)
        rl.DrawText(strings.clone_to_cstring(st_mouse_pos), i32(mouse_pos.x), i32(mouse_pos.y), 20, rl.WHITE)
        update_time += rl.GetFrameTime()
        if update_time > 0.01{
            game.Update_ship(ship)
            //game.Update_asteroids(asteroids)
            game.Check_collision(ship, asteroids)
            // Remove inactive asteroids and bullets
            new_asteroids := [dynamic]^game.Asteroid{}
            new_bullets := [dynamic]^game.Bullet{}
            for asteroid in asteroids {
                if asteroid.active {
                    append(&new_asteroids, asteroid)
                }else{
                    rl.TraceLog(rl.TraceLogLevel.INFO, "Asteroid destroyed")
                }

            }
            for bullet in ship.bullets {
                if bullet.active {
                    append(&new_bullets, bullet)
                }
            }
            asteroids = new_asteroids
            ship.bullets = new_bullets
            update_time = 0
        }
        game.Draw_ship(ship)
        for as in asteroids {      
            game.Draw_shape(as.shape, as.vertices, as.position, rl.RED)
        }
        rl.EndDrawing()
    }

    rl.CloseWindow()
}