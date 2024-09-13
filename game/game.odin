package game

import rl "vendor:raylib"
import "core:math"
import "core:math/rand"
import "core:fmt"
import "core:strings"


Score :: struct {
    background : rl.Rectangle,
    background_color : rl.Color,

    score : i32,
    high_score : i32,
    level : i32,
    number_of_asteroids : int,
    shield : i32,
    fuel : i32,
    ammo : i32,
}

Ship :: struct {
    shape : [3]rl.Vector2,
    base_shape : [3]rl.Vector2,  // New field to store the original shape
    position : rl.Vector2, //center position
    direction : rl.Vector2,
    velocity : rl.Vector2,
    acceleration : rl.Vector2,
    rotation : f32,
    color : rl.Color,

    shield : i32,
    ammo : i32,
    bullets : [dynamic]^Bullet,
    fuel : i32,
    
    play_width : f32,
    play_height : f32,
}

Asteroid :: struct {
    position : rl.Vector2, //center position
    max_radius : f32,
    min_radius : f32,

    vertices : i32,
    shape : []rl.Vector2,
    color : rl.Color,

    velocity : rl.Vector2,
    acceleration : rl.Vector2,
    rotation : f32,
    
    active : bool,
    level : i32,
}

Bullet :: struct {
    position : rl.Vector2,
    velocity : rl.Vector2,
    color : rl.Color,
    active : bool,
}

Game_state :: struct {
    ship : ^Ship,
    asteroids : ^[dynamic]^Asteroid,
    score : ^Score,
    showMessageBox : bool,
    toggle : bool,
    screen_width : i32,
    screen_height : i32,
    game_over : bool,
}

Make_ship :: proc(position : rl.Vector2, size : f32, play_width, play_height :f32,color : rl.Color) -> ^Ship {
    ship := new(Ship)
    ship.position = position
    ship.direction = rl.Vector2{0, -1}
    ship.velocity = rl.Vector2{0, 0}
    ship.acceleration = rl.Vector2{0, 0}
    ship.rotation = 0
    ship.color = color
    ship.shield = 100   
    ship.bullets = make([dynamic]^Bullet, 0, 1000)
    ship.fuel = MAX_FUEL
    ship.ammo = MAX_AMMO

    ship.play_width = play_width
    ship.play_height = play_height
    
    // Initialize base_shape relative to center
    ship.base_shape = [3]rl.Vector2{
        {0, -size},
        {-size, size},
        {size, size},
    }
    
    // Initialize shape with the same values
    ship.shape = ship.base_shape
    
    return ship
}

Make_asteroid :: proc(position : rl.Vector2, max_radius : f32, min_radius : f32, color : rl.Color, level : i32) -> ^Asteroid {
    asteroid := new(Asteroid)
    asteroid.position = position
    asteroid.max_radius = max_radius
    asteroid.min_radius = min_radius
    asteroid.color = color
    asteroid.level = level

    asteroid.vertices = i32(10 + rand.int_max(8))

    speed := 1 + rand.float32()

    asteroid.velocity = rl.Vector2{rand.float32()*2 - 1, rand.float32()*2 - 1}*speed
    asteroid.acceleration = rl.Vector2{0, 0}

    asteroid.rotation = rand.float32()*2 -1
    
    v := asteroid.vertices
    // Generate asteroid shape based on radius
    asteroid.shape = make([]rl.Vector2, v)
    for i in 0..< v {
        angle := f32(i)*(360.0/f32(v))
        radius := min_radius + (max_radius - min_radius)*f32(rand.float32())
        asteroid.shape[i] = rl.Vector2{radius*math.cos(angle*math.PI/180), radius*math.sin(angle*math.PI/180)}   
    }
    
    asteroid.active = true
    return asteroid
}
MAX_SPEED : f32 = 20.0
MAX_FUEL : i32 = 100
MAX_AMMO : i32 = 1000
ship_time : f32 = 0
Update_ship :: proc(ship : ^Ship) {
    delta_time := rl.GetFrameTime()
    speed : f32 = 15
   
    get_player_input(ship)
    
    // Apply acceleration
    ship.velocity += ship.acceleration

    // Limit speed
    
    if rl.Vector2Length(ship.velocity) > MAX_SPEED {
        ship.velocity = rl.Vector2Normalize(ship.velocity)*MAX_SPEED
    }
    
    // Apply drag (optional, for more realistic movement)
    ship.velocity *= 0.995
    
    // Update position
    ship.position += ship.velocity*delta_time*speed
    
    // Update shape based on rotation and position
    update_ship_shape(ship)
    
    update_bullets(ship)
}

