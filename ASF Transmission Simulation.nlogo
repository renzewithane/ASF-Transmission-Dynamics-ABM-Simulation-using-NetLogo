globals [num-agents day deaths remaining %infected PIG-COUNT initial-positions spread-interval orange-source]

to setup
  clear-all
  reset-ticks ; Add this line to reset the ticks counter
  calculate-number-of-agents
  set day 0
  set deaths 0
  set remaining num-agents
  set %infected 0 ; Initialize %infected
  set PIG-COUNT 0 ; Initialize PIG-COUNT
  set spread-interval 5 ; Set the interval for spreading susceptible agents (in ticks)
  set orange-source nobody ; Initialize the orange + 1 source turtle
  create-agents
  update-pig-count ; Add this line to update the pig count monitor
  set initial-positions [list xcor ycor] of turtles ; Store initial positions

  ; Create a plot for "Swine Population"
  set-current-plot "Swine Population"
  plot 0 ; Initialize the plot with 0

  ; Configure the "susceptible" pen
  set-current-plot-pen "susceptible"
  set-plot-pen-mode 1 ; Set the mode to "number of turtles"

  ; Configure the "latent" pen
  set-current-plot-pen "latent"
  set-plot-pen-mode 0 ; Set the mode to "number of turtles"

  move-agents
  update-model

  ; At setup, set one pink agent to orange + 1
  ask one-of turtles with [color = pink] [
    set color red
    set orange-source self ; Set the orange + 1 source turtle
  ]

  ; Update the "susceptible" pen with the count of susceptible agents
  set-current-plot "Swine Population"
  set-current-plot-pen "susceptible"
  set-plot-pen-mode 0 ; Set mode to "no lines"
  plot count turtles with [color = orange + 1] ; Count the number of susceptible agents

  ; Update the "latent" pen with the count of latent agents
  set-current-plot-pen "latent"
  set-plot-pen-mode 0 ; Set mode to "no lines"
  plot count turtles with [color = pink] ; Count the number of latent agents

  ; Slow down the simulation by adding a delay
  wait 0.1 ; Adjust the delay time as needed
  tick
end

to create-agents
  create-turtles num-agents [
    set color pink
    set-shape
    setxy random-xcor random-ycor ; Set initial position without changing it later
  ]
end

to set-shape
  ifelse (simulation-shape = "pigs") [
    set shape "pigg"
    set size 1.25
  ] [
    set shape "circle"
    set size 1 ; Adjust the size as needed for circles
  ]
end

to calculate-number-of-agents
  let sf-percentage 0.6
  let mf-percentage 0.3
  let lf-percentage 0.1

  let sf-agents int (farm-count * sf-percentage * (1 + random 9))
  let mf-agents int (farm-count * mf-percentage * (11 + random 14))
  let lf-agents int (farm-count * lf-percentage * (26 + random 24))

  let total-agents sf-agents + mf-agents + lf-agents
  set num-agents total-agents ; Directly set the global variable
end

to go
  if not any? turtles [
    stop
  ]
  if ticks >= 365 [
    stop
  ]
  move-agents
  update-model
  if ticks >= 10 and ticks mod spread-interval = 0 [
    spread-susceptible
    spread-infectious ; Add this line to spread infectious agents
    spread-deceased ; Add this line to spread deceased agents
  ]

  ; Update the "susceptible" pen with the count of susceptible agents
  set-current-plot "Swine Population"
  set-current-plot-pen "susceptible"
  set-plot-pen-mode 0 ; Set mode to "no lines"
  plot count turtles with [color = orange + 1] ; Count the number of susceptible agents

  ; Update the "latent" pen with the count of latent agents
  set-current-plot-pen "latent"
  set-plot-pen-mode 0 ; Set mode to "no lines"
  plot count turtles with [color = pink] ; Count the number of latent agents

  ; Update the "infectious" pen with the count of infectious agents
  set-current-plot-pen "infectious"
  set-plot-pen-mode 0 ; Set mode to "no lines"
  plot count turtles with [color = red] ; Count the number of infectious agents

  ; Update the "deceased" pen with the count of deceased agents
  set-current-plot-pen "deceased"
  set-plot-pen-mode 0 ; Set mode to "no lines"
  plot count turtles with [color = magenta - 3] ; Count the number of deceased agents

  ; Slow down the simulation by adding a delay
  wait 0.1 ; Adjust the delay time as needed
  tick
end


to move-agents
  ; Do nothing to keep the agents' positions constant
end

to update-model
  set day day + 1
  let death-rate 3 ; Adjust this based on your scenario
  let deaths-this-week count turtles with [color = blue and random-float 1 < death-rate]

  ; Update deaths and remaining
  set deaths deaths + deaths-this-week
  set remaining num-agents - deaths

  ; Calculate percentage of infected pigs and update global variable
  let raw-infected count turtles with [color = blue] / num-agents * 100
  set %infected round (raw-infected * 10000) / 10000 ; Round to 4 decimal places

  ; Display information
  print (word "Day: " day ", Deaths: " deaths ", Remaining: " remaining ", %infected: " %infected "%")

  ; Update pig count monitor
  update-pig-count
end

to update-pig-count
  set PIG-COUNT count turtles
end

