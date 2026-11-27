# 03 · Settings

## 1. Purpose and entry/exit

Settings opens from Lobby or Pause using `settings.open`. The host enters `/settings/graphics`, then moves between `/settings/graphics`, `/settings/controls`, `/settings/social` and `/settings/others`. Back requests `settings.close` and restores the caller. Maintain one unsaved draft across tab changes. Game keeps running when opened from Pause.

## 2. ASCII wireframes

### Graphics settings

[Open SVG](wireframes/03-settings-graphics.svg)

```text
+-----------------------------------------------------------------------------------------------+
|      ++-------++-------------------------------------------+-----------+--------------++      |
|      ||Back   ||Settings title                             |           |Context label ||      |
|      +--------------------+-------------------+-------------------+--------------------+      |
|      |Graphics tab        |Controls tab       |Social tab         |Others tab          |      |
|      +---------------------------------------------------------------------------------+      |
|      |+-------------++-+---------------------++Control-----------------------------++++|      |
|      ||A11          || |Setting label        |+------------------------------------+||||      |
|      ||             |+Setting row 2-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             |+Setting row 3-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 4                                                 ||||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 5                                                 ||||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 6                                                 ||||      |
|      ||             |+Setting row 7-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             |+Setting row 8-------------------------------------------------+|||      |
|      ||             |+Partial row---------------------------------------------------+|||      |
|      |+-------------++--------------------------------------------------------------+++|      |
|      ++------------------------------------------------+-+--------+--------++---------++      |
|      ||Settings status                                 | |Reset   |Discard ||Apply    ||      |
|      ++------------------------------------------------+-+--------+--------++---------++      |
+-----------------------------------------------------------------------------------------------+

[A01 Settings header]
  [A02 Back]
  [A03 Settings title]
  [A04 Context label]
[A05 Settings tabs]
  [A06 Graphics tab]
  [A07 Controls tab]
  [A08 Social tab]
  [A09 Others tab]
[A10 Settings body]
  [A11 Settings groups]
  [A12 Control list]
    [A13 Setting row 1]
      [A14 Setting label]
      [A15 Control]
    [A16 Setting row 2]
    [A17 Setting row 3]
    [A18 Setting row 4]
    [A19 Setting row 5]
    [A20 Setting row 6]
    [A21 Setting row 7]
    [A22 Setting row 8]
    [A23 Partial row]
  [A24 Scroll track]
[A25 Settings footer]
  [A26 Settings status]
  [A27 Reset]
  [A28 Discard]
  [A29 Apply]
```

### Controls settings

[Open SVG](wireframes/03-settings-controls.svg)

```text
+-----------------------------------------------------------------------------------------------+
|      ++-------++-------------------------------------------+-----------+--------------++      |
|      ||Back   ||Settings title                             |           |Context label ||      |
|      +--------------------+-------------------+-------------------+--------------------+      |
|      |Graphics tab        |Controls tab       |Social tab         |Others tab          |      |
|      +---------------------------------------------------------------------------------+      |
|      |+-------------++-+---------------------++Control-----------------------------++++|      |
|      ||A11          || |Setting label        |+------------------------------------+||||      |
|      ||             |+Setting row 2-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             |+Setting row 3-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 4                                                 ||||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 5                                                 ||||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 6                                                 ||||      |
|      ||             |+Setting row 7-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             |+Setting row 8-------------------------------------------------+|||      |
|      ||             |+Partial row---------------------------------------------------+|||      |
|      |+-------------++--------------------------------------------------------------+++|      |
|      ++------------------------------------------------+-+--------+--------++---------++      |
|      ||Settings status                                 | |Reset   |Discard ||Apply    ||      |
|      ++------------------------------------------------+-+--------+--------++---------++      |
+-----------------------------------------------------------------------------------------------+

[A01 Settings header]
  [A02 Back]
  [A03 Settings title]
  [A04 Context label]
[A05 Settings tabs]
  [A06 Graphics tab]
  [A07 Controls tab]
  [A08 Social tab]
  [A09 Others tab]
[A10 Settings body]
  [A11 Settings groups]
  [A12 Control list]
    [A13 Setting row 1]
      [A14 Setting label]
      [A15 Control]
    [A16 Setting row 2]
    [A17 Setting row 3]
    [A18 Setting row 4]
    [A19 Setting row 5]
    [A20 Setting row 6]
    [A21 Setting row 7]
    [A22 Setting row 8]
    [A23 Partial row]
  [A24 Scroll track]
[A25 Settings footer]
  [A26 Settings status]
  [A27 Reset]
  [A28 Discard]
  [A29 Apply]
```

### Social settings

[Open SVG](wireframes/03-settings-social.svg)

