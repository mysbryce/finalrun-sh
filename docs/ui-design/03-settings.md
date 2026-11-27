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
|      |+-------------++-+---------------------++Control-----------------------------++  |      |
|      ||A11          || |Setting label        |+------------------------------------+|  |      |
|      ||             |+Setting row 2-------------------------------------------------+  |      |
|      ||             |+--------------------------------------------------------------+  |      |
|      ||             |+Setting row 3-------------------------------------------------+  |      |
|      ||             |+--------------------------------------------------------------+  |      |
|      ||             ||Setting row 4                                                 |  |      |
|      ||             |+--------------------------------------------------------------+  |      |
|      ||             ||                                                              |  |      |
|      ||             ||                                                              |  |      |
|      ||             ||                                                              |  |      |
|      ||             ||                                                              |  |      |
|      ||             ||                                                              |  |      |
|      ||             ||                                                              |  |      |
|      ||             ||                                                              |  |      |
|      |+-------------++--------------------------------------------------------------+  |      |
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
[A19 Settings footer]
  [A20 Settings status]
  [A21 Reset]
  [A22 Discard]
  [A23 Apply]
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

### Social settings with Voice enabled

[Open SVG](wireframes/03-settings-social-voice.svg)

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
|      ||             |+-+---------------------++Open mic threshold slider-----------++|||      |
|      ||             || |A21                  |+------------------------------------+||||      |
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
      [A21 Open mic threshold label]
      [A22 Open mic threshold slider]
    [A23 Setting row 7]
    [A24 Setting row 8]
    [A25 Partial row]
  [A26 Scroll track]
[A27 Settings footer]
  [A28 Settings status]
  [A29 Reset]
  [A30 Discard]
  [A31 Apply]
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

Right and bottom are insets from the 1280 × 720 frame. Parent bounds contain their children. Each drawing is a separate state.

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
| A19 | Settings footer | 96 | 632 | 96 | 32 | 1088 | 56 | Frame |
| A20 | Settings status | 112 | 640 | 520 | 40 | 648 | 40 | Settings footer |
| A21 | Reset | 784 | 640 | 376 | 40 | 120 | 40 | Settings footer |
| A22 | Discard | 912 | 640 | 248 | 40 | 120 | 40 | Settings footer |
| A23 | Apply | 1040 | 640 | 112 | 40 | 128 | 40 | Settings footer |

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

### Social settings with Voice enabled

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
| A21 | Open mic threshold label | 328 | 432 | 656 | 240 | 296 | 48 | Setting row 6 |
| A22 | Open mic threshold slider | 640 | 438 | 144 | 246 | 496 | 36 | Setting row 6 |
| A23 | Setting row 7 | 312 | 484 | 128 | 188 | 840 | 48 | Control list |
| A24 | Setting row 8 | 312 | 536 | 128 | 136 | 840 | 48 | Control list |
| A25 | Partial row | 312 | 588 | 128 | 116 | 840 | 16 | Control list |
| A26 | Scroll track | 1160 | 172 | 112 | 116 | 8 | 432 | Settings body |
| A27 | Settings footer | 96 | 632 | 96 | 32 | 1088 | 56 | Frame |
| A28 | Settings status | 112 | 640 | 520 | 40 | 648 | 40 | Settings footer |
| A29 | Reset | 784 | 640 | 376 | 40 | 120 | 40 | Settings footer |
| A30 | Discard | 912 | 640 | 248 | 40 | 120 | 40 | Settings footer |
| A31 | Apply | 1040 | 640 | 112 | 40 | 128 | 40 | Settings footer |

### Settings confirmation

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Dialog scrim | 0 | 0 | 0 | 0 | 1280 | 720 | Frame |
| A02 | Settings dialog | 384 | 232 | 384 | 232 | 512 | 256 | Dialog scrim |
| A03 | Dialog title | 408 | 256 | 408 | 432 | 464 | 32 | Settings dialog |
| A04 | Dialog body | 408 | 300 | 408 | 340 | 464 | 80 | Settings dialog |
| A05 | Secondary action | 584 | 424 | 560 | 256 | 136 | 40 | Settings dialog |
| A06 | Primary action | 728 | 424 | 408 | 256 | 144 | 40 | Settings dialog |