to spread-susceptible
  ; Define the factor based on the number of agents
  let factor 0.1
  if count turtles >= 0 and count turtles < 500 [
    set factor random-float (0.1 + 0.4) ; Random number between 0.1 and 0.5
  ]
  if count turtles >= 500 and count turtles < 1000 [
    set factor random-float (0.6 + 0.4) ; Random number between 0.6 and 1
  ]
  if count turtles >= 1000 and count turtles < 2000 [
    set factor random-float (1.1 + 0.9) ; Random number between 1.1 and 2
  ]
  if count turtles >= 2000 [
    set factor random-float (2.1 + 0.9) ; Random number between 2.1 and 3
  ]

  ; Identify the susceptible agents (pink) and make them orange + 1
  let susceptible-turtles turtles with [color = pink]
  ask susceptible-turtles [
    set color pink ; Change color to pink initially
  ]

  ; Only introduce susceptible agents when 'go' button is clicked
  ; Select a random source turtle
  let source-turtle one-of turtles
  ask source-turtle [
    set color orange + 1 ; Change color to orange plus 1
  ]

  ; Spread gradually from the source to nearby turtles
  ask turtles with [color = pink] [
    let distance-to-source distance source-turtle
    if distance-to-source <= 5 [
      let max-distance max [distance source-turtle] of turtles with [color = red]
      if max-distance > 0 [
        let normalized-distance distance-to-source / max-distance
        ; Adjust the chance of spreading based on the number of turtles and the factor
        let chance factor * normalized-distance
        ifelse random-float 1 < chance [
          set color orange + 1 ; Change color to orange plus 1
        ] [
          ; Do nothing or add any other actions for the "else" case
        ]
      ]
    ]
  ]
end


to spread-infectious
  ; Identify the infectious agents (orange + 1) and make them pink after a delay
  ask turtles with [color = orange + 1] [
    let delay-time random 11 + 5 ; Random delay between 5 and 15 ticks
    if ticks mod (delay-time + 1) = 0 [
      set color red ; Change color to red
    ]
  ]
end

to spread-deceased
  ; Identify the deceased agents (red) and make them magenta-3 after a delay
  ask turtles with [color = red] [
    let delay-time random 11 + 5 ; Random delay between 5 and 15 ticks
    if ticks mod (delay-time + 1) = 0 [
      set color magenta - 3 ; Change color to magenta-3
    ]
  ]
end






@#$#@#$#@
GRAPHICS-WINDOW
398
10
869
482
-1
-1
14.030303030303031
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
0
0
1
ticks
30.0

BUTTON
118
55
213
88
setup
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
222
55
317
88
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
23
443
438
471
ASF Transmission Dynamics Simulation using NetLogo
15
1.0
1

TEXTBOX
96
463
342
491
Mortiga - Toral - Postre - Macarilay - Alimba
11
1.0
1

TEXTBOX
130
478
279
496
IT 114 - Quantitative Methods
11
1.0
1

MONITOR
324
49
389
94
% infected
%infected
17
1
11

SLIDER
7
10
389
43
farm-count
farm-count
30
200
200.0
1
1
NIL
HORIZONTAL

MONITOR
97
154
190
199
day
day
17
1
11

MONITOR
197
154
289
199
deaths
deaths
17
1
11

MONITOR
296
154
389
199
remaining
remaining
17
1
11

PLOT
8
206
389
438
Swine Population
days
swine
0.0
365.0
0.0
0.0
true
true
"" ""
PENS
"latent" 1.0 0 -2064490 true "" ""
"susceptible" 1.0 0 -817084 true "" ""
"infectious" 1.0 0 -2674135 true "" ""
"deceased" 1.0 0 -12186836 true "" ""

CHOOSER
203
102
389
147
simulation-shape
simulation-shape
"pigs" "circle"
1

SLIDER
8
102
195
135
routes
routes
1
100
22.0
1
1
NIL
HORIZONTAL

BUTTON
8
55
107
88
clear
clear-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
8
154
90
199
initial pig count
pig-count
17
1
11

@#$#@#$#@
## WHAT IS IT?

This project models an agent-based simulation that visualises emerging dynamics from the interaction and influence of a small subset of multiple biological and social factors in the development of the African Swine Fever (ASF) Virus. Given the scale of the virus, and the complexity of global societal structures, the simulation may not be viewed as a precise model of universal application. The simulation may, however, be tailored to locales to enable governments, specifically the District II of Camarines Norte, Philippines where this project originated, to assess intervention strategies and outcomes at local, municipal and district levels. In facilitating such analysis, variables that play a critical role in the development of the pandemic have been singled out for manipulation in the model.

## CREDITS AND REFERENCES

This African Swine Fever Transmission Simulation was created in partial fulfillment of for IT 114 - Quantitative Methods (Modelling and Simulation) by the following:

<ul>
  <li><a href="https://www.facebook.com/cherylmarie.alimba" style="text-decoration: none; color: inherit;">Alimba, Cheryl Marie C.</a></li>
  <li><a href="https://www.facebook.com/jenelyn.macarilay.jenayy27" style="text-decoration: none; color: inherit;">Macarilay, Jenelyn E.</a></li>
  <li><a href="https://www.facebook.com/renzewithane" style="text-decoration: none; color: inherit;">Mortiga, Renze Meinard</a></li>
  <li><a href="https://www.facebook.com/wendee.postre.37" style="text-decoration: none; color: inherit;">Postre, Wendee D.</a></li>
  <li><a href="https://www.facebook.com/tin.trl" style="text-decoration: none; color: inherit;">Toral, Christine M.</a></li>
</ul>

Presented and Submitted to:

<ul>
  <li><a href="https://www.facebook.com/edgarbryann" style="text-decoration: none; color: inherit;">Nicart, Edgar Bryan B., MIT</a></li>
</ul>
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

pigg
false
15
Circle -1 true true 173 110 88
Circle -1 true true 70 80 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 127 150 105 195 90 195 67 150
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 98 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 231 100 240 120 257 114 255 60
Polygon -7500403 true false 210 75 210 105 193 99 180 45
Rectangle -2674135 true false 120 60 45 90

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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
0
@#$#@#$#@
