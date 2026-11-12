# EndCapper

**Version 1.4.3 for World of Warcraft: Forever.**

Decorate your action bars and screen corners with 28 fantasy designs. Mix and match artwork or link matching pairs, then adjust placement, size and mirroring from EndCapper’s own panel.

## Install or update

Extract the `EndCapper` folder into your Forever client's `Interface/AddOns` folder. The final path must be `Interface/AddOns/EndCapper/EndCapper.toc`.

When upgrading, replace the old addon folder with the release folder. Keep your `WTF` folder: it contains saved settings. Enable EndCapper in the AddOns list. Restart the client if newly installed artwork does not appear after `/reload`.

## Choose and position artwork

1. Outside combat, click the EndCapper logo or type `/ecap`.
2. Choose the **End Cap** or **Corner Cap** tab. End Cap starts enabled. Each tab has its own **Enable** checkbox, artwork, and placement. Use the scrollable artwork dropdown in the Left or Right column. Selecting artwork also focuses that side's controls. Check **Link pairs** to select matching sisters together.
3. Click a custom cap’s outline to select that side. Its outline turns blue. Drag the outline to move the cap, or use the panel to adjust size, flip and artwork offsets.
4. Click **Save** in EndCapper to keep the position and settings for both caps. **Cancel** or closing the panel restores the saved placement.

**Link pairs** disables the side selectors and applies sister designs together. Linked mode shows one scrollable dropdown of complete combinations, such as Moonbough / Lunar. Swap reverses the displayed and applied order. Unlinked mode retains the two individual artwork dropdowns. Moonbough pairs with Lunar; Verdant pairs with Moonwell. Standalone designs are cloned and mirrored. **Swap** exchanges the sisters; Flip, Size, X and Y apply to both. **Separation distance** sets the horizontal gap between the two visible drag-frame edges, from 0 to 2000 UI units. At 0 their edges touch without overlap. The midpoint between the two frame centres stays at the screen centre when **Pair centre X offset** is 0. **Snap to center** sets the offset to 0 and keeps the gap and vertical placement. The native chevrons beside every slider adjust it by one unit. Y offsets both artworks vertically. Dragging either linked cap moves the pair and preserves its separation. Uncheck Link pairs to keep the visible frame positions and resume independent controls. **Reset pair** resets shared placement, flip and swap and snaps both caps to the bottom. Save keeps the mode and controls; Cancel discards the preview.

**Corner Cap** mirrors the artwork and anchors each cap at its bottom screen corner. Resizing grows the frame inward and upward from its outside corner. Linked Corner Caps move inward together. **Snap to corner** or **Snap to corners** restores the edge placement.

**Snap to bottom** aligns the drag box with the screen bottom, then aligns the artwork's measured crop line to that edge. It targets the selected side when unlinked and both sides when linked. This is the default alignment; **Reset side / Reset pair** reapplies it. Y = 0 uses the crop line as its bottom reference, and positive Y lifts the art. Existing explicit Y values remain offsets until Snap or Reset sets them to zero. X offsets keep their existing meaning.

First-link separation starts near native cap spacing. Your adjusted separation is retained when unlinking and relinking, including a deliberate zero. Reset Pair restores native-based spacing for the reset artwork size.

Dragging upward releases bottom snap. Artwork offsets move the artwork within its drag frame. Entering combat discards unsaved EndCapper previews.

Animated effects stop at the artwork's bottom edge. This cutoff follows artwork size and positioning while leaving the art and drag box intact.

## Included artwork