```text
+-----------------------------------------------------------------------------------------------+
|      ++-------++-------------------------------------------+-----------+--------------++      |
|      ||Back   ||Settings title                             |           |Context label ||      |
|      +--------------------+-------------------+-------------------+--------------------+      |
|      |Graphics tab        |Controls tab       |Social tab         |Others tab          |      |
|      +---------------------------------------------------------------------------------+      |
|      |+-------------++-+---------------------++Control-----------------------------++++|      |
|      ||A11          || |Setting label        |+------------------------------------+||||      |
|      ||             |+Setting row 2-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             |+Setting row 3-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 4                                                 ||||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 5                                                 ||||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 6                                                 ||||      |
|      ||             |+Setting row 7-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             |+Setting row 8-------------------------------------------------+|||      |
|      ||             |+Partial row---------------------------------------------------+|||      |
|      |+-------------++--------------------------------------------------------------+++|      |
|      ++------------------------------------------------+-+--------+--------++---------++      |
|      ||Settings status                                 | |Reset   |Discard ||Apply    ||      |
|      ++------------------------------------------------+-+--------+--------++---------++      |
+-----------------------------------------------------------------------------------------------+

[A01 Settings header]
  [A02 Back]
  [A03 Settings title]
  [A04 Context label]
[A05 Settings tabs]
  [A06 Graphics tab]
  [A07 Controls tab]
  [A08 Social tab]
  [A09 Others tab]
[A10 Settings body]
  [A11 Settings groups]
  [A12 Control list]
    [A13 Setting row 1]
      [A14 Setting label]
      [A15 Control]
    [A16 Setting row 2]
    [A17 Setting row 3]
    [A18 Setting row 4]
    [A19 Setting row 5]
    [A20 Setting row 6]
    [A21 Setting row 7]
    [A22 Setting row 8]
    [A23 Partial row]
  [A24 Scroll track]
[A25 Settings footer]
  [A26 Settings status]
  [A27 Reset]
  [A28 Discard]
  [A29 Apply]
```

### Others settings

[Open SVG](wireframes/03-settings-others.svg)

```text
+-----------------------------------------------------------------------------------------------+
|      ++-------++-------------------------------------------+-----------+--------------++      |
|      ||Back   ||Settings title                             |           |Context label ||      |
|      +--------------------+-------------------+-------------------+--------------------+      |
|      |Graphics tab        |Controls tab       |Social tab         |Others tab          |      |
|      +---------------------------------------------------------------------------------+      |
|      |+-------------++-+---------------------++Control-----------------------------++++|      |
|      ||A11          || |Setting label        |+------------------------------------+||||      |
|      ||             |+Setting row 2-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             |+Setting row 3-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 4                                                 ||||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 5                                                 ||||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             ||Setting row 6                                                 ||||      |
|      ||             |+Setting row 7-------------------------------------------------+|||      |
|      ||             |+--------------------------------------------------------------+|||      |
|      ||             |+Setting row 8-------------------------------------------------+|||      |
|      ||             |+Partial row---------------------------------------------------+|||      |
|      |+-------------++--------------------------------------------------------------+++|      |
|      ++------------------------------------------------+-+--------+--------++---------++      |
|      ||Settings status                                 | |Reset   |Discard ||Apply    ||      |
|      ++------------------------------------------------+-+--------+--------++---------++      |
+-----------------------------------------------------------------------------------------------+

[A01 Settings header]
  [A02 Back]
  [A03 Settings title]
  [A04 Context label]
[A05 Settings tabs]
  [A06 Graphics tab]
  [A07 Controls tab]
  [A08 Social tab]
  [A09 Others tab]
[A10 Settings body]
  [A11 Settings groups]
  [A12 Control list]
    [A13 Setting row 1]
      [A14 Setting label]
      [A15 Control]
    [A16 Setting row 2]
    [A17 Setting row 3]
    [A18 Setting row 4]
    [A19 Setting row 5]
    [A20 Setting row 6]
    [A21 Setting row 7]
    [A22 Setting row 8]
    [A23 Partial row]
  [A24 Scroll track]
[A25 Settings footer]
  [A26 Settings status]
  [A27 Reset]
  [A28 Discard]
  [A29 Apply]
```

### Settings confirmation

[Open SVG](wireframes/03-settings-dialog.svg)

```text
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                            +-------------------------------------+                            |
|                            | +Dialog title---------------------+ |                            |
|                            | +---------------------------------+ |                            |
|                            | |Dialog body                      | |                            |
|                            | |                                 | |                            |
|                            | +---------------------------------+ |                            |
|                            |                                     |                            |
|                            |              +A05------++A06------+ |                            |
|                            |              +---------++---------+ |                            |
|                            +-------------------------------------+                            |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+

[A01 Dialog scrim]
  [A02 Settings dialog]
    [A03 Dialog title]
    [A04 Dialog body]
    [A05 Secondary action]
    [A06 Primary action]
```

## 3. Layout

Right and bottom give offsets to the base-frame edges. Group bounds intentionally contain their children. Rows and regions use base CSS pixels.

