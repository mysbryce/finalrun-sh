# 04 · HUD and in-game overlays

## 1. Purpose and entry/exit

Use `/` for a read-only live or downed HUD. Host opens `/inventory`, `/search`, `/pause`, `/death`, `/arrest` or `/transfer` and owns return routing. Surrender is an input-taking prompt within `/`. The active game keeps running behind interactive panels. Godot clears incompatible panels when life, transfer or connection changes. See [flow](flow.md) for input mode and route ownership.

## 2. ASCII wireframes

### Live HUD

[Open SVG](wireframes/04-hud.svg)

```text
+-----------------------------------------------------------------------------------------------+
| +--------------++A03----++Compass----------------------------------+           +Cash--------+ |
| |Minimap       |+-------++-----+-----------------------------+-----+           +------------+ |
| |              |+A04----+      |Heist alert                  |                                |
| |              |+A05----+      ++---------------------------++                                |
| |              |+Safety-+       |Notifications              |                                 |
| |              |+-------+       |                           |                                 |
| +--------------+                |                           |                                 |
|                                 +---------------------------+                                 |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                    +---------------------+                                    |
|                                    |Interact card        |                                    |
|                                    |                     |                                    |
| +Party member 1---+                |                     |                                    |
| +-----------------+                +---------------------+                                    |
| |Party member 2   |                +Surrender hint-------+                                    |
| +-----------------+                +---------------------+ +-----+-----+--++--+---+--++-----+ |
| |Self health      |                                        |A18  |A19  |  ||  |A22|  ||A24  | |
| +-----------------+                                        +-----+-----+--++--+---+--++-----+ |
+-----------------------------------------------------------------------------------------------+

[A01 Net stats]
[A02 Minimap]
[A03 Role badge]
[A04 Mask timer]
[A05 Notoriety]
[A06 Safety]
[A07 Compass]
[A08 Heist alert]
[A09 Notifications]
[A10 Cash]
[A11 Party and self]
  [A12 Party member 1]
  [A13 Party member 2]
  [A14 Self health]
[A15 Interact card]
[A16 Surrender hint]
[A17 Hotbar]
  [A18 Slot 1]
  [A19 Slot 2]
  [A20 Slot 3]
  [A21 Slot 4]
  [A22 Slot 5]
  [A23 Slot 6]
  [A24 Bag value and hint]
```

### Downed HUD

[Open SVG](wireframes/04-hud-downed.svg)

```text
+-----------------------------------------------------------------------------------------------+
| +--------------++A03----++Compass----------------------------------+           +Cash--------+ |
| |Minimap       |+-------++-----------------------------------------+           +------------+ |
| |              |                                                                              |
| |              |                +---------------------------+                                 |
| |              |+Safety-+       |Notifications              |                                 |
| |              |+-------+       |                           |                                 |
| +--------------+                |                           |                                 |
|                                 +---------------------------+                                 |
|                              ++Downed title-------------------++                              |
|                              |+-------------------------------+|                              |
|                              |                                 |                              |
|                              |+Revive progress----------------+|                              |
|                              |+Finish warning-----------------+|                              |
|                              |+Downed controls----------------+|                              |
|                              |+-------------------------------+|                              |
|                              +---------------------------------+                              |
|                                                                                               |
|                                                                                               |
| +Party member 1---+                                                                           |
| +-----------------+                                                                           |
| |Party member 2   |                                                                           |
| +-----------------+                                                                           |
| |Self health      |                                                                           |
| +-----------------+                                                                           |
+-----------------------------------------------------------------------------------------------+

[A01 Net stats]
[A02 Minimap]
[A03 Role badge]
[A04 Safety]
[A05 Compass]
[A06 Notifications]
[A07 Cash]
[A08 Party and self]
  [A09 Party member 1]
  [A10 Party member 2]
  [A11 Self health]
[A12 Downed panel]
  [A13 Downed title]
  [A14 Bleed-out progress]
  [A15 Revive progress]
  [A16 Finish warning]
  [A17 Downed controls]
```

### Body search with owner inventory

[Open SVG](wireframes/04-inventory-search.svg)

```text
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|                                                                                               |
|                             +Search title----++A04-++++A12-+---------+A13----++A14---------++ |
|                             +----------------------++++----------------------++------------++ |
|                             |Body grid             ||||Bag grid              ||Primary     || |
|                             |                      ||||                      ||            || |
|                             |                      ||||                      ||            || |
|                             |                      ||||                      |+------------+| |
|                             |                      ||||                      ||Secondary   || |
|                             |                      ||||                      ||            || |
|                             |                      ||||                      |+-----++-----+| |
|                             |                      ||||                      ||A19  ||A20  || |
|                             |                      ||||                      ||     ||     || |
|                             |                      ||||                      |+A21-+++-----+| |
|                             |                      ||||                      |+----++--+---+| |
|                             |                      ||||                      ||A22 ||  |A24|| |
|                             |                      ||||                      ||    |+--+---+| |
|                             |                      ||||                      |+----+|  |A26|| |
|                             |                      ||||                      |+-----+--+---+| |
|                             +----------------------+||+----------------------+              | |
|                             +A07-------+A08--+A09--++++Selected item-++Back-+A30---++A31---++ |
|                             +----------+-----+-----++++--------------++-----+------++------++ |
|                                                                                               |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+

[A01 Body search panel]
  [A02 Search header]
    [A03 Search title]
    [A04 Item count]
  [A05 Body grid]
  [A06 Search footer]
    [A07 Search error]
    [A08 Search close]
    [A09 Take hint]
[A10 Inventory panel]
  [A11 Inventory header]
    [A12 Bag title]
    [A13 Bag value]
    [A14 Equipment title]
  [A15 Bag grid]
  [A16 Equipment column]
    [A17 Primary]
    [A18 Secondary]
    [A19 Armor]
    [A20 Bag slot]
    [A21 Pouch label]
    [A22 Pouch]
    [A23 Pocket 1]
    [A24 Pocket 2]
    [A25 Pocket 3]
    [A26 Pocket 4]
  [A27 Inventory footer]
    [A28 Selected item]
    [A29 Back]
    [A30 Close hint]
    [A31 Select hint]
```

