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
const HUD_MINIMAP_RECT := Rect2(24, 40, 200, 170)  # px; must match ui/web/src/features/hud/layout.ts MINIMAP
const HUD_MINIMAP_WORLD_SIZE: float = 60.0         # metres shown top to bottom
const HUD_MINIMAP_HEIGHT: float = 80.0             # camera height above the player
const UI_PAGE_URL: String = "res://ui/dist/index.html"  # built web UI (ui/web/ -> ui/dist/)
const UI_DEV_URL: String = "http://localhost:5173/"     # Vite dev server
const UI_DEV_FLAG: String = "--ui-dev"                  # client user arg: load UI_DEV_URL