Group buttons are 184 × 36 with 4 px gaps, ordered by first appearance in each tab. Rows use 48 px content with 4 px gaps, beginning at y=172. After applying capability and renderer filtering, repack visible rows contiguously. Row labels and controls repeat the row-1 offsets with `top = 172 + 52 × visible_index − scroll_offset`. The Social drawing shows the current four rows with Voice hidden. Other drawings show scrollable content; hide the rail when content fits. The whole Voice group appears as extra rows in the same scroller when supported, including the 36 px Open Mic threshold control. Keep the default English dropdown. Reset and Credits are schema actions; Reset uses the footer only. Display confirmation, rebind conflict, Credits, dirty exit and Reset share the confirmation layout.

The Voice-enabled drawing is a future capability example with voice enabled and Open Mic selected. Its threshold slider follows the same shared Slider geometry. Default activation remains Push to Talk; the current Social drawing keeps the entire Voice group hidden.

## 4. States

| State | Behavior |
|---|---|
| First paint/loading | Show tabs and skeleton rows. Apply, Reset and Discard lock until the first settings snapshot. |
| Ready | Show ConfigFile values merged with defaults, capability reasons, and a neutral saved status. |
| Dirty | Mark changed rows and show changed count in footer. Apply submits one patch. Discard returns to current persisted revision. |
| Applying | Lock Apply, tab changes and Back during the reply. Retain scroll and draft. Future feature bindings retain their defaults and carry “Coming later.” |
| Save/revision error | Keep draft, show one inline error. On stale revision, rebase unchanged draft keys onto latest snapshot and mark conflicts. Never overwrite updated keys silently. |
| Display preview | Show 15 s confirmation. Revert on timer, Escape, focus loss or host error. Keep commits full patch. Failed save reverts display and leaves draft editable. |
| Input capture | Show action name, prompt, and Cancel. Auto-cancel after 15 s. Press or click away only via explicit Cancel or focus loss, so first capture input is deterministic. |
| Device loss | Keep device row visible with clear fallback state. System default is used at runtime when the voice capability is available. |
| Restart pending | Settings footer states which keys take effect next launch. Live values apply with no restart. |
| Empty / unavailable | When voice is available, an empty mute list says “No muted players” and an empty device list shows System Default. Apply the availability rule below. English remains available. |

### Availability and storage

Renderer options unsupported by the running build are hidden, including individual enum choices. When no supported choice remains, hide the entire setting. This rule also filters quality-preset members before they are offered.

Each schema entry carries `group`, the group rail label from the tables below. The schema fields `storage`, `capability` and `unavailable` define the remaining visibility and persistence rules. `storage: 'config_file'` uses `user://settings.cfg` with section equal to the tab. `storage: 'session'` uses the current ENet connection only, clearing on disconnect. `storage: 'none'` describes actions. A false capability with `unavailable: 'hidden'` removes both row and focus target. A false capability with `unavailable: 'coming_later'` retains a disabled row with the exact tag “Coming later.” A null capability has no feature gate. Labels and stored defaults remain stable while hidden.

The whole Voice group in Social and Voice bus volume in Others use the `voice_chat` capability. Future voice keybinding in Controls remains listed with “Coming later.” Telemetry and crash reports are hidden until their named backend capability exists. Party invite permissions and muted peer IDs use session storage. Older ConfigFile entries for those two keys are ignored. Language remains a one-entry English dropdown. Only the texture profile keeps the approved restart requirement.

### Graphics

Approved presets control `render_scale, shadows, textures, anti_aliasing, view_distance`. Low = 75, low, low, off, low. Medium = 100, medium, medium, fxaa, medium. High = 100, high, high, msaa_4x, high. A manual change to any supported preset member selects Custom. Apply presets only to offered members. Host capability projection follows the availability rule above. UI scale is exposed at 90–110% and verified in the implementation smoke.

| Group | Setting key | Label | Type | Default | Range or options | Apply | Storage | Behavior |
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
| Accessibility | `ui_scale` | UI scale | integer | 100 | 90–110, step 5 | Immediately on Apply | `[graphics]` | Expose 90–110%. Apply to adjustable text/chrome within pinned minimap and inventory geometry. Validate in the two-client smoke. |
| Accessibility | `colorblind_mode` | Colorblind mode | enum | `off` | `off`, `protanopia`, `deuteranopia`, `tritanopia` | Immediately on Apply | `[graphics]` | Remap optional status tints. Text, markers and shapes remain present every mode. |

### Controls

Physical inputs display readable names such as W, Space and LMB. E remains contextual interact/lockpick/search. R is Revive and B is Reload. Debug-only travel is Ctrl+1–4 and sell is Y. Normal builds reserve 1–6 for hotbar selection. Future chat, map, help, emotes, ping and voice bindings remain listed with “Coming later” until shipped. Server-timed channels start on press and cancel on movement, damage or pressing the same action again. Godot owns those action gates.

