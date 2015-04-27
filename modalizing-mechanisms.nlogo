;;This file is part of the Modalizing Mechanisms model.
;;
;;the Modalizing Mechanisms model is free software: you can redistribute it and/or modify
;;it under the terms of the GNU General Public License as published by
;;the Free Software Foundation, either version 3 of the License, or
;;(at your option) any later version.
;;the Modalizing Mechanisms model is distributed in the hope that it will be useful,
;;but WITHOUT ANY WARRANTY; without even the implied warranty of
;;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;GNU General Public License for more details.
;;
;;You should have received a copy of the GNU General Public License
;;along with the Modalizing Mechanisms model.  If not, see <http://www.gnu.org/licenses/>.

extensions [matrix]

__includes ["utils.nls"]

breed [monsters monster]
breed [hunters hunter]

globals [should-stop old-number-of-hunters hunters-list states messages acts hunter-pure-strats]

turtles-own [energy huntstage]
monsters-own [monstertype myhunter stagecolors]
hunters-own [mymonster strategy investmentpolicy]

to setup
  clear-all
  initialize-utils
  initialize-monsters
  initialize-hunters
  reset-ticks
end

to initialize-monsters
 create-monsters number-of-monsters [
    set stagecolors [yellow red blue]
    set energy monster-starting-energy
    set monstertype random 3
    set color item monstertype stagecolors
    set huntstage 0
    set myhunter nobody
    setxy random-xcor random-ycor]
end

to initialize-hunters
 create-hunters number-of-hunters [
    set energy hunter-starting-energy
    set strategy random-hunter-strat
    ;; set strategy matrix:make-identity 3
    set investmentpolicy random-hunter-investment-policy
    set shape "square"
    set color orange
    set huntstage 0
    set mymonster nobody
    setxy random-xcor random-ycor]
end

to go
  check-progress
  if should-stop [
    stop
  ]
  monsters-go
  hunters-go
  tick
end

to check-progress
  ;; calculates an average of the number of hunters over the last 10000 ticks. It it doesn't grow, we stop
  set hunters-list lput count hunters hunters-list
  if ticks / 10000 = floor (ticks / 10000) [
    let new-number-of-hunters mean hunters-list
    set hunters-list []
    if old-number-of-hunters >= new-number-of-hunters [
      set should-stop true
    ]
    set old-number-of-hunters new-number-of-hunters
  ]
end

to monsters-go
  monsters-time-passes  
end

to hunters-go
  hunters-find-monster
  hunters-hunt
  hunters-time-passes
end

to monsters-time-passes
  ask monsters [
    set energy energy - 1
    if energy <= 0 [
      if-else monstertype = 0 [
        set monstertype (weighted-random-choice list prob-air (1 - prob-air)) + 1
        set energy monster-starting-energy
        set color item monstertype stagecolors
      ]
      [
        if huntstage > 0 [
          ;; show mysender
          dismantle-hunt self myhunter
        ]
        monster-die self  
      ]
    ]
  ]
end

to monster-die [thismonster]
  ask thismonster [
    hatch 1 [
    set color yellow
    set monstertype 0       
    set energy monster-starting-energy
    setxy random-xcor random-ycor
    ]
    die
  ]
end

to hunters-time-passes
  ask hunters [
    set energy energy - 1
    if energy <= 0 [
      if huntstage > 0 [
      dismantle-hunt mymonster self
      ]
      die
    ]
    if energy >= hunter-reproducing-energy [
        hatch 1 [
          set energy ([ energy ] of myself) / 2
          setxy random-xcor random-ycor
          if random-float 1 < mutation-probability [
            if-else random-float 1 < mutation-mix [
              set strategy perturb-matrix perturbation-ratio [ strategy ] of myself
              set investmentpolicy perturb-vector perturbation-ratio [ investmentpolicy ] of myself
            ] [
              set strategy random-hunter-strat
              set investmentpolicy random-hunter-investment-policy
            ]
          ]
        ]
        set energy energy / 2
    ]
  ]
end

to hunters-find-monster
  ask hunters [
    if mymonster = nobody [
      let nearby-idle-monsters monsters in-radius hunter-radius with [myhunter = nobody]
      set mymonster one-of nearby-idle-monsters
      if mymonster != nobody [
        ;; show "found a monster"
        ask mymonster [ set myhunter myself ]
        ask (turtle-set self mymonster) [set huntstage 1 ]
      ]
    ]
  ]
end

