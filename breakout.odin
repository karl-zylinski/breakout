package breakout

import rl "vendor:raylib"
import "core:math/rand"
import "core:math/linalg"
import "core:math"
import "core:fmt"

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
BLOCK_MARGIN :: 0

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

		/*clear(&blocks)

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
		}*/
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

	camera := rl.Camera2D {
		zoom = f32(rl.GetScreenHeight())/PIXEL_SCREEN_WIDTH
	}

	for !rl.WindowShouldClose() {
		if rl.IsMouseButtonPressed(.LEFT) {
			restart()
			ball_pos.x = paddle_pos_x + paddle_width/2
			ball_pos.y = PADDLE_POS_Y - BALL_RADIUS
			ball_dir = linalg.normalize0(rl.GetScreenToWorld2D(rl.GetMousePosition(), camera) - ball_pos)
			ball_attached = false
		}

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

		/*Collision_Faces :: enum {
			North, East, South, West,
		}
		collided_with_faces: bit_set[Collision_Faces]

		blocks_to_remove := make([dynamic]int, context.temp_allocator)

		for b, i in blocks {
			block_rect := rl.Rectangle {
				b.pos.x, b.pos.y,
				BLOCK_WIDTH, BLOCK_HEIGHT,
			}

			if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, block_rect) {
				if ball_pos.y < block_rect.y {
					collided_with_faces += {.North}
				}

				if ball_pos.y > block_rect.y + block_rect.height {
					collided_with_faces += {.South}
				}

				if ball_pos.x < block_rect.x {
					collided_with_faces += {.West}
				}

				if ball_pos.x > block_rect.x + block_rect.width {
					collided_with_faces += {.East}
				}

				append(&blocks_to_remove, i)
			}
		}

		if collided_with_faces != nil {
			reflection_normal: rl.Vector2

			if .North in collided_with_faces {
				reflection_normal += {0, -1}
			}

			if .South in collided_with_faces {
				reflection_normal += {0, 1}
			}

			if .West in collided_with_faces {
				reflection_normal += {-1, 0}
			}

			if .East in collided_with_faces {
				reflection_normal += {1, 0}
			}

			fmt.println(reflection_normal)
			fmt.println(linalg.normalize0(reflection_normal))
			ball_dir = linalg.reflect(ball_dir, linalg.normalize0(reflection_normal))

			/*for bi in blocks_to_remove {
				unordered_remove(&blocks, bi)
			}*/
		}*/


		// DRAW

		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND_COLOR)

		rl.BeginMode2D(camera)
		rl.DrawRectangleRec(paddle_rect, PLAYER_COLOR)
		rl.DrawCircleV(ball_pos, BALL_RADIUS, {200, 90, 20, 255})

		for b in blocks {
			block_rect := rl.Rectangle {
				b.pos.x, b.pos.y,
				BLOCK_WIDTH, BLOCK_HEIGHT,
			}

			rl.DrawRectangleRec(block_rect, block_color_values[b.color])
			rl.DrawRectangleLinesEx(block_rect, 1, rl.BLACK)
		}

		Collision_Faces :: enum {
			North, East, South, West,
		}

		collided_with_faces: bit_set[Collision_Faces]

		mw := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

		rl.DrawCircleV(mw, BALL_RADIUS, rl.MAGENTA)

		bd := f32(BALL_RADIUS*2)

		for b, i in blocks {
			block_rect := rl.Rectangle {
				b.pos.x, b.pos.y,
				BLOCK_WIDTH, BLOCK_HEIGHT,
			}

			if rl.CheckCollisionCircleRec(mw, BALL_RADIUS, block_rect) {
				top_rect := rl.Rectangle {
					b.pos.x, b.pos.y - bd,
					BLOCK_WIDTH, bd,
				}

				bottom_rect := rl.Rectangle {
					b.pos.x, b.pos.y + BLOCK_HEIGHT,
					BLOCK_WIDTH, bd,
				}

				left_rect := rl.Rectangle {
					b.pos.x - bd, b.pos.y,
					bd-0.5, BLOCK_HEIGHT-0.5,
				}

				right_rect := rl.Rectangle {
					b.pos.x + BLOCK_WIDTH + 0.5, b.pos.y,
					bd - 0.5, BLOCK_HEIGHT-0.5,
				}

				if rl.CheckCollisionCircleRec(mw, BALL_RADIUS, top_rect) {
					collided_with_faces += {.North}
					rl.DrawRectangleRec(top_rect, {255, 0, 0, 100})
				}

				if rl.CheckCollisionCircleRec(mw, BALL_RADIUS, bottom_rect) {
					collided_with_faces += {.South}
					rl.DrawRectangleRec(bottom_rect, {255, 0, 0, 100})
				}

				if rl.CheckCollisionCircleRec(mw, BALL_RADIUS, left_rect) {
					collided_with_faces += {.West}
					rl.DrawRectangleRec(left_rect, {255, 0, 0, 100})
				}

				if rl.CheckCollisionCircleRec(mw, BALL_RADIUS, right_rect) {
					collided_with_faces += {.East}
					rl.DrawRectangleRec(right_rect, {255, 0, 0, 100})
				}
			}
		}

		if collided_with_faces != nil {
			reflection_normal: rl.Vector2

			if .North in collided_with_faces {
				reflection_normal += {0, -1}
			}

			if .South in collided_with_faces {
				reflection_normal += {0, 1}
			}

			if .West in collided_with_faces {
				reflection_normal += {-1, 0}
			}

			if .East in collided_with_faces {
				reflection_normal += {1, 0}
			}


			rl.DrawLineEx(mw, mw + linalg.normalize0(reflection_normal)*10, 2, rl.RED)

			/*for bi in blocks_to_remove {
				unordered_remove(&blocks, bi)
			}*/
		}