Update_asteroids :: proc(asteroids : [dynamic]^Asteroid, ship : ^Ship) {
    for asteroid in asteroids {
        update_asteroid(asteroid, ship)
    }
}

update_asteroid :: proc(asteroid : ^Asteroid, ship: ^Ship) {
    delta_time := rl.GetFrameTime()
    speed : f32 = 1
    for i in 0..<asteroid.vertices {
        rotated := rotate_point(asteroid.shape[i], asteroid.rotation, speed, delta_time)
        asteroid.shape[i] = rotated
    }
    asteroid.position += asteroid.velocity*delta_time*speed
    asteroid.acceleration = rl.Vector2Normalize(asteroid.position - ship.position)*0.1
    asteroid.velocity -= asteroid.acceleration
    if rl.Vector2Length(asteroid.velocity) > MAX_SPEED {
        asteroid.velocity = rl.Vector2Normalize(asteroid.velocity)*MAX_SPEED
    }
}

update_ship_shape :: proc(ship : ^Ship) {
    delta_time := rl.GetFrameTime()
    if ship.position.x > ship.play_width {
        ship.position.x = 0
    }
    if ship.position.x < 0 {
        ship.position.x = ship.play_width
    }
    if ship.position.y > ship.play_height {
        ship.position.y = 0
    }
    if ship.position.y < 0 {
        ship.position.y = ship.play_height
    }
    for i in 0..<3 {
        rotated := rotate_point(ship.base_shape[i], ship.rotation, 4, delta_time)
        ship.shape[i] = rotated
    }
    //clamp ammo and fuel
    ship.ammo = math.clamp(ship.ammo, 0, MAX_AMMO)
    ship.fuel = math.clamp(ship.fuel, 0, MAX_FUEL)
}

rotate_point :: proc(point : rl.Vector2, angle, ang_speed, delta_time : f32) -> rl.Vector2 {
    rad := (angle + delta_time*ang_speed)*math.PI/180
    cos_rot := math.cos(rad)
    sin_rot := math.sin(rad)
    return rl.Vector2{
        point.x * cos_rot - point.y * sin_rot,
        point.x * sin_rot + point.y * cos_rot,
    }
}


fire_bullet :: proc(ship : ^Ship) {
    bullet := new(Bullet)
    bullet.position = ship.position + ship.shape[0]  // Use the ship's nose as the starting position
    extra_speed := angle_to_vector(ship.rotation)*(MAX_SPEED + 5)
    bullet.velocity = ship.velocity + extra_speed
    bullet.color = rl.WHITE
    bullet.active = true
    append(&ship.bullets, bullet)
}

update_bullets :: proc(ship : ^Ship) {
    delta_time := rl.GetFrameTime()
    speed : f32 = 20
    ship_position := ship.position
    for bullet in ship.bullets {
        if bullet.active {
            bullet.position = bullet.position + bullet.velocity*speed*delta_time
            distance := rl.Vector2Distance(bullet.position, ship_position)
            if distance > 1000 {
                bullet.active = false
            }
        }
    }

    // new_bullets := [dynamic]^Bullet{}
    for bullet in ship.bullets {
        if !bullet.active {
            free(bullet)
        }
    }
    // delete(ship.bullets)
    // ship.bullets = new_bullets
    
}

angle_to_vector :: proc(angle : f32) -> rl.Vector2 {
    radians := angle*math.PI/180
    return rl.Vector2{math.sin(radians), -math.cos(radians)}
}


