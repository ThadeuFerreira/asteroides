package game

import rl "vendor:raylib"
import "core:math"


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
    bullets : [dynamic]^Bullet,
}

Asteroid :: struct {
    position : rl.Vector2, //center position
    max_radius : f32,
    min_radius : f32,
    shape : []rl.Vector2,
    velocity : rl.Vector2,
    color : rl.Color,
    level : i32,
}

Bullet :: struct {
    position : rl.Vector2,
    velocity : rl.Vector2,
    color : rl.Color,
    active : bool,
}

Make_ship :: proc(position : rl.Vector2, size : f32, color : rl.Color) -> ^Ship {
    ship := new(Ship)
    ship.position = position
    ship.direction = rl.Vector2{0, -1}
    ship.velocity = rl.Vector2{0, 0}
    ship.acceleration = rl.Vector2{0, 0}
    ship.rotation = 0
    ship.color = color
    ship.shield = 100   
    ship.bullets = make([dynamic]^Bullet, 0, 1000)
    
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

Update_ship :: proc(ship : ^Ship) {
    get_player_input(ship)
    
    // Apply acceleration
    ship.velocity += ship.acceleration
    
    // Apply drag (optional, for more realistic movement)
    ship.velocity *= 0.99
    
    // Update position
    ship.position += ship.velocity
    
    // Update shape based on rotation and position
    update_ship_shape(ship)
    
    update_bullets(ship)
}

update_ship_shape :: proc(ship : ^Ship) {
    if ship.position.x > f32(rl.GetScreenWidth()) {
        ship.position.x = 0
    }
    if ship.position.x < 0 {
        ship.position.x = f32(rl.GetScreenWidth())
    }
    if ship.position.y > f32(rl.GetScreenHeight()) {
        ship.position.y = 0
    }
    if ship.position.y < 0 {
        ship.position.y = f32(rl.GetScreenHeight())
    }
    for i in 0..<3 {
        rotated := rotate_point(ship.base_shape[i], ship.rotation)
        ship.shape[i] = rotated
    }
}

rotate_point :: proc(point : rl.Vector2, angle : f32) -> rl.Vector2 {
    rad := angle*math.PI/180
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
    bullet.velocity = ship.velocity + angle_to_vector(ship.rotation)*10
    bullet.color = rl.WHITE
    bullet.active = true
    append(&ship.bullets, bullet)
}


update_bullets :: proc(ship : ^Ship) {
    for bullet in ship.bullets {
        if bullet.active {
            bullet.position = bullet.position + bullet.velocity
        }
    }
}

angle_to_vector :: proc(angle : f32) -> rl.Vector2 {
    radians := angle*math.PI/180
    return rl.Vector2{math.sin(radians), -math.cos(radians)}
}


get_player_input :: proc(ship : ^Ship) {
    if rl.IsKeyDown(rl.KeyboardKey.SPACE) && !rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) && !rl.IsKeyDown(rl.KeyboardKey.RIGHT_CONTROL) {
        // Calculate acceleration based on ship's current rotation
        acceleration_magnitude : f32 = 0.5
        ship.acceleration = angle_to_vector(ship.rotation)* acceleration_magnitude
    } else if rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_CONTROL) {
        fire_bullet(ship)
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

Draw_ship :: proc(ship : ^Ship) {
    for bullet in ship.bullets {
        draw_bullet(bullet)
    }
    rl.DrawTriangleLines(ship.position + ship.shape[0], ship.position + ship.shape[1], ship.position + ship.shape[2], ship.color)
}

draw_bullet :: proc(bullet : ^Bullet) {
    rl.DrawCircleV(bullet.position, 2, bullet.color)
}