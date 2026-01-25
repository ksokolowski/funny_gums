#!/usr/bin/env bash
# emojis.sh - Safe colorful emoji constants for terminal UI
#
# IMPORTANT: Some emojis break gum frame alignment in terminals.
# Avoid emojis with:
#   - VS16 (Variation Selector 16, U+FE0F) - forces emoji presentation
#   - ZWJ (Zero Width Joiner) sequences - combined emojis
#
# This file provides tested, safe, COLORFUL emojis organized by semantic category.
# All emojis have been verified to work correctly in gum frames.

# Prevent multiple sourcing
[[ -n "${_EMOJIS_SH_LOADED:-}" ]] && return 0
_EMOJIS_SH_LOADED=1

################################################################################
# STATUS INDICATORS
################################################################################
EMOJI_SUCCESS="✅"        # Completed successfully (green checkmark)
EMOJI_FAILURE="❌"        # Failed/error (red X)
EMOJI_WARNING="🟡"        # Warning (yellow circle)
EMOJI_PENDING="⬜"        # Not started (white square)
EMOJI_SKIP="⏩"           # Skipped (fast forward)
EMOJI_RUNNING="⏳"        # In progress (hourglass)
EMOJI_DONE="✨"           # All done/sparkles
EMOJI_OK="🟢"             # OK/good (green circle)
EMOJI_ERROR="🔴"          # Error (red circle)
EMOJI_PAUSED="🟠"         # Paused/waiting (orange circle)

################################################################################
# COLORED CIRCLES (for status/indicators)
################################################################################
EMOJI_RED="🔴"
EMOJI_ORANGE="🟠"
EMOJI_YELLOW="🟡"
EMOJI_GREEN="🟢"
EMOJI_BLUE="🔵"
EMOJI_PURPLE="🟣"
EMOJI_BLACK="⚫"
EMOJI_WHITE="⚪"

################################################################################
# COLORED SQUARES (for grids/dashboards)
################################################################################
EMOJI_RED_SQ="🟥"
EMOJI_ORANGE_SQ="🟧"
EMOJI_YELLOW_SQ="🟨"
EMOJI_GREEN_SQ="🟩"
EMOJI_BLUE_SQ="🟦"
EMOJI_PURPLE_SQ="🟪"
EMOJI_BLACK_SQ="⬛"
EMOJI_WHITE_SQ="⬜"

################################################################################
# COLORED DIAMONDS (for highlights)
################################################################################
EMOJI_ORANGE_DIAMOND="🔶"
EMOJI_BLUE_DIAMOND="🔷"
EMOJI_SMALL_ORANGE="🔸"
EMOJI_SMALL_BLUE="🔹"
EMOJI_DIAMOND="💎"
EMOJI_DIAMOND_DOT="💠"

################################################################################
# COLORED HEARTS (for favorites/love)
################################################################################
EMOJI_HEART_RED="❤"       # Note: no VS16
EMOJI_HEART_ORANGE="🧡"
EMOJI_HEART_YELLOW="💛"
EMOJI_HEART_GREEN="💚"
EMOJI_HEART_BLUE="💙"
EMOJI_HEART_PURPLE="💜"
EMOJI_HEART_BLACK="🖤"
EMOJI_HEART_WHITE="🤍"
EMOJI_HEART_PINK="💗"
EMOJI_HEART_SPARK="💖"

################################################################################
# ACTIONS / OPERATIONS
################################################################################
EMOJI_SETUP="🔧"          # Setup/configure (wrench)
EMOJI_PROCESS="🔄"        # Processing/converting (arrows)
EMOJI_BUILD="🔨"          # Building/compiling (hammer)
EMOJI_INSTALL="📥"        # Installing/downloading (inbox)
EMOJI_REMOVE="🗑"         # Removing/deleting (wastebasket, no VS16)
EMOJI_UPDATE="🔃"         # Updating/syncing (arrows)
EMOJI_SEARCH="🔍"         # Searching (magnifier)
EMOJI_LOCK="🔐"           # Authentication/locked
EMOJI_UNLOCK="🔓"         # Unlocked
EMOJI_KEY="🔑"            # Credentials/keys
EMOJI_SAVE="💾"           # Saving/disk
EMOJI_CLEAN="🧹"          # Cleanup (broom)
EMOJI_LINK="🔗"           # Link/chain
EMOJI_SCISSORS="✂"        # Cut (no VS16)
EMOJI_PIN="📌"            # Pin/important
EMOJI_CLIP="📎"           # Paperclip/attach
EMOJI_EDIT="📝"           # Edit/memo
EMOJI_COPY="📋"           # Copy/clipboard