get_player_input :: proc(ship : ^Ship) {
    if rl.IsKeyDown(rl.KeyboardKey.SPACE) && !rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) && !rl.IsKeyDown(rl.KeyboardKey.RIGHT_CONTROL) {
        // Calculate acceleration based on ship's current rotation
        acceleration_magnitude : f32 = 0.6
        ship.acceleration = angle_to_vector(ship.rotation)* acceleration_magnitude
        ship.fuel -= 1
    } else if rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_CONTROL) {
        fire_bullet(ship)
        ship.ammo -= 1
        ship.acceleration = rl.Vector2{0, 0}
    } else {
        ship.acceleration = rl.Vector2{0, 0}
    }
    
    rotation_speed : f32 = 5
    if rl.IsKeyDown(rl.KeyboardKey.LEFT) || rl.IsKeyDown(rl.KeyboardKey.A) {
        ship.rotation -= rotation_speed
    }
    if rl.IsKeyDown(rl.KeyboardKey.RIGHT) || rl.IsKeyDown(rl.KeyboardKey.D) {
        ship.rotation += rotation_speed
    }    
}

Check_collision :: proc(ship : ^Ship, asteroids : [dynamic]^Asteroid) {
    //bool CheckCollisionPointPoly(Vector2 point, Vector2 *points, int pointCount);                      // Check if point is within a polygon described by array of vertices
    for asteroid in asteroids {
        temp_shape := make([]rl.Vector2, asteroid.vertices)
        defer delete(temp_shape)
        for i in 0..<asteroid.vertices {
            temp_shape[i] = asteroid.shape[i] + asteroid.position
        }

        ship_colision := false
        for i in 0..<3 {
            if CheckCollisionPointPoly(ship.position + ship.shape[i], temp_shape, asteroid.vertices){
                ship_colision = true
                ship.shield -= 10
                break
            }
        }
        if ship_colision {
            ship.shield -= 10
            asteroid.active = false
        } else {
            for bullet in ship.bullets {     
                if CheckCollisionPointPoly(bullet.position, temp_shape, asteroid.vertices) {
                    bullet.active = false
                    asteroid.active = false
                }
            }
        }
    }
}

Spaw_asteroid :: proc(gs : ^Game_state) {
    max_radius := f32(gs.screen_width)/2 + 200
    min_radius := f32(gs.screen_width)/2 + 100

    r := math.sqrt(min_radius*min_radius + (max_radius*max_radius - min_radius*min_radius)*rand.float32())
    theta := rand.float32()*2*math.PI
    x := f32(gs.screen_width)/2 + r*math.cos(theta)
    y := f32(gs.screen_height)/2 + r*math.sin(theta)
    asteroid_position := rl.Vector2{x, y}

    asteroid := Make_asteroid(asteroid_position, 120, 60, rl.RED, 3)
    append(gs.asteroids, asteroid)
    rl.TraceLog(rl.TraceLogLevel.INFO, "Asteroid spawned at %f, %f", asteroid_position.x, asteroid_position.y)
}

Destroy_asteroid :: proc(asteroid : ^Asteroid, asteroids : ^[dynamic]^Asteroid) {
    defer free(asteroid)
    
    if asteroid.level > 1 {
            radius := asteroid.max_radius 
            position := asteroid.position
            dir := rl.Vector2{rand.float32()*2 - 1, rand.float32()*2 - 1}
            new_position := position + dir*radius
            new_asteroid := Make_asteroid(new_position, asteroid.max_radius/2, asteroid.min_radius/2, asteroid.color, asteroid.level - 1)
            append(asteroids, new_asteroid)

            new_position = position - dir*radius
            new_asteroid = Make_asteroid(new_position, asteroid.max_radius/2, asteroid.min_radius/2, asteroid.color, asteroid.level - 1)
            append(asteroids, new_asteroid)     
    }

    delete(asteroid.shape)
    
}

Draw_ship :: proc(ship : ^Ship) {
    for bullet in ship.bullets {
        draw_bullet(bullet)
    }
    rl.DrawTriangleLines(ship.position + ship.shape[0], ship.position + ship.shape[1], ship.position + ship.shape[2], ship.color)
}

draw_bullet :: proc(bullet : ^Bullet) {
    rl.DrawCircleV(bullet.position, 2, bullet.color)
}

Draw_shape :: proc(shape : []rl.Vector2, vertices : i32, position : rl.Vector2, color : rl.Color) {
    //	DrawSplineLinear                 :: proc(points: [^]Vector2, pointCount: c.int, thick: f32, color: Color) --- // Draw spline: Linear, minimum 2 points
    temp_shape := make([]rl.Vector2, vertices)
    defer delete(temp_shape)
    
    for i in 0..<vertices {
        temp_shape[i] = shape[i] + position
    }
    temp_shape[vertices - 1] = shape[0] + position
    a := raw_data(temp_shape[:])

    rl.DrawSplineLinear(a, vertices, 2, color)   
}

