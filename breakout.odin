package breakout

import rl "vendor:raylib"
import "core:math/rand"
import "core:math/linalg"
import "core:math"
import "core:fmt"

PIXEL_SCREEN_WIDTH :: 320
PADDLE_POS_Y :: 260
PADDLE_WIDTH :: 50
PADDLE_HEIGHT :: 6
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

block_color_score := [Block_Color]int {
	.Yellow = 2,
	.Green = 4,
	.Orange = 6,
	.Red = 8,
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

paddle_pos_x: f32
move_speed: f32
ball_speed: f32
ball_pos: rl.Vector2
ball_dir: rl.Vector2
started: bool
blocks: [NUM_BLOCKS_X][NUM_BLOCKS_Y]bool
score: int
physics_time: f32

block_exists :: proc(x, y: int) -> bool {
	if x < 0 || y < 0 || x >= NUM_BLOCKS_X || y >= NUM_BLOCKS_Y {
		return false
	}

	return blocks[x][y]
}

reflect_perturbe :: proc(dir: rl.Vector2, normal: rl.Vector2) -> rl.Vector2 {
	r := linalg.reflect(dir, linalg.normalize(normal))
	rot_angle := math.lerp(f32(-math.TAU/40), math.TAU/40, rand.float32())
	return linalg.normalize(rl.Vector2Rotate(r, rot_angle))
}

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(1280, 1280, "Breakout!")
	rl.SetTargetFPS(500)

	ball_texture := rl.LoadTexture("ball.png")
	paddle_texture := rl.LoadTexture("paddle.png")

	restart :: proc() {
		paddle_pos_x = f32(PIXEL_SCREEN_WIDTH)/2 - PADDLE_WIDTH/2
		move_speed = f32(200)
		started = false
		ball_speed = f32(240)
		ball_pos = {
			PIXEL_SCREEN_WIDTH/2,
			160,
		}
		ball_dir = {}
		score = 0

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
			ball_pos.x = paddle_pos_x + PADDLE_WIDTH/2
			ball_pos.y = PADDLE_POS_Y - BALL_RADIUS
			ball_dir = linalg.normalize0(rl.GetScreenToWorld2D(rl.GetMousePosition(), camera) - ball_pos)
			started = true
		}

		// UPDATE
		if !started && rl.IsKeyPressed(.SPACE) {
			ball_dir = rl.Vector2Rotate(rl.Vector2 {0, 1}, math.lerp(f32(-math.TAU/10), math.TAU/10, rand.float32()))
			started = true
		}

		paddle_move_velocity: f32

		if rl.IsKeyDown(.LEFT) {
			paddle_move_velocity -= move_speed
		}

		if rl.IsKeyDown(.RIGHT) {
			paddle_move_velocity += move_speed
		}

		previous_paddle_pos_x := paddle_pos_x
		previous_ball_pos := ball_pos
		physics_time += rl.GetFrameTime() 
		physics_dt :: 1.0/60.0 /// 0.016s

		for physics_time > physics_dt {
			previous_paddle_pos_x = paddle_pos_x
			previous_ball_pos = ball_pos

			if started {
				ball_pos += ball_dir * ball_speed * physics_dt
			}

			if ball_pos.x + BALL_RADIUS > PIXEL_SCREEN_WIDTH {
				ball_pos.x = PIXEL_SCREEN_WIDTH - BALL_RADIUS
				ball_dir = reflect_perturbe(ball_dir, {-1, 0})
			} 

			if ball_pos.x - BALL_RADIUS < 0 {
				ball_pos.x = BALL_RADIUS
				ball_dir = reflect_perturbe(ball_dir, {1, 0})
			}

			if ball_pos.y - BALL_RADIUS < 0 {
				ball_pos.y = BALL_RADIUS
				ball_dir = reflect_perturbe(ball_dir, {0, 1})
			}

			if ball_pos.y > PIXEL_SCREEN_WIDTH + BALL_RADIUS*10 {
				restart()
			}
			paddle_pos_x += paddle_move_velocity * physics_dt
			paddle_pos_x = clamp(paddle_pos_x, 0, PIXEL_SCREEN_WIDTH - PADDLE_WIDTH)
			
			paddle_rect := rl.Rectangle {
				paddle_pos_x, PADDLE_POS_Y,
				PADDLE_WIDTH, PADDLE_HEIGHT,
			}

			if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, paddle_rect) {
				collision_normal: rl.Vector2

				if ball_pos.y < paddle_rect.y + paddle_rect.height {
					collision_normal += {0, -1}
					ball_pos.y = paddle_rect.y - BALL_RADIUS
				}

				if ball_pos.y > paddle_rect.y {
					collision_normal += {0, 1}
					ball_pos.y = paddle_rect.y + paddle_rect.height + BALL_RADIUS
				}

				if ball_pos.x < paddle_rect.x {
					collision_normal += {-1, 0}
				}

				if ball_pos.x > paddle_rect.x + paddle_rect.width {
					collision_normal += {1, 0}
				}

				if collision_normal != 0 {
					ball_dir = reflect_perturbe(ball_dir, linalg.normalize(collision_normal))
				}

				if paddle_move_velocity > 0 {
					ball_dir = linalg.normalize(ball_dir + (ball_dir.x > 0 ? 0.1 : 0.2))
				}

				if paddle_move_velocity < 0 {
					ball_dir = linalg.normalize(ball_dir - (ball_dir.x < 0 ? 0.1 : 0.2))
				}

				score -= 1
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
							ball_dir = reflect_perturbe(ball_dir, linalg.normalize(collision_normal))
						}

						blocks[x][y] = false
						row_color := row_colors[y]
						score += block_color_score[row_color]
						break num_blocks_x_loop
					}
				}
			}

			physics_time -= physics_dt
		}

		physics_blend_t := physics_time / f32(physics_dt)
		ball_render_pos := math.lerp(previous_ball_pos, ball_pos, physics_blend_t)
		paddle_render_pos_x := math.lerp(previous_paddle_pos_x, paddle_pos_x, physics_blend_t)

		// DRAW

		rl.BeginDrawing()
		rl.ClearBackground({ 150, 190, 220, 255 })

		rl.BeginMode2D(camera)
		rl.DrawTextureV(paddle_texture, {paddle_render_pos_x, PADDLE_POS_Y}, rl.WHITE)
		//rl.DrawRectangleRec(paddle_rect, { 50, 150, 90, 255 })
		rl.DrawTextureV(ball_texture, ball_render_pos - {BALL_RADIUS, BALL_RADIUS}, rl.WHITE)
		//rl.DrawCircleV(ball_pos, BALL_RADIUS, {200, 90, 20, 255})

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

		score_text := fmt.ctprint(score)
		rl.DrawText(score_text, 5, 5, 10, rl.WHITE)

		rl.EndMode2D()
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}