| Group | Setting key | Label | Type | Default | Range or options | Apply | Storage | Behavior |
|---|---|---|---|---|---|---|---|---|
| Mouse | `mouse_sensitivity` | Mouse sensitivity | number | 0.003 | 0.0005–0.01, step 0.0001 | Immediately on Apply | `[controls]` | Radians per physical mouse pixel. Default matches GameConst. |
| Mouse | `ads_sensitivity` | ADS sensitivity | number | 0.75 | 0.1–2, step 0.05 | Immediately on Apply | `[controls]` | Multiplier on mouse sensitivity during planned aim. Disabled with “Coming later” until the feature ships. |
| Mouse | `invert_y` | Invert Y | boolean | false | false / true | Immediately on Apply | `[controls]` | Flip pitch input. |
| Mouse | `aim_mode` | Aim behavior | enum | `hold` | `hold`, `toggle` | Immediately on Apply | `[controls]` | Use after the action ships. Reset held state on a route change. Disabled with “Coming later” until the feature ships. |
| Mouse | `crouch_mode` | Crouch behavior | enum | `hold` | `hold`, `toggle` | Immediately on Apply | `[controls]` | Use after the action ships. Reset held state on a route change. Disabled with “Coming later” until the feature ships. |
| Mouse | `sprint_mode` | Sprint behavior | enum | `hold` | `hold`, `toggle` | Immediately on Apply | `[controls]` | Use after the action ships. Reset held state on a route change. Disabled with “Coming later” until the feature ships. |
| Movement | `bind_move_forward` | Move forward | binding | `KeyW` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Crawl forward while downed. |
| Movement | `bind_move_left` | Move left | binding | `KeyA` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Crawl left while downed. |
| Movement | `bind_move_back` | Move backward | binding | `KeyS` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Crawl back while downed. |
| Movement | `bind_move_right` | Move right | binding | `KeyD` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Crawl right while downed. |
| Movement | `bind_jump` | Jump | binding | `Space` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned movement action. Disabled with “Coming later” until the feature ships. |
| Movement | `bind_sprint` | Sprint | binding | `ShiftLeft` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned movement action. Disabled with “Coming later” until the feature ships. |
| Movement | `bind_crouch` | Crouch | binding | `ControlLeft` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned movement action. Disabled with “Coming later” until the feature ships. |
| Mouse | `bind_look` | Look | binding | `MouseMotion` | Fixed physical input | Immediately on Apply | `[controls]` | Live. Fixed mouse motion, not a key slot. |
| Combat | `bind_aim` | Aim / ADS | binding | `MouseRight` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Disabled with “Coming later” until the feature ships. |
| Combat | `bind_fire` | Fire | binding | `MouseLeft` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Godot gates safezones, role, and life state. |
| Combat | `bind_reload` | Reload | binding | `KeyB` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. R stays assigned to live Revive. Disabled with “Coming later” until the feature ships. |
| Combat | `bind_mask` | Put on mask | binding | `KeyF` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. |
| Combat | `bind_cop_duty` | Go on duty | binding | `KeyG` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. |
| Combat | `bind_surrender` | Surrender | binding | `KeyH` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | H sends the existing server request directly. Eligibility for the hint comes from HudState. |
| Interactions | `bind_interact` | Interact / lockpick / search | binding | `KeyE` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live shared contextual action. Planned generic interaction, e.g. alarm, NPC, doors and extraction prompts, can use it. |
| Interactions | `bind_smash` | Smash | binding | `KeyV` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live contextual loot action. |
| Interactions | `bind_revive` | Revive | binding | `KeyR` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Server channel. |
| Interactions | `bind_finish` | Finish off | binding | `KeyX` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Server channel. |
| Interactions | `bind_cuff` | Cuff | binding | `KeyC` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Server channel. |
| Interactions | `bind_search_take` | Take first search item | binding | `KeyT` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live developer shortcut. Target the current open search in the production binding. |
| Interactions | `bind_search_close` | Close body search | binding | `KeyQ` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Fixed active-panel fallback after rebind only if retained by the owner. |
| Interactions | `bind_sell_loot` | Sell loot | binding | `KeyY` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Debug builds only. Y replaces the existing developer sale key 5. |
| Inventory and map | `bind_inventory` | Inventory | binding | `Tab` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Live. Tab is an intentionally shared panel-focus key. |
| Inventory and map | `bind_hotbar_1` | Hotbar slot 1 | binding | `Digit1` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Normal hotbar selection on 1. Server still validates the selected action or equipment. |
| Inventory and map | `bind_hotbar_2` | Hotbar slot 2 | binding | `Digit2` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Normal hotbar selection on 2. Server still validates the selected action or equipment. |
| Inventory and map | `bind_hotbar_3` | Hotbar slot 3 | binding | `Digit3` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Normal hotbar selection on 3. Server still validates the selected action or equipment. |
| Inventory and map | `bind_hotbar_4` | Hotbar slot 4 | binding | `Digit4` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Normal hotbar selection on 4. Server still validates the selected action or equipment. |
| Inventory and map | `bind_hotbar_5` | Hotbar slot 5 | binding | `Digit5` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Normal hotbar selection on 5. Server still validates the selected action or equipment. |
| Inventory and map | `bind_hotbar_6` | Hotbar slot 6 | binding | `Digit6` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Normal hotbar selection on 6. Server still validates the selected action or equipment. |
| Inventory and map | `bind_map` | World map | binding | `KeyM` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. No gameplay map panel in this delivery. Disabled with “Coming later” until the feature ships. |
| Communication | `bind_ping` | Place ping | binding | `MouseMiddle` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Contextual world ping. Disabled with “Coming later” until the feature ships. |
| Communication | `bind_push_to_talk` | Push to talk | binding | `AltLeft` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Held only in enabled PTT mode. Disabled with “Coming later” until the feature ships. |
| Communication | `bind_chat` | Text chat | binding | `Enter` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Reserved Enter confirmation takes priority within UI panels. Disabled with “Coming later” until the feature ships. |
| Communication | `bind_emote` | Emote wheel | binding | `KeyJ` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Disabled with “Coming later” until the feature ships. |
| Communication | `bind_help` | Help | binding | `KeyK` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Planned. Disabled with “Coming later” until the feature ships. |
| Social and travel | `bind_party_create` | Create party | binding | `KeyP` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Create in game with P. Pause contains current party management and invitations. |
| Social and travel | `bind_join_motel` | Travel to Motel | binding | `Ctrl+Digit1` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Debug builds only. Ctrl+1 replaces developer travel key 1. |
| Social and travel | `bind_join_lootybay` | Travel to LootyBay | binding | `Ctrl+Digit2` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Debug builds only. Ctrl+2 replaces developer travel key 2. |
| Social and travel | `bind_join_house` | Travel to House | binding | `Ctrl+Digit3` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Debug builds only. Ctrl+3 replaces developer travel key 3. |
| Social and travel | `bind_join_center` | Travel to Center | binding | `Ctrl+Digit4` | Physical key / mouse / chord, null unbinds | Immediately on Apply | `[controls]` | Debug builds only. Ctrl+4 replaces developer travel key 4. |
| Interface | `bind_pause` | Pause / back | binding | `Escape` | Fixed physical input | Immediately on Apply | `[controls]` | Fixed global escape. Existing gameplay Esc releases pointer or closes inventory. |
| Interface | `reset_controls` | Reset Controls | action | `null` | Button | On activation | None | Stage defaults for all Controls keys. Apply saves. |

