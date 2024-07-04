package breakout

import rl "vendor:raylib"
import "core:math/rand"
import "core:math/linalg"
import "core:math"

Block_Color :: enum {
	Yellow,
	Green,
	Orange,
	Red,
}

Block :: struct {
	pos: rl.Vector2,
	color: Block_Color,
}


block_color_values := [Block_Color]rl.Color {
	.Yellow = { 253, 249, 150, 255 },
	.Green = { 180, 245, 190, 255 },
	.Orange = { 170, 120, 250, 255 },
	.Red = { 250, 90, 85, 255 },
}

PIXEL_SCREEN_WIDTH :: 320
BACKGROUND_COLOR :: rl.Color { 150, 190, 220, 255 }
PLAYER_COLOR :: rl.Color { 50, 150, 90, 255 }
PADDLE_POS_Y :: 260
PADDLE_HEIGHT :: 10
BALL_RADIUS :: 4
BLOCK_WIDTH :: 27
BLOCK_HEIGHT :: 10
BLOCK_MARGIN :: 1

paddle_width: f32
paddle_pos_x: f32
move_speed: f32
ball_speed: f32
ball_pos: rl.Vector2
ball_dir: rl.Vector2
ball_attached: bool
blocks: [dynamic]Block

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(1280, 1280, "Breakout!")
	rl.SetTargetFPS(500)

	restart :: proc() {
		paddle_width = f32(50)
		paddle_pos_x = f32(PIXEL_SCREEN_WIDTH)/2 - paddle_width/2
		move_speed = f32(200)
		ball_attached = true
		ball_speed = f32(200)
		ball_pos = {}
		ball_dir = {}
	}

	restart()

	for x in 0..<10 {
		for y in 0..<8 {
			pos := rl.Vector2 {
				f32(20 + x * BLOCK_WIDTH + x * BLOCK_MARGIN),
				f32(40 + y * BLOCK_HEIGHT + y * BLOCK_MARGIN),
			}

			append(&blocks, Block {
				pos = pos,
				color = Block_Color(3-y/2),
			})
		}
	}

	for !rl.WindowShouldClose() {
		// UPDATE

		if rl.IsKeyDown(.LEFT) {
			paddle_pos_x -= rl.GetFrameTime() * move_speed
		}

		if rl.IsKeyDown(.RIGHT) {
			paddle_pos_x += rl.GetFrameTime() * move_speed
		}

		paddle_pos_x = clamp(paddle_pos_x, 0, PIXEL_SCREEN_WIDTH - paddle_width)
		
		paddle_rect := rl.Rectangle {
			paddle_pos_x, PADDLE_POS_Y,
			paddle_width, PADDLE_HEIGHT,
		}

		if ball_attached { 
			ball_pos.x = paddle_pos_x + paddle_width/2
			ball_pos.y = PADDLE_POS_Y - BALL_RADIUS

			if rl.IsKeyPressed(.SPACE) {
				ball_dir = rl.Vector2Rotate(rl.Vector2 {0, -1}, math.smoothstep(f32(-math.TAU/5), math.TAU/5, rand.float32()))
				ball_attached = false
			}
		} else {
			ball_pos += ball_dir * ball_speed * rl.GetFrameTime()

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

			if ball_pos.y + BALL_RADIUS > PIXEL_SCREEN_WIDTH {
				restart()
			}

			if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, paddle_rect) {
				ball_dir = linalg.reflect(ball_dir, rl.Vector2{0, -1})	
			}
		}

		for b, i in blocks {
			block_rect := rl.Rectangle {
				b.pos.x, b.pos.y,
				BLOCK_WIDTH, BLOCK_HEIGHT,
			}

			if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, block_rect) {
				if ball_pos.y - BALL_RADIUS < block_rect.y {
					ball_dir = linalg.reflect(ball_dir, rl.Vector2{0, -1})
				} else if ball_pos.y + BALL_RADIUS > block_rect.y + block_rect.height {
					ball_dir = linalg.reflect(ball_dir, rl.Vector2{0, 1})
				} else if ball_pos.x + BALL_RADIUS > block_rect.x + block_rect.width {
					ball_dir = linalg.reflect(ball_dir, rl.Vector2{1, 0})
				} else if ball_pos.x - BALL_RADIUS < block_rect.x {
					ball_dir = linalg.reflect(ball_dir, rl.Vector2{-1, 0})
				} 

				unordered_remove(&blocks, i)
				break
			}
		}

		// DRAW

		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND_COLOR)

		camera := rl.Camera2D {
			zoom = f32(rl.GetScreenHeight())/PIXEL_SCREEN_WIDTH
		}

		rl.BeginMode2D(camera)
		rl.DrawRectangleRec(paddle_rect, PLAYER_COLOR)
		rl.DrawCircleV(ball_pos, BALL_RADIUS, {200, 90, 20, 255})

		for b in blocks {
			block_rect := rl.Rectangle {
				b.pos.x, b.pos.y,
				BLOCK_WIDTH, BLOCK_HEIGHT,
			}

			rl.DrawRectangleRec(block_rect, block_color_values[b.color])
		}

		rl.EndMode2D()
		rl.EndDrawing()
	}

	rl.CloseWindow()
}