### Owner inventory

[Open SVG](wireframes/04-inventory.svg)

```text
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|                                                                                               |
|                                                      ++A03-+---------+A04----++A05---------++ |
|                                                      ++----------------------++------------++ |
|                                                      ||Bag grid              ||Primary     || |
|                                                      ||                      ||            || |
|                                                      ||                      ||            || |
|                                                      ||                      |+------------+| |
|                                                      ||                      ||Secondary   || |
|                                                      ||                      ||            || |
|                                                      ||                      |+-----++-----+| |
|                                                      ||                      ||A10  ||A11  || |
|                                                      ||                      ||     ||     || |
|                                                      ||                      |+A12-+++-----+| |
|                                                      ||                      |+----++--+---+| |
|                                                      ||                      ||A13 ||  |A15|| |
|                                                      ||                      ||    |+--+---+| |
|                                                      ||                      |+----+|  |A17|| |
|                                                      ||                      |+-----+--+---+| |
|                                                      |+----------------------+              | |
|                                                      ++Selected item-++Back-+A21---++A22---++ |
|                                                      ++--------------++-----+------++------++ |
|                                                                                               |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+

[A01 Inventory panel]
  [A02 Inventory header]
    [A03 Bag title]
    [A04 Bag value]
    [A05 Equipment title]
  [A06 Bag grid]
  [A07 Equipment column]
    [A08 Primary]
    [A09 Secondary]
    [A10 Armor]
    [A11 Bag slot]
    [A12 Pouch label]
    [A13 Pouch]
    [A14 Pocket 1]
    [A15 Pocket 2]
    [A16 Pocket 3]
    [A17 Pocket 4]
  [A18 Inventory footer]
    [A19 Selected item]
    [A20 Back]
    [A21 Close hint]
    [A22 Select hint]
```

### Pause menu

[Open SVG](wireframes/04-pause.svg)

```text
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                  ++-----------------------+-+                                 |
|                                  ||Pause title            | |                                 |
|                                  |+Pause context----------+ |                                 |
|                                  |+-----------------------+ |                                 |
|                                  |+Resume-----------------+ |                                 |
|                                  |+-----------------------+ |                                 |
|                                  |+Settings---------------+ |                                 |
|                                  |+-----------------------+ |                                 |
|                                  ||Leave to Lobby         | |                                 |
|                                  |+-----------------------+ |                                 |
|                                  ||Quit                   | |                                 |
|                                  |+-----------------------+ |                                 |
|                                  ||Pause feedback         | |                                 |
|                                  ++-----------------------+-+                                 |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+

[A01 Pause dim]
  [A02 Pause panel]
    [A03 Pause title]
    [A04 Pause context]
    [A05 Resume]
    [A06 Settings]
    [A07 Leave to Lobby]
    [A08 Quit]
    [A09 Pause feedback]
```

### Surrender prompt

[Open SVG](wireframes/04-surrender.svg)

```text
+-----------------------------------------------------------------------------------------------+
| +--------------++A03----++Compass----------------------------------+           +Cash--------+ |
| |Minimap       |+-------++-----+-----------------------------+-----+           +------------+ |
| |              |+A04----+      |Heist alert                  |                                |
| |              |+A05----+      ++---------------------------++                                |
| |              |+Safety-+       |Notifications              |                                 |
| |              |+-------+       |                           |                                 |
| +--------------+                |                           |                                 |
|                                 +---------------------------+                                 |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                              +---------------------------------+                              |
|                              |+Surrender title----------------+|                              |
|                              |+-------------------------------+|                              |
|                              ||Surrender terms                ||                              |
|                              |+-------------------------------+|                              |
| +Party member 1---+          |+A26-------+       +A27---------+|                              |
| +-----------------+          |+----------+       +------------+|                              |
| |Party member 2   |          +---------------------------------+                              |
| +-----------------+                                        +-----+-----+--++--+---+--++-----+ |
| |Self health      |                                        |A16  |A17  |  ||  |A20|  ||A22  | |
| +-----------------+                                        +-----+-----+--++--+---+--++-----+ |
+-----------------------------------------------------------------------------------------------+

[A01 Net stats]
[A02 Minimap]
[A03 Role badge]
[A04 Mask timer]
[A05 Notoriety]
[A06 Safety]
[A07 Compass]
[A08 Heist alert]
[A09 Notifications]
[A10 Cash]
[A11 Party and self]
  [A12 Party member 1]
  [A13 Party member 2]
  [A14 Self health]
[A15 Hotbar]
  [A16 Slot 1]
  [A17 Slot 2]
  [A18 Slot 3]
  [A19 Slot 4]
  [A20 Slot 5]
  [A21 Slot 6]
  [A22 Bag value and hint]
[A23 Surrender panel]
  [A24 Surrender title]
  [A25 Surrender terms]
  [A26 Cancel surrender]
  [A27 Confirm surrender]
```