### Graphics settings

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Settings header | 96 | 32 | 96 | 632 | 1088 | 56 | Frame |
| A02 | Back | 112 | 40 | 1072 | 640 | 96 | 40 | Settings header |
| A03 | Settings title | 224 | 40 | 472 | 640 | 584 | 40 | Settings header |
| A04 | Context label | 976 | 40 | 112 | 640 | 192 | 40 | Settings header |
| A05 | Settings tabs | 96 | 100 | 96 | 576 | 1088 | 44 | Frame |
| A06 | Graphics tab | 96 | 100 | 912 | 576 | 272 | 44 | Settings tabs |
| A07 | Controls tab | 368 | 100 | 640 | 576 | 272 | 44 | Settings tabs |
| A08 | Social tab | 640 | 100 | 368 | 576 | 272 | 44 | Settings tabs |
| A09 | Others tab | 912 | 100 | 96 | 576 | 272 | 44 | Settings tabs |
| A10 | Settings body | 96 | 156 | 96 | 100 | 1088 | 464 | Frame |
| A11 | Settings groups | 112 | 172 | 984 | 116 | 184 | 432 | Settings body |
| A12 | Control list | 312 | 172 | 128 | 116 | 840 | 432 | Settings body |
| A13 | Setting row 1 | 312 | 172 | 128 | 500 | 840 | 48 | Control list |
| A14 | Setting label | 328 | 172 | 656 | 500 | 296 | 48 | Setting row 1 |
| A15 | Control | 640 | 178 | 144 | 506 | 496 | 36 | Setting row 1 |
| A16 | Setting row 2 | 312 | 224 | 128 | 448 | 840 | 48 | Control list |
| A17 | Setting row 3 | 312 | 276 | 128 | 396 | 840 | 48 | Control list |
| A18 | Setting row 4 | 312 | 328 | 128 | 344 | 840 | 48 | Control list |
| A19 | Setting row 5 | 312 | 380 | 128 | 292 | 840 | 48 | Control list |
| A20 | Setting row 6 | 312 | 432 | 128 | 240 | 840 | 48 | Control list |
| A21 | Setting row 7 | 312 | 484 | 128 | 188 | 840 | 48 | Control list |
| A22 | Setting row 8 | 312 | 536 | 128 | 136 | 840 | 48 | Control list |
| A23 | Partial row | 312 | 588 | 128 | 116 | 840 | 16 | Control list |
| A24 | Scroll track | 1160 | 172 | 112 | 116 | 8 | 432 | Settings body |
| A25 | Settings footer | 96 | 632 | 96 | 32 | 1088 | 56 | Frame |
| A26 | Settings status | 112 | 640 | 520 | 40 | 648 | 40 | Settings footer |
| A27 | Reset | 784 | 640 | 376 | 40 | 120 | 40 | Settings footer |
| A28 | Discard | 912 | 640 | 248 | 40 | 120 | 40 | Settings footer |
| A29 | Apply | 1040 | 640 | 112 | 40 | 128 | 40 | Settings footer |

### Controls settings

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Settings header | 96 | 32 | 96 | 632 | 1088 | 56 | Frame |
| A02 | Back | 112 | 40 | 1072 | 640 | 96 | 40 | Settings header |
| A03 | Settings title | 224 | 40 | 472 | 640 | 584 | 40 | Settings header |
| A04 | Context label | 976 | 40 | 112 | 640 | 192 | 40 | Settings header |
| A05 | Settings tabs | 96 | 100 | 96 | 576 | 1088 | 44 | Frame |
| A06 | Graphics tab | 96 | 100 | 912 | 576 | 272 | 44 | Settings tabs |
| A07 | Controls tab | 368 | 100 | 640 | 576 | 272 | 44 | Settings tabs |
| A08 | Social tab | 640 | 100 | 368 | 576 | 272 | 44 | Settings tabs |
| A09 | Others tab | 912 | 100 | 96 | 576 | 272 | 44 | Settings tabs |
| A10 | Settings body | 96 | 156 | 96 | 100 | 1088 | 464 | Frame |
| A11 | Settings groups | 112 | 172 | 984 | 116 | 184 | 432 | Settings body |
| A12 | Control list | 312 | 172 | 128 | 116 | 840 | 432 | Settings body |
| A13 | Setting row 1 | 312 | 172 | 128 | 500 | 840 | 48 | Control list |
| A14 | Setting label | 328 | 172 | 656 | 500 | 296 | 48 | Setting row 1 |
| A15 | Control | 640 | 178 | 144 | 506 | 496 | 36 | Setting row 1 |
| A16 | Setting row 2 | 312 | 224 | 128 | 448 | 840 | 48 | Control list |
| A17 | Setting row 3 | 312 | 276 | 128 | 396 | 840 | 48 | Control list |
| A18 | Setting row 4 | 312 | 328 | 128 | 344 | 840 | 48 | Control list |
| A19 | Setting row 5 | 312 | 380 | 128 | 292 | 840 | 48 | Control list |
| A20 | Setting row 6 | 312 | 432 | 128 | 240 | 840 | 48 | Control list |
| A21 | Setting row 7 | 312 | 484 | 128 | 188 | 840 | 48 | Control list |
| A22 | Setting row 8 | 312 | 536 | 128 | 136 | 840 | 48 | Control list |
| A23 | Partial row | 312 | 588 | 128 | 116 | 840 | 16 | Control list |
| A24 | Scroll track | 1160 | 172 | 112 | 116 | 8 | 432 | Settings body |
| A25 | Settings footer | 96 | 632 | 96 | 32 | 1088 | 56 | Frame |
| A26 | Settings status | 112 | 640 | 520 | 40 | 648 | 40 | Settings footer |
| A27 | Reset | 784 | 640 | 376 | 40 | 120 | 40 | Settings footer |
| A28 | Discard | 912 | 640 | 248 | 40 | 120 | 40 | Settings footer |
| A29 | Apply | 1040 | 640 | 112 | 40 | 128 | 40 | Settings footer |

