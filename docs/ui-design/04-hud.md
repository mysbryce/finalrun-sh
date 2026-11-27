# 04 · HUD and in-game overlays

## 1. Purpose and entry/exit

Use `/` for live and downed HUD. The host opens `/inventory`, `/search`, `/pause`, `/death`, `/arrest` and `/transfer` and owns return routing. The bound H action sends surrender directly through Godot. Pause contains in-game party management and incoming invitations while the session continues. An authoritative outcome receipt can remain above a newly spawned HUD for the remainder of its 900 ms lifetime. Godot clears stale panels on life, transfer or connection changes.

## 2. ASCII wireframes

### Live HUD

[Open SVG](wireframes/04-hud.svg)

```text
+-----------------------------------------------------------------------------------------------+
| +--------------++A03----++Compass----------------------------------+           +Cash--------+ |
| |Minimap       |+-------++-----+-----------------------------+-----+           +------------+ |
| |              |+A04----+      |Heist alert                  |                                |
| |              |+A05----+      ++---------------------------++                                |
| |              |+Safety---------|Notifications              |                                 |
| |              |+---------------|                           |                                 |
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
| |Minimap       |+-------++-----+-----------------------------+-----+           +------------+ |
| |              |               |Heist alert                  |                                |
| |              |               ++---------------------------++                                |
| |              |+Safety---------|Notifications              |                                 |
| |              |+---------------|                           |                                 |
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
[A06 Heist alert]
[A07 Notifications]
[A08 Cash]
[A09 Party and self]
  [A10 Party member 1]
  [A11 Party member 2]
  [A12 Self health]
[A13 Downed panel]
  [A14 Downed title]
  [A15 Bleed-out progress]
  [A16 Revive progress]
  [A17 Finish warning]
  [A18 Downed controls]
```

### Body search with owner inventory

[Open SVG](wireframes/04-inventory-search.svg)

```text
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|                                                                                               |
|                             +Search title----++A04-++++A13-+---------+A14----++A15---------++ |
|                             +----------------------++++----------------------++------------++ |
|                             |Body grid             ||||Bag grid              ||Primary     || |
|                             |                      ||||                      ||            || |
|                             |                      ||||                      ||            || |
|                             |                      ||||                      |+------------+| |
|                             |                      ||||                      ||Secondary   || |
|                             |                      ||||                      ||            || |
|                             |                      ||||                      |+-----++-----+| |
|                             |                      ||||                      ||A20  ||A21  || |
|                             |                      ||||                      ||     ||     || |
|                             |                      ||||                      |+A22-+++-----+| |
|                             |                      ||||                      |+----++--+---+| |
|                             |                      ||||                      ||A23 ||  |A25|| |
|                             |                      ||||                      ||    |+--+---+| |
|                             |                      ||||                      |+----+|  |A27|| |
|                             |                      ||||                      |+-----+--+---+| |
|                             +----------------------+||+----------------------+              | |
|                             +A08-------+A09-++A10--++++Selected item-++Back-+A31---++A32---++ |
|                             +----------+----++-----++++--------------++-----+------++------++ |
|                                                                                               |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+

[A01 Body search panel]
  [A02 Search header]
    [A03 Search title]
    [A04 Item count]
  [A05 Body grid]
  [A06 Body scrollbar]
  [A07 Search footer]
    [A08 Search error]
    [A09 Search close]
    [A10 Take hint]
[A11 Inventory panel]
  [A12 Inventory header]
    [A13 Bag title]
    [A14 Bag value]
    [A15 Equipment title]
  [A16 Bag grid]
  [A17 Equipment column]
    [A18 Primary]
    [A19 Secondary]
    [A20 Armor]
    [A21 Bag slot]
    [A22 Pouch label]
    [A23 Pouch]
    [A24 Pocket 1]
    [A25 Pocket 2]
    [A26 Pocket 3]
    [A27 Pocket 4]
  [A28 Inventory footer]
    [A29 Selected item]
    [A30 Back]
    [A31 Close hint]
    [A32 Select hint]
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
|                                             ++Party title----------------++                   |
|                                             |+---------------------------+|                   |
|                +-+-----------------------++ |+Party feedback-------------+|                   |
|                | |Pause title            || |+---------------------------+|                   |
|                | +Pause context----------+| |++A15--------------++A16---++|                   |
|                | +-----------------------+| |++-----------------++------++|                   |
|                | +Resume-----------------+| |||A18              ||A19   |||                   |
|                | +-----------------------+| |++A21--------------++A22---++|                   |
|                | +Settings---------------+| ||+-----------------++------+||                   |
|                | +-----------------------+| |+Server player picker-------+|                   |
|                | |Leave to Lobby         || |+---------------------------+|                   |
|                | +-----------------------+| |++Invite sender------------++|                   |
|                | |Quit                   || ||+A26----++A27----+--------+||                   |
|                | +-----------------------+| ||+-------++-------+         ||                   |
|                | |Pause feedback         || |+A29----------+Leave party--+|                   |
|                +-+-----------------------++ |+-------------+-------------+|                   |
|                                             |+Party action feedback------+|                   |
|                                             |+---------------------------+|                   |
|                                             +-----------------------------+                   |
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
  [A10 Party panel]
    [A11 Party title]
    [A12 Party feedback]
    [A13 Party slots]
      [A14 Member 1]
        [A15 Member 1 identity]
        [A16 Member 1 kick]
      [A17 Member 2]
        [A18 Member 2 identity]
        [A19 Member 2 kick]
      [A20 Member 3]
        [A21 Member 3 identity]
        [A22 Member 3 kick]
    [A23 Server player picker]
    [A24 Incoming invite]
      [A25 Invite sender]
      [A26 Accept invite]
      [A27 Decline invite]
    [A28 Party actions]
      [A29 Create or invite]
      [A30 Leave party]
      [A31 Party action feedback]
```