################################################################################
# MILESTONES / ACHIEVEMENTS
################################################################################
EMOJI_TROPHY="🏆"         # Achievement/winner
EMOJI_MEDAL="🏅"          # Medal/award
EMOJI_STAR="⭐"           # Star/favorite
EMOJI_GLOWING_STAR="🌟"   # Glowing star/highlight
EMOJI_TARGET="🎯"         # Target/goal reached
EMOJI_FLAG="🚩"           # Milestone flag
EMOJI_CHECKERED="🏁"      # Finish line
EMOJI_PARTY="🎉"          # Celebration
EMOJI_CONFETTI="🎊"       # Confetti
EMOJI_BALLOON="🎈"        # Balloon
EMOJI_GIFT="🎁"           # Gift/reward
EMOJI_CROWN="👑"          # Crown/king
EMOJI_GEM="💎"            # Gem/premium
EMOJI_ROCKET="🚀"         # Launch/deploy

################################################################################
# CATEGORIES / DOMAINS
################################################################################
EMOJI_NETWORK="🌐"        # Network/internet (globe)
EMOJI_FILES="📁"          # Files/folders
EMOJI_FILE="📄"           # Single file
EMOJI_PACKAGE="📦"        # Packages/archives
EMOJI_DATABASE="🗄"       # Database (no VS16)
EMOJI_CLOUD="☁"           # Cloud (no VS16)
EMOJI_SERVER="🖥"         # Server (no VS16)
EMOJI_TERMINAL="💻"       # Terminal/console
EMOJI_PHONE="📱"          # Mobile
EMOJI_MAIL="📧"           # Email
EMOJI_CALENDAR="📅"       # Date/schedule
EMOJI_CLOCK="🕐"          # Time
EMOJI_BOOKMARK="🔖"       # Bookmark/saved
EMOJI_TAG="🏷"            # Tag/label (no VS16)

################################################################################
# HARDWARE
################################################################################
EMOJI_CPU="🔲"            # CPU/processor
EMOJI_MEMORY="🧠"         # RAM/memory (brain)
EMOJI_DISK="💾"           # Storage/disk
EMOJI_GPU="🎮"            # Graphics (gamepad)
EMOJI_POWER="🔋"          # Battery/power
EMOJI_TEMP="🌡"           # Temperature (no VS16)
EMOJI_FAN="🌀"            # Fan/cooling (cyclone)
EMOJI_RGB="🌈"            # RGB/lighting (rainbow)
EMOJI_USB="🔌"            # USB/connections (plug)
EMOJI_SPEAKER="🔊"        # Audio/speaker
EMOJI_MIC="🎤"            # Microphone
EMOJI_CAMERA="📷"         # Camera
EMOJI_PRINTER="🖨"        # Printer (no VS16)
EMOJI_LIGHT="💡"          # Light/idea

################################################################################
# SYSTEM / SERVICES
################################################################################
EMOJI_SERVICE="⚡"        # Service/daemon (lightning)
EMOJI_START="▶"           # Start (no VS16)
EMOJI_STOP="⏹"           # Stop
EMOJI_PAUSE="⏸"          # Pause
EMOJI_RESTART="🔁"        # Restart/reload
EMOJI_PLAY="🎵"           # Play/media
EMOJI_NEXT="⏭"           # Next (no VS16)
EMOJI_PREV="⏮"           # Previous (no VS16)

################################################################################
# ALERTS / NOTIFICATIONS
################################################################################
EMOJI_ALERT="🚨"          # Critical alert (siren)
EMOJI_BELL="🔔"           # Notification bell
EMOJI_BELL_OFF="🔕"       # Muted
EMOJI_MEGAPHONE="📢"      # Announcement
EMOJI_LOUDSPEAKER="📣"    # Loudspeaker
EMOJI_SPEECH="💬"         # Speech bubble
EMOJI_THOUGHT="💭"        # Thought bubble
EMOJI_FIRE="🔥"           # Hot/critical/trending
EMOJI_BOOM="💥"           # Explosion/impact
EMOJI_ZAP="⚡"            # Electric/fast