to hunters-hunt
  ask hunters [
    if-else huntstage = 0
      [ stop ]
      [if mymonster = nobody [
        dismantle-hunt mymonster self
        ;; show "i'm outta here"
        relocate self
        stop
      ]
    ]
    if huntstage = 1 [ first-round mymonster self ]
    if huntstage = 2 [ second-round mymonster self ]
  ]
end

to first-round [monster hunter]
  ;; show "first round"
  let act get-act monster hunter
  if-else act > 0 or [monstertype] of monster > 0 [
    let payoff unprepared-attack [monstertype] of monster act
    ;; show "1st round payoff"
    ;; show payoff
    ask hunter [ set energy (energy + payoff) ]
    dismantle-hunt monster hunter
    monster-die monster
    relocate hunter
  ] [
    ask (turtle-set hunter monster) [ set huntstage 2 ]
  ]
end

to second-round [monster hunter]
  ;; show "second round"
  ;; show [ monstertype ] of monster
  if ([ monstertype ] of monster) > 0 [
    let act get-act monster hunter
    let policy [ investmentpolicy] of hunter
    let payoff prepared-attack [monstertype] of monster act policy
    ;; show payoff
    ask hunter [ set energy (energy + payoff) ]
    dismantle-hunt monster hunter
    monster-die monster
    relocate hunter
  ]
end

to-report unprepared-attack [thismonstertype act]
  if thismonstertype = 0 [ report energy-of-undecided ]
  if-else thismonstertype = act
    [ report 10 ]
    [ report investment-to-payoff 0 ]
end

to-report prepared-attack [thismonstertype act policy]
  ;; show "prepared attack"
  if-else thismonstertype = act [
    let investment item (act - 1) policy
    report (investment-to-payoff investment) - 1
  ] [
    report -1
  ]
end
  
to dismantle-hunt [monster hunter]
  if monster != nobody [
    ask monster [
      set myhunter nobody
      set huntstage 0
    ]
  ]
  if hunter != nobody [
    ask hunter [
      set mymonster nobody
      set huntstage 0
    ]
  ]
end

to-report get-act [monster hunter]
  let hunterstrat [strategy] of hunter
  let thismonstertype [monstertype] of monster
  let stratpertype matrix:get-row hunterstrat thismonstertype
  let act weighted-random-choice stratpertype
  report act
end

