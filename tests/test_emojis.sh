#!/usr/bin/env bash
# test_emojis.sh - Visual test for safe emojis in gum frames
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$PROJECT_DIR/lib/core/colors.sh"
source "$PROJECT_DIR/lib/core/emojis.sh"
source "$PROJECT_DIR/lib/ui/ui.sh"

echo ""
echo "Testing safe colorful emojis in gum frames..."
echo "All right borders should align properly."
echo ""

# Test status indicators
ui_box --width 60 --padding "0 2" \
    "${BOLD}Status Indicators${RESET}" \
    "$EMOJI_SUCCESS Success    $EMOJI_FAILURE Failure" \
    "$EMOJI_WARNING Warning    $EMOJI_OK OK" \
    "$EMOJI_ERROR Error       $EMOJI_PAUSED Paused" \
    "$EMOJI_PENDING Pending    $EMOJI_SKIP Skip" \
    "$EMOJI_RUNNING Running    $EMOJI_DONE Done"

echo ""

# Test colored circles
ui_box --width 60 --padding "0 2" \
    "${BOLD}Colored Circles${RESET}" \
    "$EMOJI_RED Red  $EMOJI_ORANGE Orange  $EMOJI_YELLOW Yellow  $EMOJI_GREEN Green" \
    "$EMOJI_BLUE Blue  $EMOJI_PURPLE Purple  $EMOJI_BLACK Black  $EMOJI_WHITE White"

echo ""

# Test colored squares
ui_box --width 60 --padding "0 2" \
    "${BOLD}Colored Squares${RESET}" \
    "$EMOJI_RED_SQ $EMOJI_ORANGE_SQ $EMOJI_YELLOW_SQ $EMOJI_GREEN_SQ $EMOJI_BLUE_SQ $EMOJI_PURPLE_SQ $EMOJI_BLACK_SQ $EMOJI_WHITE_SQ"

echo ""

# Test diamonds
ui_box --width 60 --padding "0 2" \
    "${BOLD}Diamonds${RESET}" \
    "$EMOJI_ORANGE_DIAMOND Orange  $EMOJI_BLUE_DIAMOND Blue  $EMOJI_DIAMOND Gem" \
    "$EMOJI_SMALL_ORANGE Small  $EMOJI_SMALL_BLUE Small  $EMOJI_DIAMOND_DOT Dot"

echo ""

# Test hearts
ui_box --width 60 --padding "0 2" \
    "${BOLD}Hearts${RESET}" \
    "$EMOJI_HEART_RED $EMOJI_HEART_ORANGE $EMOJI_HEART_YELLOW $EMOJI_HEART_GREEN $EMOJI_HEART_BLUE" \
    "$EMOJI_HEART_PURPLE $EMOJI_HEART_BLACK $EMOJI_HEART_WHITE $EMOJI_HEART_PINK $EMOJI_HEART_SPARK"

echo ""

# Test actions
ui_box --width 60 --padding "0 2" \
    "${BOLD}Actions / Operations${RESET}" \
    "$EMOJI_SETUP Setup      $EMOJI_PROCESS Process   $EMOJI_BUILD Build" \
    "$EMOJI_INSTALL Install   $EMOJI_REMOVE Remove    $EMOJI_UPDATE Update" \
    "$EMOJI_SEARCH Search     $EMOJI_LOCK Lock       $EMOJI_UNLOCK Unlock" \
    "$EMOJI_KEY Key          $EMOJI_SAVE Save       $EMOJI_CLEAN Clean" \
    "$EMOJI_LINK Link        $EMOJI_PIN Pin         $EMOJI_CLIP Clip" \
    "$EMOJI_EDIT Edit        $EMOJI_COPY Copy       $EMOJI_SCISSORS Cut"

echo ""