### Direct surrender availability

[Open SVG](wireframes/04-surrender.svg)

```text
+-----------------------------------------------------------------------------------------------+
| +--------------++A03----++Compass----------------------------------+           +Cash--------+ |
| |Minimap       |+-------++-----+-----------------------------+-----+           +------------+ |
| |              |+A04----+      |Heist alert                  |                                |
| |              |+A05----+      ++---------------------------++                                |
| |              |+Safety---------|Notifications              |                                 |
| |              |+---------------|                           |                                 |
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

### Outcome receipt over the new HUD

[Open SVG](wireframes/04-hud-receipt.svg)

```text
+-----------------------------------------------------------------------------------------------+
| +--------------++A03----++Compass----------------------------------+           +Cash--------+ |
| |Minimap       |+-------++-----+-----------------------------+-----+           +------------+ |
| |              |+A04----+      |Heist alert                  |                                |
| |              |+A05----+      ++---------------------------++                                |
| |              |+Safety---------|Notifications              |                                 |
| |              |+---------------|                           |                                 |
| +--------------+                |                           |                                 |
|                                 +---------------------------+                                 |
|                              ++Receipt title------------------++                              |
|                              |+-------------------------------+|                              |
|                              |+Receipt summary----------------+|                              |
|                              |+-------------------------------+|                              |
|                              |+Receipt dismiss----------------+|                              |
|                              |+-------------------------------+|                              |
|                              +---------------------------------+                              |
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
[A25 Receipt card]
  [A26 Receipt title]
  [A27 Receipt summary]
  [A28 Receipt dismiss]
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
|                              |+Receipt dismiss----------------+|                              |
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
    [A06 Receipt dismiss]
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
|                              |+Receipt dismiss----------------+|                              |
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
    [A06 Receipt dismiss]
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

Right and bottom are insets from the 1280 × 720 frame. Parent bounds contain their children. Each drawing is a separate state.

### Live HUD

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Net stats | 24 | 16 | 1056 | 688 | 200 | 16 | Frame |
| A02 | Minimap | 24 | 40 | 1056 | 510 | 200 | 170 | Frame |
| A03 | Role badge | 240 | 40 | 928 | 652 | 112 | 28 | Frame |
| A04 | Mask timer | 240 | 74 | 928 | 618 | 112 | 28 | Frame |
| A05 | Notoriety | 240 | 108 | 928 | 584 | 112 | 28 | Frame |
| A06 | Safety | 240 | 142 | 832 | 550 | 208 | 28 | Frame |
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
| A04 | Safety | 240 | 142 | 832 | 550 | 208 | 28 | Frame |
| A05 | Compass | 360 | 24 | 360 | 664 | 560 | 32 | Frame |
| A06 | Heist alert | 440 | 64 | 440 | 612 | 400 | 44 | Frame |
| A07 | Notifications | 456 | 116 | 456 | 492 | 368 | 112 | Frame |
| A08 | Cash | 1080 | 24 | 24 | 652 | 176 | 44 | Frame |
| A09 | Party and self | 24 | 534 | 1016 | 24 | 240 | 162 | Frame |
| A10 | Party member 1 | 24 | 534 | 1016 | 138 | 240 | 48 | Party and self |
| A11 | Party member 2 | 24 | 588 | 1016 | 84 | 240 | 48 | Party and self |
| A12 | Self health | 24 | 642 | 1016 | 24 | 240 | 54 | Party and self |
| A13 | Downed panel | 416 | 260 | 416 | 272 | 448 | 188 | Frame |
| A14 | Downed title | 432 | 272 | 432 | 420 | 416 | 28 | Downed panel |
| A15 | Bleed-out progress | 432 | 308 | 432 | 400 | 416 | 12 | Downed panel |
| A16 | Revive progress | 432 | 332 | 432 | 356 | 416 | 32 | Downed panel |
| A17 | Finish warning | 432 | 372 | 432 | 312 | 416 | 36 | Downed panel |
| A18 | Downed controls | 432 | 416 | 432 | 284 | 416 | 20 | Downed panel |

