import raylib, math, hashes, sugar, macros, strutils, lenientops, sequtils, algorithm

template BGREY*() : auto = makecolor("242424", 255)
template OFFWHITE*() : auto = makecolor(235, 235, 235)

type Triangle* = object
    v1* : Vector2
    v2* : Vector2
    v3* : Vector2

func makecolor*(f, d, l : int | float | uint8, o : uint8 = 255) : Color = ## Easy color constructor
    return Color(r : uint8 f, g : uint8 d, b : uint8 l, a : uint8 o)

func makecolor*(s : string, alp : uint8 = 255) : Color =
    return makecolor(fromHex[uint8]($s[0..1]), fromHex[uint8]($s[2..3]), fromHex[uint8]($s[4..5]), alp)

func makevec2*(x, y: float | float32 | int) : Vector2 =  ## Easy vec2 constructor
    Vector2(x : float x, y : float y)

func sigmoid*(x : int | float, a : int | float = 1, b : int | float = E, h : int | float = 1, k : int | float = 0, z : int | float = 0) : float = ## Sigmoid in the form a(1/1 + e^(hx + z)) + k
    return a * 1/(1 + pow(E, h * x + z)) + k

template iterIt*(s, op : untyped) : untyped =
    for i in low(s)..high(s):
        let it {.inject.} = s[i]
        op

const colorArr* : array[27, Color] = [LIGHTGRAY, GRAY, DARKGRAY, YELLOW, GOLD, ORANGE, PINK, RED, MAROON, GREEN, LIME, DARKGREEN, SKYBLUE, BLUE, DARKBLUE, PURPLE, VIOLET, DARKPURPLE, BEIGE, BROWN, DARKBROWN, WHITE, BLACK, MAGENTA, RAYWHITE, BGREY, OFFWHITE] ## Array of all rl colours

func `+`*(v, v2 : Vector2) : Vector2 =
    result.x = v.x + v2.x
    result.y = v.y + v2.y

func `-`*(v, v2 : Vector2) : Vector2 =
    result.x = v.x - v2.x
    result.y = v.y - v2.y

func `+`*[T](v : Vector2, n : T) : Vector2 =
    result.x = v.x + n
    result.y = v.y + n

func `-`*[T](v : Vector2, n : T) : Vector2 =
    result.x = v.x - n.float
    result.y = v.y - n.float

func `+=`*[T](v : var Vector2, t : T) = 
    v = v + t

func `*=`*[T](v : var Vector2, t : T) =
    v = v * t

func `/`*(v, v2 : Vector2) : Vector2 =
    result.x = v.x / v2.x
    result.y = v.y / v2.y

func `/`*(v, : Vector2, f : float) : Vector2 =
    result.x = v.x / f
    result.y = v.y / f

func `/`*(v, : Vector2, i : int) : Vector2 =
    result.x = v.x / float i
    result.y = v.y / float i

func `/=`*[T](v : var Vector2, t : T) =
    v = v / t

func `div`*(v, : Vector2, f : float) : Vector2 =
    result.x = ceil(v.x / f)
    result.y = ceil(v.y / f)

func `div`*(v, : Vector2, i : int) : Vector2 =
    result.x = float v.x.int div i
    result.y = float v.y.int div i

func `mod`*(v, v2 : Vector2) : Vector2 =
    return makevec2(v.x mod v2.x, v.y mod v2.y)

func `*`*(v, v2 : Vector2) : Vector2 =
    result.x = v.x * v2.x
    result.y = v.y * v2.y

func `*`*(v : Vector2, i : int | float | float32) : Vector2 =
    return makevec2(v.x * float32 i, v.y * float32 i)

func `dot`*(v, v2 : Vector2) : float = ## Dot product of 2 vecs
    return (v.x * v2.x) + (v.y * v2.y)

func `*`*(v : Vector2, mat : seq[seq[int]] | seq[seq[float]]) : Vector2 = ## Requires 2x2 matrix atm
    doAssert mat.len == 2 and mat[0].len == 2, "Only supports 2x2 matrix"
    let
        x = v.x
        y = v.y
        a = mat[0, 0]
        b = mat[0, 1]
        c = mat[1, 0]
        d = mat[1, 1]
    return makevec2((x * a) + (y * c), (x * b) + (y * d))

