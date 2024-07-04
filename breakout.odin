package breakout

import rl "vendor:raylib"
import "core:math/rand"
import "core:math/linalg"
import "core:math"
import "core:fmt"

PIXEL_SCREEN_WIDTH :: 320
BACKGROUND_COLOR :: rl.Color { 150, 190, 220, 255 }
PLAYER_COLOR :: rl.Color { 50, 150, 90, 255 }
PADDLE_POS_Y :: 260
PADDLE_HEIGHT :: 10
BALL_RADIUS :: 4
BLOCK_WIDTH :: 28
BLOCK_HEIGHT :: 10
NUM_BLOCKS_X :: 10
NUM_BLOCKS_Y :: 8

Block_Color :: enum {
	Yellow,
	Green,
	Orange,
	Red,
}

block_color_values := [Block_Color]rl.Color {
	.Yellow = { 253, 249, 150, 255 },
	.Green = { 180, 245, 190, 255 },
	.Orange = { 170, 120, 250, 255 },
	.Red = { 250, 90, 85, 255 },
}

row_colors := [NUM_BLOCKS_Y]Block_Color {
	.Red,
	.Red,
	.Orange,
	.Orange,
	.Green,
	.Green,
	.Yellow,
	.Yellow,
}

paddle_width: f32
paddle_pos_x: f32
move_speed: f32
ball_speed: f32
ball_pos: rl.Vector2
ball_dir: rl.Vector2
ball_moving: bool
blocks: [NUM_BLOCKS_X][NUM_BLOCKS_Y]bool