### Death and respawn

[Open SVG](wireframes/04-death.svg)

```text
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                              +---------------------------------+                              |
|                              |+Overlay title------------------+|                              |
|                              |+-------------------------------+|                              |
|                              |+Outcome summary----------------+|                              |
|                              |+-------------------------------+|                              |
|                              |+Overlay status-----------------+|                              |
|                              |+-------------------------------+|                              |
|                              |+Overlay footer-----------------+|                              |
|                              |+-------------------------------+|                              |
|                              +---------------------------------+                              |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+

[A01 World dim]
  [A02 Death panel]
    [A03 Overlay title]
    [A04 Outcome summary]
    [A05 Overlay status]
    [A06 Overlay footer]
```

### Arrest receipt

[Open SVG](wireframes/04-arrest.svg)

```text
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                              +---------------------------------+                              |
|                              |+Overlay title------------------+|                              |
|                              |+-------------------------------+|                              |
|                              |+Outcome summary----------------+|                              |
|                              |+-------------------------------+|                              |
|                              |+Overlay status-----------------+|                              |
|                              |+-------------------------------+|                              |
|                              |+Overlay footer-----------------+|                              |
|                              |+-------------------------------+|                              |
|                              +---------------------------------+                              |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+

[A01 World dim]
  [A02 Arrest panel]
    [A03 Overlay title]
    [A04 Outcome summary]
    [A05 Overlay status]
    [A06 Overlay footer]
```

### Map transfer

[Open SVG](wireframes/04-transfer.svg)

```text
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                              +---------------------------------+                              |
|                              |+Overlay title------------------+|                              |
|                              |+-------------------------------+|                              |
|                              |+Outcome summary----------------+|                              |
|                              |+-------------------------------+|                              |
|                              |+Overlay status-----------------+|                              |
|                              |+-------------------------------+|                              |
|                              |+Overlay footer-----------------+|                              |
|                              |+-------------------------------+|                              |
|                              +---------------------------------+                              |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+

[A01 World dim]
  [A02 Transfer panel]
    [A03 Overlay title]
    [A04 Outcome summary]
    [A05 Overlay status]
    [A06 Overlay footer]
```

## 3. Layout

Right and bottom give offsets to the base-frame edges. Group bounds intentionally contain their children. Rows and regions use base CSS pixels.

### Live HUD

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Net stats | 24 | 16 | 1056 | 688 | 200 | 16 | Frame |
| A02 | Minimap | 24 | 40 | 1056 | 510 | 200 | 170 | Frame |
| A03 | Role badge | 240 | 40 | 928 | 652 | 112 | 28 | Frame |
| A04 | Mask timer | 240 | 74 | 928 | 618 | 112 | 28 | Frame |
| A05 | Notoriety | 240 | 108 | 928 | 584 | 112 | 28 | Frame |
| A06 | Safety | 240 | 142 | 928 | 550 | 112 | 28 | Frame |
| A07 | Compass | 360 | 24 | 360 | 664 | 560 | 32 | Frame |
| A08 | Heist alert | 440 | 64 | 440 | 612 | 400 | 44 | Frame |
| A09 | Notifications | 456 | 116 | 456 | 492 | 368 | 112 | Frame |
| A10 | Cash | 1080 | 24 | 24 | 652 | 176 | 44 | Frame |
| A11 | Party and self | 24 | 534 | 1016 | 24 | 240 | 162 | Frame |
| A12 | Party member 1 | 24 | 534 | 1016 | 138 | 240 | 48 | Party and self |
| A13 | Party member 2 | 24 | 588 | 1016 | 84 | 240 | 48 | Party and self |
| A14 | Self health | 24 | 642 | 1016 | 24 | 240 | 54 | Party and self |
| A15 | Interact card | 496 | 450 | 496 | 134 | 288 | 136 | Frame |
| A16 | Surrender hint | 496 | 594 | 496 | 94 | 288 | 32 | Frame |
| A17 | Hotbar | 812 | 630 | 24 | 24 | 444 | 66 | Frame |
| A18 | Slot 1 | 812 | 630 | 392 | 24 | 76 | 66 | Hotbar |
| A19 | Slot 2 | 894 | 630 | 310 | 24 | 76 | 66 | Hotbar |
| A20 | Slot 3 | 976 | 630 | 262 | 24 | 42 | 66 | Hotbar |
| A21 | Slot 4 | 1024 | 630 | 214 | 24 | 42 | 66 | Hotbar |
| A22 | Slot 5 | 1072 | 630 | 166 | 24 | 42 | 66 | Hotbar |
| A23 | Slot 6 | 1120 | 630 | 118 | 24 | 42 | 66 | Hotbar |
| A24 | Bag value and hint | 1168 | 630 | 24 | 24 | 88 | 66 | Hotbar |