func getRotMat*(th : int | float) : seq[seq[int]] | seq[seq[float]] =
    return @[@[cos th, -sin th], @[sin th, cos th]]

func `<|`*(v : Vector2, n : float32 | int | float) : bool = ## True if either x or y < x2 or y2
    return v.x < n or v.y < n

func `<&`*(v : Vector2, n : float32 | int | float) : bool = ## True if both x and y < x2 and y2
    return v.x < n and v.y < n

func `<&`*(v : Vector2, v2 : Vector2) : bool = ## True if both x and y < x2 and y2
    return v.x < v2.x and v.y < v2.y

func drawTextCentered*(s : string, x, y, fsize : int, colour : Color) =
    let tSizeVec = MeasureTextEx(GetFontDefault(), s, float fsize, max(10,fsize) / 20) div 2
    DrawText s, x - tSizeVec.x.int, y - tSizeVec.y.int, fsize, colour

func drawTextCenteredX*(s : string, x, y, fsize : int, colour : Color) =
    let tSizeVec = MeasureTextEx(GetFontDefault(), s, float fsize, max(20,fsize) / 10) div 2
    DrawText s, x - tSizeVec.x.int, y, fsize, colour

proc int2bin*(i : int) : int =
    var i = i
    var rem = 1
    var tmp = 1
    while i != 0:
        rem = i mod 2
        i = i div 2
        result = result + rem * tmp
        tmp = tmp * 10

func makerect*(v, v2, v3, v4 : Vector2) : Rectangle = ## Doesn't check that your points can form a rectangle
    Rectangle(x : v.x, y : v.y, width : v2.x - v.x, height : v3.y - v2.y)

func makerect*(x, y, w, h : int) : Rectangle =
    Rectangle(x : float x, y : float y, width : float w, height : float h)

func `in`*(v : Vector2, r : Rectangle) : bool =
    return (v.x in r.x..r.x + r.width) and (v.y in r.y..r.y + r.height)

func `notin`*(v : Vector2, r : Rectangle) : bool =
    return not(v in r)

func sign(v, v2, v3 : Vector2) : float =
    return (v.x - v3.x) * (v2.y - v3.y) - (v2.x - v3.x) * (v.y - v3.y)

func `in`*(v, t1, t2, t3 : Vector2) : bool =
    let d = sign(v, t1, t2)
    let d2 = sign(v, t2, t3)
    let d3 = sign(v, t3, t1)
    return not (((d < 0) or (d2 < 0) or (d3 < 0)) and ((d > 0) or (d2 > 0) or (d3 > 0)))

func `in`*(v : Vector2, tri : Triangle) : bool =
    let d = sign(v, tri.v1, tri.v2)
    let d2 = sign(v, tri.v2, tri.v3)
    let d3 = sign(v, tri.v3, tri.v1)
    return not (((d < 0) or (d2 < 0) or (d3 < 0)) and ((d > 0) or (d2 > 0) or (d3 > 0)))

func `in`*(v : Vector2, v1, v2, v3, v4 : Vector2) : bool =
    let vSeq = [v1, v2, v3, v4].sorted((x, y) => cmp[float](x.x, y.y), Ascending)
    return v.in(vSeq[0], vSeq[1], vSeq[2]) or v.in(vSeq[1], vSeq[2], vSeq[3])

proc UnloadTexture*(texargs : varargs[Texture]) = ## runs UnloadTexture for each vararg
    texargs.iterIt(UnloadTexture it)

proc UnloadMusicStream*(musargs : varargs[Music]) = ## runs UnloadMusicStream on each vararg
    musargs.iterIt(UnloadMusicStream it)

proc UnloadSound*(soundargs : varargs[Sound]) = ## runs UnloadSound for each varargs
    soundargs.iterIt(UnloadSound it)

func toTuple*(v : Vector2) : (float32, float32) = ## Returns (x, y)
    return (v.x, v.y) 

func min*(v, v2 : Vector2) : Vector2 = ## Returns min of x and min of y 
    return makevec2(min(v.x, v2.x), min(v.y, v2.y))

func min*[T](args : varargs[T]) : T =
    var lastmin : T
    for i in args:
        if i < lastmin:
            lastmin = i
    return lastmin 

func max*(v, v2 : Vector2) : Vector2 = ## Returns max of x and max of y
    return makevec2(max(v.x, v2.x), max(v.y, v2.y))