### Social

Party invites offers Everyone and Nobody for the current session. Mutes hold current peer IDs and reset on disconnect. The whole Voice group is hidden while `voice_chat` is absent. When available, Push to Talk is the default activation mode. The input threshold slider remains visible in the supported Voice group and is enabled only when Open Mic is selected. Its design default is −40 dBFS, with a −60–0 dBFS range and 1 dB steps. Changing mode uses the existing draft and Apply flow. Device rows reflect current host IDs and display clear fallback state.

| Group | Setting key | Label | Type | Default | Range or options | Apply | Storage | Behavior |
|---|---|---|---|---|---|---|---|---|
| Party and names | `party_invites` | Party invites | enum | `everyone` | `everyone`, `nobody` | Immediately on Apply | Session only | Session preference scoped to the current connection. Everyone or Nobody applies per peer. Clear on disconnect. |
| Party and names | `show_player_names` | Show player names | boolean | true | false / true | Immediately on Apply | `[social]` | Applies to displayed names. Local labels and teammate slots remain usable. |
| Party and names | `chat_filter` | Chat filter | boolean | true | false / true | Immediately on Apply | `[social]` | Enable supported cleanup on displayed chat. Dormant until chat ships. Disabled with “Coming later” until the feature ships. |
| Voice | `voice_chat` | Voice chat | boolean | false | false / true | Immediately on Apply | `[social]` | Whole Voice group requires the voice_chat capability. |
| Voice | `voice_mode` | Voice activation | enum | `push_to_talk` | `push_to_talk`, `open_mic` | Immediately on Apply | `[social]` | Push-to-talk by default. Open Mic is allowed after selection and microphone permission. Follows the whole Voice capability gate. |
| Voice | `voice_input_threshold` | Open mic threshold | integer | -40 | -60–0, step 1 | Immediately on Apply | `[social]` | Open Mic threshold in dBFS on local input level, default −40 dBFS. Hidden until voice_chat exists and disabled unless Open Mic is selected. Follows the whole Voice capability gate. |
| Voice | `voice_input_device` | Input device | device | `system_default` | `system_default` or ID from `SettingsView.devices` | Immediately on Apply | `[social]` | Stable Godot-provided device ID. Disconnected device falls back to system default and is flagged. Follows the whole Voice capability gate. |
| Voice | `voice_output_device` | Output device | device | `system_default` | `system_default` or ID from `SettingsView.devices` | Immediately on Apply | `[social]` | Stable Godot-provided device ID. Disconnected device falls back to system default and is flagged. Follows the whole Voice capability gate. |
| Voice | `voice_receive_volume` | Voice receive volume | integer | 100 | 0–100, step 1 | Immediately on Apply | `[social]` | Scale received voice before the global voice bus. Follows the whole Voice capability gate. |
| Voice | `muted_players` | Muted players | integer_array | `[]` | Positive peer IDs, unique, max 256 | Immediately on Apply | Session only | Unique current-session peer IDs, max 256. Reset on disconnect and never write to ConfigFile. Follows the whole Voice capability gate. |
| Privacy | `streamer_mode` | Streamer mode | boolean | false | false / true | Immediately on Apply | `[social]` | Mask server ID and player names in interface output, accessibility labels and local notifications. |

