import raylib, rlgl, rayutils, sequtils, math, random

randomize()

type
    Player = object
        pos : Vector2
        dir : Vector2
        canMove : bool
    Enemy = object
        pos : Vector2
        npos : Vector2
        dir : Vector2
        tDir : Vector2
        rot : float
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
        rlColor4ub col.r, col.g, col.b, col.a div 2
        rlVertex2f origin.x, origin.y

        rlColor4ub col.r, col.g, col.b, col.a div 2

        rlVertex2f verts[i].x, verts[i].y 
        rlVertex2f verts[i + 1].x, verts[i + 1].y 
        rlEnd()
        rlglDraw()

template genConeCPV(th : float, center : Vector2) : auto = circlePartVerts(th - PI / 5, PI / 2.5, 10, 200, center)

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


func renderEnms(enms : seq[Enemy], eTex : Texture, eCol, visCol : Color) =
    for e in enms:
        let ecenter = e.pos + makevec2(eTex.width / 2, eTex.height / 2)
        let cpv = genConeCPV(angleToPoint(e.dir), ecenter)
        let dirRotMat = getRotMat(angleToPoint e.dir)
        let eDrawPoints = rectPoints(makerect(int e.pos.x, int e.pos.y, eTex.width, eTex.height)).mapIt(it - ecenter).mapIt(it * dirRotMat).mapIt(it + ecenter)
        drawCirclePart cpv, ecenter, visCol
        drawTriangleFan(eDrawPoints, eCol)

proc moveEnems(enems : var seq[Enemy], target : Vector2, collided : bool) =
    if not collided:
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
    else:
        for i in 0..<enems.len:
            enems[i].dir = normalize((target - enems[i].pos))
            enems[i].tDir = enems[i].dir

            enems[i].pos += enems[i].dir * 5
            enems[i].pos = min(max(makevec2(0, 0), enems[i].pos), makevec2(screenWidth, screenHeight))
            enems[i].npos = enems[i].pos


func checkCol(enems : seq[Enemy], eTex : Texture, point : Vector2) : bool =
    for e in enems:
        if point in makerect(int e.pos.x, int e.pos.y, eTex.width, eTex.height):
            return true
    return false

func checkConeCol(enems : seq[Enemy], eTex : Texture, point : Vector2) : bool =
    for e in enems:
        let ecenter = e.pos + makevec2(eTex.width / 2, eTex.height / 2)
        let cpv = genConeCPV(angleToPoint(e.dir), ecenter)
        for i in 0..<cpv.len - 1:
            if point.in(ecenter, cpv[i], cpv[i + 1]):
                return true

let
    plrTex = LoadTexture "assets/sprites/plr.png"
    enmTex = LoadTexture "assets/sprites/Enem.png"
    damping = 0.2
    reducedColorArr = colorArr[3..10] & colorArr[12..13] & colorArr[15..16] & colorArr[21] & colorArr[23..24] & colorArr[26]

var
    plr = Player(pos : makevec2(screenWidth, screenHeight), canMove : true)
    velo : Vector2
    enemies : seq[Enemy]
    fcount : int
    eCols : (Color, Color)
    collided : bool

for i in 0..9:
    enemies.add Enemy(pos : makevec2(rand screenWidth, rand screenHeight))

while not WindowShouldClose():
    ClearBackground BGREY
    let mp = GetMousePosition() - makevec2(plrTex.width / 2, plrTex.height / 2)
    plr.pos = mp
    plr.pos = min(max(makevec2(0, 0), plr.pos), makevec2(screenWidth, screenHeight))
    let plrCenter = plr.pos + makevec2(plrTex.width / 2, plrTex.height / 2)

    if checkConeCol(enemies, enmTex, plrCenter):
        collided = true

    BeginDrawing()

    if fcount mod 6000 == 0:
        let rInx = rand(reducedColorArr.len - 1)
        var rInx2 = rand(reducedColorArr.len - 1)
        while rInx2 == rInx:
            rInx2 = rand(reducedColorArr.len - 1)
        eCols = (reducedColorArr[rInx], reducedColorArr[rInx2])
        collided = false
        for i in 0..2:
            enemies.add Enemy(pos : makevec2(rand screenWidth, rand screenHeight))
    elif collided:
        eCols = (RED, RED)

    DrawTextureV plrTex, plr.pos, WHITE
    moveEnems enemies, plr.pos, collided
    renderEnms enemies, enmTex, eCols[0], eCols[1]
    EndDrawing()

    fcount += 1
CloseWindow()