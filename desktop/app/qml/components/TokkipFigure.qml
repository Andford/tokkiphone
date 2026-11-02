// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// Tokkip, alive: the bunny from the Tokkip family (Andford/tokkip), drawn as
// in Tokkip PC (windows/src/tokkip/): cream fur, teal ears and tail, round ink
// eyes with no shine that blink to a line. He breathes, blinks, sways his
// ears and looks about; `mood` says how he feels. Behind him, if `cookie`, the
// soft Material Expressive shape that changes with his mood (a round cookie at
// rest, a four-leaf clover turning while he works).
//
// Drawn on one Canvas in "studio units" (the body is 200 wide, its top at
// y = −90, its bottom at 120), scaled to fit. It only redraws while visible
// and animating, at about 30 frames a second.
Item {
    id: tokkip

    // "idle", "happy", "working", "sad", "sleep" or "surprised".
    property string mood: "idle"
    property bool animate: true
    // The shape behind him.
    property bool cookie: true
    property color cookieColor: Qt.rgba(accent.r, accent.g, accent.b, 0.16)
    property color body: "#F7EAD3"
    property color accent: "#3F9E9A"
    // Eyes and mouth: the accent, a little darker.
    property color ink: Qt.darker(accent, 1.14)
    property color cheek: Qt.rgba(240 / 255, 120 / 255, 140 / 255, 0.36)

    implicitWidth: 160
    implicitHeight: 160

    Accessible.role: Accessible.Graphic
    Accessible.name: mood === "sad" ? qsTr("Tokkip, sad")
        : mood === "sleep" ? qsTr("Tokkip, asleep")
        : mood === "working" ? qsTr("Tokkip, working")
        : qsTr("Tokkip")

    property real t: 0
    // The cookie melts from one shape to the next when the mood changes.
    property var _from: _shapeOf(mood)
    property var _to: _shapeOf(mood)
    property real _k: 1
    property real _turn: 0
    onMoodChanged: {
        _from = _mix(_from, _to, _k)
        _to = _shapeOf(mood)
        _k = 0
        melt.restart()
    }
    NumberAnimation { id: melt; target: tokkip; property: "_k"; from: 0; to: 1; duration: 520; easing.type: Easing.OutCubic }

    function _shapeOf(m) {
        switch (m) {
        case "working": return { lobes: 4, depth: 0.11, spin: 24 }
        case "happy": return { lobes: 10, depth: 0.09, spin: 30 }
        case "surprised": return { lobes: 12, depth: 0.08, spin: 14 }
        case "sad": return { lobes: 3, depth: 0.1, spin: 0 }
        case "sleep": return { lobes: 0, depth: 0, spin: 0 }
        default: return { lobes: 9, depth: 0.05, spin: 0 }
        }
    }
    function _mix(a, b, k) {
        return { lobes: k < 0.5 ? a.lobes : b.lobes, depth: a.depth * (1 - k) + b.depth * k, spin: a.spin * (1 - k) + b.spin * k, a: a, b: b, k: k }
    }

    Timer {
        interval: 33
        repeat: true
        running: tokkip.animate && tokkip.visible && tokkip.width > 0
        property double last: 0
        onRunningChanged: last = Date.now()
        onTriggered: {
            const now = Date.now()
            const dt = Math.min(0.1, (now - last) / 1000)
            last = now
            tokkip.t += dt
            tokkip._turn += dt * (tokkip._from.spin * (1 - tokkip._k) + tokkip._to.spin * tokkip._k)
            canvas.requestPaint()
        }
    }
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        antialiasing: true

        // An ellipse centred on (cx, cy) (QML's ellipse() takes a box).
        function oval(c, cx, cy, rx, ry) { c.ellipse(cx - rx, cy - ry, rx * 2, ry * 2) }

        function cookiePath(c, r, cy) {
            const a = tokkip._from, b = tokkip._to, k = tokkip._k
            const rot = tokkip._turn * Math.PI / 180
            const depth = a.depth * (1 - k) + b.depth * k
            c.beginPath()
            for (let i = 0; i <= 96; i++) {
                const th = i / 96 * Math.PI * 2
                const fa = a.lobes ? a.depth * Math.cos(a.lobes * (th - rot)) : 0
                const fb = b.lobes ? b.depth * Math.cos(b.lobes * (th - rot)) : 0
                const rr = r * (1 + fa * (1 - k) + fb * k) / (1 + depth)
                const x = Math.cos(th) * rr, y = cy + Math.sin(th) * rr
                if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
            }
            c.closePath()
        }

        function ear(c, fill, inner) {
            function leaf(len, w, col) {
                c.beginPath()
                c.moveTo(-w * 0.45, 6)
                c.bezierCurveTo(-w * 1.05, -len * 0.45, -w * 0.65, -len, 0, -len)
                c.bezierCurveTo(w * 0.65, -len, w * 1.05, -len * 0.45, w * 0.45, 6)
                c.closePath()
                c.fillStyle = col
                c.fill()
            }
            leaf(128, 46, fill)
            c.save(); c.translate(0, -8); leaf(128 * 0.78, 46 * 0.52, inner); c.restore()
        }

        function bodyPath(c) {
            const x = -100, y = -90, w = 200, h = 210, r = 54
            c.beginPath()
            c.moveTo(x + r, y)
            c.arcTo(x + w, y, x + w, y + h, r)
            c.arcTo(x + w, y + h, x, y + h, r)
            c.arcTo(x, y + h, x, y, r)
            c.arcTo(x, y, x + w, y, r)
            c.closePath()
        }

        onPaint: {
            const c = getContext("2d")
            c.reset()
            const t = tokkip.t, m = tokkip.mood
            const s = Math.min(width, height) / 360
            c.save()
            c.translate(width / 2, height / 2 + 46 * s)
            c.scale(s, s)

            if (tokkip.cookie) {
                c.fillStyle = tokkip.cookieColor
                cookiePath(c, 165 + (tokkip.animate ? Math.sin(t * 1.3) * 3 : 0), -36)
                c.fill()
            }

            // How he moves: breath, a bounce when happy, ears and where he looks.
            const breath = tokkip.animate ? Math.sin(t * 2.1) : 0
            const bounce = m === "happy" && tokkip.animate ? -Math.abs(Math.sin(t * 5)) * 10 : 0
            const droop = m === "sad" ? 26 : m === "sleep" ? 16 : m === "surprised" ? -8 : 0
            const sway = tokkip.animate ? Math.sin(t * 1.6) * 3 : 0
            const wiggle = m === "happy" && tokkip.animate ? Math.sin(t * 9) * 8 : 0
            const look = m === "working" && tokkip.animate ? Math.sin(t * 1.4) * 0.6
                : (m === "idle" && tokkip.animate ? Math.sin(t * 0.37) * Math.sin(t * 0.23) * 0.5 : 0)
            const nod = m === "sad" ? -0.18 : m === "sleep" ? -0.1 : 0
            // A blink every few seconds (never asleep, never happy: his eyes are shut or arcs then).
            const cycle = (t + 0.7) % 3.7
            const open = tokkip.animate && cycle < 0.14 ? Math.abs(cycle - 0.07) / 0.07 : 1

            c.translate(0, bounce)
            c.save()
            c.translate(0, 120)
            c.scale(1 + breath * 0.012, 1 - breath * 0.012)
            c.translate(0, -120)

            // Tail and ears.
            c.fillStyle = tokkip.accent
            c.beginPath(); c.arc(96 + Math.sin(t * 3) * 2, 74, 26, 0, Math.PI * 2); c.fill()
            for (const sd of [-1, 1]) {
                c.save()
                c.translate(sd * 50, -84)
                c.rotate((sd * 10 + sd * droop + sd * sway + (sd < 0 ? wiggle : -wiggle)) * Math.PI / 180)
                ear(c, tokkip.body, tokkip.accent)
                c.restore()
            }

            // Body, with a soft light from above.
            bodyPath(c)
            c.fillStyle = tokkip.body
            c.fill()
            c.save()
            bodyPath(c)
            c.clip()
            const g = c.createLinearGradient(0, -90, 0, 120)
            g.addColorStop(0, Qt.rgba(1, 1, 1, 0.18))
            g.addColorStop(1, Qt.rgba(0, 0, 0, 0.06))
            c.fillStyle = g
            c.fillRect(-120, -100, 240, 230)

            // The face follows where he looks.
            c.translate(Math.sin(look) * 62, 20 - Math.sin(nod) * 40)
            c.fillStyle = Qt.rgba(tokkip.cheek.r, tokkip.cheek.g, tokkip.cheek.b, m === "happy" ? 0.6 : tokkip.cheek.a)
            for (const sd of [-1, 1]) { c.beginPath(); oval(c, sd * 70, 18, 17, 9); c.fill() }

            c.strokeStyle = tokkip.ink
            c.fillStyle = tokkip.ink
            c.lineCap = "round"
            c.lineJoin = "round"
            c.lineWidth = 6
            for (const sd of [-1, 1]) {
                c.save()
                c.translate(sd * 46, -6)
                if (m === "happy") {
                    c.beginPath(); c.arc(0, 8, 13, Math.PI * 1.15, Math.PI * 1.85); c.stroke()
                } else if (m === "sleep") {
                    c.beginPath(); c.arc(0, -2, 12, Math.PI * 0.15, Math.PI * 0.85); c.stroke()
                } else {
                    const r = m === "surprised" ? 15 : 12
                    const o = m === "sad" ? Math.min(open, 0.8) : open
                    if (o < 0.35) {
                        c.beginPath(); c.moveTo(-12, 0); c.lineTo(12, 0); c.stroke()
                    } else {
                        c.beginPath(); oval(c, 0, 0, r, r * Math.min(1, o)); c.fill()
                    }
                }
                c.restore()
            }
            // A small tear now and then, when he's sad.
            if (m === "sad") {
                const k = (t % 3.2) / 3.2
                if (k < 0.7) {
                    c.fillStyle = Qt.rgba(120 / 255, 190 / 255, 1, 0.85 * (1 - k / 0.7))
                    c.beginPath(); oval(c, -50, 12 + k * 40, 5, 7); c.fill()
                }
            }

            // The mouth.
            c.strokeStyle = tokkip.ink
            c.fillStyle = tokkip.ink
            c.lineWidth = 5.5
            const y = 30
            c.beginPath()
            switch (m) {
            case "happy": c.arc(0, y - 14, 22, Math.PI * 0.12, Math.PI * 0.88); c.stroke(); break
            case "sad": c.arc(0, y + 16, 16, Math.PI * 1.22, Math.PI * 1.78); c.stroke(); break
            case "surprised": oval(c, 0, y, 8, 10); c.fill(); break
            case "sleep": oval(c, 0, y, 5, 5 + Math.sin(t * 1.4) * 1.5); c.fill(); break
            case "working": c.moveTo(-12, y); c.lineTo(12, y); c.stroke(); break
            default: c.arc(0, y - 12, 18, Math.PI * 0.2, Math.PI * 0.8); c.stroke()
            }
            c.restore() // face clip

            // Paws, low on his sides.
            c.fillStyle = Qt.darker(tokkip.body, 1.05)
            for (const sd of [-1, 1]) {
                c.save()
                c.translate(sd * 80, 96 + (m === "working" && tokkip.animate ? Math.sin(t * 8 + sd) * 4 : 0))
                c.rotate(sd * 0.2)
                c.beginPath(); oval(c, 0, 0, 22, 17); c.fill()
                c.restore()
            }
            c.restore() // breath

            // Asleep: little z's drifting up.
            if (m === "sleep") {
                c.fillStyle = tokkip.ink
                for (let i = 0; i < 3; i++) {
                    const k = ((t * 0.35 + i / 3) % 1)
                    c.globalAlpha = Math.sin(k * Math.PI)
                    c.font = "bold " + Math.round(26 + i * 8) + "px sans-serif"
                    c.fillText("z", 70 + k * 50 + i * 10, -110 - k * 90)
                }
                c.globalAlpha = 1
            }
            c.restore()
        }
    }
}