| Design | Effects |
| --- | --- |
| Banshee | Undead Sylvanas, with black dungeon fog, two red flame eye trails and Void Glow |
| High General | Living Sylvanas, with golden luminance bloom, Divine Radiance, two blue eye trails and a gentle whirlwind |
| Undead | Decaying undead face with amber eyes, blue banners and green-lit ruins, with Amber Flow and Rot Fog |
| Lordaeron | Ruined crypt arches and bones, with Amber Flow and Rot Fog |
| Shadowfang | Battle-scarred black Worgen with blue eyes and Gilnean tree, with blue spectral trail and Gloom |
| Snowfang | White Worgen with amber eyes, braids and ruined Gilnean pillar, with Amber Flow and Gloom |
| Moonbough | Moonlight glow |
| Verdant | Moonlight glow |
| Moonwell | Pulsing glyphs, moon, water and reflected light, with Azure Glow and Water Ripples |
| Lunar | Moonlight glow |
| Stormhorn | Blue glow and broad blue flame |
| Felwing | Green glow, dripping and pulsing glyphs |
| Hexbound | Horned warlock, pulsing green eyes, glyphs and crystals, with Fel Flame, Fel Casting and Shadow Glow |
| Cryptgate | Chained skull shrine, amber eye trails and candle flame, with animated falling poison, green Rot Fog and Blue Mist |
| Plaguewell | Undercity stairs, glowing amber lantern and poison drain, with animated falling poison, green Rot Fog and Blue Mist |
| Soulbound | Warlock grimoire, hovering soul crystal and pulsing green details, with Fel Flame, Fel Casting and Shadow Glow |
| Violetspire | Custom floating crystal and fragments, pulsing emission, rotating seal and arcane glow |
| Kirin Tor | Open mage spellbook, native Kirin Tor eye seal and arcane glow |
| Cinderforged | Pulsing molten cracks, fire glow and flames |
| Cindermaw | Pulsing cracks, eyes and mouth, with fire glow and flames |
| Rimeforged | Independently pulsing runes and ice, spectral trail and Frost Form |
| Rimeguard | Independently pulsing runes, ice and eyes, spectral trail and Frost Form |
| Frosthilt | Frostmourne's hilt and horned skull guard, with Icy Mist, Blue Frost Glow and one native Cold Flame eye trail |
| Frostblade | Frostmourne's blade tip and ice edge, with Icy Mist and Blue Frost Glow |
| Seraph | Eyeless holy hood and wing, rotating gold halo, Holy Glow and animated Divine Radiance |
| Sanctum | Holy crystal and wing, Holy Glow and animated Divine Radiance |
| Umbra | Eyeless shadow hood and wing, rotating violet halo, Void Glow and Void Smoke |
| Eclipse | Void crystal and wing, Void Glow and Void Smoke |

**Default** uses the game’s standard artwork and positioning. **Hidden** hides the cap.

Sanctum and Eclipse retain their central crystal mounts without outer halo rings. Seraph and Umbra retain their separate rotating halos.

Effects play automatically. Undead and Lordaeron run Amber Flow and Rot Fog together. Paired native effects on other designs run together, alongside any custom emission or rotating halo listed above. Existing saved settings are preserved when upgrading.

Violetspire and Kirin Tor form a linked sister pair. The spire retains its custom floating crystal, fragments and pulsing emission, with its existing rotating seal and Arcane Glow. Kirin Tor uses its own native Dalaran Eye effect alongside Arcane Glow.

With **Flip horizontally** unchecked, Lordaeron, Shadowfang, Stormhorn, Felwing, Hexbound, Plaguewell and Frosthilt mirror on the right. Undead, Snowfang, Soulbound, Cryptgate and the other custom designs mirror on the left. Checking Flip reverses that default, including attached effects. Switching artwork keeps your checkbox choice. Existing saved appearances are preserved; uncheck Flip to adopt a revised default on an already configured cap.

**Show Ecap button** toggles the logo launcher. With options open, drag the launcher by its gold outline. Save keeps its visibility and position. Use `/ecap` to reopen options when the button is hidden.

## Commands

- `/ecap` or `/endcapper`: open artwork options.
- `/ecap status`: report native effect loading state on each side.

## Compatibility and troubleshooting

- Designed for Forever's default mouse-and-keyboard action bar (interface 16001).
- Replacement action-bar addons and gamepad layouts are not supported. Options are English only.
- Artwork selections, mirroring, linked pairs and placement are saved per layout for both End Caps and Corner Caps.
- Editing is available outside combat. No third-party libraries are required.
- Native effects may need time to load and refresh automatically when loading completes. Use `/ecap status` if one remains absent; saving changed settings or showing the cap again can recover a late-loaded model.
- Disabling EndCapper and reloading restores the original caps; saved settings remain available.

For bug reports, include the addon version, `/dump GetBuildInfo()` output, artwork/side, steps to reproduce and any Lua error. See `CHANGELOG.md` and `LICENSE` for release and distribution details.