### Others

The English dropdown stays visible with one entry. Ordinary audio channels use their approved defaults. Voice bus volume follows the whole Voice capability. Telemetry and crash reports default off and wait for their backends. Ordinary toast duration is configurable. Heist event toasts use a fixed 8 s lifetime plus an active alert line. Credits are bundled text in the shared dialog.

| Group | Setting key | Label | Type | Default | Range or options | Apply | Storage | Behavior |
|---|---|---|---|---|---|---|---|---|
| Audio | `master_volume` | Master volume | integer | 100 | 0–100, step 1 | Immediately on Apply | `[others]` | Apply to the corresponding local audio bus. |
| Audio | `music_volume` | Music volume | integer | 70 | 0–100, step 1 | Immediately on Apply | `[others]` | Apply to the corresponding local audio bus. |
| Audio | `sfx_volume` | Sound effects volume | integer | 100 | 0–100, step 1 | Immediately on Apply | `[others]` | Apply to the corresponding local audio bus. |
| Audio | `ui_volume` | Interface sound volume | integer | 80 | 0–100, step 1 | Immediately on Apply | `[others]` | Apply to the corresponding local audio bus. |
| Audio | `voice_volume` | Voice bus volume | integer | 100 | 0–100, step 1 | Immediately on Apply | `[others]` | Apply to the corresponding local audio bus. Follows the whole Voice capability gate. |
| General | `language` | Language | enum | `en` | `en` | Immediately on Apply | `[others]` | Keep the dropdown visible with the single English option. |
| HUD | `minimap_rotate` | Rotate minimap | boolean | false | false / true | Immediately on Apply | `[others]` | Counter-rotate Godot minimap view with heading. Keep player arrow forward. |
| HUD | `show_compass` | Show compass | boolean | true | false / true | Immediately on Apply | `[others]` | Show the compass strip. |
| HUD | `show_damage_numbers` | Show damage numbers | boolean | false | false / true | Immediately on Apply | `[others]` | Applies after authoritative damage numbers ship. Disabled with “Coming later” until the feature ships. |
| HUD | `notifications_duration` | Notification duration | integer | 4 | 2–10, step 1 | Immediately on Apply | `[others]` | Seconds for ordinary toasts. Heist event toasts use 8 s and their active alert line lasts until server clear. |
| Privacy | `telemetry` | Share telemetry | boolean | false | false / true | Immediately on Apply | `[others]` | Default off. Hidden until telemetry_backend exists. |
| Privacy | `crash_reports` | Share crash reports | boolean | false | false / true | Immediately on Apply | `[others]` | Default off. Hidden until crash_reports_backend exists. |
| General | `credits` | Credits | action | `null` | Button | On activation | None | Open bundled credits in the dialog. No write. |
| General | `reset_all` | Reset all settings | action | `null` | Button | On activation | None | Stage defaults for all persisted settings after confirmation. Apply saves. |

