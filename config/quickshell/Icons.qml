pragma Singleton

import QtQuick
import Quickshell

// Nerd Font glyphs, by codepoint (same ones zenities uses).
Singleton {
    function g(cp) {
        return String.fromCodePoint(cp);
    }

    readonly property string artix: g(0xF31F)
    readonly property string arch: g(0xF08C7)
    readonly property string power: g(0xF011)
    readonly property string lock: g(0xF023)
    readonly property string reboot: g(0xF2F9)
    readonly property string suspend: g(0xF057)
    readonly property string exit: g(0xF2F5)

    readonly property string wsActive: g(0xF4BF)
    readonly property string wsInactive: g(0xF4C3)

    readonly property string prev: g(0xF04A)
    readonly property string pause: g(0xF04C)
    readonly property string play: g(0xF04B)
    readonly property string next: g(0xF04E)
    readonly property string music: g(0xF001)

    readonly property string circle: g(0xF111)
    readonly property string brightness: g(0xF05A8)
    readonly property string eye: g(0xF06E)
    readonly property string eyeSlash: g(0xF070)
    readonly property string camera: g(0xF030)

    readonly property string volMute: g(0xEEE8)
    readonly property string volHigh: g(0xF028)
    readonly property string volLow: g(0xF027)

    readonly property string ethernet: g(0xF0200)
    readonly property string wifi4: g(0xF0928)
    readonly property string wifi3: g(0xF0925)
    readonly property string wifi2: g(0xF0922)
    readonly property string wifi1: g(0xF091F)
    readonly property string wifi0: g(0xF092F)
    readonly property string wifiOff: g(0xF092D)

    readonly property string btOn: g(0xF00AF)
    readonly property string btOff: g(0xF00B2)
    readonly property string btConnected: g(0xF00B1)

    readonly property string bell: g(0xF0F3)
    readonly property string bellSlash: g(0xF1F6)
    readonly property string trash: g(0xF1F8)
    readonly property string close: g(0xF00D)
    readonly property string check: g(0xF00C)
    readonly property string refresh: g(0xF021)
    readonly property string unlock: g(0xF09C)
    readonly property string chevronRight: g(0xF054)
    readonly property string user: g(0xF007)
    readonly property string headphones: g(0xF025)
    readonly property string keyboard: g(0xF11C)
    readonly property string phone: g(0xF10B)
    readonly property string gamepad: g(0xF11B)
    readonly property string desktop: g(0xF108)
    readonly property string laptop: g(0xF109)
    readonly property string mouse: g(0xF037D)
    readonly property string speaker: g(0xF04C3)
    readonly property string mic: g(0xF130)
    readonly property string image: g(0xF03E)
    readonly property string crop: g(0xF125)
    readonly property string windowIcon: g(0xF2D0)
    readonly property string search: g(0xF002)
    readonly property string circleO: g(0xF10C)
    readonly property string video: g(0xF03D)
    readonly property string replay: g(0xF02DA)
    readonly property string stop: g(0xF04D)
    readonly property string save: g(0xF0C7)
    readonly property string cog: g(0xF013)
    readonly property string folder: g(0xF07B)
    readonly property string chevronDown: g(0xF078)
    readonly property string region: g(0xF0489)
}