func max*[T](args : varargs[T]) : T =
    var lastmax : T
    for i in args:
        if i > lastmax:
            lastmax = i
    return lastmax

func ceil*(v : Vector2) : Vector2 = ## Returns ceil x, ceil y
    return makevec2(ceil v.x, ceil v.y)

func grEqCeil*(n : int | float | float32) : int | float | float32 = ## Ceil but inclusive
    if n == n.int.float:
        return n
    return ceil(n)

func grEqCeil*(v : Vector2) : Vector2 = ## Returns vec2 with x and y grEqCeiled
    return makevec2(grEqCeil v.x, grEqCeil v.y)

func `[]`*[T](container : seq[seq[T]], v : Vector2) : T = ## Vector2 access to 2d arrays
    return container[int v.x][int v.y]

func `[]`*[T](container : seq[seq[T]], x, y : int | float | float32) : T = ## [i, j] access to 2d arrays
    return container[int x][int y]

func `[]=`*[T](container : var seq[seq[T]], x, y : int | float | float32, d : T) = ## [i, j] setter for 2d arrays
    container[int x][int y] = d

func `[]=`*[T](container : var seq[seq[T]], v : Vector2, d : T) = ## Vector2 setter for 2d arrays
    container[int v.x][int v.y] = d

func genSeqSeq*[T](y, x : int, val : T) : seq[seq[T]] = ## return a seq[seq[T]] populated with the given value. X and Y are reversed like with matrices
    for i in 0..<y:
        result.add @[]
        for j in 0..<x:
            result[i].add(val)

func `&=`*[T](s : var string, z : T) = 
    s = s & $z

func apply*(v : Vector2, op : proc(f : float32) : float32) : Vector2 = ## runs proc on x and y
    return makevec2(op v.x, op v.y)

func round*(v : Vector2) : Vector2 = ## round x, round y
    return makevec2(round v.x, round v.y)

func round*(v : Vector2 , places : int) : Vector2 = ## round x, round y
    return makevec2(round(v.x, places), round(v.y, places))

func roundToInt*(f : float) : int = 
    int round f

func roundDown*(v : Vector2) : Vector2 = ## rounds down x and y
    return makevec2(float32 int v.x, float32 int v.y)

proc roundDown*(n : float | float32) : float | float32 = ## rounds down
    return float int n

proc drawTexCentered*(tex : Texture, pos : Vector2, tint : Color) = ## Draws Texture from center
    tex.DrawTexture(int pos.x + tex.width / 2, int pos.y + tex.height / 2, tint)

proc drawTexCentered*(tex : Texture, posx, posy : int | float | float32, tint : Color) = ## Draws texture from center
    tex.DrawTexture(int posx + tex.width div 2, int posy + tex.height div 2, tint)

func reflect*(i, tp : int | float) : int | float = ## Flips value over tp
    return tp * 2 - i

func reflect*(v : Vector2, tp : int | float) : Vector2 =
    return makevec2(tp * 2 - v.x, tp * 2 - v.y)

func abs*(v : Vector2) : Vector2 =
    return makevec2(abs v.x, abs v.y)

func cart2Polar*(v : Vector2, c = Vector2(x : 0, y : 0)) : Vector2 = ## Untested
    let v = v - c
    result.x = sqrt((v.x ^ 2) + (v.y ^ 2)) 
    result.y = arctan(v.y / v.x)

func invert*(v : Vector2) : Vector2 = ## switches x and y
    return makevec2(v.y, v.x)

func dist*(v, v2 : Vector2) : float = ## distance of 2 vecs (Untested)
    return abs sqrt(((v.x - v2.x) ^ 2) + ((v.y - v2.y) ^ 2))

func makevec3*(i, j, k : float) : Vector3 = ## Easy vec3 constructor
    return Vector3(x : i, y : j, z : k)

func normalizeToScreen*(v, screenvec : Vector2) : Vector2 = ## Normalize vec2 over screencoord
    return makevec2(v.x / screenvec.x, v.y / screenvec.y )

proc hash*(v : Vector2) : Hash = ## Hash for vec2
    var h : Hash = 0
    h = h !& hash v.x
    h = h !& hash v.y
    result = !$h

