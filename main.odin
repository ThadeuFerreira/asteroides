package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"
import "core:strings"
import "/game"




screen_width : i32 = 1400
screen_height : i32 = 1000
play_width : f32 = 1000
score_width : f32 = f32(screen_width) - play_width

SHIP_SIZE : i32 = 30

BRUSH_SHAPE :: enum {
    SQUARE,
    CIRCLE
}

main :: proc()
{
    // Initialization
    //--------------------------------------------------------------------------------------
    ship_position := rl.Vector2{play_width/2, f32(screen_height/2)}
    ship := game.Make_ship(ship_position, f32(SHIP_SIZE), play_width, f32(screen_height), rl.WHITE)
    rl.SetConfigFlags(rl.ConfigFlags{rl.ConfigFlag.WINDOW_TRANSPARENT});
    update_time : f32 = 0
    rl.InitWindow(screen_width, screen_height, "raylib [core] example - basic window");
    rl.HideCursor()
        
    asteroids := make([dynamic]^game.Asteroid, 0, 100)
    score_background := rl.Rectangle{play_width, 0, score_width, f32(screen_height)}
    score := game.Make_score(score_background, rl.RED)
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
            a := game.Make_asteroid(mouse_pos, 120, 60, rl.RED, 3)
            append(&asteroids, a)
        }

        st_mouse_pos :=  fmt.tprintf( "%v, %v", mouse_pos.x ,mouse_pos.y)
        rl.DrawText(strings.clone_to_cstring(st_mouse_pos), i32(mouse_pos.x), i32(mouse_pos.y), 20, rl.WHITE)
        update_time += rl.GetFrameTime()
        if update_time > 0.01{
            game.Update_ship(ship)
            game.Update_asteroids(asteroids, ship)
            game.Check_collision(ship, asteroids)
            // Remove inactive asteroids and bullets
            new_asteroids := [dynamic]^game.Asteroid{}
            new_bullets := [dynamic]^game.Bullet{}
            for asteroid in asteroids {
                if asteroid.active {
                    append(&new_asteroids, asteroid)
                }else{
                    game.Destroy_asteroid(asteroid, &new_asteroids)
                    score.score += 10
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
        game.Update_score(score, ship, asteroids)
        game.Draw_score(score)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}