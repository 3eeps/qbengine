DEFINT A-Z
DECLARE SUB updPlayer ()
DECLARE SUB updActors ()
DECLARE SUB updScreen ()
DECLARE SUB initGame ()
DECLARE SUB gameMenu ()
RANDOMIZE TIMER

TYPE obj
  x AS INTEGER
  y AS INTEGER
  hp AS INTEGER
  dirCount as INTEGER
  energy AS INTEGER
  spr AS INTEGER
  ' *** lets move STATE to ints at some point, no need to compare strings
  state AS STRING * 4
  target AS INTEGER
  ftile AS INTEGER
END TYPE

DIM SHARED win AS obj
DIM SHARED user AS obj
DIM SHARED actor(32) AS obj

DIM SHARED maxTarget
DIM SHARED vdistObjList(3) as obj
DIM SHARED src(8, 8)
DIM SHARED scene(100, 100)
DIM SHARED sprIndex(6800)
DIM SHARED sprNameList(152)
DIM SHARED sprTypeData(152)
DIM SHARED targetType
DIM SHARED sprType

DIM SHARED exitGame
DIM SHARED vdist
DIM SHARED maxAi
DIM SHARED uconsole AS STRING

initGame
DO
  updPlayer
  updActors
  updScreen

LOOP UNTIL exitGame = 1
WHILE INKEY$ <> "": WEND
SYSTEM

SUB gameMenu

  SCREEN 13'7
  SLEEP (1)
  COLOR 8: LOCATE 10, 16: PRINT "fir"
  COLOR 12: LOCATE 10, 19: PRINT "@"
  COLOR 14: LOCATE 10, 20: PRINT "TEAM"
  SLEEP (3)
  CLS
  COLOR 12: LOCATE 12, 14: PRINT "PRESS ANY KEY"
  DO: LOOP UNTIL INKEY$ <> ""

END SUB

SUB initGame

  SCREEN 13
  gameMenu

  ' game params
  maxTarget = 4
  maxAi = 1
  vdist = 8
  sprSize = 8
  user.x = 20
  user.y = 12
  user.spr = 42
  win.x = 30 - user.x
  win.y = 49 - user.y
  sprNum = 152

  ' build actors
  FOR i = 1 TO maxAi
    actor(i).x = 30
    actor(i).y = 45
    actor(i).hp = 35
    actor(i).state = "wand"
    actor(i).energy = 45
    actor(i).target = 0
    actor(i).spr = 42
    actor(i).ftile = scene(actor(i).x, actor(i).y)
    scene(actor(i).x, actor(i).y) = actor(i).spr
  NEXT

  ' load sprite pak
  OPEN "test.pak" FOR INPUT AS #1
  fileLen = (sprNum * 42) + 1
  FOR i = 1 TO fileLen
    INPUT #1, sprIndex(i)
  NEXT

  index = 0
  FOR i = 6386 TO 6537
    index = index + 1
    INPUT #1, sprNameList(index)
  NEXT

  index = 0
  FOR i = 6538 TO 6689
    index = index + 1
    INPUT #1, sprTypeData(index)
  NEXT
  CLOSE #1

  ' hacky fix, sorta works
  sprIndex(43) = 8
  FOR i = 43 TO 6538 STEP 42
    sprIndex(i) = 8
  NEXT

  ' load .map file
  OPEN "test.map" FOR INPUT AS #1
  FOR y = 0 TO 100
    FOR x = 0 TO 100
      INPUT #1, scene(x, y)
    NEXT
  NEXT
  CLOSE #1

END SUB