## 5. Interactions

Start focus on the Settings title, then Back, active tab, group rail, visible controls, Reset, Discard and Apply. Tab bar uses Left/Right arrows and Enter/Space; group buttons scroll without changing settings. Slider readouts update on drag and keys. Toggles and select changes update the draft. Enter activates focused controls. Escape walks out of capture, popover, dialog, then screen. If dirty, offer Keep editing or Discard before leaving. Apply writes validated durable values; supported non-display settings apply immediately after commit. Reload settings after bridge reconnect and keep a draft only if the revision still matches.

For rebind, activate keybind row and ask Godot to capture one physical press/chord. Escape cancels. Mouse movement or wheel does not capture. Godot reserves Escape and ignores the initiating click, repeats, unsupported inputs and OS shortcuts. Tab may remain Inventory because host scopes UI traversal. If the same physical binding exists in the active gameplay context, show both action labels. Offer Cancel or Replace. Replace stages the new binding and clears the old editable binding in the same draft. Disable Replace if the other action is fixed. A separate Clear button within capture's secondary action menu stages unbound where allowed. Never clear default movement or Fire without explicit confirmation. Reset stages default values with a confirmation, then Apply commits. While capture owns inputs, route switches and gameplay are gated. Gamepad later.

## 6. Data

Read `settings` → `SettingsView.values`, `revision`, `capabilities`, `devices`, `displayModes`, `pendingRestart`, `preview` and `saveError`. Values include both durable and current-session preferences as classified by the schema. Send `settings.tab`, `settings.close`, `settings.capture`, `settings.capture_cancel`, `settings.apply`, `settings.display_confirm`. Reset, Discard, Credits and ordinary form edits act locally until Apply. Read schema keys, defaults and validation from [settings-schema.json](settings-schema.json).

## 7. Godot side

**NEW** `ui/settings/SettingsService.gd` owns Godot `ConfigFile` at `user://settings.cfg`, section equal to the tab for durable keys. Missing or invalid old values use schema defaults. Keep `party_invites` and `muted_players` in connection-scoped state keyed by current peer IDs, and clear them at disconnect. Ignore legacy disk values for those keys. Stage and validate a full patch, commit durable values atomically, then update session values only after success. Apply host capabilities using section 4.

[Main.gd](../../main/Main.gd), [Player.gd](../../features/player/Player.gd), [PlayerCamera.gd](../../features/player/PlayerCamera.gd), [Hud.gd](../../ui/hud/Hud.gd), [Minimap.gd](../../ui/hud/Minimap.gd), [GameConst.gd](../../lib/constants/GameConst.gd) and [uiScale.ts](../../ui/web/src/app/uiScale.ts) own the input, surfaces and current defaults to extend. Server PartyService enforces the synchronized current-session invite permission per peer. **NEW** voice/backend capabilities, devices and threshold processing are supplied by Godot when those integrations exist.

## 8. Accessibility

Body text ≥14 px, help ≥11 px, contrast ≥4.5:1. Pair active underline with selected semantics. On/Off, invalid state, pending restart and unsupported state use words. Focus comes back to original control after dropdown or dialog. Peek height preserves clear scroll affordance and focused controls auto-scroll fully into view. Reduced motion disables animated scroll. Announce preview once and at five seconds remaining. Give error summary an accessible label and focus the first invalid editable control after dismissal.

## 9. Decisions

1. Decided 2026-11-27: Keep approved defaults and restart flags. Apply the renderer availability rule in section 4.
2. Decided 2026-11-27: Use Ctrl+1–4 for debug travel and Y for debug sale. Reserve normal 1–6 for hotbar selection, B for Reload and R for Revive.
3. Decided 2026-11-27: List future chat, map, help, emotes and voice bindings disabled with “Coming later” until each feature ships.
4. Decided 2026-11-27: Invite permissions and mute list are session-only per peer. Gate the whole Voice section, default to Push to Talk, and support Open Mic with its input-threshold slider.
5. Decided 2026-11-27: Expose 90–110% UI scale for the implementation smoke. Keep telemetry/crash reports off and hidden until backends exist. Keep the single-entry English dropdown.