# Test milestones
ui_box --width 60 --padding "0 2" \
    "${BOLD}Milestones / Achievements${RESET}" \
    "$EMOJI_TROPHY Trophy     $EMOJI_MEDAL Medal     $EMOJI_CROWN Crown" \
    "$EMOJI_STAR Star        $EMOJI_GLOWING_STAR Glow      $EMOJI_GEM Gem" \
    "$EMOJI_TARGET Target     $EMOJI_FLAG Flag      $EMOJI_CHECKERED Finish" \
    "$EMOJI_PARTY Party      $EMOJI_CONFETTI Confetti  $EMOJI_BALLOON Balloon" \
    "$EMOJI_GIFT Gift"

echo ""

# Test categories
ui_box --width 60 --padding "0 2" \
    "${BOLD}Categories / Domains${RESET}" \
    "$EMOJI_NETWORK Network   $EMOJI_FILES Folder    $EMOJI_FILE File" \
    "$EMOJI_PACKAGE Package   $EMOJI_DATABASE DB       $EMOJI_CLOUD Cloud" \
    "$EMOJI_SERVER Server     $EMOJI_TERMINAL Term     $EMOJI_PHONE Phone" \
    "$EMOJI_MAIL Mail        $EMOJI_CALENDAR Calendar $EMOJI_CLOCK Clock" \
    "$EMOJI_BOOKMARK Bookmark  $EMOJI_TAG Tag"

echo ""

# Test hardware
ui_box --width 60 --padding "0 2" \
    "${BOLD}Hardware${RESET}" \
    "$EMOJI_CPU CPU         $EMOJI_MEMORY Memory    $EMOJI_DISK Disk" \
    "$EMOJI_GPU GPU         $EMOJI_POWER Power     $EMOJI_TEMP Temp" \
    "$EMOJI_FAN Fan         $EMOJI_RGB RGB        $EMOJI_USB USB" \
    "$EMOJI_SPEAKER Speaker   $EMOJI_MIC Mic        $EMOJI_CAMERA Camera" \
    "$EMOJI_PRINTER Printer   $EMOJI_LIGHT Light"

echo ""

# Test system/services
ui_box --width 60 --padding "0 2" \
    "${BOLD}System / Services${RESET}" \
    "$EMOJI_SERVICE Service   $EMOJI_START Start     $EMOJI_STOP Stop" \
    "$EMOJI_PAUSE Pause      $EMOJI_RESTART Restart   $EMOJI_PLAY Play" \
    "$EMOJI_NEXT Next       $EMOJI_PREV Prev"

echo ""

# Test alerts
ui_box --width 60 --padding "0 2" \
    "${BOLD}Alerts / Notifications${RESET}" \
    "$EMOJI_ALERT Alert      $EMOJI_BELL Bell      $EMOJI_BELL_OFF Muted" \
    "$EMOJI_MEGAPHONE Mega      $EMOJI_LOUDSPEAKER Loud      $EMOJI_SPEECH Speech" \
    "$EMOJI_THOUGHT Thought    $EMOJI_FIRE Fire      $EMOJI_BOOM Boom" \
    "$EMOJI_ZAP Zap"

echo ""

# Test navigation
ui_box --width 60 --padding "0 2" \
    "${BOLD}Navigation / Directions${RESET}" \
    "$EMOJI_UP Up  $EMOJI_DOWN Down  $EMOJI_LEFT Left  $EMOJI_RIGHT Right" \
    "$EMOJI_BACK Back  $EMOJI_TOP Top  $EMOJI_SOON Soon" \
    "$EMOJI_NEW New  $EMOJI_FREE Free  $EMOJI_COOL Cool  $EMOJI_OK_BUTTON OK  $EMOJI_SOS SOS"

echo ""

# Test nature
ui_box --width 60 --padding "0 2" \
    "${BOLD}Nature / Decorative${RESET}" \
    "$EMOJI_SUN Sun  $EMOJI_MOON Moon  $EMOJI_RAINBOW Rainbow  $EMOJI_SNOWFLAKE Snow" \
    "$EMOJI_DROPLET Water  $EMOJI_LEAF Leaf  $EMOJI_TREE Tree  $EMOJI_CACTUS Cactus" \
    "$EMOJI_FLOWER Blossom  $EMOJI_SUNFLOWER Sunflower  $EMOJI_ROSE Rose  $EMOJI_MUSHROOM Mushroom"