to relocate [agent]
  if agent != nobody [
    ask agent [ setxy random-xcor random-ycor ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
115
305
418
629
16
16
8.9
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
745
80
956
113
monster-starting-energy
monster-starting-energy
0
10
5
1
1
NIL
HORIZONTAL

BUTTON
20
30
90
65
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
70
90
103
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
110
90
145
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
745
125
955
158
number-of-monsters
number-of-monsters
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
970
215
1201
248
hunter-reproducing-energy
hunter-reproducing-energy
100
150
150
1
1
NIL
HORIZONTAL

SLIDER
970
80
1201
113
hunter-starting-energy
hunter-starting-energy
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
970
125
1200
158
number-of-hunters
number-of-hunters
0
100
50
1
1
NIL
HORIZONTAL

PLOT
115
30
420
290
Hunter counts
tick
number
0.0
1000.0
0.0
100.0
true
true
"" ""
PENS
"hunter" 1.0 0 -16777216 true "" "plot count hunters"

SLIDER
970
170
1200
203
hunter-radius
hunter-radius
0
30
20
1
1
NIL
HORIZONTAL

PLOT
435
30
720
290
Mean Air Investment
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"mean" 1.0 0 -16777216 true "" "plot mean [ item 0 investmentpolicy ] of hunters"
"std dev" 1.0 0 -7500403 true "" "plot standard-deviation [ item 0 investmentpolicy ] of hunters"

SLIDER
745
170
955
203
energy-of-undecided
energy-of-undecided
0
10
0
1
1
NIL
HORIZONTAL

SLIDER
970
260
1205
293
mutation-probability
mutation-probability
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
745
215
955
248
prob-air
prob-air
0
1
0.35
0.01
1
NIL
HORIZONTAL

SLIDER
970
305
1205
338
mutation-mix
mutation-mix
0
1
1
0.01
1
NIL
HORIZONTAL

SLIDER
970
350
1205
383
perturbation-ratio
perturbation-ratio
0
1
0.2
.1
1
NIL
HORIZONTAL

TEXTBOX
745
40
895
58
Monster Parameters
12
0.0
1

TEXTBOX
970
40
1120
58
Hunter Parameters
12
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model shows how bet hedging in the presence of exponentially diminishing returns leads a population of agents to become sensitive to the probability with which a certain Bernoulli process occurs.

The model is discussed in my paper 'Modalizing Mechanisms' (forthcoming at the *Journal of Philosophy*).

## HOW IT WORKS

*Hunters* (represented by orange squares in the View) hunt for *monsters* (represented as triangles). Monsters are born in an *inchoate* stage (yellow triangles) and then, after a number of ticks given by monster-starting-energy (default: 5) they evolve, with probabilities given by prob-air and 1 - prob-air, to *air* monsters (red triangles) or *sea* monsters (blue). If they are not hunted down, after another monster-starting-energy ticks, they die, and an inchoate monster is hatched in their stead at a random location. The initial population of monsters is given by number-of-monsters, default: 50.

Hunters (the initial population is given by number-of-hunters, default: 50) watch out for monsters (how far they can see is given by hunter-radius, default: 20) and when they see one they hunt it. The hunting process is described in the paper referred to above. The payoff of a hunt is added to the hunter's energy. Each hunter starts their life with hunter-starting-energy energy units (default: 100). With each tick they lose 1 energy unit. When they reach 0, they die, but if they reach hunter-reproducing-energy (default: 150), they hatch a new hunter, which appears at a random location. The newly hatched hunter has, most of the time, the same strategy as their parent, but, sometimes (the probability is given by mutation-probability, default: 0.1), they have a mutated strategy. Mutation works as follows:

* Most of the time, the mutated strategy is a perturbation of the old one. The perturbation works by adding random noise in a prefixed proportion (given by mutation-mix, default: 0.2) and renormalizing.

* Sometimes, the mutated strategy is a completely random one. The probability of a perturbation (as opposed to a wholly new mutation) is given by mutation-mix. In fact, the default for this parameter (the one used in the paper referred to above) is 1. This means that, in the simulations discussed in the paper, mutation was always perturbation of the parent strategy.

The way in which hunters reproduce is designed to provide a discrete analogue of the replicator-mutator dynamics: better performing hunters will reproduce more often, sometimes atching mutated offspring.

## HOW TO USE IT

The SETUP button creates an initial arrangement of monsters and hunters. The GO button starts a simulation, which will then run until the GO button is pressed again, or until the number of hunters in a population has stabilized. That is, every 10k ticks, the mean number of hunters in the previous 10k ticks is calculated, and compared with the mean number of hunters in the previous 10k snapshot. That is, when the tick counter has reached 10k, with compare the mean number of hunters in the first 10k ticks with 0; then, when the tick counter reaches 20k, we compare the mean number of hunters from 10k + 1 to 20k with the mean number of hunters at 10k, etc. When this mean stops growing, the simulation stops.

The rationale behind this behavior is this: monsters act as a fixed resource (their population doesn't increase, nor decrease), so the more hunters there are, the more fitness they have and, consequently, the better their strategy is. When the mean population count reaches a plateau (stops growing) this indicates that they have reached a local optimum. This procedure is not extremely precise; suggestions for improvement are welcome!

## THINGS TO NOTICE

Note how, while the count of hunters grows asymptotically with time, the mean investment policy has a less smooth development. This is probably because the mean hunter strategy (which is a matrix, and thus hard to plot) is more important in the initial stages than the investment policy, which only later becomes crucial. But I'm not sure about this; suggestions are also welcome here!

## THINGS TO TRY

The paper, and the model as it is set up, assume exponentially diminishing returns on investment. This is hardcoded in the investment-to-payoff function in utils.nls. You can change the return on investment to a linear one by using investment-to-payoff-linear instead of investment-to-payoff-inv-exp in investment-to-payoff.

You will see that hunters simply resort to a step function, investing everything in the eventuality of an air attack whenever prob-air > 0.5.

## EXTENDING THE MODEL

It would be interesting to see what happens if hunters had to deal with monsters evolving to n varieties, for n > 2.


## CREDITS AND REFERENCES

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Martinez, M. (forthcoming).  Modalizing Mechanisms, *Journal of Philosophy* 
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2015 Manolo Martínez.

This model is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.


Financial support for this work was provided by the DGI, Spanish Government, research project FFI2011-26853, and Consolider-Ingenio project CSD2009-00056.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="for-paper" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean-hunter-strat</metric>
    <metric>mean [item 0 investmentpolicy] of hunters</metric>
    <metric>standard-deviation [item 0 investmentpolicy] of hunters</metric>
    <steppedValueSet variable="prob-air" first="0" step="0.005" last="1"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