### Downed HUD

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Net stats | 24 | 16 | 1056 | 688 | 200 | 16 | Frame |
| A02 | Minimap | 24 | 40 | 1056 | 510 | 200 | 170 | Frame |
| A03 | Role badge | 240 | 40 | 928 | 652 | 112 | 28 | Frame |
| A04 | Safety | 240 | 142 | 928 | 550 | 112 | 28 | Frame |
| A05 | Compass | 360 | 24 | 360 | 664 | 560 | 32 | Frame |
| A06 | Notifications | 456 | 116 | 456 | 492 | 368 | 112 | Frame |
| A07 | Cash | 1080 | 24 | 24 | 652 | 176 | 44 | Frame |
| A08 | Party and self | 24 | 534 | 1016 | 24 | 240 | 162 | Frame |
| A09 | Party member 1 | 24 | 534 | 1016 | 138 | 240 | 48 | Party and self |
| A10 | Party member 2 | 24 | 588 | 1016 | 84 | 240 | 48 | Party and self |
| A11 | Self health | 24 | 642 | 1016 | 24 | 240 | 54 | Party and self |
| A12 | Downed panel | 416 | 260 | 416 | 272 | 448 | 188 | Frame |
| A13 | Downed title | 432 | 272 | 432 | 420 | 416 | 28 | Downed panel |
| A14 | Bleed-out progress | 432 | 308 | 432 | 400 | 416 | 12 | Downed panel |
| A15 | Revive progress | 432 | 332 | 432 | 356 | 416 | 32 | Downed panel |
| A16 | Finish warning | 432 | 372 | 432 | 312 | 416 | 36 | Downed panel |
| A17 | Downed controls | 432 | 416 | 432 | 284 | 416 | 20 | Downed panel |

### Body search with owner inventory

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Body search panel | 395 | 92 | 558 | 92 | 327 | 536 | Frame |
| A02 | Search header | 395 | 92 | 558 | 592 | 327 | 36 | Body search panel |
| A03 | Search title | 406 | 92 | 648 | 592 | 226 | 36 | Search header |
| A04 | Item count | 638 | 92 | 569 | 592 | 73 | 36 | Search header |
| A05 | Body grid | 406 | 128 | 569 | 134 | 305 | 458 | Body search panel |
| A06 | Search footer | 395 | 592 | 558 | 92 | 327 | 36 | Body search panel |
| A07 | Search error | 406 | 599 | 739 | 99 | 135 | 22 | Search footer |
| A08 | Search close | 548 | 599 | 660 | 99 | 72 | 22 | Search footer |
| A09 | Take hint | 627 | 599 | 569 | 99 | 84 | 22 | Search footer |
| A10 | Inventory panel | 731 | 92 | 25 | 92 | 524 | 536 | Frame |
| A11 | Inventory header | 731 | 92 | 25 | 592 | 524 | 36 | Inventory panel |
| A12 | Bag title | 743 | 92 | 461 | 592 | 76 | 36 | Inventory header |
| A13 | Bag value | 943 | 92 | 232 | 592 | 105 | 36 | Inventory header |
| A14 | Equipment title | 1060 | 92 | 37 | 592 | 183 | 36 | Inventory header |
| A15 | Bag grid | 743 | 128 | 232 | 134 | 305 | 458 | Inventory panel |
| A16 | Equipment column | 1060 | 128 | 37 | 187 | 183 | 405 | Inventory panel |
| A17 | Primary | 1060 | 128 | 37 | 504 | 183 | 88 | Equipment column |
| A18 | Secondary | 1060 | 223 | 37 | 409 | 183 | 88 | Equipment column |
| A19 | Armor | 1060 | 318 | 132 | 314 | 88 | 88 | Equipment column |
| A20 | Bag slot | 1155 | 318 | 37 | 314 | 88 | 88 | Equipment column |
| A21 | Pouch label | 1060 | 412 | 148 | 292 | 72 | 16 | Equipment column |
| A22 | Pouch | 1060 | 432 | 148 | 188 | 72 | 100 | Equipment column |
| A23 | Pocket 1 | 1142 | 432 | 88 | 238 | 50 | 50 | Equipment column |
| A24 | Pocket 2 | 1193 | 432 | 37 | 238 | 50 | 50 | Equipment column |
| A25 | Pocket 3 | 1142 | 483 | 88 | 187 | 50 | 50 | Equipment column |
| A26 | Pocket 4 | 1193 | 483 | 37 | 187 | 50 | 50 | Equipment column |
| A27 | Inventory footer | 731 | 592 | 25 | 92 | 524 | 36 | Inventory panel |
| A28 | Selected item | 743 | 599 | 333 | 99 | 204 | 22 | Inventory footer |
| A29 | Back | 956 | 599 | 244 | 99 | 80 | 22 | Inventory footer |
| A30 | Close hint | 1044 | 599 | 148 | 99 | 88 | 22 | Inventory footer |
| A31 | Select hint | 1140 | 599 | 37 | 99 | 103 | 22 | Inventory footer |