CheckCollisionPointPoly :: proc(point : rl.Vector2, points : []rl.Vector2, pointCount : i32) -> bool {
    inside := false
    if pointCount > 2 {
        j := pointCount - 1
        for i in 0..<pointCount  {
            if (points[i].y > point.y) != (points[j].y > point.y) &&
                (point.x < (points[j].x - points[i].x)*(point.y - points[i].y)/(points[j].y - points[i].y) + points[i].x) {
                inside = !inside
            }
            j = i
        }
    }
    return inside
}

Make_score :: proc(background : rl.Rectangle, background_color : rl.Color) -> ^Score {
    score := new(Score)
    score.background = background
    score.background_color = background_color
    score.score = 0
    score.high_score = 0
    score.level = 1
    score.number_of_asteroids = 0
    score.shield = 100
    score.fuel = 100
    return score
}

Update_score :: proc(score : ^Score, ship : ^Ship, asteroids : [dynamic]^Asteroid) {
    score.number_of_asteroids = len(asteroids)
    score.shield = ship.shield
    score.fuel = ship.fuel
    score.ammo = ship.ammo
    if score.number_of_asteroids == 0 {
        score.level += 1  
    }
}

Draw_score :: proc(score : ^Score) {
    rl.DrawRectangleRec(score.background, score.background_color)
    rl.DrawText(rl.TextFormat("Score: %v", score.score), i32(score.background.x + 10), i32(score.background.y + 10), 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("High Score: %v", score.high_score), i32(score.background.x + 10), i32(score.background.y + 30), 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("Level: %v", score.level), i32(score.background.x + 10), i32(score.background.y + 50), 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("Asteroids: %v", score.number_of_asteroids), i32(score.background.x + 10), i32(score.background.y + 70), 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("Shield: %v", score.shield), i32(score.background.x + 10), i32(score.background.y + 90), 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("Fuel: %v", score.fuel), i32(score.background.x + 10), i32(score.background.y + 110), 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("Ammo: %v", score.ammo), i32(score.background.x + 10), i32(score.background.y + 130), 20, rl.WHITE)
}

Reset_Game :: proc(gs : ^Game_state) {
    gs.score.score = 0
    gs.score.level = 1
    gs.score.number_of_asteroids = 0
    gs.score.shield = 100
    gs.score.fuel = 100
    gs.score.ammo = 1000
    gs.showMessageBox = false
    gs.toggle = false
    
    gs.ship.position = rl.Vector2{f32(gs.screen_width)/2, f32(gs.screen_height/2)}
    gs.ship.velocity = rl.Vector2{0, 0}
    gs.ship.acceleration = rl.Vector2{0, 0}
    gs.ship.rotation = 0
    gs.ship.shield = 100
    gs.ship.fuel = 100
    gs.ship.ammo = 1000
    gs.ship.bullets = make([dynamic]^Bullet, 0, 1000)
    delete(gs.asteroids^)
    //gs.asteroids = make(^[dynamic]^Asteroid, 0, 100)

}

Draw_GUI :: proc(gs : ^Game_state) {
    // if rl.GuiButton((rl.Rectangle){ f32(gs.screen_width -120), 24, 120, 30 }, "#191#Show Message"){
    //     showMessageBox = true
    // }   
    // rl.GuiCheckBox((rl.Rectangle){ f32(screen_width -120), 64, 120, 30 }, "#192#Toggle", &toggle)
    
    // // rl.GuiSlider((rl.Rectangle){ f32(screen_width -120), 104, 120, 30 }, "10", "200", &query_distance, 10, 200)
    // if (showMessageBox)
    // {
    //     result := rl.GuiMessageBox((rl.Rectangle){ 85, 70, 250, 100 },
    //         "#191#Message Box", "Hi! This is a message!", "Nice;Cool")

    //     if result >= 0 {
    //         showMessageBox = false
    //     }
    // }
}

Draw_gameover :: proc(gs : ^Game_state) {
    rl.DrawText("Game Over", gs.screen_width/2 - 100, gs.screen_height/2, 40, rl.RED)
    rl.DrawText("Press R to restart", gs.screen_width/2 - 100, gs.screen_height/2 + 40, 20, rl.RED)
}