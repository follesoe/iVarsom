#! /bin/sh

function print_example() {
    echo "Example"
    echo "  icons ios ~/AppIcon.pdf ~/Icons/"
}
    
function print_usage() {
    echo "Usage"
    echo "  icons <ios|watch|complication|macos> in-file.pdf (out-dir)"
}

function command_exists() {
    if type "$1" >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

if command_exists "sips" == 0 ; then
    echo "sips tool not found"
    exit 1
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ] ; then
    print_usage
    exit 0
fi

PLATFORM="$1"
FILE="$2"
if [ -z "$PLATFORM" ] || [ -z "$FILE" ] ; then
    echo "Error: missing arguments"
    echo ""
    print_usage
    echo ""
    print_example
    exit 1
fi

DIR="$3"
if [ -z "$DIR" ] ; then
    DIR=$(dirname $FILE)
fi

# Create directory if needed
mkdir -p "$DIR"

if [[ "$PLATFORM" == *"ios"* ]] ; then # iOS
    sips -s format png -Z '180'  "${FILE}" --out "${DIR}"/iPhone@3x.png
    sips -s format png -Z '29'   "${FILE}" --out "${DIR}"/iPadSettings.png
    sips -s format png -Z '58'   "${FILE}" --out "${DIR}"/iPadSettings@2x.png
    sips -s format png -Z '58'   "${FILE}" --out "${DIR}"/iPhoneSettings@2x.png
    sips -s format png -Z '120'  "${FILE}" --out "${DIR}"/iPhone@2x.png
    sips -s format png -Z '87'   "${FILE}" --out "${DIR}"/iPhoneSettings@3x.png
    sips -s format png -Z '40'   "${FILE}" --out "${DIR}"/iPadSpotlight.png
    sips -s format png -Z '80'   "${FILE}" --out "${DIR}"/iPadSpotlight@2x.png
    sips -s format png -Z '80'   "${FILE}" --out "${DIR}"/iPhoneSpotlight@2x.png
    sips -s format png -Z '120'  "${FILE}" --out "${DIR}"/iPhoneSpotlight@3x.png
    sips -s format png -Z '76'   "${FILE}" --out "${DIR}"/iPad.png
    sips -s format png -Z '152'  "${FILE}" --out "${DIR}"/iPad@2x.png
    sips -s format png -Z '167'  "${FILE}" --out "${DIR}"/iPadPro@2x.png
    sips -s format png -Z '40'   "${FILE}" --out "${DIR}"/iPhoneNotification@2x.png
    sips -s format png -Z '60'   "${FILE}" --out "${DIR}"/iPhoneNotification@3x.png
    sips -s format png -Z '20'   "${FILE}" --out "${DIR}"/iPadNotification.png
    sips -s format png -Z '40'   "${FILE}" --out "${DIR}"/iPadNotification@2x.png
    sips -s format png -Z '1024' "${FILE}" --out "${DIR}"/AppStoreMarketing.png
    
    # https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/AppIconType.html
    contents_json='{"images":[{"size":"20x20","idiom":"iphone","filename":"iPhoneNotification@2x.png","scale":"2x"},{"size":"20x20","idiom":"iphone","filename":"iPhoneNotification@3x.png","scale":"3x"},{"size":"29x29","idiom":"iphone","filename":"iPhoneSettings@2x.png","scale":"2x"},{"size":"29x29","idiom":"iphone","filename":"iPhoneSettings@3x.png","scale":"3x"},{"size":"40x40","idiom":"iphone","filename":"iPhoneSpotlight@2x.png","scale":"2x"},{"size":"40x40","idiom":"iphone","filename":"iPhoneSpotlight@3x.png","scale":"3x"},{"size":"60x60","idiom":"iphone","filename":"iPhone@2x.png","scale":"2x"},{"size":"60x60","idiom":"iphone","filename":"iPhone@3x.png","scale":"3x"},{"size":"20x20","idiom":"ipad","filename":"iPadNotification.png","scale":"1x"},{"size":"20x20","idiom":"ipad","filename":"iPadNotification@2x.png","scale":"2x"},{"size":"29x29","idiom":"ipad","filename":"iPadSettings.png","scale":"1x"},{"size":"29x29","idiom":"ipad","filename":"iPadSettings@2x.png","scale":"2x"},{"size":"40x40","idiom":"ipad","filename":"iPadSpotlight.png","scale":"1x"},{"size":"40x40","idiom":"ipad","filename":"iPadSpotlight@2x.png","scale":"2x"},{"size":"76x76","idiom":"ipad","filename":"iPad.png","scale":"1x"},{"size":"76x76","idiom":"ipad","filename":"iPad@2x.png","scale":"2x"},{"size":"83.5x83.5","idiom":"ipad","filename":"iPadPro@2x.png","scale":"2x"},{"size":"1024x1024","idiom":"ios-marketing","filename":"AppStoreMarketing.png","scale":"1x"}],"info":{"version":1,"author":"xcode"}}'
    echo $contents_json > "${DIR}"/Contents.json
