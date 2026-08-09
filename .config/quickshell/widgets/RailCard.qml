import QtQuick

import qs.components

// Wide card shell for the composite tiles (clock / workspaces / music /
// weather). The module fills the default slot. It IS a RailTile with a flat
// (non-recoloring) surface, matching the mockup's .item.card. Height adapts to
// content via RailTile's implicitHeight rule.
RailTile {
    hoverRecolor: false
}