block_exists :: proc(x, y: int) -> bool {
	if x < 0 || y < 0 || x >= NUM_BLOCKS_X || y >= NUM_BLOCKS_Y {
		return false
	}

	return blocks[x][y]
}

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(1280, 1280, "Breakout!")
	rl.SetTargetFPS(10)

	restart :: proc() {
		paddle_width = f32(50)
		paddle_pos_x = f32(PIXEL_SCREEN_WIDTH)/2 - paddle_width/2
		move_speed = f32(200)
		ball_moving = false
		ball_speed = f32(200)
		ball_pos = {
			PIXEL_SCREEN_WIDTH/2,
			160,
		}
		ball_dir = {}

		for x in 0..<NUM_BLOCKS_X {
			for y in 0..<NUM_BLOCKS_Y {
				blocks[x][y] = true
			}
		}
	}

	restart()

	camera := rl.Camera2D {
		zoom = f32(rl.GetScreenHeight())/PIXEL_SCREEN_WIDTH
	}

	for !rl.WindowShouldClose() {
		if rl.IsMouseButtonPressed(.LEFT) {
			restart()
			ball_pos.x = paddle_pos_x + paddle_width/2
			ball_pos.y = PADDLE_POS_Y - BALL_RADIUS
			ball_dir = linalg.normalize0(rl.GetScreenToWorld2D(rl.GetMousePosition(), camera) - ball_pos)
			ball_moving = true
		}

		// UPDATE

		if !ball_moving && rl.IsKeyPressed(.SPACE) {
			ball_dir = rl.Vector2Rotate(rl.Vector2 {0, 1}, math.smoothstep(f32(-math.TAU/5), math.TAU/5, rand.float32()))
			ball_moving = true
		}

		if ball_moving {
			ball_pos += ball_dir * ball_speed * rl.GetFrameTime()
		}

		if ball_pos.x + BALL_RADIUS > PIXEL_SCREEN_WIDTH {
			ball_pos.x = PIXEL_SCREEN_WIDTH - BALL_RADIUS
			ball_dir = linalg.reflect(ball_dir, rl.Vector2{-1, 0})
		} 

		if ball_pos.x - BALL_RADIUS < 0 {
			ball_pos.x = BALL_RADIUS
			ball_dir = linalg.reflect(ball_dir, rl.Vector2{1, 0})
		}

		if ball_pos.y - BALL_RADIUS < 0 {
			ball_pos.y = BALL_RADIUS
			ball_dir = linalg.reflect(ball_dir, rl.Vector2{0, 1})
		}

		if ball_pos.y + BALL_RADIUS*2 > PIXEL_SCREEN_WIDTH {
			restart()
		}

		paddle_move_velocity: f32

		if rl.IsKeyDown(.LEFT) {
			paddle_move_velocity -= move_speed
		}

		if rl.IsKeyDown(.RIGHT) {
			paddle_move_velocity += move_speed
		}

		paddle_pos_x += paddle_move_velocity * rl.GetFrameTime()
		paddle_pos_x = clamp(paddle_pos_x, 0, PIXEL_SCREEN_WIDTH - paddle_width)
		
		paddle_rect := rl.Rectangle {
			paddle_pos_x, PADDLE_POS_Y,
			paddle_width, PADDLE_HEIGHT,
		}

		if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, paddle_rect) {
			collision_normal: rl.Vector2

			if ball_pos.y < paddle_rect.y {
				collision_normal += {0, -1}
				ball_pos.y = paddle_rect.y - BALL_RADIUS
			}

			if ball_pos.x < paddle_rect.x {
				collision_normal += {-1, 0}
				ball_pos.x = paddle_rect.x - BALL_RADIUS
			}

			if ball_pos.x > paddle_rect.x + paddle_rect.width {
				collision_normal += {1, 0}
				ball_pos.x = paddle_rect.x + paddle_rect.width + BALL_RADIUS
			}

			if collision_normal != 0 {
				ball_dir = linalg.normalize(linalg.reflect(ball_dir, linalg.normalize(collision_normal)))
			}

			if paddle_move_velocity > 0 {
				ball_dir = linalg.normalize(ball_dir + (ball_dir.x > 0 ? 0.1 : 0.2))
			}

			if paddle_move_velocity < 0 {
				ball_dir = linalg.normalize(ball_dir - (ball_dir.x < 0 ? 0.1 : 0.2))
			}
		}

		num_blocks_x_loop: for x in 0..<NUM_BLOCKS_X {
			for y in 0..<NUM_BLOCKS_Y {
				if blocks[x][y] == false {
					continue
				}

				block_rect := rl.Rectangle {
					f32(20 + x * BLOCK_WIDTH),
					f32(40 + y * BLOCK_HEIGHT),
					BLOCK_WIDTH,
					BLOCK_HEIGHT,
				}

				if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, block_rect) {
					collision_normal: rl.Vector2

					if ball_pos.y < block_rect.y && !block_exists(x, y - 1) {
						collision_normal += {0, -1}
					}

					if ball_pos.y > block_rect.y + block_rect.height && !block_exists(x, y + 1) {
						collision_normal += {0, 1}
					}

					if ball_pos.x < block_rect.x && !block_exists(x - 1, y) {
						collision_normal += {-1, 0}
					}

					if ball_pos.x > block_rect.x + block_rect.width && !block_exists(x + 1, y) {
						collision_normal += {1, 0}
					}

					if collision_normal != 0 {
						ball_dir = linalg.reflect(ball_dir, linalg.normalize(collision_normal))
					}

					blocks[x][y] = false
					break num_blocks_x_loop
				}
			}
		}

		// DRAW

		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND_COLOR)

		rl.BeginMode2D(camera)
		rl.DrawRectangleRec(paddle_rect, PLAYER_COLOR)
		rl.DrawCircleV(ball_pos, BALL_RADIUS, {200, 90, 20, 255})

		for x in 0..<NUM_BLOCKS_X {
			for y in 0..<NUM_BLOCKS_Y {
				if blocks[x][y] == false {
					continue
				}

				block_rect := rl.Rectangle {
					f32(20 + x * BLOCK_WIDTH),
					f32(40 + y * BLOCK_HEIGHT),
					BLOCK_WIDTH,
					BLOCK_HEIGHT,
				}

				top_left := rl.Vector2 {
					block_rect.x, block_rect.y
				}

				top_right := rl.Vector2 {
					block_rect.x + block_rect.width, block_rect.y
				}

				bottom_left := rl.Vector2 {
					block_rect.x, block_rect.y + block_rect.height
				}

				bottom_right := rl.Vector2 {
					block_rect.x + block_rect.width, block_rect.y + block_rect.height
				}

				rl.DrawRectangleRec(block_rect, block_color_values[row_colors[y]])
				rl.DrawLineEx(top_left, top_right, 1, {255, 255, 150, 100})
				rl.DrawLineEx(top_left, bottom_left, 1, {255, 255, 150, 100})
				rl.DrawLineEx(bottom_left, bottom_right, 1, {0, 0, 50, 100})
				rl.DrawLineEx(top_right, bottom_right, 1, {0, 0, 50, 100})
			}
		}

		rl.EndMode2D()
		rl.EndDrawing()
	}

	rl.CloseWindow()
}