### Body search with owner inventory

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Body search panel | 395 | 92 | 558 | 92 | 327 | 536 | Frame |
| A02 | Search header | 395 | 92 | 558 | 592 | 327 | 36 | Body search panel |
| A03 | Search title | 406 | 92 | 648 | 592 | 226 | 36 | Search header |
| A04 | Item count | 638 | 92 | 569 | 592 | 73 | 36 | Search header |
| A05 | Body grid | 406 | 128 | 569 | 134 | 305 | 458 | Body search panel |
| A06 | Body scrollbar | 714 | 128 | 562 | 134 | 4 | 458 | Body search panel |
| A07 | Search footer | 395 | 592 | 558 | 92 | 327 | 36 | Body search panel |
| A08 | Search error | 406 | 599 | 739 | 99 | 135 | 22 | Search footer |
| A09 | Search close | 548 | 599 | 660 | 99 | 72 | 22 | Search footer |
| A10 | Take hint | 627 | 599 | 569 | 99 | 84 | 22 | Search footer |
| A11 | Inventory panel | 731 | 92 | 25 | 92 | 524 | 536 | Frame |
| A12 | Inventory header | 731 | 92 | 25 | 592 | 524 | 36 | Inventory panel |
| A13 | Bag title | 743 | 92 | 461 | 592 | 76 | 36 | Inventory header |
| A14 | Bag value | 943 | 92 | 232 | 592 | 105 | 36 | Inventory header |
| A15 | Equipment title | 1060 | 92 | 37 | 592 | 183 | 36 | Inventory header |
| A16 | Bag grid | 743 | 128 | 232 | 134 | 305 | 458 | Inventory panel |
| A17 | Equipment column | 1060 | 128 | 37 | 187 | 183 | 405 | Inventory panel |
| A18 | Primary | 1060 | 128 | 37 | 504 | 183 | 88 | Equipment column |
| A19 | Secondary | 1060 | 223 | 37 | 409 | 183 | 88 | Equipment column |
| A20 | Armor | 1060 | 318 | 132 | 314 | 88 | 88 | Equipment column |
| A21 | Bag slot | 1155 | 318 | 37 | 314 | 88 | 88 | Equipment column |
| A22 | Pouch label | 1060 | 412 | 148 | 292 | 72 | 16 | Equipment column |
| A23 | Pouch | 1060 | 432 | 148 | 188 | 72 | 100 | Equipment column |
| A24 | Pocket 1 | 1142 | 432 | 88 | 238 | 50 | 50 | Equipment column |
| A25 | Pocket 2 | 1193 | 432 | 37 | 238 | 50 | 50 | Equipment column |
| A26 | Pocket 3 | 1142 | 483 | 88 | 187 | 50 | 50 | Equipment column |
| A27 | Pocket 4 | 1193 | 483 | 37 | 187 | 50 | 50 | Equipment column |
| A28 | Inventory footer | 731 | 592 | 25 | 92 | 524 | 36 | Inventory panel |
| A29 | Selected item | 743 | 599 | 333 | 99 | 204 | 22 | Inventory footer |
| A30 | Back | 956 | 599 | 244 | 99 | 80 | 22 | Inventory footer |
| A31 | Close hint | 1044 | 599 | 148 | 99 | 88 | 22 | Inventory footer |
| A32 | Select hint | 1140 | 599 | 37 | 99 | 103 | 22 | Inventory footer |

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
| A02 | Pause panel | 232 | 160 | 688 | 160 | 360 | 400 | Pause dim |
| A03 | Pause title | 256 | 184 | 712 | 500 | 312 | 36 | Pause panel |
| A04 | Pause context | 256 | 228 | 712 | 452 | 312 | 40 | Pause panel |
| A05 | Resume | 256 | 280 | 712 | 400 | 312 | 40 | Pause panel |
| A06 | Settings | 256 | 332 | 712 | 348 | 312 | 40 | Pause panel |
| A07 | Leave to Lobby | 256 | 384 | 712 | 296 | 312 | 40 | Pause panel |
| A08 | Quit | 256 | 436 | 712 | 244 | 312 | 40 | Pause panel |
| A09 | Pause feedback | 256 | 488 | 712 | 184 | 312 | 48 | Pause panel |
| A10 | Party panel | 616 | 112 | 264 | 80 | 400 | 528 | Pause dim |
| A11 | Party title | 632 | 128 | 280 | 564 | 368 | 28 | Party panel |
| A12 | Party feedback | 632 | 164 | 280 | 516 | 368 | 40 | Party panel |
| A13 | Party slots | 632 | 216 | 280 | 356 | 368 | 148 | Party panel |
| A14 | Member 1 | 632 | 216 | 280 | 460 | 368 | 44 | Party slots |
| A15 | Member 1 identity | 640 | 220 | 394 | 464 | 246 | 36 | Member 1 |
| A16 | Member 1 kick | 894 | 220 | 288 | 464 | 98 | 36 | Member 1 |
| A17 | Member 2 | 632 | 268 | 280 | 408 | 368 | 44 | Party slots |
| A18 | Member 2 identity | 640 | 272 | 394 | 412 | 246 | 36 | Member 2 |
| A19 | Member 2 kick | 894 | 272 | 288 | 412 | 98 | 36 | Member 2 |
| A20 | Member 3 | 632 | 320 | 280 | 356 | 368 | 44 | Party slots |
| A21 | Member 3 identity | 640 | 324 | 394 | 360 | 246 | 36 | Member 3 |
| A22 | Member 3 kick | 894 | 324 | 288 | 360 | 98 | 36 | Member 3 |
| A23 | Server player picker | 632 | 376 | 280 | 308 | 368 | 36 | Party panel |
| A24 | Incoming invite | 632 | 424 | 280 | 216 | 368 | 80 | Party panel |
| A25 | Invite sender | 640 | 430 | 288 | 266 | 352 | 24 | Incoming invite |
| A26 | Accept invite | 640 | 460 | 528 | 224 | 112 | 36 | Incoming invite |
| A27 | Decline invite | 760 | 460 | 408 | 224 | 112 | 36 | Incoming invite |
| A28 | Party actions | 632 | 520 | 280 | 104 | 368 | 96 | Party panel |
| A29 | Create or invite | 632 | 520 | 472 | 160 | 176 | 40 | Party actions |
| A30 | Leave party | 816 | 520 | 280 | 160 | 184 | 40 | Party actions |
| A31 | Party action feedback | 632 | 568 | 280 | 104 | 368 | 48 | Party actions |

