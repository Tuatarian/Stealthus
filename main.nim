import raylib, rlgl, rayutils, sequtils, math, random

randomize()

type
    Player = object
        pos : Vector2
        dir : Vector2
        canMove : bool
        collider : Rectangle
    Enemy = object
        pos : Vector2
        npos : Vector2
        dir : Vector2
        tDir : Vector2
        rot : float
        collider : Rectangle
        lookAngle : float
        alert : bool

const
    screenWidth = 1920
    screenHeight = 1080

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
        # if IsKeyDown([KEY_LEFT, KEY_A]):
        #     result.x += -acc
        # if IsKeyDown([KEY_RIGHT, KEY_D]):
        #     result.x += acc
        # if IsKeyDown([KEY_UP, KEY_W]):
        #     result.y += -acc
        # if IsKeyDown([KEY_DOWN, KEY_S]):
        #     result.y += acc
        # if result.y + result.x == 2 * acc:
        #     result /= 2
        if plr.pos == makevec2(0, 0):
            debugEcho (GetMousePosition() - plr.pos).normalize
        return (GetMousePosition() - plr.pos).normalize / 10


func renderEnms(enms : seq[Enemy], eTex : Texture) =
    for e in enms:
        let ecenter = e.pos + makevec2(eTex.width / 2, eTex.height / 2)
        let cpv = circlePartVerts(angleToPoint(e.dir) - PI / 5, PI / 2.5, 10, 200, ecenter)
        drawCirclePart cpv, ecenter, GREEN
        let dirRotMat = getRotMat(angleToPoint e.dir)
        let eDrawPoints = rectPoints(makerect(int e.pos.x, int e.pos.y, eTex.width, eTex.height)).mapIt(it - ecenter).mapIt(it * dirRotMat).mapIt(it + ecenter)
        drawTriangleFan(eDrawPoints, RED)

proc moveEnems(enems : var seq[Enemy]) =
    for i in 0..<enems.len:
        if enems[i].pos == enems[i].npos or enems[i].tDir == makevec2(0, 0):
            enems[i].npos = makevec2(rand screenWidth, rand screenHeight)
            enems[i].tDir = (enems[i].npos - enems[i].pos).normalize
                
        if abs(enems[i].dir - enems[i].tDir) <& 0.1:
            enems[i].dir = enems[i].tDir

        if enems[i].dir != enems[i].tDir:
            enems[i].dir += (enems[i].tDir - enems[i].dir) / 125
            enems[i].rot = angleToPoint enems[i].dir

        else:
            enems[i].pos += enems[i].dir / 2.5

            if abs(enems[i].pos - enems[i].npos) <& 1:
                enems[i].pos = enems[i].npos

        enems[i].pos = min(max(makevec2(0, 0), enems[i].pos), makevec2(screenWidth, screenHeight))

let
    plrTex = LoadTexture "assets/sprites/plr.png"
    enmTex = LoadTexture "assets/sprites/Enem.png"
    damping = 0.2

var
    plr = Player(pos : makevec2(screenWidth, screenHeight), canMove : true, collider : makerect(0, 0, 32, 32))
    velo : Vector2
    enemies : seq[Enemy]

for i in 0..9:
    enemies.add Enemy(pos : makevec2(rand screenWidth, rand screenHeight))

while not WindowShouldClose():
    ClearBackground BGREY
    let mp = GetMousePosition() - makevec2(plrTex.width / 2, plrTex.height / 2)
    plr.pos = mp
    (plr.collider.x, plr.collider.y) = toTuple mp
    plr.pos = min(max(makevec2(0, 0), plr.pos), makevec2(screenWidth, screenHeight))

    let plrCenter = plr.pos + makevec2(plrTex.width / 2, plrTex.height / 2)
    let relMp = GetMousePosition() - plrCenter
    var mousAng = angleToPoint relMp

    BeginDrawing()

    let cpv = circlePartVerts(mousAng - (PI / 5), PI / 2.5, 10, 200, plrCenter)

    DrawTextureV plrTex, plr.pos, WHITE
    drawCirclePart cpv, plrCenter, WHITE
    moveEnems enemies
    renderEnms enemies, enmTex
    EndDrawing()
CloseWindow()