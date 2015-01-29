## image_datatypes.arr
## -------------------
## Blame issues on:
##  Philip Blair (GitHub: belph)
##  peblairman@gmail.com

## Description:
## ------------
## Provides data definitions
##  for the image library.

provide {
  rgba-color : rgba-color,
  rgb-color  : rgb-color,
  grey       : gray,
  orangered : orangered,
  tomato : tomato,
  darkred : darkred,
  red : red,
  firebrick : firebrick,
  crimson : crimson,
  deeppink : deeppink,
  maroon : maroon,
  indianred : indianred,
  mediumvioletred : mediumvioletred,
  violetred : violetred,
  lightcoral : lightcoral,
  hotpink : hotpink,
  palevioletred : palevioletred,
  lightpink : lightpink,
  rosybrown : rosybrown,
  pink : pink,
  orchid : orchid,
  lavenderblush : lavenderblush,
  snow : snow,
  chocolate : chocolate,
  saddlebrown : saddlebrown,
  brown : brown,
  darkorange : darkorange,
  coral : coral,
  sienna : sienna,
  orange : orange,
  salmon : salmon,
  peru : peru,
  darkgoldenrod : darkgoldenrod,
  goldenrod : goldenrod,
  sandybrown : sandybrown,
  lightsalmon : lightsalmon,
  darksalmon : darksalmon,
  gold : gold,
  yellow : yellow,
  olive : olive,
  burlywood : burlywood,
  tan : tan,
  navajowhite : navajowhite,
  peachpuff : peachpuff,
  khaki : khaki,
  darkkhaki : darkkhaki,
  moccasin : moccasin,
  wheat : wheat,
  bisque : bisque,
  palegoldenrod : palegoldenrod,
  blanchedalmond : blanchedalmond,
  mediumgoldenrod : mediumgoldenrod,
  papayawhip : papayawhip,
  mistyrose : mistyrose,
  lemonchiffon : lemonchiffon,
  antiquewhite : antiquewhite,
  cornsilk : cornsilk,
  lightgoldenrodyellow : lightgoldenrodyellow,
  oldlace : oldlace,
  linen : linen,
  lightyellow : lightyellow,
  seashell : seashell,
  beige : beige,
  floralwhite : floralwhite,
  ivory : ivory,
  green : green,
  lawngreen : lawngreen,
  chartreuse : chartreuse,
  greenyellow : greenyellow,
  yellowgreen : yellowgreen,
  mediumforestgreen : mediumforestgreen,
  olivedrab : olivedrab,
  darkolivegreen : darkolivegreen,
  darkseagreen : darkseagreen,
  lime : lime,
  darkgreen : darkgreen,
  limegreen : limegreen,
  forestgreen : forestgreen,
  springgreen : springgreen,
  mediumspringgreen : mediumspringgreen,
  seagreen : seagreen,
  mediumseagreen : mediumseagreen,
  aquamarine : aquamarine,
  lightgreen : lightgreen,
  palegreen : palegreen,
  mediumaquamarine : mediumaquamarine,
  turquoise : turquoise,
  lightseagreen : lightseagreen,
  mediumturquoise : mediumturquoise,
  honeydew : honeydew,
  mintcream : mintcream,
  royalblue : royalblue,
  dodgerblue : dodgerblue,
  deepskyblue : deepskyblue,
  cornflowerblue : cornflowerblue,
  steelblue : steelblue,
  lightskyblue : lightskyblue,
  darkturquoise : darkturquoise,
  cyan : cyan,
  aqua : aqua,
  darkcyan : darkcyan,
  teal : teal,
  skyblue : skyblue,
  cadetblue : cadetblue,
  darkslategray : darkslategray,
  lightslategray : lightslategray,
  slategray : slategray,
  lightsteelblue : lightsteelblue,
  lightblue : lightblue,
  powderblue : powderblue,
  paleturquoise : paleturquoise,
  lightcyan : lightcyan,
  aliceblue : aliceblue,
  azure : azure,
  mediumblue : mediumblue,
  darkblue : darkblue,
  midnightblue : midnightblue,
  navy : navy,
  blue : blue,
  indigo : indigo,
  blueviolet : blueviolet,
  mediumslateblue : mediumslateblue,
  slateblue : slateblue,
  purple : purple,
  darkslateblue : darkslateblue,
  darkviolet : darkviolet,
  darkorchid : darkorchid,
  mediumpurple : mediumpurple,
  mediumorchid : mediumorchid,
  magenta : magenta,
  fuchsia : fuchsia,
  darkmagenta : darkmagenta,
  violet : violet,
  plum : plum,
  lavender : lavender,
  thistle : thistle,
  ghostwhite : ghostwhite,
  white : white,
  whitesmoke : whitesmoke,
  gainsboro : gainsboro,
  lightgray : lightgray,
  silver : silver,
  gray : gray,
  darkgray : darkgray,
  dimgray : dimgray,
  black : black,
  outline    : outline,
  solid      : solid,
  x-left     : x-left,
  x-center   : x-center,
  x-right    : x-right,
  y-top      : y-top,
  y-center   : y-center,
  y-bottom   : y-bottom
} end
provide-types *