### Owner inventory

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Inventory panel | 731 | 92 | 25 | 92 | 524 | 536 | Frame |
| A02 | Inventory header | 731 | 92 | 25 | 592 | 524 | 36 | Inventory panel |
| A03 | Bag title | 743 | 92 | 461 | 592 | 76 | 36 | Inventory header |
| A04 | Bag value | 943 | 92 | 232 | 592 | 105 | 36 | Inventory header |
| A05 | Equipment title | 1060 | 92 | 37 | 592 | 183 | 36 | Inventory header |
| A06 | Bag grid | 743 | 128 | 232 | 134 | 305 | 458 | Inventory panel |
| A07 | Equipment column | 1060 | 128 | 37 | 187 | 183 | 405 | Inventory panel |
| A08 | Primary | 1060 | 128 | 37 | 504 | 183 | 88 | Equipment column |
| A09 | Secondary | 1060 | 223 | 37 | 409 | 183 | 88 | Equipment column |
| A10 | Armor | 1060 | 318 | 132 | 314 | 88 | 88 | Equipment column |
| A11 | Bag slot | 1155 | 318 | 37 | 314 | 88 | 88 | Equipment column |
| A12 | Pouch label | 1060 | 412 | 148 | 292 | 72 | 16 | Equipment column |
| A13 | Pouch | 1060 | 432 | 148 | 188 | 72 | 100 | Equipment column |
| A14 | Pocket 1 | 1142 | 432 | 88 | 238 | 50 | 50 | Equipment column |
| A15 | Pocket 2 | 1193 | 432 | 37 | 238 | 50 | 50 | Equipment column |
| A16 | Pocket 3 | 1142 | 483 | 88 | 187 | 50 | 50 | Equipment column |
| A17 | Pocket 4 | 1193 | 483 | 37 | 187 | 50 | 50 | Equipment column |
| A18 | Inventory footer | 731 | 592 | 25 | 92 | 524 | 36 | Inventory panel |
| A19 | Selected item | 743 | 599 | 333 | 99 | 204 | 22 | Inventory footer |
| A20 | Back | 956 | 599 | 244 | 99 | 80 | 22 | Inventory footer |
| A21 | Close hint | 1044 | 599 | 148 | 99 | 88 | 22 | Inventory footer |
| A22 | Select hint | 1140 | 599 | 37 | 99 | 103 | 22 | Inventory footer |

### Pause menu

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Pause dim | 0 | 0 | 0 | 0 | 1280 | 720 | Frame |
| A02 | Pause panel | 460 | 160 | 460 | 160 | 360 | 400 | Pause dim |
| A03 | Pause title | 484 | 184 | 484 | 500 | 312 | 36 | Pause panel |
| A04 | Pause context | 484 | 228 | 484 | 452 | 312 | 40 | Pause panel |
| A05 | Resume | 484 | 280 | 484 | 400 | 312 | 40 | Pause panel |
| A06 | Settings | 484 | 332 | 484 | 348 | 312 | 40 | Pause panel |
| A07 | Leave to Lobby | 484 | 384 | 484 | 296 | 312 | 40 | Pause panel |
| A08 | Quit | 484 | 436 | 484 | 244 | 312 | 40 | Pause panel |
| A09 | Pause feedback | 484 | 488 | 484 | 184 | 312 | 48 | Pause panel |

### Surrender prompt

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Net stats | 24 | 16 | 1056 | 688 | 200 | 16 | Frame |
| A02 | Minimap | 24 | 40 | 1056 | 510 | 200 | 170 | Frame |
| A03 | Role badge | 240 | 40 | 928 | 652 | 112 | 28 | Frame |
| A04 | Mask timer | 240 | 74 | 928 | 618 | 112 | 28 | Frame |
| A05 | Notoriety | 240 | 108 | 928 | 584 | 112 | 28 | Frame |
| A06 | Safety | 240 | 142 | 928 | 550 | 112 | 28 | Frame |
| A07 | Compass | 360 | 24 | 360 | 664 | 560 | 32 | Frame |
| A08 | Heist alert | 440 | 64 | 440 | 612 | 400 | 44 | Frame |
| A09 | Notifications | 456 | 116 | 456 | 492 | 368 | 112 | Frame |
| A10 | Cash | 1080 | 24 | 24 | 652 | 176 | 44 | Frame |
| A11 | Party and self | 24 | 534 | 1016 | 24 | 240 | 162 | Frame |
| A12 | Party member 1 | 24 | 534 | 1016 | 138 | 240 | 48 | Party and self |
| A13 | Party member 2 | 24 | 588 | 1016 | 84 | 240 | 48 | Party and self |
| A14 | Self health | 24 | 642 | 1016 | 24 | 240 | 54 | Party and self |
| A15 | Hotbar | 812 | 630 | 24 | 24 | 444 | 66 | Frame |
| A16 | Slot 1 | 812 | 630 | 392 | 24 | 76 | 66 | Hotbar |
| A17 | Slot 2 | 894 | 630 | 310 | 24 | 76 | 66 | Hotbar |
| A18 | Slot 3 | 976 | 630 | 262 | 24 | 42 | 66 | Hotbar |
| A19 | Slot 4 | 1024 | 630 | 214 | 24 | 42 | 66 | Hotbar |
| A20 | Slot 5 | 1072 | 630 | 166 | 24 | 42 | 66 | Hotbar |
| A21 | Slot 6 | 1120 | 630 | 118 | 24 | 42 | 66 | Hotbar |
| A22 | Bag value and hint | 1168 | 630 | 24 | 24 | 88 | 66 | Hotbar |
| A23 | Surrender panel | 416 | 414 | 416 | 122 | 448 | 184 | Frame |
| A24 | Surrender title | 432 | 430 | 432 | 262 | 416 | 28 | Surrender panel |
| A25 | Surrender terms | 432 | 466 | 432 | 206 | 416 | 48 | Surrender panel |
| A26 | Cancel surrender | 432 | 534 | 704 | 146 | 144 | 40 | Surrender panel |
| A27 | Confirm surrender | 680 | 534 | 432 | 146 | 168 | 40 | Surrender panel |