################################################################################
# NAVIGATION / DIRECTIONS
################################################################################
EMOJI_UP="⬆"              # Up (no VS16)
EMOJI_DOWN="⬇"            # Down (no VS16)
EMOJI_LEFT="⬅"            # Left (no VS16)
EMOJI_RIGHT="➡"           # Right (no VS16)
EMOJI_BACK="🔙"           # Back
EMOJI_TOP="🔝"            # Top
EMOJI_SOON="🔜"           # Soon/coming
EMOJI_NEW="🆕"            # New
EMOJI_FREE="🆓"           # Free
EMOJI_COOL="🆒"           # Cool
EMOJI_OK_BUTTON="🆗"      # OK button
EMOJI_SOS="🆘"            # SOS/help

################################################################################
# NATURE / DECORATIVE
################################################################################
EMOJI_SUN="☀"             # Sun (no VS16)
EMOJI_MOON="🌙"           # Moon
EMOJI_RAINBOW="🌈"        # Rainbow
EMOJI_SNOWFLAKE="❄"       # Snow/cold (no VS16)
EMOJI_DROPLET="💧"        # Water/droplet
EMOJI_LEAF="🍀"           # Four leaf clover/luck
EMOJI_TREE="🌴"           # Palm tree
EMOJI_FLOWER="🌸"         # Cherry blossom
EMOJI_SUNFLOWER="🌻"      # Sunflower
EMOJI_ROSE="🌹"           # Rose
EMOJI_CACTUS="🌵"         # Cactus
EMOJI_MUSHROOM="🍄"       # Mushroom

################################################################################
# FOOD & DRINK (for fun themes)
################################################################################
EMOJI_APPLE="🍎"          # Apple
EMOJI_ORANGE_FRUIT="🍊"   # Orange
EMOJI_LEMON="🍋"          # Lemon
EMOJI_GRAPES="🍇"         # Grapes
EMOJI_STRAWBERRY="🍓"     # Strawberry
EMOJI_PIZZA="🍕"          # Pizza
EMOJI_COFFEE="☕"         # Coffee
EMOJI_BEER="🍺"           # Beer
EMOJI_CAKE="🎂"           # Birthday cake
EMOJI_COOKIE="🍪"         # Cookie
EMOJI_CANDY="🍬"          # Candy
EMOJI_ICE_CREAM="🍦"      # Ice cream

################################################################################
# ANIMALS (for mascots/fun)
################################################################################
EMOJI_CAT="🐱"            # Cat
EMOJI_DOG="🐶"            # Dog
EMOJI_UNICORN="🦄"        # Unicorn
EMOJI_DRAGON="🐉"         # Dragon
EMOJI_BUTTERFLY="🦋"      # Butterfly
EMOJI_BEE="🐝"            # Bee
EMOJI_TURTLE="🐢"         # Turtle (slow)
EMOJI_RABBIT="🐰"         # Rabbit (fast)
EMOJI_OWL="🦉"            # Owl (wise)
EMOJI_FOX="🦊"            # Fox (clever)
EMOJI_PENGUIN="🐧"        # Penguin
EMOJI_OCTOPUS="🐙"        # Octopus

################################################################################
# FACES / EXPRESSIONS (for feedback)
################################################################################
EMOJI_SMILE="😊"          # Happy/success
EMOJI_GRIN="😄"           # Very happy
EMOJI_WINK="😉"           # Wink
EMOJI_COOL_FACE="😎"      # Cool
EMOJI_THINKING="🤔"       # Thinking
EMOJI_SURPRISED="😮"      # Surprised
EMOJI_SAD="😢"            # Sad
EMOJI_ANGRY="😠"          # Angry
EMOJI_SLEEPING="😴"       # Sleeping/idle
EMOJI_NERD="🤓"           # Nerd/technical
EMOJI_ROBOT="🤖"          # Robot/automated
EMOJI_GHOST="👻"          # Ghost/hidden