### Direct surrender availability

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Net stats | 24 | 16 | 1056 | 688 | 200 | 16 | Frame |
| A02 | Minimap | 24 | 40 | 1056 | 510 | 200 | 170 | Frame |
| A03 | Role badge | 240 | 40 | 928 | 652 | 112 | 28 | Frame |
| A04 | Mask timer | 240 | 74 | 928 | 618 | 112 | 28 | Frame |
| A05 | Notoriety | 240 | 108 | 928 | 584 | 112 | 28 | Frame |
| A06 | Safety | 240 | 142 | 832 | 550 | 208 | 28 | Frame |
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

### Outcome receipt over the new HUD

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Net stats | 24 | 16 | 1056 | 688 | 200 | 16 | Frame |
| A02 | Minimap | 24 | 40 | 1056 | 510 | 200 | 170 | Frame |
| A03 | Role badge | 240 | 40 | 928 | 652 | 112 | 28 | Frame |
| A04 | Mask timer | 240 | 74 | 928 | 618 | 112 | 28 | Frame |
| A05 | Notoriety | 240 | 108 | 928 | 584 | 112 | 28 | Frame |
| A06 | Safety | 240 | 142 | 832 | 550 | 208 | 28 | Frame |
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
| A25 | Receipt card | 416 | 260 | 416 | 296 | 448 | 164 | Frame |
| A26 | Receipt title | 432 | 272 | 432 | 420 | 416 | 28 | Receipt card |
| A27 | Receipt summary | 432 | 308 | 432 | 368 | 416 | 44 | Receipt card |
| A28 | Receipt dismiss | 432 | 368 | 432 | 312 | 416 | 40 | Receipt card |