### Death and respawn

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | World dim | 0 | 0 | 0 | 0 | 1280 | 720 | Frame |
| A02 | Death panel | 408 | 238 | 408 | 238 | 464 | 244 | World dim |
| A03 | Overlay title | 432 | 262 | 432 | 426 | 416 | 32 | Death panel |
| A04 | Outcome summary | 432 | 306 | 432 | 370 | 416 | 44 | Death panel |
| A05 | Overlay status | 432 | 362 | 432 | 326 | 416 | 32 | Death panel |
| A06 | Overlay footer | 432 | 418 | 432 | 262 | 416 | 40 | Death panel |

### Arrest receipt

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | World dim | 0 | 0 | 0 | 0 | 1280 | 720 | Frame |
| A02 | Arrest panel | 408 | 238 | 408 | 238 | 464 | 244 | World dim |
| A03 | Overlay title | 432 | 262 | 432 | 426 | 416 | 32 | Arrest panel |
| A04 | Outcome summary | 432 | 306 | 432 | 370 | 416 | 44 | Arrest panel |
| A05 | Overlay status | 432 | 362 | 432 | 326 | 416 | 32 | Arrest panel |
| A06 | Overlay footer | 432 | 418 | 432 | 262 | 416 | 40 | Arrest panel |

### Map transfer

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | World dim | 0 | 0 | 0 | 0 | 1280 | 720 | Frame |
| A02 | Transfer panel | 408 | 238 | 408 | 238 | 464 | 244 | World dim |
| A03 | Overlay title | 432 | 262 | 432 | 426 | 416 | 32 | Transfer panel |
| A04 | Outcome summary | 432 | 306 | 432 | 370 | 416 | 44 | Transfer panel |
| A05 | Overlay status | 432 | 362 | 432 | 326 | 416 | 32 | Transfer panel |
| A06 | Overlay footer | 432 | 418 | 432 | 262 | 416 | 40 | Transfer panel |

The HUD holds the minimap at (24,40), matching Godot's 200 × 170 texture. Strip labels at 45° and ticks at 15° move at 4 px per degree beneath the fixed center tick. Reserve the 44 px heist alert band. Notification tray accepts four 24 px lines with 4 px gaps, ordering oldest above newest. Each notification uses a single display line and a full accessible name. Position self health consistently at y=642. Occupied party rows start at y=534. Do not move self when party members are missing or away.

The interact card is a fixed screen prompt, four possible 24 px action rows with a 24 px title and 8 px insets. Body-search uses the active task's proposed external panel geometry at right 558 alongside the unchanged owner panel at right 25, giving a 9 px gap. Current release candidate centered search stays usable until the external panel task lands. A bag cell at column c and row r begins at `(743 + 51c, 128 + 51r)`; body cell substitutes x origin 406. Use c=0–5, r=0–8, 50 × 50 cells and 1 px gaps. Item footprints use `(51w − 1) × (51h − 1)`. Gear slots and footer anchors follow the existing inventory design. Intentional group containment is shown in each table. Surrender and pause confirmations reuse button sizes and modal hierarchy from [components](components.md). Pause confirmations use the [settings dialog geometry](03-settings.md#settings-confirmation).

## 4. States

### Live surfaces

| Element | When ready | Empty, loading, disabled or error |
|---|---|---|
| Network | Show integer FPS and ping in ms. | Dash for unavailable data. Do not fabricate packet loss. |
| Minimap | Godot world texture, thin frame, orientation marker and arrow. Default north-up and an arrow based on `heading`. Optional rotating minimap rotates in Godot and fixes the arrow up. | Show frame with “Map unavailable” after usable local spawn if texture is absent. Clear on transfer. |
| Compass | Cardinal labels and current heading with center tick. | Hide when preference is off. Without heading show dash; no inferred direction. |
| Role / timer | Citizen, Criminal · Masked, Cop · On duty. During the 3 s masking channel show mm:ss with ceil rounding and “Masking.” Once masked, hide channel timer and retain masked role. | Unknown role uses “Role unavailable.” No permanent countdown after masking. |
| Safety | “Safezone” if true, “Weapons locked” in other locked instances where supplied. | Hidden in combat or when field absent. Server still rejects disallowed fire. |
| Cash / notoriety / bag | Format integer currency for cash and bag. Notoriety displays raw score while Criminal. | Currency zero shows $0, empty bag $0. During missing snapshot use dash, not zero. |
| Party and self | Up to two other members and self. Four health segments represent each 25% band; fill partial segment proportionally. Include current and max HP. Label leader, Away, Downed or Dead. | Empty slots disappear. Away uses no meter; self missing snapshot uses dash. Optional low-health tint below 30% plus “Low health.” |
| Hotbar | Always six regions, 1 and 2 wider. Selected via amber edge and selection marker. Include quantity when present. Show BAG value beside `TAB` or live binding chip. | Empty entries show slot key and empty pattern. Existing slot 1 stays active until switching is supported. |
| Interaction | Context from Godot. Label each key/action. Clear prompt when no authorized action or input goes to panel. | Unavailable action reason appears when host supplies one. Older snapshots with no prompt show nothing. |
| Heist alert | Server-scoped recipient receives location label and seconds left when supplied. Use inset edge and “Heist alert.” | Hide when empty or expired. Retain ordinary toasts separately. |
| Notifications | Authoritative snapshot up to four short messages. Default 4 s, honor supported preference. | Busy updates replace snapshot. Error toast includes action outcome. Empty tray is hidden. |

