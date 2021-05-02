import raylib, rlgl, rayutils, sequtils, math, random, strformat

randomize()

type
    Player = object
        pos : Vector2
        dir : Vector2
        canMove : bool
        dead : bool
        collider : Rectangle
    Enemy = object
        pos : Vector2
        npos : Vector2
        dir : Vector2
        tDir : Vector2
        rot : float
        lookAngle : float
        alert : bool
    Bullet = object
        pos : Vector2
        dir : Vector2
        rot : float

const
    screenWidth = 1920
    screenHeight = 1080
    screenCenter = makevec2(screenWidth div 2, screenHeight div 2)

InitWindow screenWidth, screenHeight, "Stealthus"

InitAudioDevice()

SetTargetFPS 60

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
            return (GetMousePosition() - plr.pos).normalize / 10


func renderEnms(enms : seq[Enemy], eTex : Texture, eCol, visCol : Color) =
    for e in enms:
        let ecenter = e.pos + makevec2(eTex.width / 2, eTex.height / 2)
        let cpv = genConeCPV(angleToPoint(e.dir), ecenter)
        let dirRotMat = getRotMat(e.rot)
        let eDrawPoints = rectPoints(makerect(int e.pos.x, int e.pos.y, eTex.width, eTex.height)).mapIt(it - ecenter).mapIt(it * dirRotMat).mapIt(it + ecenter)
        drawCirclePart cpv, ecenter, visCol
        drawTriangleFan(eDrawPoints, eCol)

proc moveEnems(enems : var seq[Enemy]) =
    for i in 0..<enems.len:
        let nposInDir = abs(enems[i].npos - enems[i].pos) <& abs(enems[i].dir * (20 / 3))
        if nposInDir or enems[i].tDir == makevec2(0, 0):
            enems[i].npos = makevec2(rand screenWidth, rand screenHeight)
            enems[i].tDir = (enems[i].npos - enems[i].pos).normalize
                
        if abs(enems[i].dir - enems[i].tDir) <& 0.1:
            enems[i].dir = enems[i].tDir

        if enems[i].dir != enems[i].tDir:
            enems[i].dir += (enems[i].tDir - enems[i].dir) / 7.5
            enems[i].rot = angleToPoint enems[i].dir

        else:
            enems[i].pos += enems[i].dir * (20 / 3)

            if abs(enems[i].pos - enems[i].npos) <& 1:
                enems[i].pos = enems[i].npos

        enems[i].pos = min(max(makevec2(0, 0), enems[i].pos), makevec2(screenWidth, screenHeight))


func angryEnemCast(eSeq : var seq[Enemy], rotAmt : float) : seq[Bullet]=
    for inx, e in eSeq.pairs:
        let bPosSeq = circlePartVerts(e.rot, 2 * PI, 5, 5, e.pos)
        var bullets : seq[Bullet]
        for v in bPosSeq:
            bullets.add Bullet(pos : v, dir : normalize (v - e.pos), rot : angleToPoint(v - e.pos))
        result &= bullets
        eSeq[inx].rot += rotAmt

func moveBullets(bSeq : var seq[Bullet]) =
    for i in 0..<bSeq.len:
        bSeq[i].pos += bSeq[i].dir * 5

func renderBullets(bSeq : seq[Bullet], bTex : Texture) =
    for b in bSeq:
        let rotMat = getRotMat b.rot
        drawTriangleFan rectPoints(makerect(int b.pos.x, int b.pos.y, 32, 32)).mapIt(it - b.pos).mapIt(it * rotMat).mapIt(it + b.pos), RED

func checkCol(enems : seq[Enemy], eTex : Texture, bullets : seq[Bullet], collider : Rectangle) : bool =
    var colPoints = toSeq(rectPoints(collider)) & makevec2(collider.x + (collider.width / 2), collider.y)
    for e in enems:
        for p in colPoints:
            if p in makerect(int e.pos.x, int e.pos.y, eTex.width, eTex.height):
                return true
    for b in bullets:
        let rotMat = getRotMat b.rot
        let bPos = rectPoints(makerect(int b.pos.x, int b.pos.y, 32, 32)).mapIt(it - b.pos).mapIt(it * rotMat).mapIt(it + b.pos)
        for point in colPoints:
            if point.in(bPos[0], bPos[1], bPos[2], bPos[3]):
                return true
    return false

func checkConeCol(enems : seq[Enemy], eTex : Texture, collider : Rectangle) : bool =
    let colPoints = toSeq(rectPoints(collider)) & makevec2(collider.x + (collider.width / 2), collider.y)
    for e in enems:
        let ecenter = e.pos + makevec2(eTex.width / 2, eTex.height / 2)
        let cpv = genConeCPV(angleToPoint(e.dir), ecenter)
        for i in 0..<cpv.len - 1:
            for p in colPoints:
                if p.in(ecenter, cpv[i], cpv[i + 1]):
                    return true

func calcScore(pos : Vector2, center : Vector2) : float =
    let dist = abs dist(center, pos)
    let arg = dist / 100
    return 10 * sigmoid(arg, z = -6) 