fi

if [[ "$PLATFORM" == *"watch"* ]] ; then # Apple Watch
    sips -s format png -Z '48'  "${FILE}" --out "${DIR}"/Watch38mmNotificationCenter.png
    sips -s format png -Z '55'  "${FILE}" --out "${DIR}"/Watch42mmNotificationCenter.png
    sips -s format png -Z '66'  "${FILE}" --out "${DIR}"/Watch45mmNotificationCenter.png
    sips -s format png -Z '58'  "${FILE}" --out "${DIR}"/WatchCompanionSettings@2x.png
    sips -s format png -Z '87'  "${FILE}" --out "${DIR}"/WatchCompanionSettings@3x.png    
    sips -s format png -Z '80'  "${FILE}" --out "${DIR}"/Watch38MM42MMHomeScreen.png
    sips -s format png -Z '88'  "${FILE}" --out "${DIR}"/Watch40MMHomeScreen.png
    sips -s format png -Z '92'  "${FILE}" --out "${DIR}"/Watch41MMHomeScreen.png
    sips -s format png -Z '100' "${FILE}" --out "${DIR}"/Watch44MMHomeScreen.png
    sips -s format png -Z '102' "${FILE}" --out "${DIR}"/Watch45MMHomeScreen.png
    sips -s format png -Z '172' "${FILE}" --out "${DIR}"/Watch38MMShortLook.png
    sips -s format png -Z '196' "${FILE}" --out "${DIR}"/Watch40MM42MMShortLook.png
    sips -s format png -Z '216' "${FILE}" --out "${DIR}"/Watch44MMShortLook.png
    sips -s format png -Z '234' "${FILE}" --out "${DIR}"/Watch45MMShortLook.png
    sips -s format png -Z '1024' "${FILE}" --out "${DIR}"/WatchAppStore.png

    # https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/AppIconType.html
    contents_json='{"images":[{"filename":"Watch38mmNotificationCenter.png","idiom":"watch","role":"notificationCenter","scale":"2x","size":"24x24","subtype":"38mm"},{"filename":"Watch42mmNotificationCenter.png","idiom":"watch","role":"notificationCenter","scale":"2x","size":"27.5x27.5","subtype":"42mm"},{"filename":"WatchCompanionSettings@2x.png","idiom":"watch","role":"companionSettings","scale":"2x","size":"29x29"},{"filename":"WatchCompanionSettings@3x.png","idiom":"watch","role":"companionSettings","scale":"3x","size":"29x29"},{"filename":"Watch45mmNotificationCenter.png","idiom":"watch","role":"notificationCenter","scale":"2x","size":"33x33","subtype":"45mm"},{"filename":"Watch38MM42MMHomeScreen.png","idiom":"watch","role":"appLauncher","scale":"2x","size":"40x40","subtype":"38mm"},{"filename":"Watch40MMHomeScreen.png","idiom":"watch","role":"appLauncher","scale":"2x","size":"44x44","subtype":"40mm"},{"filename":"Watch41MMHomeScreen.png","idiom":"watch","role":"appLauncher","scale":"2x","size":"46x46","subtype":"41mm"},{"filename":"Watch44MMHomeScreen.png","idiom":"watch","role":"appLauncher","scale":"2x","size":"50x50","subtype":"44mm"},{"filename":"Watch45MMHomeScreen.png","idiom":"watch","role":"appLauncher","scale":"2x","size":"51x51","subtype":"45mm"},{"filename":"Watch38MMShortLook.png","idiom":"watch","role":"quickLook","scale":"2x","size":"86x86","subtype":"38mm"},{"filename":"Watch40MM42MMShortLook.png","idiom":"watch","role":"quickLook","scale":"2x","size":"98x98","subtype":"42mm"},{"filename":"Watch44MMShortLook.png","idiom":"watch","role":"quickLook","scale":"2x","size":"108x108","subtype":"44mm"},{"filename":"Watch45MMShortLook.png","idiom":"watch","role":"quickLook","scale":"2x","size":"117x117","subtype":"45mm"},{"filename":"WatchAppStore.png","idiom":"watch-marketing","scale":"1x","size":"1024x1024"}],"info":{"author":"xcode","version":1}}'
    echo $contents_json > "${DIR}"/Contents.json