# in-color-range:
# Predicate to check whether or not
#   the given number is within the
#   range [0, 255]
fun in-color-range(n :: Number) -> Boolean:
  (0 <= n) and (n <= 255)
where:
  in-color-range(-1) is false
  in-color-range(100) is true
  in-color-range(266) is false
end

# Represents Color Data
# TODO: Default alpha to 255?
data Color:
  | rgba-color(red :: Number%(in-color-range),
      green :: Number%(in-color-range),
      blue :: Number%(in-color-range),
      alpha :: Number%(in-color-range))
end

fun rgb-color(red :: Number%(in-color-range), green :: Number%(in-color-range), blue :: Number%(in-color-range)):
  rgba-color(red, green, blue, 255)
end

orangered = rgb-color(255,69,0)
tomato = rgb-color(255,99,71)
darkred = rgb-color(139,0,0)
red = rgb-color(255,0,0)
firebrick = rgb-color(178,34,34)
crimson = rgb-color(220,20,60)
deeppink = rgb-color(255,20,147)
maroon = rgb-color(176,48,96)
indianred = rgb-color(205,92,92)
mediumvioletred = rgb-color(199,21,133)
violetred = rgb-color(208,32,144)
lightcoral = rgb-color(240,128,128)
hotpink = rgb-color(255,105,180)
palevioletred = rgb-color(219,112,147)
lightpink = rgb-color(255,182,193)
rosybrown = rgb-color(188,143,143)
pink = rgb-color(255,192,203)
orchid = rgb-color(218,112,214)
lavenderblush = rgb-color(255,240,245)
snow = rgb-color(255,250,250)
chocolate = rgb-color(210,105,30)
saddlebrown = rgb-color(139,69,19)
brown = rgb-color(132,60,36)
darkorange = rgb-color(255,140,0)
coral = rgb-color(255,127,80)
sienna = rgb-color(160,82,45)
orange = rgb-color(255,165,0)
salmon = rgb-color(250,128,114)
peru = rgb-color(205,133,63)
darkgoldenrod = rgb-color(184,134,11)
goldenrod = rgb-color(218,165,32)
sandybrown = rgb-color(244,164,96)
lightsalmon = rgb-color(255,160,122)
darksalmon = rgb-color(233,150,122)
gold = rgb-color(255,215,0)
yellow = rgb-color(255,255,0)
olive = rgb-color(128,128,0)
burlywood = rgb-color(222,184,135)
tan = rgb-color(210,180,140)
navajowhite = rgb-color(255,222,173)
peachpuff = rgb-color(255,218,185)
khaki = rgb-color(240,230,140)
darkkhaki = rgb-color(189,183,107)
moccasin = rgb-color(255,228,181)
wheat = rgb-color(245,222,179)
bisque = rgb-color(255,228,196)
palegoldenrod = rgb-color(238,232,170)
blanchedalmond = rgb-color(255,235,205)
mediumgoldenrod = rgb-color(234,234,173)
papayawhip = rgb-color(255,239,213)
mistyrose = rgb-color(255,228,225)
lemonchiffon = rgb-color(255,250,205)
antiquewhite = rgb-color(250,235,215)
cornsilk = rgb-color(255,248,220)
lightgoldenrodyellow = rgb-color(250,250,210)
oldlace = rgb-color(253,245,230)
linen = rgb-color(250,240,230)
lightyellow = rgb-color(255,255,224)
seashell = rgb-color(255,245,238)
beige = rgb-color(245,245,220)
floralwhite = rgb-color(255,250,240)
ivory = rgb-color(255,255,240)
green = rgb-color(0,255,0)
lawngreen = rgb-color(124,252,0)
chartreuse = rgb-color(127,255,0)
greenyellow = rgb-color(173,255,47)
yellowgreen = rgb-color(154,205,50)
mediumforestgreen = rgb-color(107,142,35)
olivedrab = rgb-color(107,142,35)
darkolivegreen = rgb-color(85,107,47)
darkseagreen = rgb-color(143,188,139)
lime = rgb-color(0,255,0)
darkgreen = rgb-color(0,100,0)
limegreen = rgb-color(50,205,50)
forestgreen = rgb-color(34,139,34)
springgreen = rgb-color(0,255,127)
mediumspringgreen = rgb-color(0,250,154)
seagreen = rgb-color(46,139,87)
mediumseagreen = rgb-color(60,179,113)
aquamarine = rgb-color(112,216,144)
lightgreen = rgb-color(144,238,144)
palegreen = rgb-color(152,251,152)
mediumaquamarine = rgb-color(102,205,170)
turquoise = rgb-color(64,224,208)
lightseagreen = rgb-color(32,178,170)
mediumturquoise = rgb-color(72,209,204)
honeydew = rgb-color(240,255,240)
mintcream = rgb-color(245,255,250)
royalblue = rgb-color(65,105,225)
dodgerblue = rgb-color(30,144,255)
deepskyblue = rgb-color(0,191,255)
cornflowerblue = rgb-color(100,149,237)
steelblue = rgb-color(70,130,180)
lightskyblue = rgb-color(135,206,250)
darkturquoise = rgb-color(0,206,209)
cyan = rgb-color(0,255,255)
aqua = rgb-color(0,255,255)
darkcyan = rgb-color(0,139,139)
teal = rgb-color(0,128,128)
skyblue = rgb-color(135,206,235)
cadetblue = rgb-color(96,160,160)
darkslategray = rgb-color(47,79,79)
lightslategray = rgb-color(119,136,153)
slategray = rgb-color(112,128,144)
lightsteelblue = rgb-color(176,196,222)
lightblue = rgb-color(173,216,230)
powderblue = rgb-color(176,224,230)
paleturquoise = rgb-color(175,238,238)
lightcyan = rgb-color(224,255,255)
aliceblue = rgb-color(240,248,255)
azure = rgb-color(240,255,255)
mediumblue = rgb-color(0,0,205)
darkblue = rgb-color(0,0,139)
midnightblue = rgb-color(25,25,112)
navy = rgb-color(36,36,140)
blue = rgb-color(0,0,255)
indigo = rgb-color(75,0,130)
blueviolet = rgb-color(138,43,226)
mediumslateblue = rgb-color(123,104,238)
slateblue = rgb-color(106,90,205)
purple = rgb-color(160,32,240)
darkslateblue = rgb-color(72,61,139)
darkviolet = rgb-color(148,0,211)
darkorchid = rgb-color(153,50,204)
mediumpurple = rgb-color(147,112,219)
mediumorchid = rgb-color(186,85,211)
magenta = rgb-color(255,0,255)
fuchsia = rgb-color(255,0,255)
darkmagenta = rgb-color(139,0,139)
violet = rgb-color(238,130,238)
plum = rgb-color(221,160,221)
lavender = rgb-color(230,230,250)
thistle = rgb-color(216,191,216)
ghostwhite = rgb-color(248,248,255)
white = rgb-color(255,255,255)
whitesmoke = rgb-color(245,245,245)
gainsboro = rgb-color(220,220,220)
lightgray = rgb-color(211,211,211)
silver = rgb-color(192,192,192)
gray = rgb-color(190,190,190)
darkgray = rgb-color(169,169,169)
dimgray = rgb-color(105,105,105)
black = rgb-color(0,0,0)



# Represents the Image Mode.
# Equivalent to Racket's 'solid
#   'outline.
data Mode:
  | outline
  | solid
end

# Represents horizontal alignments
data X-Place:
  | x-left
  | x-center
  | x-right
end

# Represents vertical alignments
data Y-Place:
  | y-top
  | y-center
  | y-bottom
end
