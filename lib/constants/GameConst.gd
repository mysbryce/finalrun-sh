class_name GameConst
extends RefCounted
## Single source of truth for names, capacities, timings and other magic values.
##
## `lib/` depends on nothing else in the project, so this file must never import
## a scene, feature or map. Scripts outside `lib/` reference `GameConst.X`
## instead of repeating literals.

# --- Maps --------------------------------------------------------------------

const MAP_MOTEL: String = "Motel"
const MAP_LOOTY_BAY: String = "LootyBay"
const MAP_HOUSE: String = "House"
const MAP_CENTER: String = "Center"

const INSTANCED_MAPS: Array[String] = [MAP_MOTEL, MAP_LOOTY_BAY]
const SHARED_MAPS: Array[String] = [MAP_HOUSE, MAP_CENTER]

# --- Networking / lifecycle --------------------------------------------------

const PORT: int = 7777
const MAX_CLIENTS: int = 64

const SERVER_ID_PREFIX: String = "SV-SPACE-"
const SERVER_ID_MODULO: int = 10000
const MAX_SERVER_ID: int = 9999

const EMPTY_INSTANCE_FREE_SECONDS: float = 60.0
const TRANSFER_TIMEOUT_SECONDS: float = 10.0

# --- Map config --------------------------------------------------------------

const DEFAULT_MAP_CAPACITY: int = 16

const MAP_CAPACITY := {
	MAP_MOTEL: 16,
	MAP_LOOTY_BAY: 12,
	MAP_HOUSE: MAX_CLIENTS,
	MAP_CENTER: MAX_CLIENTS,
}

const MAP_SAFEZONE := {
	MAP_MOTEL: true,
	MAP_LOOTY_BAY: false,
	MAP_HOUSE: false,
	MAP_CENTER: false,
}

const ZONE_EXTRACT: String = "ExtractZone"
const ZONE_POLICE_STATION: String = "PoliceStation"
const ZONE_NAMES: Array[String] = [ZONE_EXTRACT, ZONE_POLICE_STATION]

# --- Party -------------------------------------------------------------------

const PARTY_MAX_MEMBERS: int = 3
const PARTY_INVITE_TTL_MS: int = 30000  # server-side invite lifetime
const PARTY_PENDING_TIMEOUT_MS: int = 5000  # client clears the pending flag after this

# --- Player rules ------------------------------------------------------------

const MASK_CHANNEL_SECONDS: float = 3.0
const MASK_MOVE_CANCEL_DISTANCE: float = 0.5
const SURRENDER_RANGE: float = 6.0
const SURRENDER_COP_REWARD_RATIO: float = 0.5
const NOTORIETY_DIVISOR: float = 10000.0
const NOTORIETY_MAX_BONUS: float = 1.5

const ATTACK_RANGE: float = 40.0
const ATTACK_DAMAGE: int = 25
const FIRE_INTERVAL_MS: int = 250  # minimum time between shots per player
const LINE_OF_SIGHT_EYE_HEIGHT: float = 1.4
const LINE_OF_SIGHT_TARGET_HEIGHT: float = 1.2

const WORLD_COLLISION_LAYER: int = 1
const PLAYERS_COLLISION_LAYER: int = 2
## World + players: the only two physics layers an attack raycast may hit.
const RAYCAST_COLLISION_MASK: int = 3

const PLAYER_SPEED: float = 5.0
const PLAYER_GRAVITY: float = 18.0
const PLAYER_INPUT_SEND_INTERVAL: float = 0.05
const PLAYER_MAX_HEALTH: int = 100
const PLAYER_SYNC_INTERVAL: float = 0.05   # seconds between position snapshots (20 Hz)
const PLAYER_INTERP_RATE: float = 15.0     # exponential smoothing rate per second
const PLAYER_SNAP_DISTANCE: float = 3.0    # metres; larger gaps teleport instead of sliding

# Camera
const CAMERA_PIVOT_HEIGHT: float = 1.6
const CAMERA_DISTANCE: float = 4.5
const CAMERA_MOUSE_SENSITIVITY: float = 0.003  # radians per pixel
const CAMERA_PITCH_MIN: float = -1.2           # radians, looking down
const CAMERA_PITCH_MAX: float = 0.6            # radians, looking up
const PLAYER_TURN_SPEED: float = 12.0          # lerp_angle rate per second

# Appearance
const APPEARANCE_SLOTS: PackedStringArray = ["hair", "top", "bottom", "shoes", "hat", "mask"]
const BODY_TYPES: PackedStringArray = ["male", "female"]
const COSMETICS_DIR: String = "res://data/cosmetics/"
const BODY_MODELS: Dictionary = {
	"male": "res://assets/characters/kenney_mini_characters/character-male-a.glb",
	"female": "res://assets/characters/kenney_mini_characters/character-female-a.glb",
}
const CHARACTER_HEIGHT: float = 1.8            # target visual height in metres
const ANIM_WALK_SPEED: float = 0.5             # m/s; below this play idle (10% of PLAYER_SPEED)
const ANIM_SPRINT_SPEED: float = 4.5           # m/s; at or above this play sprint (90% of PLAYER_SPEED)
const ANIM_BLEND_TIME: float = 0.15            # seconds

