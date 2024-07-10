package breakout

import rl "vendor:raylib"
import "core:math/rand"
import "core:math/linalg"
import "core:math"
import "core:fmt"

SCREEN_SIZE :: 320
PADDLE_POS_Y :: 260
PADDLE_WIDTH :: 50
PADDLE_HEIGHT :: 6
PADDLE_SPEED :: 200
BALL_SPEED :: 240
BALL_RADIUS :: 4
BALL_START_Y :: 160
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
ball_pos: rl.Vector2
ball_dir: rl.Vector2
started: bool
game_over: bool
blocks: [NUM_BLOCKS_X][NUM_BLOCKS_Y]bool
score: int
accumulated_time: f32

block_exists :: proc(x, y: int) -> bool {
	if x < 0 || y < 0 || x >= NUM_BLOCKS_X || y >= NUM_BLOCKS_Y {
		return false
	}

	return blocks[x][y]
}

reflect :: proc(dir, normal: rl.Vector2) -> rl.Vector2 {
	new_dir := linalg.reflect(dir, normal)
	return linalg.normalize0(new_dir)
}

restart :: proc() {
	paddle_pos_x = f32(SCREEN_SIZE)/2 - PADDLE_WIDTH/2
	started = false
	game_over = false
	ball_pos = {}
	ball_dir = {}
	score = 0

	for x in 0..<NUM_BLOCKS_X {
		for y in 0..<NUM_BLOCKS_Y {
			blocks[x][y] = true
		}
	}
}

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(1280, 1280, "Breakout!")
	rl.SetTargetFPS(500)
	rl.InitAudioDevice()

	ball_texture := rl.LoadTexture("ball.png")
	paddle_texture := rl.LoadTexture("paddle.png")
	hit_block_sound := rl.LoadSound("hit_block.wav")
	hit_paddle_sound := rl.LoadSound("hit_paddle.wav")
	game_over_sound := rl.LoadSound("game_over.wav")

	restart()

	camera := rl.Camera2D {
		zoom = f32(rl.GetScreenHeight())/SCREEN_SIZE
	}

	for !rl.WindowShouldClose() {
		if !started {
			ball_pos = { f32(math.cos(rl.GetTime()) * SCREEN_SIZE/2.5)+SCREEN_SIZE/2, BALL_START_Y }
			
			if rl.IsKeyPressed(.SPACE) {
				ball_dir = linalg.normalize0(rl.Vector2 {paddle_pos_x + PADDLE_WIDTH/2, PADDLE_POS_Y} - ball_pos)
				started = true
			}
		} else if game_over {
			if rl.IsKeyPressed(.SPACE) {
				restart()
			}
		} else {
			accumulated_time += rl.GetFrameTime() 
		}

		previous_paddle_pos_x := paddle_pos_x
		previous_ball_pos := ball_pos
		DT :: 1.0/60.0 /// 0.016s

		for accumulated_time > DT {
			previous_paddle_pos_x = paddle_pos_x
			previous_ball_pos = ball_pos

			if started {
				ball_pos += ball_dir * BALL_SPEED * DT
			}

			if ball_pos.x + BALL_RADIUS > SCREEN_SIZE {
				ball_pos.x = SCREEN_SIZE - BALL_RADIUS
				ball_dir = reflect(ball_dir, rl.Vector2{-1, 0})
			} 

			if ball_pos.x - BALL_RADIUS < 0 {
				ball_pos.x = BALL_RADIUS
				ball_dir = reflect(ball_dir, rl.Vector2{1, 0})
			}

			if ball_pos.y - BALL_RADIUS < 0 {
				ball_pos.y = BALL_RADIUS
				ball_dir = reflect(ball_dir, rl.Vector2{0, 1})
			}

			if ball_pos.y > SCREEN_SIZE + BALL_RADIUS*10 {
				game_over = true
				rl.PlaySound(game_over_sound)
			}

			paddle_move_velocity: f32

			if rl.IsKeyDown(.LEFT) {
				paddle_move_velocity -= PADDLE_SPEED
			}

			if rl.IsKeyDown(.RIGHT) {
				paddle_move_velocity += PADDLE_SPEED
			}

			paddle_pos_x += paddle_move_velocity * DT
			paddle_pos_x = clamp(paddle_pos_x, 0, SCREEN_SIZE - PADDLE_WIDTH)
			
			paddle_rect := rl.Rectangle {
				paddle_pos_x, PADDLE_POS_Y,
				PADDLE_WIDTH, PADDLE_HEIGHT,
			}

			if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, paddle_rect) {
				collision_normal: rl.Vector2

				if previous_ball_pos.y < paddle_rect.y + paddle_rect.height {
					collision_normal += {0, -1}
					ball_pos.y = paddle_rect.y - BALL_RADIUS
				}

				if previous_ball_pos.y > paddle_rect.y {
					collision_normal += {0, 1}
					ball_pos.y = paddle_rect.y + paddle_rect.height + BALL_RADIUS
				}

				if previous_ball_pos.x < paddle_rect.x {
					collision_normal += {-1, 0}
				}

				if previous_ball_pos.x > paddle_rect.x + paddle_rect.width {
					collision_normal += {1, 0}
				}

				if collision_normal != 0 {
					ball_dir = reflect(ball_dir, collision_normal)
				}

				rl.PlaySound(hit_paddle_sound)
			}

			block_x_loop: for x in 0..<NUM_BLOCKS_X {
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

						if previous_ball_pos.y < block_rect.y {
							collision_normal += {0, -1}
						}

						if previous_ball_pos.y > block_rect.y + block_rect.height {
							collision_normal += {0, 1}
						}

						if previous_ball_pos.x < block_rect.x {
							collision_normal += {-1, 0}
						}

						if previous_ball_pos.x > block_rect.x + block_rect.width {
							collision_normal += {1, 0}
						}

						if block_exists(x + int(collision_normal.x), y) {
							collision_normal.x = 0
						}

						if block_exists(x, y + int(collision_normal.y)) {
							collision_normal.y = 0
						}

						if collision_normal != 0 {
							ball_dir = reflect(ball_dir, collision_normal)
						}

						blocks[x][y] = false
						row_color := row_colors[y]
						score += block_color_score[row_color]
						rl.SetSoundPitch(hit_block_sound, rand.float32_range(0.8, 1.2))
						rl.PlaySound(hit_block_sound)
						break block_x_loop
					}
				}
			}

			accumulated_time -= DT
		}

		blend := accumulated_time / f32(DT)
		ball_render_pos := math.lerp(previous_ball_pos, ball_pos, blend)
		paddle_render_pos_x := math.lerp(previous_paddle_pos_x, paddle_pos_x, blend)

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

		if !started {
			start_text: cstring = "Start: SPACE"
			start_text_width := rl.MeasureText(start_text, 15)
			rl.DrawText(start_text, SCREEN_SIZE/2-start_text_width/2, BALL_START_Y - 30, 15, rl.WHITE)
		}

		if game_over {
			game_over_text: cstring = fmt.ctprintf("Score: %v. Reset: SPACE", score)
			game_over_text_width := rl.MeasureText(game_over_text, 15)
			rl.DrawText(game_over_text, SCREEN_SIZE/2-game_over_text_width/2, BALL_START_Y - 30, 15, rl.WHITE)
		}

		rl.EndMode2D()
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.CloseAudioDevice()
	rl.CloseWindow()
}