### Social settings

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Settings header | 96 | 32 | 96 | 632 | 1088 | 56 | Frame |
| A02 | Back | 112 | 40 | 1072 | 640 | 96 | 40 | Settings header |
| A03 | Settings title | 224 | 40 | 472 | 640 | 584 | 40 | Settings header |
| A04 | Context label | 976 | 40 | 112 | 640 | 192 | 40 | Settings header |
| A05 | Settings tabs | 96 | 100 | 96 | 576 | 1088 | 44 | Frame |
| A06 | Graphics tab | 96 | 100 | 912 | 576 | 272 | 44 | Settings tabs |
| A07 | Controls tab | 368 | 100 | 640 | 576 | 272 | 44 | Settings tabs |
| A08 | Social tab | 640 | 100 | 368 | 576 | 272 | 44 | Settings tabs |
| A09 | Others tab | 912 | 100 | 96 | 576 | 272 | 44 | Settings tabs |
| A10 | Settings body | 96 | 156 | 96 | 100 | 1088 | 464 | Frame |
| A11 | Settings groups | 112 | 172 | 984 | 116 | 184 | 432 | Settings body |
| A12 | Control list | 312 | 172 | 128 | 116 | 840 | 432 | Settings body |
| A13 | Setting row 1 | 312 | 172 | 128 | 500 | 840 | 48 | Control list |
| A14 | Setting label | 328 | 172 | 656 | 500 | 296 | 48 | Setting row 1 |
| A15 | Control | 640 | 178 | 144 | 506 | 496 | 36 | Setting row 1 |
| A16 | Setting row 2 | 312 | 224 | 128 | 448 | 840 | 48 | Control list |
| A17 | Setting row 3 | 312 | 276 | 128 | 396 | 840 | 48 | Control list |
| A18 | Setting row 4 | 312 | 328 | 128 | 344 | 840 | 48 | Control list |
| A19 | Setting row 5 | 312 | 380 | 128 | 292 | 840 | 48 | Control list |
| A20 | Setting row 6 | 312 | 432 | 128 | 240 | 840 | 48 | Control list |
| A21 | Setting row 7 | 312 | 484 | 128 | 188 | 840 | 48 | Control list |
| A22 | Setting row 8 | 312 | 536 | 128 | 136 | 840 | 48 | Control list |
| A23 | Partial row | 312 | 588 | 128 | 116 | 840 | 16 | Control list |
| A24 | Scroll track | 1160 | 172 | 112 | 116 | 8 | 432 | Settings body |
| A25 | Settings footer | 96 | 632 | 96 | 32 | 1088 | 56 | Frame |
| A26 | Settings status | 112 | 640 | 520 | 40 | 648 | 40 | Settings footer |
| A27 | Reset | 784 | 640 | 376 | 40 | 120 | 40 | Settings footer |
| A28 | Discard | 912 | 640 | 248 | 40 | 120 | 40 | Settings footer |
| A29 | Apply | 1040 | 640 | 112 | 40 | 128 | 40 | Settings footer |

### Others settings

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Settings header | 96 | 32 | 96 | 632 | 1088 | 56 | Frame |
| A02 | Back | 112 | 40 | 1072 | 640 | 96 | 40 | Settings header |
| A03 | Settings title | 224 | 40 | 472 | 640 | 584 | 40 | Settings header |
| A04 | Context label | 976 | 40 | 112 | 640 | 192 | 40 | Settings header |
| A05 | Settings tabs | 96 | 100 | 96 | 576 | 1088 | 44 | Frame |
| A06 | Graphics tab | 96 | 100 | 912 | 576 | 272 | 44 | Settings tabs |
| A07 | Controls tab | 368 | 100 | 640 | 576 | 272 | 44 | Settings tabs |
| A08 | Social tab | 640 | 100 | 368 | 576 | 272 | 44 | Settings tabs |
| A09 | Others tab | 912 | 100 | 96 | 576 | 272 | 44 | Settings tabs |
| A10 | Settings body | 96 | 156 | 96 | 100 | 1088 | 464 | Frame |
| A11 | Settings groups | 112 | 172 | 984 | 116 | 184 | 432 | Settings body |
| A12 | Control list | 312 | 172 | 128 | 116 | 840 | 432 | Settings body |
| A13 | Setting row 1 | 312 | 172 | 128 | 500 | 840 | 48 | Control list |
| A14 | Setting label | 328 | 172 | 656 | 500 | 296 | 48 | Setting row 1 |
| A15 | Control | 640 | 178 | 144 | 506 | 496 | 36 | Setting row 1 |
| A16 | Setting row 2 | 312 | 224 | 128 | 448 | 840 | 48 | Control list |
| A17 | Setting row 3 | 312 | 276 | 128 | 396 | 840 | 48 | Control list |
| A18 | Setting row 4 | 312 | 328 | 128 | 344 | 840 | 48 | Control list |
| A19 | Setting row 5 | 312 | 380 | 128 | 292 | 840 | 48 | Control list |
| A20 | Setting row 6 | 312 | 432 | 128 | 240 | 840 | 48 | Control list |
| A21 | Setting row 7 | 312 | 484 | 128 | 188 | 840 | 48 | Control list |
| A22 | Setting row 8 | 312 | 536 | 128 | 136 | 840 | 48 | Control list |
| A23 | Partial row | 312 | 588 | 128 | 116 | 840 | 16 | Control list |
| A24 | Scroll track | 1160 | 172 | 112 | 116 | 8 | 432 | Settings body |
| A25 | Settings footer | 96 | 632 | 96 | 32 | 1088 | 56 | Frame |
| A26 | Settings status | 112 | 640 | 520 | 40 | 648 | 40 | Settings footer |
| A27 | Reset | 784 | 640 | 376 | 40 | 120 | 40 | Settings footer |
| A28 | Discard | 912 | 640 | 248 | 40 | 120 | 40 | Settings footer |
| A29 | Apply | 1040 | 640 | 112 | 40 | 128 | 40 | Settings footer |