echo ""

# Test food
ui_box --width 60 --padding "0 2" \
    "${BOLD}Food & Drink${RESET}" \
    "$EMOJI_APPLE Apple  $EMOJI_ORANGE_FRUIT Orange  $EMOJI_LEMON Lemon  $EMOJI_GRAPES Grapes" \
    "$EMOJI_STRAWBERRY Berry  $EMOJI_PIZZA Pizza  $EMOJI_COFFEE Coffee  $EMOJI_BEER Beer" \
    "$EMOJI_CAKE Cake  $EMOJI_COOKIE Cookie  $EMOJI_CANDY Candy  $EMOJI_ICE_CREAM Ice"

echo ""

# Test animals
ui_box --width 60 --padding "0 2" \
    "${BOLD}Animals${RESET}" \
    "$EMOJI_CAT Cat  $EMOJI_DOG Dog  $EMOJI_UNICORN Unicorn  $EMOJI_DRAGON Dragon" \
    "$EMOJI_BUTTERFLY Butterfly  $EMOJI_BEE Bee  $EMOJI_TURTLE Turtle  $EMOJI_RABBIT Rabbit" \
    "$EMOJI_OWL Owl  $EMOJI_FOX Fox  $EMOJI_PENGUIN Penguin  $EMOJI_OCTOPUS Octopus"

echo ""

# Test faces
ui_box --width 60 --padding "0 2" \
    "${BOLD}Faces / Expressions${RESET}" \
    "$EMOJI_SMILE Happy  $EMOJI_GRIN Grin  $EMOJI_WINK Wink  $EMOJI_COOL_FACE Cool" \
    "$EMOJI_THINKING Think  $EMOJI_SURPRISED Wow  $EMOJI_SAD Sad  $EMOJI_ANGRY Angry" \
    "$EMOJI_SLEEPING Sleep  $EMOJI_NERD Nerd  $EMOJI_ROBOT Robot  $EMOJI_GHOST Ghost"

echo ""

# Test gestures
ui_box --width 60 --padding "0 2" \
    "${BOLD}Hands / Gestures${RESET}" \
    "$EMOJI_THUMBS_UP Up  $EMOJI_THUMBS_DOWN Down  $EMOJI_CLAP Clap  $EMOJI_WAVE Wave" \
    "$EMOJI_POINT_UP $EMOJI_POINT_DOWN $EMOJI_POINT_LEFT $EMOJI_POINT_RIGHT Point" \
    "$EMOJI_MUSCLE Strong  $EMOJI_PRAY Thanks"

echo ""

# Test misc symbols
ui_box --width 60 --padding "0 2" \
    "${BOLD}Misc Symbols${RESET}" \
    "$EMOJI_CHECK Check  $EMOJI_CROSS Cross  $EMOJI_BULLET Bullet  $EMOJI_ARROW Arrow" \
    "$EMOJI_INFINITY Infinity  $EMOJI_RECYCLE Recycle  $EMOJI_SPARKLE Sparkle" \
    "$EMOJI_QUESTION Question  $EMOJI_EXCLAIM Exclaim  $EMOJI_HUNDRED 100"

echo ""
echo "If all right borders are aligned, these emojis are safe to use!"
echo ""
echo "Themed sets examples:"
echo "  Traffic light: $EMOJI_RED $EMOJI_YELLOW $EMOJI_GREEN"
echo "  Priority:      $EMOJI_RED $EMOJI_ORANGE $EMOJI_YELLOW $EMOJI_GREEN $EMOJI_BLUE"
echo "  Progress:      $EMOJI_WHITE_SQ $EMOJI_YELLOW_SQ $EMOJI_GREEN_SQ $EMOJI_SUCCESS"
echo "  Build status:  $EMOJI_PROCESS $EMOJI_BUILD $EMOJI_PACKAGE $EMOJI_ROCKET $EMOJI_SUCCESS"
echo "  Severity:      $EMOJI_LIGHT $EMOJI_YELLOW $EMOJI_ORANGE $EMOJI_RED $EMOJI_ALERT"
echo ""
