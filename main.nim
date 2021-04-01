import raylib, rlgl, rayutils, sequtils, math

type
    Player = object
        pos : Vector2
        canMove : bool
        collider : Rectangle
    Enemy = object
        collider : Rectangle
        lookAngle : float
        alert : bool

const
    screenWidth = 1280
    screenHeight = 720

InitWindow screenWidth, screenHeight, "Stealthus"

func circlePartVerts(th1, th2 : float, tNum : int, r : float, origin : Vector2) : seq[Vector2] =
    let dTH = (th1 - th2) / tNum.float
    let rotMat = getRotMat(dTH)
    result = @[makevec2(origin.x + r, origin.y)]
    result[0] *= (result[0] - origin) * getRotMat(th1) + origin
    debugEcho makevec2(1, 1) * getRotMat(th1)
    for i in 0..<tNum:
        result.add (result[i] - origin) * rotMat + origin

func drawCirclePart(verts : seq[Vector2], origin : Vector2) =
    rlBegin(RL_TRIANGLES)
    for i in 0..<verts.len - 1:
        rlColor3f 1, 1, 1
        rlVertex2f origin.x, origin.y

        rlColor4ub 0, 0, 0, 0
        rlVertex2f verts[i].x, verts[i].y 
        rlVertex2f verts[i + 1].x, verts[i + 1].y
        rlglDraw()
    rlEnd()

func movePlayer(plr : Player) : Vector2 =
    let acc = 0.15
    if plr.canMove:
        if IsKeyDown([KEY_LEFT, KEY_A]):
            result.x += -acc
        if IsKeyDown([KEY_RIGHT, KEY_D]):
            result.x += acc
        if IsKeyDown([KEY_UP, KEY_W]):
            result.y += -acc
        if IsKeyDown([KEY_DOWN, KEY_S]):
            result.y += acc
        if result.y + result.x == 2 * acc:
            result /= 2

let
    plrTex = LoadTexture "assets/sprites/plr.png"
    damping = 0.2

var
    plr = Player(pos : makevec2(0, 0), canMove : true, collider : makerect(0, 0, 32, 32))
    velo : Vector2
    enemies : seq[Enemy]

while not WindowShouldClose():
    ClearBackground BGREY
    
    velo *= damping

    velo += movePlayer plr
    plr.pos += velo
    plr.collider.x += velo.x; plr.collider.y += velo.y

    BeginDrawing()
    let cpv = circlePartVerts(0f, -PI / 2, 5, 20, makevec2(screenWidth div 2, screenHeight div 2))
    drawCirclePart(cpv, makevec2(0, 0))
    for v in cpv:
        DrawCircleV v, 10, GREEN
    DrawCircle screenWidth div 2, screenHeight div 2, 10, YELLOW
    DrawTextureV plrTex, plr.pos, WHITE
    EndDrawing()
CloseWindow()