### Death and respawn

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | World dim | 0 | 0 | 0 | 0 | 1280 | 720 | Frame |
| A02 | Death panel | 408 | 238 | 408 | 238 | 464 | 244 | World dim |
| A03 | Overlay title | 432 | 262 | 432 | 426 | 416 | 32 | Death panel |
| A04 | Outcome summary | 432 | 306 | 432 | 370 | 416 | 44 | Death panel |
| A05 | Overlay status | 432 | 362 | 432 | 326 | 416 | 32 | Death panel |
| A06 | Receipt dismiss | 432 | 418 | 432 | 262 | 416 | 40 | Death panel |

### Arrest receipt

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | World dim | 0 | 0 | 0 | 0 | 1280 | 720 | Frame |
| A02 | Arrest panel | 408 | 238 | 408 | 238 | 464 | 244 | World dim |
| A03 | Overlay title | 432 | 262 | 432 | 426 | 416 | 32 | Arrest panel |
| A04 | Outcome summary | 432 | 306 | 432 | 370 | 416 | 44 | Arrest panel |
| A05 | Overlay status | 432 | 362 | 432 | 326 | 416 | 32 | Arrest panel |
| A06 | Receipt dismiss | 432 | 418 | 432 | 262 | 416 | 40 | Arrest panel |

### Map transfer

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | World dim | 0 | 0 | 0 | 0 | 1280 | 720 | Frame |
| A02 | Transfer panel | 408 | 238 | 408 | 238 | 464 | 244 | World dim |
| A03 | Overlay title | 432 | 262 | 432 | 426 | 416 | 32 | Transfer panel |
| A04 | Outcome summary | 432 | 306 | 432 | 370 | 416 | 44 | Transfer panel |
| A05 | Overlay status | 432 | 362 | 432 | 326 | 416 | 32 | Transfer panel |
| A06 | Overlay footer | 432 | 418 | 432 | 262 | 416 | 40 | Transfer panel |

Keep minimap (24,40,200,170) tied to Godot. Compass uses 4 px per degree, 15° ticks and 45° labels. Heist alert line keeps its dedicated band, while the four-row toast tray uses 24 px rows and 4 px gaps. The heist toast occupies one tray row for 8 s. Self stays at y=642 with two party frames above.

Safety expands to 208 × 28 for the approved copy. Body-search panel remains right 558 and owner inventory right 25, with a 9 px gap. Bag cell origin is `(743 + 51c, 128 + 51r)`, c=0–5 and r=0–8, each 50 × 50. Footprint is `(51w − 1) × (51h − 1)`. Body uses x=406 and its independent scrolling geometry in section 4.

Pause places its existing menu at (232,160,360,400) and current in-game party panel at (616,112,400,528). The standalone death/arrest receipt uses its center panel. On spawn-first, switch to the compact receipt drawing at (416,260,448,164) above the fresh live HUD for the remaining lifetime. Each is a separate drawing. The direct-surrender drawing shows only the read-only H hint in the live HUD. Confirmations for session or party Leave/Kick reuse the shared settings-dialog bounds.

## 4. States

### Live surfaces

| Element | When ready | Empty, loading, disabled or error |
|---|---|---|
| Network | Show integer FPS and ping in ms. | Dash for unavailable data. Do not fabricate packet loss. |
| Minimap | Godot world texture, thin frame, orientation marker and arrow. Default north-up and an arrow based on `heading`. Optional rotating minimap rotates in Godot and fixes the arrow up. | Show frame with “Map unavailable” after usable local spawn if texture is absent. Clear on transfer. |
| Compass | Cardinal labels and current heading with center tick. | Hide when preference is off. Without heading show dash; no inferred direction. |
| Role / timer | Citizen, Criminal · Masked, Cop · On duty. During the 3 s masking channel show mm:ss with ceil rounding and “Masking.” Once masked, hide channel timer and retain masked role. | Unknown role uses “Role unavailable.” No permanent countdown after masking. |
| Safety | Show exactly “SAFE ZONE - weapons locked” whenever `HudState.weaponsLocked` is true. Applies to Motel, House and Center. | Hide when false or absent in an older snapshot. Server owns all weapon restrictions. |
| Cash / notoriety / bag | Format integer currency for cash and bag. Notoriety displays raw score while Criminal. | Currency zero shows $0, empty bag $0. During missing snapshot use dash, not zero. |
| Party and self | Up to two other members and self. Four health segments represent each 25% band; fill partial segment proportionally. Include current and max HP. Label leader, Away, Downed or Dead. | Empty slots disappear. Away uses no meter; self missing snapshot uses dash. Optional low-health tint below 30% plus “Low health.” |
| Hotbar | Always six regions, 1 and 2 wider. Selected via amber edge and selection marker. Include quantity when present. Show BAG value beside `TAB` or live binding chip. | Empty entries show slot key and empty pattern. Number keys 1–6 select the corresponding hotbar slot. Unavailable slot actions remain server-validated. |
| Interaction | Context from Godot. Label each key/action. Clear prompt when no authorized action or input goes to panel. | Unavailable action reason appears when host supplies one. Older snapshots with no prompt show nothing. |
| Heist alert | Keep the existing same-instance Cop/Criminal audience. Show the event as an 8 s toast and retain the separate alert line while `heistAlert.active` is true. | Deduplicate by alert ID. Toast ends after 8 s while the active line remains until server clear. Host supplies remaining toast time on replay. |
| Notifications | Authoritative snapshot up to four short messages. Default 4 s for ordinary messages, honoring the preference. Heist event toast is fixed at 8 s. | Busy updates replace snapshot. Error toast includes action outcome. Empty tray is hidden. |