/*
		for b, i in blocks {
			block_rect := rl.Rectangle {
				b.pos.x, b.pos.y,
				BLOCK_WIDTH, BLOCK_HEIGHT,
			}

			/*if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, block_rect) {
				nearest_edge_dist := abs(block_rect.y - ball_pos.y)
				edge_normal := rl.Vector2 {0, -1}

				if d := abs(block_rect.y + block_rect.height - ball_pos.y); d < nearest_edge_dist {
					nearest_edge_dist = d
					edge_normal = {0, 1}
				}

				if d := abs(block_rect.x - ball_pos.x); d < nearest_edge_dist {
					nearest_edge_dist = d
					edge_normal = {-1, 0}
				}
				
				if d := abs(block_rect.x + block_rect.width - ball_pos.x); d < nearest_edge_dist {
					nearest_edge_dist = d
					edge_normal = {1, 0}
				}


				ball_dir = linalg.reflect(ball_dir, edge_normal)
				unordered_remove(&blocks, i)
				break
			}*/


			mw := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
			if rl.CheckCollisionCircleRec(mw, BALL_RADIUS, block_rect) {
				nearest_edge_dist := abs(block_rect.y - mw.y)
				edge_normal := rl.Vector2 {0, -1}

				if d := abs(block_rect.y + block_rect.height - mw.y); d < nearest_edge_dist {
					nearest_edge_dist = d
					edge_normal = {0, 1}
				}

				if d := abs(block_rect.x - mw.x); d < nearest_edge_dist {
					nearest_edge_dist = d
					edge_normal = {-1, 0}
				}
				
				if d := abs(block_rect.x + block_rect.width - mw.x); d < nearest_edge_dist {
					nearest_edge_dist = d
					edge_normal = {1, 0}
				}


				//ball_dir = linalg.reflect(ball_dir, edge_normal)
				rl.DrawLineEx(mw, mw + edge_normal*10, 2, rl.RED)
			/*	unordered_remove(&blocks, i)
				break*/
			}
		}*/

		rl.EndMode2D()
		rl.EndDrawing()
	}

	rl.CloseWindow()
}