### Settings confirmation

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Dialog scrim | 0 | 0 | 0 | 0 | 1280 | 720 | Frame |
| A02 | Settings dialog | 384 | 232 | 384 | 232 | 512 | 256 | Dialog scrim |
| A03 | Dialog title | 408 | 256 | 408 | 432 | 464 | 32 | Settings dialog |
| A04 | Dialog body | 408 | 300 | 408 | 340 | 464 | 80 | Settings dialog |
| A05 | Secondary action | 584 | 424 | 560 | 256 | 136 | 40 | Settings dialog |
| A06 | Primary action | 728 | 424 | 408 | 256 | 144 | 40 | Settings dialog |

Group buttons are 184 × 36 with 4 px gap within the rail, top-aligned in listed group order of first appearance. Selecting a group scrolls its first row into view. Ordered data rows fill the control list region at 52 px pitch (48 px content and 4 px gap). Each repeats the label and control layout shown in row 1 with their top adjusted by row offset minus scroll offset. A tab with fewer rows stops at its final row. Footer Reset is Reset Tab on Graphics and Social, Reset Controls on Controls, and Reset All Settings on Others. Reset and Credits are action keys in the schema. Render reset actions in footer only. List and dialog scroll independently. Display confirmation, rebind conflict, credits, consent, dirty exit and reset share the confirmation layout. Modal body is internally scrollable on long content.

## 4. States

| State | Behavior |
|---|---|
| First paint/loading | Show tabs and skeleton rows. Apply, Reset and Discard lock until the first settings snapshot. |
| Ready | Show ConfigFile values merged with defaults, capability reasons, and a neutral saved status. |
| Dirty | Mark changed rows and show changed count in footer. Apply submits one patch. Discard returns to current persisted revision. |
| Applying | Lock Apply, tab changes and Back during the reply. Retain scroll and draft. A plan-only control is disabled with reason. |
| Save/revision error | Keep draft, show one inline error. On stale revision, rebase unchanged draft keys onto latest snapshot and mark conflicts. Never overwrite updated keys silently. |
| Display preview | Show 15 s confirmation. Revert on timer, Escape, focus loss or host error. Keep commits full patch. Failed save reverts display and leaves draft editable. |
| Input capture | Show action name, prompt, and Cancel. Auto-cancel after 15 s. Press or click away only via explicit Cancel or focus loss, so first capture input is deterministic. |
| Device loss | Keep device row visible with clear fallback state. Equivalent system default is used at runtime. |
| Restart pending | Settings footer states which keys take effect next launch. Live values apply with no restart. |
| Empty / unavailable | Empty mute list says “No muted players.” Empty device source shows System Default. Missing locale/capability locks unsupported choices. |

### Graphics

Preset mapping lists `render_scale, shadows, textures, anti_aliasing, view_distance`: Low = 75, low, low, off, low. Medium = 100, medium, medium, fxaa, medium. High = 100, high, high, msaa_4x, high. Select Custom on a manual change to one of those values. If hardware rejects a preset member, report which control prevented the preset and keep existing draft values. Render-scale and gamma apply only on validated host support. Pitch and FOV do not affect browser geometry.

| Group | Setting key | Label | Type | Default | Range or options | Apply | ConfigFile | Behavior |
|---|---|---|---|---|---|---|---|---|
| Display | `display_mode` | Display mode | enum | `borderless` | `windowed`, `borderless`, `fullscreen` | Preview, then Keep | `[graphics]` | Preview 15 s and keep or revert. |
| Display | `resolution` | Resolution | enum | `native` | `native`, `1280x720`, `1600x900`, `1920x1080`, `2560x1440`, `3840x2160` | Preview, then Keep | `[graphics]` | Preview 15 s. Native uses the current display. Disable in borderless and filter unsupported modes. |
| Display | `vsync` | VSync | boolean | true | false / true | Immediately on Apply | `[graphics]` | Apply to the main window. |
| Display | `frame_cap` | Frame cap | enum | `120` | `30`, `60`, `90`, `120`, `144`, `165`, `240`, `unlimited` | Immediately on Apply | `[graphics]` | Display in FPS. VSync can cap to refresh rate first. |
| Quality | `render_scale` | Render scale | integer | 100 | 50–100, step 5 | Immediately on Apply | `[graphics]` | Percent of 3D render resolution. Interface stays at CEF physical resolution. |
| Quality | `quality_preset` | Quality preset | enum | `medium` | `low`, `medium`, `high`, `custom` | Immediately on Apply | `[graphics]` | Writes the five controlled values. Change any controlled value to select Custom. |
| Quality | `shadows` | Shadows | enum | `medium` | `off`, `low`, `medium`, `high` | Immediately on Apply | `[graphics]` | 3D shadow profile. |
| Quality | `textures` | Textures | enum | `medium` | `low`, `medium`, `high` | Next launch | `[graphics]` | Set pending texture profile on disk and apply on next game launch. |
| Quality | `anti_aliasing` | Anti-aliasing | enum | `fxaa` | `off`, `fxaa`, `msaa_2x`, `msaa_4x` | Immediately on Apply | `[graphics]` | Apply to the 3D viewport when supported. |
| Quality | `view_distance` | View distance | enum | `medium` | `low`, `medium`, `high` | Immediately on Apply | `[graphics]` | Client LOD profile. Server visibility and interaction ranges stay authoritative. |
| Accessibility | `gamma` | Brightness / gamma | number | 1 | 0.7–1.5, step 0.05 | Immediately on Apply | `[graphics]` | Affects the 3D picture only. |
| Accessibility | `fov` | Field of view | integer | 75 | 60–100, step 1 | Immediately on Apply | `[graphics]` | Vertical degrees on the active player camera. |
| Accessibility | `ui_scale` | UI scale | integer | 100 | 90–110, step 5 | Immediately on Apply | `[graphics]` | Percent applied to adjustable UI text and chrome within layout bounds. Shared minimap and inventory geometry stay locked. |
| Accessibility | `colorblind_mode` | Colorblind mode | enum | `off` | `off`, `protanopia`, `deuteranopia`, `tritanopia` | Immediately on Apply | `[graphics]` | Remap optional status tints. Text, markers and shapes remain present every mode. |