### Life and outcome surfaces

- **Downed.** Available in LootyBay under current rules. Overlay keeps movement view and shows server-derived bleed-out from 60 s, a 5 s penalty per hit, revive progress when supplied and an explicit “Finish in progress” warning when server reports an active channel. Show “At risk of being finished” if no active finish is announced. Revive duration 5 s, finish 2 s, cuff 3 s. When event is unknown show dash and await current snapshot. Hide weapon, inventory and world interaction. Crawl is the only movement mode. Server can route a second down within 30 s of revive directly to death. No local bleed-out transition at zero.
- **Death.** Show “You died,” available cause, and automatic Motel respawn status. Show any precise setback only from authoritative outcome data. Criminal death drops remaining inventory and ends Criminal role. Cop death ends duty and clears issued kit. Host can show receipt for up to 900 ms while load already starts. Do not gate actual respawn on a UI timer. If the spawn arrives sooner, keep receipt as a normal notification after transfer.
- **Surrender.** Show hint only if Godot can provide current eligibility to an ALIVE Criminal in range of an ALIVE Cop. Proposed 6 m and LOS preflight is presentation only; server validates. Confirmation gives bag loss, gear retained and return to Motel. Cancel ends prompt. On confirmation lock buttons until server result. Denial restores movement and displays concise reason. If eligibility changes before confirmation, cancel and recapture.
- **Arrest.** Show cuff or surrender receipt only on server outcome. Explain bag forfeited, gear retained, Citizen at Motel. Cuff skips the surrender prompt. Show receipt up to 900 ms within loading. No jail duration is assumed. Cop-side payout feedback uses existing notifications.
- **Transfer.** Display target map, reason and loading/waiting status. Use loader progress from Godot when available. Keep stage changes discrete. Client load + server ack remains authoritative, with 10 s server timeout. Await local spawn and matching state. Timeout, failure or disconnect yields terminal feedback with Return to Lobby when the host can offer it. There is no client-side automatic transfer retry.
- **Pause.** Pause opens over the world with the hint “Session continues.” Resume, Settings, Leave to Lobby, Quit. For leave or quit open a confirmation with Cancel as default. A failed leave retains the menu if still connected and shows one error. While paused, the server continues play and state changes can close the menu. Settings opened from pause keeps the same game input gate.

### Inventory and body search

- **Owner inventory.** Existing header, gear order, 6 × 9 bag, footer and transparent outer surface. Show neutral tiles for empty cells. On loading retain panel with empty tile skeleton and no input. If inventory data becomes unavailable while open, leave Close enabled and show unavailable in footer. Select any existing tile to update details. Item rarity comes from its value. Drag within the bag only using pointer events with 4 px activation, valid target marker, checked footprint and optimistic movement. Swap with one other item only if both resulting footprints fit, clear each other and clear all remaining items. Use original w/h and grab offset. Reconcile with next server snapshot. On immediate IPC error revert to committed snapshot; on no refresh after 5 s return to last confirmed inventory and show “Move could not be confirmed.” No rotate, equip, drop, use or cross-panel drag.
- **Body search.** Open only after server grants session. Criminals may search downed bodies; Cops may search downed Criminals and take through seizure. Citizens cannot search. Server excludes issued gear. Use the existing search request and per-UID pending state. Body items pack row-first with their sizes. Activate tile to take or seize. Empty text inside body grid, failure in footer. On “Bag full,” keep search open and preserve items. If another viewer takes the item, authoritative removal wins. Close on target change, range/LOS failure, life change or transfer. Pending states never prove ownership.
- **Availability.** Inventory is alive-gated in the proposed input policy. Search uses server validation and remains visually distinct from normal bag move. If two panel snapshots arrive apart, show placeholder for the missing half and lock its actions.

### Role and life visibility matrix

**✓** persistent, **C** conditional on context/data, **—** hidden. DEAD, arrested and transfer columns describe their dominant overlay. Arrest is an outcome, outside the life enum.

| Element | Citizen alive | Criminal alive | Cop alive | Downed Criminal | Downed Cop | Dead | Arrested | Transfer |
|---|---|---|---|---|---|---|---|---|
| Net, minimap, compass, cash | ✓ | ✓ | ✓ | ✓ | ✓ | — | — | — |
| Role, party and self health | ✓ | ✓ | ✓ | ✓ | ✓ | — | — | — |
| Notoriety | — | ✓ | — | — | — | — | — | — |
| Masking timer | C | — | — | — | — | — | — | — |
| Safety | C | C | C | C | C | — | — | — |
| Hotbar and bag value | ✓ | ✓ | ✓ | — | — | — | — | — |
| Context card | C | C | C | — | — | — | — | — |
| Heist alert | — | C | C | — | — | — | — | — |
| ordinary toasts | C | C | C | C | C | — | — | — |
| Downed bleed-out, revive, finish | — | — | — | ✓ / C / C | ✓ / C / C | — | — | — |
| Surrender prompt | — | C | — | — | — | — | — | — |
| Body search | — | C | C | — | — | — | — | — |
| Inventory | C | C | C | — | — | — | — | — |
| Pause | C | C | C | C | C | — | — | — |
| Outcome or transfer | — | — | — | — | — | ✓ | ✓ | ✓ |

