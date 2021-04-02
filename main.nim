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

func circlePartVerts(th : float, dTH : float, tNum : int, r : float, origin : Vector2) : seq[Vector2] =
    let dTH = dTH / tNum.float
    let rotMat = getRotMat(dTH)
    result = @[makevec2(origin.x + r, origin.y)]
    result[0] = (result[0] - origin) * getRotMat(th) + origin
    for i in 0..<tNum:
        result.add (result[i] - origin) * rotMat + origin

func drawCirclePart(verts : seq[Vector2], origin : Vector2, col : Color) =
    for i in 0..<verts.len - 1:
        rlBegin(RL_TRIANGLES)
        rlColor4ub col.r, col.g, col.b, col.a
        rlVertex2f origin.x, origin.y

        rlColor4ub col.r, col.g, col.b, 0
        rlVertex2f verts[i].x, verts[i].y 
        rlVertex2f verts[i + 1].x, verts[i + 1].y
        rlEnd()
        rlglDraw()

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


    let plrCenter = plr.pos + makevec2(plrTex.width / 2, plrTex.height / 2)
    let relMp = GetMousePosition() - plrCenter
    var mousAng = angleToPoint relMp

    BeginDrawing()

    let cpv = circlePartVerts(mousAng - (PI / 5), PI / 2.5, 10, 200, plrCenter)

    DrawTextureV plrTex, plr.pos, WHITE
    drawCirclePart(cpv, plrCenter, WHITE)
    EndDrawing()
CloseWindow()