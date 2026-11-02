// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes

// The Galletita theme's backdrop (the theme is still "hive" inside, so the
// setting people saved keeps working): soft Tokkip cookies, the Material
// Expressive shape he sits on, scattered behind the setup window and, in
// Galletita, the whole app. They appear from `origin` outwards, each turns
// slowly and breathes, and now and then a soft glow travels out from the
// origin across them, a little stronger where it passes.
//
// Light on resources: a few dozen GPU-drawn shapes and one clock that ticks
// every `frameMs`. In the app every backdrop shares Theme's clock; the setup
// window runs its own. `paused` holds the current frame; `animate` false
// draws them still (reduced motion, battery saver, the user's setting).
Item {
    id: backdrop

    property bool animate: true
    property bool paused: false
    property bool ownClock: true
    property bool growIn: true
    // Spacing unit: cookies sit about five cells apart.
    property real cell: 24
    property real strength: 1
    property color lineColor
    property color glowColor
    property point origin: Qt.point(width / 2, height / 3)
    property int frameMs: 33
    property real breathSeconds: 6.0
    property real pulseSeconds: 4.5
    // Rounded corners (0: none), for the phone preview.
    property real corner: 0
    property real reach: 0.62
    property real pulseReach: 0.75

    property real time: 0
    property real grow: 1
    readonly property real diagonal: Math.hypot(width, height)

    clip: true

    property real _base: 0
    property double _since: 0
    Timer {
        interval: backdrop.frameMs
        repeat: true
        running: backdrop.ownClock && backdrop.animate && !backdrop.paused && backdrop.visible && backdrop.width > 0
        onRunningChanged: {
            if (running)
                backdrop._since = Date.now()
            else
                backdrop._base = backdrop.time
        }
        onTriggered: backdrop.time = backdrop._base + (Date.now() - backdrop._since) / 1000
    }

    NumberAnimation {
        id: growAnimation
        target: backdrop
        property: "grow"
        from: 0
        to: 1
        duration: 1800
        easing.type: Easing.OutCubic
    }
    Component.onCompleted: {
        if (growIn && animate) {
            grow = 0
            growAnimation.start()
        }
    }

    // The cookie's outline, centred on (0, 0): 9 soft bumps, radius 1.
    readonly property var outline: {
        const pts = []
        for (let i = 0; i <= 72; i++) {
            const th = i / 72 * Math.PI * 2
            const r = (1 + 0.07 * Math.cos(9 * th)) / 1.07
            pts.push(Qt.point(Math.cos(th) * r, Math.sin(th) * r))
        }
        return pts
    }
    // Where the cookies sit: a staggered grid, each a little nudged and sized.
    readonly property var spots: {
        const out = []
        const step = Math.max(72, cell * 6.5)
        const cols = Math.ceil(width / step) + 1, rows = Math.ceil(height / (step * 0.87)) + 1
        for (let r = 0; r < rows; r++)
            for (let q = 0; q < cols; q++) {
                const seed = Math.sin(r * 12.9898 + q * 78.233) * 43758.5453
                const f = seed - Math.floor(seed)
                out.push({
                    x: q * step + (r % 2 ? step / 2 : 0) + (f - 0.5) * step * 0.3,
                    y: r * step * 0.87 + (0.5 - f) * step * 0.25,
                    size: step * (0.2 + 0.16 * f),
                    phase: f * Math.PI * 2,
                    spin: (f - 0.5) * 16
                })
            }
        return out
    }

    Repeater {
        model: backdrop.spots
        Shape {
            id: one
            required property var modelData
            readonly property real dist: Math.hypot(modelData.x - backdrop.origin.x, modelData.y - backdrop.origin.y) / Math.max(1, backdrop.diagonal)
            // Fades out with distance, and appears as it grows out from the origin.
            readonly property real fade: Math.max(0, 1 - dist / Math.max(0.05, backdrop.reach))
                                         * (dist <= backdrop.grow ? 1 : 0)
            // The glow passing through: a ring travelling out every pulseSeconds.
            readonly property real wave: backdrop.animate
                ? Math.max(0, 1 - Math.abs(dist - ((backdrop.time % backdrop.pulseSeconds) / backdrop.pulseSeconds) * backdrop.pulseReach) * 9)
                : 0
            readonly property real breath: backdrop.animate
                ? Math.sin(backdrop.time * 2 * Math.PI / backdrop.breathSeconds + modelData.phase) : 0

            x: modelData.x
            y: modelData.y
            width: 1
            height: 1
            visible: fade > 0.01
            opacity: Math.min(1, backdrop.strength * (0.35 + 0.65 * fade))
            scale: modelData.size * (1 + breath * 0.05)
            rotation: modelData.phase * 57.3 + (backdrop.animate ? backdrop.time * modelData.spin : 0)
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 1.6 / one.scale
                strokeColor: Qt.rgba(backdrop.lineColor.r, backdrop.lineColor.g, backdrop.lineColor.b, backdrop.lineColor.a * (0.9 + 0.6 * one.wave))
                fillColor: Qt.rgba(backdrop.lineColor.r, backdrop.lineColor.g, backdrop.lineColor.b, backdrop.lineColor.a * (0.4 + 0.5 * one.wave))
                PathPolyline { path: backdrop.outline }
            }
        }
    }
}