Compass, texture readiness and display preferences can suppress persistent elements. Current rules do not normally produce a downed Citizen. If that state arrives, use the same downed visibility and no search or surrender. Panels override live elements: inventory and combined search hide HUD, pause dims underlying HUD and suppresses contextual hints and toasts, surrender keeps stable read-only HUD and hides duplicate interact/surrender hints. Transfer supersedes competing prompts and keeps valid queued outcome summary inside transfer status.

## 5. Interactions

Gameplay HUD does not receive mouse input. Godot handles movement, look, gate checks, hotbar and world actions. Use existing key hints on interact rows and replace their displayed text with current bindings when available. Fields like cash and HP have no click target. Page panels take cursor focus. For owner inventory focus route root first, then bag items by slot order, equipment by slot order, footer Back. With default Tab, Shift+Tab from root enters focus targets, and Tab moves between targets once focus is inside; bound inventory key or Esc close according to [flow](flow.md). Enter or Space selects focused item. Keep drag pointer based with native HTML5 drag disabled; geometry cancels CSS zoom on the pointer-positioned drag overlay. Esc cancels active drag before close. Pointer cancellation clears tentative tile state.

For body search, focus title then item tiles in row order, footer Close, owner's inventory controls. Bound search-close key and Esc close search. Enter or Space takes selected body tile. T can take first item in developer builds if enabled and always uses the active session. For surrender, focus Cancel, then Confirm; H confirms only on second press after key release. In pause, focus Resume, Settings, Leave to Lobby, Quit. In confirmation, focus Cancel before destructive action. Transfer error focuses Return to Lobby. Restore gameplay capture only after Godot clears active route. Gamepad later.

## 6. Data

Read `hud` → `HudState` including `net`, `heading`, `role`, `life`, `timer`, `safety`, `cash`, `bag`, `notoriety`, `health`, `maxHealth`, `self`, `party`, `interact`, `hotbar`, `activeSlot`, `notifications`, `surrenderAvailable`, `heistAlert` and `channels`. Read `inventory` → `InventoryView` and `search` → `SearchView`. A null search clears target and UI. Read `game_overlay` → `GameOverlayView` and `transfer` → `TransferView`. Send `inventory.move`, `inventory.close`, `search.take`, `search.close`, `surrender.confirm`, `surrender.cancel`, `pause.resume`, `settings.open`, `session.leave`, `app.quit` and `transfer.return_to_lobby`. Observe host `route`. View-only roles or overlays produce no gameplay requests. Existing host key actions stay outside page IPC.

## 7. Godot side

[Hud.gd](../../ui/hud/Hud.gd) builds owner snapshots, item views and panel routes; [Minimap.gd](../../ui/hud/Minimap.gd) renders real world geometry; [Main.gd](../../main/Main.gd) supplies ping, targeting, connection and panel wiring. [Player.gd](../../features/player/Player.gd) and [PlayerRoleController.gd](../../features/player/PlayerRoleController.gd) supply health, life and role. [PlayerService.gd](../../features/player/PlayerService.gd) owns money, death, surrender and transfer initiation. [DownedService.gd](../../features/downed/DownedService.gd) owns body/search rules and channels. [ItemUtils.gd](../../lib/utils/ItemUtils.gd) supplies item footprints. [PartyService.gd](../../features/party/PartyService.gd) owns membership. [TransferService.gd](../../features/transfer/TransferService.gd) owns reservations and timeout. [Lootable.gd](../../features/heist/Lootable.gd) emits loud alert to scoped recipients and [Instance.gd](../../features/instance/Instance.gd) currently prints it. **NEW** Main and Hud adapt existing signals and authorized outcomes into structured life/transfer/safety/alert display. **NEW** Publish channel presentation to the affected player without extending gameplay authority to the browser.

## 8. Accessibility

Body text ≥4.5:1 against local backing. Smallest label ≥11 px, common 14 px. Explain severity with text plus shape. Four numeric health segments, role names, masking labels, and countdown captions remain legible across colorblind modes. Announce downed, revive start, finishing warning, arrest, transfer failure and death once. Do not announce HP, heading, FPS or countdown every frame. Critical visual states use stable shapes and text, no flash. Active items show a border and explicit selected state. Item buttons include action, name, and rarity when meaningful. Shared focus ring and reasonable focus recovery for every interactive overlay.

## 9. Open questions

1. Confirm “Masking” means the 3 s channel only. Decide whether any future mask expiry needs a separate field. Current Criminal role has no countdown.
2. Confirm safety copy for House and Center. They lock weapons under combat logic while the instance safezone flag currently describes Motel.
3. Confirm the authorized Cop/Criminal heist alert audience and presentation lifetime. Keep current scoped transport and approach pending gameplay decision.
4. Decide whether release channels require physically holding the binding. Current key handlers begin a server-timed channel on press; the downed design describes hold-interact.
5. Approve optional arrest/death receipt timing and precise client display priority if spawn arrives first. Keep server transfer independent.
6. Confirm the external search task lands before this design ships. Decide how to handle body items whose footprints overflow the 6 × 9 body grid and what status to announce. Owner inventory changes, such as a future keyboard placement mode or equipment rule, require separate approval.
7. Confirm surrender prompt eligibility snapshot source and server outcome event. Existing surrender requests directly on H and error feedback is text.
8. Confirm focus and captured input on Windows CEF in a two-client smoke. Verify that Tab, Escape, drag and panel dismissal never leak movement or fire.