let
    plrTex = LoadTexture "assets/sprites/plr.png"
    enmTex = LoadTexture "assets/sprites/Enem.png"
    hitSound = LoadSound "assets/sounds/sfx/dblClick.ogg"
    btSound = LoadSound "assets/sounds/sfx/Error.ogg"
    reducedColorArr = colorArr[3..10] & colorArr[12..13] & colorArr[15..16] & colorArr[21] & colorArr[23..24] & colorArr[26]
    musArgs = [LoadMusicStream "assets/sounds/music/DodgeSlow.mp3", LoadMusicStream "assets/sounds/music/DodgeFast.mp3"]
    # ds = LoadMusicStream "assets/sounds/sfx/Capture.ogg"

SetMasterVolume 0.5
btSound.SetSoundVolume(1)

var
    plr = Player(pos : makevec2(screenWidth, screenHeight), canMove : true)
    enemies : seq[Enemy]
    fcount : int
    eCols : (Color, Color)
    collided : bool
    bullets : seq[Bullet]
    lossTimer : int
    score : float
    fCollided : int
    ffCollided : bool
    impi : int

# for i in 0..1:
#     enemies.add Enemy(pos : makevec2(rand screenWidth, rand screenHeight))

while not WindowShouldClose():

    ClearBackground BGREY

    musArgs.iterIt(UpdateMusicStream it)
    let impArr = musArgs.mapIt(IsMusicPlaying it)
    let imp = impArr.foldl(a or b)
    if imp: impi = impArr.find(true)

    if not imp:
        PlayMusicStream musArgs[0]
        PlayMusicStream musArgs[1]
        PauseMusicStream musArgs[1]
    
    let mp = GetMousePosition() - makevec2(plrTex.width / 2, plrTex.height / 2)
    plr.pos = mp
    plr.pos = min(max(makevec2(0, 0), plr.pos), makevec2(screenWidth, screenHeight))
    plr.collider = makerect(int plr.pos.x, int plr.pos.y, plrTex.width, plrTex.height)
    let plrCenter = plr.pos + makevec2(plrTex.width / 2, plrTex.height / 2)

    if checkCol(enemies, enmTex, bullets, plr.collider):
        plr.dead = true
        PlaySound hitSound
        PauseMusicStream musArgs[1]
        # StopMusicStream musArgs[0]
    
    if plr.dead:
        fcount = 0
        score = 0
        fCollided = 0
        lossTimer += 1
        bullets = @[]
        enemies = @[]
        plr.dead = true
        if lossTimer == 7:
            lossTimer = 0
            for i in 0..2:
                enemies.add Enemy(pos : makevec2(rand screenWidth, rand screenHeight))
            plr.dead = false
            collided = false
            let rInx = rand(reducedColorArr.len - 1)
            var rInx2 = rand(reducedColorArr.len - 1)
            while rInx2 == rInx:
                rInx2 = rand(reducedColorArr.len - 1)
            eCols = (reducedColorArr[rInx], reducedColorArr[rInx2])
    else:
        if not collided: moveEnems enemies
        
        if checkConeCol(enemies, enmTex, plr.collider) and not collided:
            collided = true
            PlaySound btSound
            musArgs[0].PauseMusicStream()
            if not musArgs[1].IsMusicPlaying(): ResumeMusicStream musArgs[1]

        if fcount mod 360 == 0:
            bullets = @[]
            let rInx = rand(reducedColorArr.len - 1)
            var rInx2 = rand(reducedColorArr.len - 1)
            while rInx2 == rInx:
                rInx2 = rand(reducedColorArr.len - 1)
            eCols = (reducedColorArr[rInx], reducedColorArr[rInx2])
            collided = false
            for i in 0..2:
                enemies.add Enemy(pos : makevec2(rand screenWidth, rand screenHeight))
            for i in 0..<enemies.len:
                enemies[i].rot = angleToPoint enemies[i].dir
            fcount = 0
            fCollided = 0
            PauseMusicStream musArgs[1]
            if not IsMusicPlaying(musArgs[0]): ResumeMusicStream musArgs[0]
        elif collided:
            if fCollided mod 35 == 5:
                if not ffCollided:
                    PlaySound btSound
                    ffCollided = true
                fCollided = 5
                bullets &= angryEnemCast(enemies, PI)
            moveBullets bullets
            
            fCollided += 1
            
            eCols[1]  = RED
    
    score += calcScore(plrCenter, screenCenter)

    BeginDrawing()
    drawTextCentered &"Score :", screenWidth div 2, (screenHeight div 2) - 25, 50, WHITE 
    drawTextCentered $int round score, screenWidth div 2,(screenHeight div 2) + 25, 50, WHITE
    drawTextCenteredX "Entering a cone starts bullet hell", screenWidth div 2, 70, 40, WHITE
    renderBullets bullets, enmTex
    DrawTextureV plrTex, plr.pos, WHITE
    renderEnms enemies, enmTex, eCols[0], eCols[1]
    # drawTextCenteredX &"Score : {$int round score}", screenWidth - 150, 70, 40, WHITE
    # drawTextCenteredX $(reflect(fcount, 180) div 60), 100, 70, 100, WHITE
    
    EndDrawing()

    fcount += 1
CloseWindow()