### Life and outcome surfaces

- **Downed.** Available in LootyBay under current rules. Overlay keeps movement view and shows server-derived bleed-out from 60 s, a 5 s penalty per hit, revive progress when supplied and an explicit “Finish in progress” warning when server reports an active channel. Show “At risk of being finished” if no active finish is announced. Revive duration 5 s, finish 2 s, cuff 3 s. When event is unknown show dash and await current snapshot. Hide weapon, inventory and world interaction. Crawl is the only movement mode. Server can route a second down within 30 s of revive directly to death. No local bleed-out transition at zero.
- **Death.** Show “You died,” known cause and automatic Motel respawn. Criminal death drops remaining inventory and ends Criminal role. Cop death ends duty and clears issued kit. Start the receipt lifetime at the host-observed authoritative event, lasting 900 ms. Continue loading independently. If spawn arrives first, keep the same receipt above the new HUD for its remaining time, as drawn below. Escape or click dismisses it early. Host remaining time prevents replay from restarting the receipt.
- **Surrender.** The hint depends only on server-supplied `HudState.surrenderAvailable` for an ALIVE Criminal. H sends the existing server surrender request directly. Show final success or rejection from the existing notification event. Server validates life, role, Cop range and LOS at execution. Clear the hint when the snapshot revokes eligibility. Success produces the arrest receipt through the typed server outcome RPC.
- **Arrest.** A successful cuff or surrender notification starts a 900 ms receipt. Show bag forfeited, gear retained and return as Citizen to Motel. Apply the same spawn-first carry-over and Escape/click dismissal as death. Cop-side payout feedback uses existing notifications. Receipt dismissal only changes presentation.
- **Transfer.** Display target map, reason and loading/waiting status. Use loader progress from Godot when available. Keep stage changes discrete. Client load + server ack remains authoritative, with 10 s server timeout. Await local spawn and matching state. Timeout, failure or disconnect yields terminal feedback with Return to Lobby when the host can offer it. There is no client-side automatic transfer retry.
- **Pause.** Keep “Session continues,” Resume, Settings, Leave to Lobby and Quit. The adjoining Party panel is current in-game UI. It shows up to three members, leader and allowed Kick actions, a current-server player picker, Create/Invite, Leave and incoming Accept/Decline. Match display names to peer IDs, including duplicate-name disambiguation. The server supplies invite expiry. An invite notification directs the user to Escape/Pause for review. Leave/Quit and party Leave/Kick use the shared confirmation dialog. Requests lock only the affected action while pending. A downed player retains valid read-only party state and allowed Leave/Kick; current server life gates disable Create/Invite/Accept. Server life/transfer updates can evict Pause.

### Inventory and body search