################################################################################
# HANDS / GESTURES
################################################################################
EMOJI_THUMBS_UP="👍"      # Approve
EMOJI_THUMBS_DOWN="👎"    # Disapprove
EMOJI_CLAP="👏"           # Applause
EMOJI_WAVE="👋"           # Wave/hello
EMOJI_POINT_UP="👆"       # Point up
EMOJI_POINT_DOWN="👇"     # Point down
EMOJI_POINT_RIGHT="👉"    # Point right
EMOJI_POINT_LEFT="👈"     # Point left
EMOJI_MUSCLE="💪"         # Strong/power
EMOJI_PRAY="🙏"           # Please/thanks

################################################################################
# MISC SYMBOLS
################################################################################
EMOJI_CHECK="✓"           # Simple checkmark (text)
EMOJI_CROSS="✗"           # Simple cross (text)
EMOJI_BULLET="•"          # Bullet point (text)
EMOJI_ARROW="→"           # Arrow (text)
EMOJI_INFINITY="♾"        # Infinity
EMOJI_RECYCLE="♻"         # Recycle
EMOJI_SPARKLE="❇"         # Sparkle (no VS16)
EMOJI_QUESTION="❓"       # Question
EMOJI_EXCLAIM="❗"        # Exclamation
EMOJI_HUNDRED="💯"        # 100/perfect

################################################################################
# THEMED SETS - Quick access for common themes
################################################################################
# Traffic light status: 🔴 🟡 🟢
# Priority levels: 🔴 🟠 🟡 🟢 🔵
# Progress stages: ⬜ 🟨 🟩 ✅
# Build status: 🔄 🔨 📦 🚀 ✅
# Severity: 💡 🟡 🟠 🔴 🚨

################################################################################
# UNSAFE EMOJIS - DO NOT USE (break gum frame alignment)
################################################################################
# ⚙️  - Gear (has VS16)
# ⏭️  - Next track (has VS16) - use ⏭ instead
# ⏮️  - Previous track (has VS16) - use ⏮ instead
# ⏯️  - Play/pause (has VS16)
# ▶️  - Play (has VS16) - use ▶ instead
# ⏸️  - Pause (has VS16)
# ⏺️  - Record (has VS16)
# ⏏️  - Eject (has VS16)
# ⚠️  - Warning (has VS16) - use 🟡 instead
# ❤️  - Red heart (has VS16) - use ❤ instead
# ☀️  - Sun (has VS16) - use ☀ instead
# ❄️  - Snowflake (has VS16) - use ❄ instead
# ☁️  - Cloud (has VS16) - use ☁ instead
# 🗑️  - Wastebasket (has VS16) - use 🗑 instead
# 🖥️  - Desktop (has VS16) - use 🖥 instead
# 🖨️  - Printer (has VS16) - use 🖨 instead
# 🏷️  - Label (has VS16) - use 🏷 instead
# ⌨️  - Keyboard (has VS16)
# 🖱️  - Mouse (has VS16)
# 🕹️  - Joystick (has VS16)
# 🗄️  - File cabinet (has VS16) - use 🗄 instead
# 👨‍💻 - Man technologist (ZWJ sequence)
# 👩‍💻 - Woman technologist (ZWJ sequence)
# Any skin-toned emojis (modifier sequences)
# Any flag emojis (regional indicator sequences)

################################################################################
# USAGE EXAMPLES
################################################################################
# source lib/core/emojis.sh
#
# # Status indicators
# echo "$EMOJI_SUCCESS Task completed"
# echo "$EMOJI_WARNING Check configuration"
# echo "$EMOJI_ERROR Connection failed"
#
# # Milestones
# echo "$EMOJI_PIN Important milestone reached"
# echo "$EMOJI_TROPHY Achievement unlocked!"
# echo "$EMOJI_PARTY All tests passed!"
#
# # Category icons for dashboard
# declare -A CATEGORY_ICON=(
#     [setup]="$EMOJI_SETUP"
#     [build]="$EMOJI_BUILD"
#     [test]="$EMOJI_TARGET"
#     [deploy]="$EMOJI_ROCKET"
#     [done]="$EMOJI_PARTY"
# )
#
# # Traffic light status
# case "$status" in
#     error)   echo "$EMOJI_RED $message" ;;
#     warning) echo "$EMOJI_YELLOW $message" ;;
#     ok)      echo "$EMOJI_GREEN $message" ;;
# esac
