package main

import rl "vendor:raylib"
import "core:math"
import "core:mem"
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

    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    temp_track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&temp_track, context.temp_allocator)
    context.temp_allocator = mem.tracking_allocator(&temp_track)

    defer {
        if len(temp_track.allocation_map) > 0 {
            fmt.eprintf("=== %v allocations not freed: ===\n", len(temp_track.allocation_map))
            for _, entry in temp_track.allocation_map {
                fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
            }
        }
        if len(temp_track.bad_free_array) > 0 {
            fmt.eprintf("=== %v incorrect frees: ===\n", len(temp_track.bad_free_array))
            for entry in temp_track.bad_free_array {
                fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
            }
        }
        mem.tracking_allocator_destroy(&temp_track)

        if len(track.allocation_map) > 0 {
            fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
            for _, entry in track.allocation_map {
                fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
            }
        }
        if len(track.bad_free_array) > 0 {
            fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
            for entry in track.bad_free_array {
                fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
            }
        }
        mem.tracking_allocator_destroy(&track)
    }
    ship_position := rl.Vector2{play_width/2, f32(screen_height/2)}
    ship := game.Make_ship(ship_position, f32(SHIP_SIZE), play_width, f32(screen_height), rl.WHITE)
    rl.SetConfigFlags(rl.ConfigFlags{rl.ConfigFlag.WINDOW_TRANSPARENT});

    rl.InitWindow(screen_width, screen_height, "raylib [core] example - basic window");
    rl.HideCursor()
        
    asteroids := make([dynamic]^game.Asteroid, 0, 100)
    score_background := rl.Rectangle{play_width, 0, score_width, f32(screen_height)}
    score := game.Make_score(score_background, rl.RED)
    rl.SetTargetFPS(120) // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------
    rl.SetTraceLogLevel(rl.TraceLogLevel.ALL) // Show trace log messages (LOG_INFO, LOG_WARNING, LOG_ERROR, LOG_DEBUG)
    showMessageBox := false
    toggle := false
    spawn_timer : f32 = 0.0
    game_over := false
    game_state := game.Game_state{ship, &asteroids, score, showMessageBox, toggle, i32(play_width), screen_height, game_over}
    // Main game loop
    for !rl.WindowShouldClose()    // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        
        mouse_pos := rl.GetMousePosition()
        // if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
        //     a := game.Make_asteroid(mouse_pos, 120, 60, rl.RED, 3)
        //     append(&asteroids, a)
        // }
        spawn_timer += rl.GetFrameTime()
        if spawn_timer > 1 {
            game.Spaw_asteroid(&game_state)
            spawn_timer = 0
            rl.TraceLog(rl.TraceLogLevel.INFO, "Number of asteroids: %d", len(asteroids))
        }

        st_mouse_pos :=  rl.TextFormat( "%v, %v", mouse_pos.x ,mouse_pos.y)
        rl.DrawText(st_mouse_pos, i32(mouse_pos.x), i32(mouse_pos.y), 20, rl.WHITE)
        
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
        delete(asteroids)
        asteroids = new_asteroids
        delete(ship.bullets)
        ship.bullets = new_bullets
    
        game.Draw_ship(ship)
        for as in asteroids {      
            game.Draw_shape(as.shape, as.vertices, as.position, rl.RED)
        }
        game.Update_score(score, ship, asteroids)
        game.Draw_score(score)
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
    // De-Initialization
    for bullet in ship.bullets {
        free(bullet)
    }
    delete(ship.bullets)
    for asteroid in asteroids {
        delete(asteroid.shape)
        free(asteroid)
    }
    delete(asteroids)
    free(ship)
    free(score)
    rl.CloseWindow()
}