- **Owner inventory.** Existing header, gear order, 6 × 9 bag, footer and transparent outer surface. Show neutral tiles for empty cells. On loading retain panel with empty tile skeleton and no input. If inventory data becomes unavailable while open, leave Close enabled and show unavailable in footer. Select any existing tile to update details. Item rarity comes from its value. Drag within the bag only using pointer events with 4 px activation, valid target marker, checked footprint and optimistic movement. Swap with one other item only if both resulting footprints fit, clear each other and clear all remaining items. Use original w/h and grab offset. Reconcile with next server snapshot. On immediate IPC error revert to committed snapshot; on no refresh after 5 s return to last confirmed inventory and show “Move could not be confirmed.” No rotate, equip, drop, use or cross-panel drag.
- **Body search.** Open only after server grants session. Criminals may search downed bodies; Cops may search downed Criminals and take through seizure. Citizens cannot search. Server excludes issued gear. Use the existing search request and per-UID pending state. Body items pack row-first into six columns with their sizes. Grow rows past nine to fit all footprints, then scroll vertically inside the fixed 305 × 458 body viewport. Preserve item UID and anchored scroll position when items change. Scroll focused items fully into view. Own bag stays six by nine. Activate tile to take or seize. Empty text inside body grid, failure in footer. On “Bag full,” keep search open and preserve items. If another viewer takes the item, authoritative removal wins. Close on target change, range/LOS failure, life change or transfer. Pending states never prove ownership.
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
| Heist alert line and event toast | — | C | C | C | C | — | — | — |
| ordinary toasts | C | C | C | C | C | — | — | — |
| Downed bleed-out, revive, finish | — | — | — | ✓ / C / C | ✓ / C / C | — | — | — |
| Direct surrender hint | — | C | — | — | — | — | — | — |
| Body search | — | C | C | — | — | — | — | — |
| Inventory | C | C | C | — | — | — | — | — |
| Pause | C | C | C | C | C | — | — | — |
| Outcome receipt | C | C | C | — | — | ✓ | ✓ | C |
| Transfer surface | — | — | — | — | — | — | — | ✓ |

Compass, texture readiness and display preferences can suppress persistent elements. Current rules do not normally produce a downed Citizen. If that state arrives, use the same downed visibility and no search or surrender. Panels override live elements: inventory and combined search hide HUD, pause dims underlying HUD and suppresses contextual hints and toasts, a server-eligible surrender hint remains read-only. An outcome receipt can remain over the fresh HUD until its existing deadline. Transfer supersedes interactive prompts and retains a current receipt above loading.



### Channel activation

Pressing an eligible action starts its server-timed channel. Moving, being hit or pressing the same key again cancels it. Keep the server as owner of completion and cancellation. [DOWNED_STATE.md](../design/DOWNED_STATE.md) describes hold-interact. Current code behavior takes precedence until an owner decision changes it. Any missing same-key cancellation path must be added in implementation, preserving the press-start interaction.

### Body scrolling geometry

The body grid has six columns and `rowCount = max(9, lastOccupiedRow + 1)` after row-first packing. Add rows until every item footprint fits. Its content height is `51 × rowCount − 1`. Viewport is always (406,128,305,458). A content cell begins at `(406 + 51c, 128 + 51r − scrollTop)` and is clipped to the viewport. Scrollbar occupies (714,128,4,458), outside the cell geometry. Owner-grid content and footprint rules stay fixed.

### In-game party state

Use the `party` push on Pause and invalidate it on disconnect. The player picker lists only current peers, displaying name plus peer ID and current eligibility. Incoming invite shows inviter, host-provided remaining seconds and Accept/Decline. Local countdown reaching zero hides its actions while the server enforces expiration. Repeated requests never extend expiry. On full party or role conflict retain the picker and show the authoritative issue. Party invite permission uses the current-session Social setting. Lobby uses the same component only after staging capability exists.

## 5. Interactions

Live HUD is read-only. Godot handles movement, look, hotbar 1–6, direct H surrender and world actions. While an outcome receipt remains above an active HUD, Godot consumes Escape or left click once to dismiss it, preventing that press from opening Pause or firing. Other movement input stays available. With a visible cursor, clicking the receipt's dismissal area sends `overlay.dismiss`. Host validates the receipt ID and clears the same deadline-owned presentation. Gamepad later.

Interactive panels take the cursor. Inventory focus is route root, bag by slot, gear by slot, Back. Default Tab toggles from the root and traverses when already inside, with Shift+Tab reversed as [flow](flow.md) specifies. Escape cancels drag before close. Drag remains pointer based, with physical-pointer overlays compensating for page zoom.

For body search, title precedes body tiles in row-first order, footer Close and owner inventory controls. Wheel/Page keys scroll the body viewport. Enter/Space activates a focused body tile, auto-scrolling it into view. Q or its binding and Escape close search. T takes the first active-session item only in supported developer builds.

Pause focus visits Resume, Settings, Leave to Lobby, Quit, then available party actions by reading order. Party picker supports arrows, typing by display name and Enter selection, keeping peer identity stable. Accept/Decline use the current inviter peer. Show expiry through text and announce expiration once. Confirm Party Leave/Kick and session Leave/Quit with Cancel as safe focus. Server state controls action availability. Transfer error focuses Return to Lobby. Host restores capture only after all panels close.