# --- Downed state ------------------------------------------------------------

const DOWNED_BLEEDOUT_SECONDS: float = 60.0
const DOWNED_HIT_PENALTY_SECONDS: float = 5.0
const DOWNED_CRAWL_SPEED: float = 1.2
const REDOWN_WINDOW_SECONDS: float = 30.0
const REVIVE_SECONDS: float = 5.0
const REVIVE_HP_RATIO: float = 0.25
const FINISH_SECONDS: float = 2.0
const CUFF_SECONDS: float = 3.0
const SEARCH_OPEN_SECONDS: float = 1.5
const SEIZURE_COP_REWARD_RATIO: float = 0.25
const INTERACT_RANGE: float = 2.5
const DOWNED_CHANNEL_MAX_MOVE: float = 0.75

# HUD
const HUD_NOTIFICATION_MS: int = 4000   # how long a notification stays on screen
const HUD_MAX_NOTIFICATIONS: int = 4    # newest kept, oldest dropped
const HUD_HOTBAR_SLOTS: int = 6  # hotbar slots, keys 1-6
const INVENTORY_BAG_COLUMNS: int = 6
const INVENTORY_BAG_SLOTS: int = 54  # bag grid slots (6 columns x 9 rows)
const HUD_MINIMAP_RECT := Rect2(24, 40, 200, 170)  # px; must match ui/web/src/features/hud/layout.ts MINIMAP
const HUD_MINIMAP_WORLD_SIZE: float = 60.0         # metres shown top to bottom
const HUD_MINIMAP_HEIGHT: float = 80.0             # camera height above the player
const UI_PAGE_URL: String = "res://ui/dist/index.html"  # built web UI (ui/web/ -> ui/dist/)
const UI_DEV_URL: String = "http://localhost:5173/"     # Vite dev server
const UI_DEV_FLAG: String = "--ui-dev"                  # client user arg: load UI_DEV_URL
const NEWS_PATH: String = "res://ui/dist/news.json"     # patch notes (ui/web/public/news.json, copied by Vite)

# Settings
const SETTINGS_PATH: String = "user://settings.cfg"  # durable settings, section = tab
const SETTINGS_SCHEMA_PATH: String = "res://ui/dist/settings-schema.json"  # ui/web/public/settings-schema.json, copied by Vite
const SETTINGS_TABS: PackedStringArray = ["graphics", "controls", "social", "others"]
const SHADOW_ATLAS_SIZES := {"low": 1024, "medium": 2048, "high": 4096}  # directional shadow atlas px per `shadows` option
const VIEW_DISTANCE_FAR := {"low": 150.0, "medium": 300.0, "high": 600.0}  # Camera3D.far (m) per `view_distance` option
## Command-line flags that set the window: display settings are not applied at startup when any is present.
const DISPLAY_CMDLINE_FLAGS: PackedStringArray = ["--resolution", "--position", "--windowed", "-w", "--fullscreen", "-f"]
## Volume setting key -> audio bus name (buses are created at startup by SettingsApplier).
const AUDIO_BUSES: Dictionary = {"music_volume": "Music", "sfx_volume": "SFX", "ui_volume": "UI"}
const STREAMER_ID_MODULO: int = 100      # streamer mode keeps only the last two digits of a peer ID
const STREAMER_MASK: String = "••"       # streamer mode prefix replacing the hidden peer ID digits
const SERVER_ID_MASK: String = "••••"    # streamer mode replacement for the server ID number
const DISPLAY_PREVIEW_MS: int = 15000  # display preview reverts unless kept within this time

# Input bindings
## Binding settings whose value can never change (Escape stays hard-coded in Main).
const FIXED_BINDINGS: PackedStringArray = ["bind_look", "bind_pause"]
const CAPTURE_TIMEOUT_MS: int = 15000  # settings.capture gives up after this
const ACTION_MOVE_FORWARD := "bind_move_forward"
const ACTION_MOVE_LEFT := "bind_move_left"
const ACTION_MOVE_BACK := "bind_move_back"
const ACTION_MOVE_RIGHT := "bind_move_right"
const ACTION_FIRE := "bind_fire"
const LOOK_BINDING_CODE := "MouseMotion"  # fixed Look binding; never produced by an event
## Binding modifier prefixes, in the only allowed order.
const BINDING_MODIFIERS: PackedStringArray = ["Ctrl", "Alt", "Shift"]
const BINDING_SEPARATOR := "+"

# Boot
const BOOT_TITLE_DWELL_MS: int = 800        # minimum title card time
const BOOT_SKIP_AFTER_MS: int = 250         # Enter skips the title only after this
const BOOT_CEF_TIMEOUT_MS: int = 15000      # page must send `ready` within this per attempt
const BOOT_CONNECT_TIMEOUT_MS: int = 12000  # connection attempt timeout
const BOOT_FALLBACK_LAYER: int = 10         # CanvasLayer of the native fallback (above the Hud)
const DEFAULT_SERVER_HOST: String = "127.0.0.1"  # client connects here unless `--connect host:port`