### Controls

Input IDs are physical and show user-facing names such as W, Space and LMB. E multiplexes interact/lockpick/search by active context. R stays Revive. Planned Reload uses B. Move debug travel to Ctrl+1–4 and sale to Y before exposing normal 1–6 hotbar selection. Debug travel bindings appear only in builds where shortcuts are enabled. Planned rows show their defaults and stay disabled until capable. Movement, aim and interaction behavior is gated by Godot.

| Group | Setting key | Label | Type | Default | Range or options | Apply | ConfigFile | Behavior |
|---|---|---|---|---|---|---|---|---|
| Mouse | `mouse_sensitivity` | Mouse sensitivity | number | 0.003 | 0.0005–0.01, step 0.0001 | Immediately on Apply | `[controls]` | Radians per physical mouse pixel. Default matches GameConst. |
| Mouse | `ads_sensitivity` | ADS sensitivity | number | 0.75 | 0.1–2, step 0.05 | Immediately on Apply | `[controls]` | Multiplier on mouse sensitivity during planned aim. |
| Mouse | `invert_y` | Invert Y | boolean | false | false / true | Immediately on Apply | `[controls]` | Flip pitch input. |
| Mouse | `aim_mode` | Aim behavior | enum | `hold` | `hold`, `toggle` | Immediately on Apply | `[controls]` | Use after the action ships. Reset held state on a route change. |
| Mouse | `crouch_mode` | Crouch behavior | enum | `hold` | `hold`, `toggle` | Immediately on Apply | `[controls]` | Use after the action ships. Reset held state on a route change. |
| Mouse | `sprint_mode` | Sprint behavior | enum | `hold` | `hold`, `toggle` | Immediately on Apply | `[controls]` | Use after the action ships. Reset held state on a route change. |
| Movement | `bind_move_forward` | Move forward | binding | `KeyW` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Crawl forward while downed. |
| Movement | `bind_move_left` | Move left | binding | `KeyA` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Crawl left while downed. |
| Movement | `bind_move_back` | Move backward | binding | `KeyS` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Crawl back while downed. |
| Movement | `bind_move_right` | Move right | binding | `KeyD` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Crawl right while downed. |
| Movement | `bind_jump` | Jump | binding | `Space` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned movement action. |
| Movement | `bind_sprint` | Sprint | binding | `ShiftLeft` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned movement action. |
| Movement | `bind_crouch` | Crouch | binding | `ControlLeft` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned movement action. |
| Mouse | `bind_look` | Look | binding | `MouseMotion` | Fixed physical input | Immediately on Apply | `[controls]` | Live. Fixed mouse motion, not a key slot. |
| Combat | `bind_aim` | Aim / ADS | binding | `MouseRight` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. |
| Combat | `bind_fire` | Fire | binding | `MouseLeft` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Godot gates safezones, role, and life state. |
| Combat | `bind_reload` | Reload | binding | `KeyB` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. R stays assigned to live Revive. |
| Combat | `bind_mask` | Put on mask | binding | `KeyF` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. |
| Combat | `bind_cop_duty` | Go on duty | binding | `KeyG` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. |
| Combat | `bind_surrender` | Surrender | binding | `KeyH` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Proposed confirmation uses same binding. |
| Interactions | `bind_interact` | Interact / lockpick / search | binding | `KeyE` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live shared contextual action. Planned generic interaction, e.g. alarm, NPC, doors and extraction prompts, can use it. |
| Interactions | `bind_smash` | Smash | binding | `KeyV` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live contextual loot action. |
| Interactions | `bind_revive` | Revive | binding | `KeyR` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Server channel. |
| Interactions | `bind_finish` | Finish off | binding | `KeyX` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Server channel. |
| Interactions | `bind_cuff` | Cuff | binding | `KeyC` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Server channel. |
| Interactions | `bind_search_take` | Take first search item | binding | `KeyT` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live developer shortcut. Target the current open search in the production binding. |
| Interactions | `bind_search_close` | Close body search | binding | `KeyQ` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Fixed active-panel fallback after rebind only if retained by the owner. |
| Interactions | `bind_sell_loot` | Sell loot | binding | `KeyY` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live on 5 today. Move debug 5 ownership with the hotbar migration. |
| Inventory and map | `bind_inventory` | Inventory | binding | `Tab` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Tab is an intentionally shared panel-focus key. |
| Inventory and map | `bind_hotbar_1` | Hotbar slot 1 | binding | `Digit1` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live selected slot 1. User selection is planned. |
| Inventory and map | `bind_hotbar_2` | Hotbar slot 2 | binding | `Digit2` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Numeric slot selection takes precedence after debug key migration. |
| Inventory and map | `bind_hotbar_3` | Hotbar slot 3 | binding | `Digit3` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Numeric slot selection takes precedence after debug key migration. |
| Inventory and map | `bind_hotbar_4` | Hotbar slot 4 | binding | `Digit4` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Numeric slot selection takes precedence after debug key migration. |
| Inventory and map | `bind_hotbar_5` | Hotbar slot 5 | binding | `Digit5` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Numeric slot selection takes precedence after debug key migration. |
| Inventory and map | `bind_hotbar_6` | Hotbar slot 6 | binding | `Digit6` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Numeric slot selection takes precedence after debug key migration. |
| Inventory and map | `bind_map` | World map | binding | `KeyM` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. No gameplay map panel in this delivery. |
| Communication | `bind_ping` | Place ping | binding | `MouseMiddle` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Contextual world ping. |
| Communication | `bind_push_to_talk` | Push to talk | binding | `AltLeft` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Held only in enabled PTT mode. |
| Communication | `bind_chat` | Text chat | binding | `Enter` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Reserved Enter confirmation takes priority within UI panels. |
| Communication | `bind_emote` | Emote wheel | binding | `KeyJ` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. |
| Communication | `bind_help` | Help | binding | `KeyK` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. |
| Social and travel | `bind_party_create` | Create party | binding | `KeyP` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Other party actions use lobby controls. |
| Social and travel | `bind_join_motel` | Travel to Motel | binding | `Ctrl+Digit1` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live debug key 1. New chord for debug-only use. |
| Social and travel | `bind_join_lootybay` | Travel to LootyBay | binding | `Ctrl+Digit2` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live debug key 2. New chord for debug-only use. |
| Social and travel | `bind_join_house` | Travel to House | binding | `Ctrl+Digit3` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live debug key 3. New chord for debug-only use. |
| Social and travel | `bind_join_center` | Travel to Center | binding | `Ctrl+Digit4` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live debug key 4. New chord for debug-only use. |
| Interface | `bind_pause` | Pause / back | binding | `Escape` | Fixed physical input | Immediately on Apply | `[controls]` | Fixed global escape. Existing gameplay Esc releases pointer or closes inventory. |
| Interface | `reset_controls` | Reset Controls | action | `null` | Button | On activation | None | Stage defaults for all Controls keys. Apply saves. |