## 6. Data

Read `hud` → `HudState.net`, `heading`, `role`, `life`, `timer`, `weaponsLocked`, `cash`, `bag`, `notoriety`, `health`, `maxHealth`, `self`, `party`, `interact`, `hotbar`, `activeSlot`, `notifications`, `surrenderAvailable`, `heistAlert` and `channels`. Read `party` → `PartyView` for Pause, `inventory` → `InventoryView`, `search` → `SearchView`, `game_overlay` → `GameOverlayView` and `transfer` → `TransferView`. A null search clears its target. Send `inventory.move`, `inventory.close`, `search.take`, `search.close`, `pause.resume`, `settings.open`, `session.leave`, `app.quit`, `transfer.return_to_lobby`, `overlay.dismiss`, `party.create`, `party.invite`, `party.accept`, `party.decline`, `party.leave` and `party.kick`. Observe `route`. H uses the existing Godot input request. Its authoritative outcome arrives through the existing notification event and is reflected in `HudState.notifications`, with an optional host-produced arrest receipt.

## 7. Godot side

[Hud.gd](../../ui/hud/Hud.gd) builds owner snapshots, item views and panel routes; [Minimap.gd](../../ui/hud/Minimap.gd) renders real world geometry; [Main.gd](../../main/Main.gd) supplies ping, targeting, connection and panel wiring. [Player.gd](../../features/player/Player.gd) and [PlayerRoleController.gd](../../features/player/PlayerRoleController.gd) supply health, life and role. [PlayerService.gd](../../features/player/PlayerService.gd) owns money, death, surrender and transfer initiation. [DownedService.gd](../../features/downed/DownedService.gd) owns body/search rules and channels. [ItemUtils.gd](../../lib/utils/ItemUtils.gd) supplies item footprints. [PartyService.gd](../../features/party/PartyService.gd) owns membership. [TransferService.gd](../../features/transfer/TransferService.gd) owns reservations and timeout. [Lootable.gd](../../features/heist/Lootable.gd) emits loud alert to scoped recipients and [Instance.gd](../../features/instance/Instance.gd) currently prints it. **CHANGED** Main and Hud add the single `weaponsLocked` flag and server-supplied `surrenderAvailable`. **NEW** Turn the typed server outcome RPC (`client_life_outcome`) into timed receipts and publish structured active-heist presentation while preserving scoped transport. [PartyService.gd](../../features/party/PartyService.gd) publishes the current roster, expiring invites and action eligibility for Pause. **NEW** Publish channel presentation to the affected player without extending gameplay authority to the browser.

## 8. Accessibility

Body text ≥4.5:1 against local backing. Smallest label ≥11 px, common 14 px. Explain severity with text plus shape. Four numeric health segments, role names, masking labels, and countdown captions remain legible across colorblind modes. Announce downed, revive start, finishing warning, arrest, transfer failure and death once. Do not announce HP, heading, FPS or countdown every frame. Critical visual states use stable shapes and text, no flash. Active items show a border and explicit selected state. Item buttons include action, name, and rarity when meaningful. Shared focus ring and reasonable focus recovery for every interactive overlay.

## 9. Decisions

1. Decided 2026-11-27: Masking is only the 3 s channel. Criminal role has no mask expiry.
2. Decided 2026-11-27: Use one `HudState.weaponsLocked` flag and the exact copy “SAFE ZONE - weapons locked” in Motel, House and Center.
3. Decided 2026-11-27: Preserve the current scoped Cop/Criminal transport. Show an 8 s event toast plus the alert line while the heist remains active.
4. Decided 2026-11-27: Press starts the server-timed channel. Movement, damage or pressing the same key again cancels. Current code takes precedence over hold-interact wording in the downed design.
5. Decided 2026-11-27: Receipt lasts 900 ms. If spawn arrives first, preserve its remaining lifetime above the new HUD and allow Escape/click dismissal.
6. Decided 2026-11-27: External search lands before this design ships. Extend the body grid with vertically scrolling rows beyond 6 × 9. Owner inventory changes require separate approval.
7. Decided 2026-11-27: Server `HudState` supplies surrender eligibility. H stays a direct request and the existing notification event supplies the outcome.

### Still open

8. Verification during implementation: run the two-client Windows CEF smoke for focus, capture, Tab, Escape, drag and panel dismissal, including 90–110% UI scale. Confirm movement and fire stay gated while panels own input.