fi

if [[ "$PLATFORM" == *"complication"* ]] ; then # Apple Watch
    sips -s format png -Z '32'  "${FILE}" --out "${DIR}"/Circular38mm2x.png
    sips -s format png -Z '36'  "${FILE}" --out "${DIR}"/Circular40mm2x.png
    sips -s format png -Z '36'  "${FILE}" --out "${DIR}"/Circular42mm2x.png
    sips -s format png -Z '40'  "${FILE}" --out "${DIR}"/Circular44mm2x.png
    sips -s format png -Z '182'  "${FILE}" --out "${DIR}"/ExtraLarge38mm2x.png
    sips -s format png -Z '203'  "${FILE}" --out "${DIR}"/ExtraLarge40mm2x.png
    sips -s format png -Z '203'  "${FILE}" --out "${DIR}"/ExtraLarge42mm2x.png
    sips -s format png -Z '224'  "${FILE}" --out "${DIR}"/ExtraLarge44mm2x.png
    sips -s format png -Z '84'  "${FILE}" --out "${DIR}"/GraphicBezel40mm2x.png
    sips -s format png -Z '84'  "${FILE}" --out "${DIR}"/GraphicBezel42mm2x.png
    sips -s format png -Z '94'  "${FILE}" --out "${DIR}"/GraphicBezel44mm2x.png
    sips -s format png -Z '84'  "${FILE}" --out "${DIR}"/GraphicCircular40mm2x.png
    sips -s format png -Z '84'  "${FILE}" --out "${DIR}"/GraphicCircular42mm2x.png
    sips -s format png -Z '94'  "${FILE}" --out "${DIR}"/GraphicCircular44mm2x.png
    sips -s format png -Z '40'  "${FILE}" --out "${DIR}"/GraphicCorner40mm2x.png
    sips -s format png -Z '40'  "${FILE}" --out "${DIR}"/GraphicCorner42mm2x.png
    sips -s format png -Z '44'  "${FILE}" --out "${DIR}"/GraphicCorner44mm2x.png
    sips -s format png -Z '52'  "${FILE}" --out "${DIR}"/GraphicModular38mm2x.png
    sips -s format png -Z '58'  "${FILE}" --out "${DIR}"/GraphicModular40mm2x.png
    sips -s format png -Z '58'  "${FILE}" --out "${DIR}"/GraphicModular42mm2x.png
    sips -s format png -Z '64'  "${FILE}" --out "${DIR}"/GraphicModular44mm2x.png
    sips -s format png -Z '40'  "${FILE}" --out "${DIR}"/GraphicUtilitarian38mm2x.png
    sips -s format png -Z '44'  "${FILE}" --out "${DIR}"/GraphicUtilitarian40mm2x.png
    sips -s format png -Z '44'  "${FILE}" --out "${DIR}"/GraphicUtilitarian42mm2x.png
    sips -s format png -Z '50'  "${FILE}" --out "${DIR}"/GraphicUtilitarian44mm2x.png
    echo "NOTE: Graphic Extra Large is not generated since that is not rectangular"
fi

if [[ "$PLATFORM" == *"macos"* ]] ; then # macOS
    sips -s format png -Z '1024' "${FILE}" --out "${DIR}"/icon_512x512@2x.png
    sips -s format png -Z '512'  "${FILE}" --out "${DIR}"/icon_512x512.png
    sips -s format png -Z '512'  "${FILE}" --out "${DIR}"/icon_256x256@2x.png
    sips -s format png -Z '256'  "${FILE}" --out "${DIR}"/icon_256x256.png
    sips -s format png -Z '256'  "${FILE}" --out "${DIR}"/icon_128x128@2x.png
    sips -s format png -Z '128'  "${FILE}" --out "${DIR}"/icon_128x128.png
    sips -s format png -Z '64'   "${FILE}" --out "${DIR}"/icon_32x32@2x.png
    sips -s format png -Z '32'   "${FILE}" --out "${DIR}"/icon_32x32.png
    sips -s format png -Z '32'   "${FILE}" --out "${DIR}"/icon_16x16@2x.png
    sips -s format png -Z '16'   "${FILE}" --out "${DIR}"/icon_16x16.png
fi