### Social

Show dropdown as Everyone, Friends, Nobody. Friends requires a verified friends source. Open Mic requires a separate confirmation in the draft; microphone permission and game activation both remain host gates. Lock dependent controls when voice is off. Mute list supports keyboard navigation and Remove beside each listed player.

| Group | Setting key | Label | Type | Default | Range or options | Apply | ConfigFile | Behavior |
|---|---|---|---|---|---|---|---|---|
| Party and names | `party_invites` | Party invites | enum | `everyone` | `everyone`, `friends`, `nobody` | Immediately on Apply | `[social]` | Server policy needed. Friends locked until a verified friends source ships. |
| Party and names | `show_player_names` | Show player names | boolean | true | false / true | Immediately on Apply | `[social]` | Applies to displayed names. Local labels and teammate slots remain usable. |
| Party and names | `chat_filter` | Chat filter | boolean | true | false / true | Immediately on Apply | `[social]` | Enable supported cleanup on displayed chat. Dormant until chat ships. |
| Voice | `voice_chat` | Voice chat | boolean | false | false / true | Immediately on Apply | `[social]` | Allow voice only after permission and activation. |
| Voice | `voice_mode` | Voice activation | enum | `push_to_talk` | `push_to_talk`, `open_mic` | Immediately on Apply | `[social]` | Open mic requires an explicit confirmation before recording. |
| Voice | `voice_input_device` | Input device | device | `system_default` | `system_default` or ID from `SettingsView.devices` | Immediately on Apply | `[social]` | Stable Godot-provided device ID. Disconnected device falls back to system default and is flagged. |
| Voice | `voice_output_device` | Output device | device | `system_default` | `system_default` or ID from `SettingsView.devices` | Immediately on Apply | `[social]` | Stable Godot-provided device ID. Disconnected device falls back to system default and is flagged. |
| Voice | `voice_receive_volume` | Voice receive volume | integer | 100 | 0–100, step 1 | Immediately on Apply | `[social]` | Scale received voice before the global voice bus. |
| Voice | `muted_players` | Muted players | string_array | `[]` | Unique stable player IDs, max 256 | Immediately on Apply | `[social]` | Verified account IDs when available. Show current-session aliases when resolving the list. |
| Privacy | `streamer_mode` | Streamer mode | boolean | false | false / true | Immediately on Apply | `[social]` | Mask server ID and player names in interface output, accessibility labels and local notifications. |

### Others

Language registers only shipped strings. The voice bus level controls total game voice output. Voice receive volume on Social applies earlier in the local mixer. Telemetry and crash options start off and remain disabled until supported. Credits are bundled text in the shared dialog.