SUB updActors
    
  FOR i = 1 TO maxAi
    IF actor(i).hp <= 0 THEN
      actor(i).state = "dead"
      GOTO skipAi
    END IF
    scene(actor(i).x, actor(i).y) = actor(i).ftile

    actor(i).energy = actor(i).energy - RND * 2
    IF actor(i).energy < 1 THEN actor(i).hp = actor(i).hp - RND * 2

    IF actor(i).energy < 25 THEN
      actor(i).target = 84
      actor(i).state = "find"
      IF actor(i).target = -1 THEN actor(i).state = "wand"
    ELSE
      actor(i).state = "wand"
    END IF
                    
    SELECT CASE actor(i).state

      CASE "wand"
		'
		actor(i).dirCount = (RND * 4) + 1
		rand = RND * 8
		IF rand = 1 THEN
			actor(i).x = actor(i).x + 1
		ELSEIF rand = 2 THEN actor(i).x = actor(i).x - 1
		ELSEIF rand = 3 THEN actor(i).y = actor(i).y - 1
		ELSEIF rand = 4 THEN actor(i).y = actor(i).y + 1		
		END IF						

      CASE "find"
		' check vdist area around actor, store up to three target to compare
		dx = 0
		dy = 0
        FOR x = actor(i).x - vdist TO actor(i).x + vdist
          FOR y = actor(i).y - vdist TO actor(i).y + vdist
          IF scene(x, y) = actor(i).target THEN
			dx = actor(i).x - x
            dy = actor(i).y - y
			IF targetCount <= maxTarget - 1 THEN 
				targetCount = targetCount + 1			
				vdistObjList(targetCount).x = dx
				vdistObjList(targetCount).y = dy
			END IF							
          END IF
          NEXT
        NEXT

		' find closest target, then clear target list
		actorx = actor(i).x 
		actory = actor(i).y
		minDist = 10000
		dx = 0
		dy = 0
		closestTarget = 0
		IF targetCount > 0 THEN
			FOR j = 1 to targetCount
				dx = vdistObjList(j).x - actorx
				dy = vdistObjList(j).y - actory
				distSqr = dx^2 + dy^2
				IF distSqr < minDist^2 THEN
					closestTarget = j
					minDist = SQR(distSqr)
				END IF
			NEXT
			dx = vdistObjList(closestTarget).x
			dy = vdistObjList(closestTarget).y
			ERASE vdistObjList
		END IF

        rand = RND * 2
        IF dx < 0 AND dy < 0 THEN
          IF rand = 1 THEN
            actor(i).x = actor(i).x + 1
          ELSE
            actor(i).y = actor(i).y + 1
          END IF
        ELSEIF dx > 0 AND dy > 0 THEN
          IF rand = 1 THEN
            actor(i).x = actor(i).x - 1
          ELSE
            actor(i).y = actor(i).y - 1
          END IF
        ELSEIF dx < 0 AND dy > 0 THEN
          IF rand = 1 THEN
            actor(i).x = actor(i).x + 1
          ELSE
            actor(i).y = actor(i).y - 1
          END IF
        ELSEIF dx > 0 AND dy < 0 THEN
          IF rand = 1 THEN
            actor(i).x = actor(i).x - 1
          ELSE
            actor(i).y = actor(i).y + 1
          END IF
        ELSEIF dx = 0 AND dy < 0 THEN actor(i).y = actor(i).y + 1
        ELSEIF dx = 0 AND dy > 0 THEN actor(i).y = actor(i).y - 1
        ELSEIF dx < 0 AND dy = 0 THEN actor(i).x = actor(i).x + 1
        ELSEIF dx > 0 AND dy = 0 THEN actor(i).x = actor(i).x - 1
        END IF

        IF scene(actor(i).x, actor(i).y) = actor(i).target THEN
          actor(i).target = -1
		  scene(actor(i).x, actor(i).y) = 0
          actor(i).energy = actor(i).energy + 25
        END IF

    END SELECT
    actor(i).ftile = scene(actor(i).x, actor(i).y)
    scene(actor(i).x, actor(i).y) = actor(i).spr	
	
skipAi:
  NEXT

END SUB

SUB updPlayer

  scene(win.x + user.x, win.y + user.y) = user.ftile
  SLEEP
  IF INP(96) = 17 AND win.y > 0 THEN win.y = win.y - 1
  IF INP(96) = 30 AND win.x > 0 THEN win.x = win.x - 1
  IF INP(96) = 31 AND win.y < 70 THEN win.y = win.y + 1
  IF INP(96) = 32 AND win.x < 65 THEN win.x = win.x + 1
  IF INP(96) = 41 THEN
    WHILE INKEY$ <> "": WEND
    INPUT ">>>", uconsole
    IF uconsole = "exit" THEN exitGame = 1
    uconsole = ""
  END IF
  user.ftile = scene(win.x + user.x, win.y + user.y)
  scene(win.x + user.x, win.y + user.y) = user.spr

END SUB

SUB updScreen

    WAIT &H3DA, 8
    LINE (248, 24)-(80, 176), 0, BF

    FOR x = 10 TO 30
      FOR y = 3 TO 21
        sprType = scene(x + win.x, y + win.y)
        IF sprType THEN PUT (x * 8, y * 8), sprIndex(sprType)
      NEXT
    NEXT
    PUT (160, 96), sprIndex(user.spr), PSET

    ' debug
    LOCATE 16, 2: COLOR 44: PRINT ">"; uconsole

    LOCATE 12, 2: COLOR 44: PRINT "type:"; targetType
    LOCATE 13, 2: COLOR 44: PRINT "actor"; actor(1).x; actor(1).y
    LOCATE 14, 2: COLOR 44: PRINT "user"; win.x; win.y
    LOCATE 15, 2: COLOR 44: PRINT "playerxy"; playerx; playery

    LOCATE 17: COLOR 39: PRINT "energy:"; actor(1).energy
    LOCATE 18: COLOR 44: PRINT "hp:"; actor(1).hp
    LOCATE 19: COLOR 8: PRINT "target:"; actor(1).target
    LOCATE 20: COLOR 48: PRINT "state:"; actor(1).state
    
END SUB