proc drawTriangleFan*(verts : openArray[Vector2], color : Color) = ## Probably inefficient convex polygon renderer
    var inpoint : Vector2
    var mutverts : seq[Vector2]

    for v in verts: 
        inpoint = inpoint + v
        mutverts.add(v)
    
    inpoint = inpoint / float verts.len
    mutverts.add(verts[0])

    for i in 1..<mutverts.len:
        var points = [inpoint, mutverts[i - 1], mutverts[i]]
        var ininpoint = (points[0] + points[1] + points[2]) / 3
        var polarpoints = [cart2Polar(points[0], ininpoint), cart2Polar(points[1], ininpoint), cart2Polar(points[2], ininpoint)]
        for j in 0..points.len:
            for k in 0..<points.len - 1 - j:
                if polarpoints[k].y > polarpoints[k + 1].y:
                    swap(polarpoints[k], polarpoints[k + 1])
                    swap(points[k], points[k + 1])
        DrawTriangle(points[0], points[1], points[2], color)

func normalize*(v : Vector2) : Vector2 = ## Normalize Vector
    return v / sqrt(v.x ^ 2 + v.y ^ 2)

func drawTexCenteredFromGrid*(tex : Texture, pos : Vector2, tilesize : int, tint : Color) =
    DrawTexture(tex, int32 pos.x * tilesize + (tilesize - tex.width) / 2, int32 pos.y * tilesize + (tilesize - tex.height) / 2, tint)

func drawTexFromGrid*(tex : Texture, pos : Vector2, tilesize : int, tint : Color) =
    DrawTexture(tex, int pos.x * tilesize, int pos.y * tilesize, tint)

func drawTexCenteredFromGrid*(tex : Texture, posx, posy : int, tilesize : int, tint : Color) =
    DrawTexture(tex, int32 posx * tilesize + (tilesize - tex.width) / 2, int32 posy * tilesize + (tilesize - tex.height) / 2, tint)

func drawTexFromGrid*(tex : Texture, posx, posy : int, tilesize : int, tint : Color) =
    DrawTexture(tex, int posx * tilesize, int posy * tilesize, tint)

func getNeighborTiles*[T](map : seq[seq[T]], y, x : int) : seq[T] =
    if y < map.len - 1:
        result.add map[y + 1, x]
    if y > 0:
        result.add map[y - 1, x]
    if x < map[0].len - 1:
        result.add map[y, x + 1]
    if x > 0:
        result.add map[y, x - 1]

iterator spsplit*(s : string, key : char | string) : string =
    var result : string
    for c in s:
        if key in result & $c:
            yield result 
            result = ""
        else:
            if c == ' ':
                result &= " " 
            else: result &= c
    yield result

func DrawCircle*(centerX : float, centerY : float, radius : float, tint : Color) =
    DrawCircle int centerX, int centerY, radius, tint

func IsKeyDown*[N](k : array[N, KeyboardKey]) : bool =
    for key in k:
        if IsKeyDown(key): return true
    return false

proc echo*[T](s : seq[seq[T]]) =
    for i in 0..<s.len:
        for j in 0..<s[i].len:
            stdout.write s[i, j], " "
        echo ""

func angleToPoint*(v : Vector2) : float = ## Returns in Radians
    result = -arctan(v.y / v.x)
    if v.x != abs(v.x) and v.y == abs(v.y):
        result = arctan(-abs(v.y / v.x))
        result = reflect(result, PI / 2)
    if v.x != abs(v.x) and v.y != abs(v.y):
        result = arctan(abs(v.y / v.x))
        result = reflect(result, -PI / 2)

func isPositive*[T](t : T) : bool =
    t == abs(t)

func rectPoints*(rect : Rectangle) : array[4, Vector2] =
    return [makevec2(rect.x, rect.y), makevec2(rect.x + rect.width, rect.y), makevec2(rect.x + rect.width, rect.y + rect.height), makevec2(rect.x, rect.y + rect.height)]

func maketri*(v1, v2, v3 : Vector2) : Triangle = 
    return Triangle(v1 : v1, v2 : v2, v3 : v3)

iterator items*(tri : Triangle) : Vector2 =
    yield tri.v1
    yield tri.v2
    yield tri.v3

iterator pairs*(tri : Triangle) : (int, Vector2) = 
    yield (0, tri.v1)
    yield (0, tri.v2)
    yield (0, tri.v3)