| Group | Setting key | Label | Type | Default | Range or options | Apply | ConfigFile | Behavior |
|---|---|---|---|---|---|---|---|---|
| Audio | `master_volume` | Master volume | integer | 100 | 0–100, step 1 | Immediately on Apply | `[others]` | Apply to the corresponding local audio bus. |
| Audio | `music_volume` | Music volume | integer | 70 | 0–100, step 1 | Immediately on Apply | `[others]` | Apply to the corresponding local audio bus. |
| Audio | `sfx_volume` | Sound effects volume | integer | 100 | 0–100, step 1 | Immediately on Apply | `[others]` | Apply to the corresponding local audio bus. |
| Audio | `ui_volume` | Interface sound volume | integer | 80 | 0–100, step 1 | Immediately on Apply | `[others]` | Apply to the corresponding local audio bus. |
| Audio | `voice_volume` | Voice bus volume | integer | 100 | 0–100, step 1 | Immediately on Apply | `[others]` | Apply to the corresponding local audio bus. |
| General | `language` | Language | enum | `en` | `en` | Immediately on Apply | `[others]` | List only shipped locales. Apply UI strings on save. |
| HUD | `minimap_rotate` | Rotate minimap | boolean | false | false / true | Immediately on Apply | `[others]` | Counter-rotate Godot minimap view with heading. Keep player arrow forward. |
| HUD | `show_compass` | Show compass | boolean | true | false / true | Immediately on Apply | `[others]` | Show the compass strip. |
| HUD | `show_damage_numbers` | Show damage numbers | boolean | false | false / true | Immediately on Apply | `[others]` | Applies after authoritative damage numbers ship. |
| HUD | `notifications_duration` | Notification duration | integer | 4 | 2–10, step 1 | Immediately on Apply | `[others]` | Seconds. Applies to ordinary toasts. Critical status uses gameplay lifetime. |
| Privacy | `telemetry` | Share telemetry | boolean | false | false / true | Immediately on Apply | `[others]` | Opt in only when a telemetry service exists. Apply consent on save. |
| Privacy | `crash_reports` | Share crash reports | boolean | false | false / true | Immediately on Apply | `[others]` | Opt in only when a crash reporter exists. Apply consent on save. |
| General | `credits` | Credits | action | `null` | Button | On activation | None | Open bundled credits in the dialog. No write. |
| General | `reset_all` | Reset all settings | action | `null` | Button | On activation | None | Stage defaults for all persisted settings after confirmation. Apply saves. |

## 5. Interactions

Start focus on the Settings title, then Back, active tab, group rail, visible controls, Reset, Discard and Apply. Tab bar uses Left/Right arrows and Enter/Space; group buttons scroll without changing settings. Slider readouts update on drag and keys. Toggles and select changes update the draft. Enter activates focused controls. Escape walks out of capture, popover, dialog, then screen. If dirty, offer Keep editing or Discard before leaving. Apply writes validated durable values; supported non-display settings apply immediately after commit. Reload settings after bridge reconnect and keep a draft only if the revision still matches.

For rebind, activate keybind row and ask Godot to capture one physical press/chord. Escape cancels. Mouse movement or wheel does not capture. Godot reserves Escape and ignores the initiating click, repeats, unsupported inputs and OS shortcuts. Tab may remain Inventory because host scopes UI traversal. If the same physical binding exists in the active gameplay context, show both action labels. Offer Cancel or Replace. Replace stages the new binding and clears the old editable binding in the same draft. Disable Replace if the other action is fixed. A separate Clear button within capture's secondary action menu stages unbound where allowed. Never clear default movement or Fire without explicit confirmation. Reset stages default values with a confirmation, then Apply commits. While capture owns inputs, route switches and gameplay are gated. Gamepad later.

## 6. Data

Read `settings` → `SettingsView.values`, `revision`, `capabilities`, `devices`, `displayModes`, `pendingRestart`, `preview` and `saveError`. Send `settings.tab`, `settings.close`, `settings.capture`, `settings.capture_cancel`, `settings.apply`, `settings.display_confirm`. Reset, Discard, Credits and ordinary form edits act locally until Apply. Read schema keys, defaults and validation from [settings-schema.json](settings-schema.json).

## 7. Godot side

**NEW** `ui/settings/SettingsService.gd` uses Godot `ConfigFile` at `user://settings.cfg`, with section precisely equal to the tab. Save durable revisions atomically and restore defaults for missing or invalid old keys. ConfigFile holds local preferences only. Server policy for invites or chat stays in existing server services with validated synchronization when available. [Main.gd](../../main/Main.gd), [Player.gd](../../features/player/Player.gd), [PlayerCamera.gd](../../features/player/PlayerCamera.gd), [Hud.gd](../../ui/hud/Hud.gd), [Minimap.gd](../../ui/hud/Minimap.gd), [GameConst.gd](../../lib/constants/GameConst.gd) and [uiScale.ts](../../ui/web/src/app/uiScale.ts) own current input, surfaces and defaults to extend. **NEW** capability checks and audio/monitor/voice integrations run through the Godot host; page receives only lists and status.

## 8. Accessibility

Body text ≥14 px, help ≥11 px, contrast ≥4.5:1. Pair active underline with selected semantics. On/Off, invalid state, pending restart and unsupported state use words. Focus comes back to original control after dropdown or dialog. Peek height preserves clear scroll affordance and focused controls auto-scroll fully into view. Reduced motion disables animated scroll. Announce preview once and at five seconds remaining. Give error summary an accessible label and focus the first invalid editable control after dismissal.

## 9. Open questions

1. Approve proposed defaults and profile values after renderer checks. Verify gamma and AA availability and which changes require restart on supported builds.
2. Approve debug 1–5 migration before enabling six-slot selection. Confirm planned B for Reload versus reassignment after keyboard tests.
3. Decide which future keybindings should initially ship disabled by capability, especially chat, map, help, emotes and voice.
4. Confirm account IDs and friend eligibility for cross-session mute and invites. Confirm voice device permissions and open-mic policy.
5. Validate 90–110% UI scale in the borderless and pinned-geometry cases before exposing it. Confirm telemetry, crash and locale availability.
