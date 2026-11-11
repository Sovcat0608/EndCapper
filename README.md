# EndCapper

**Version 1.4.0-rc.19 for World of Warcraft: Forever.**

Customize your action-bar end caps with twenty-two bundled fantasy designs, animated effects, independent sizing, positioning and horizontal mirroring. Includes the Frosthilt / Frostblade pair, forming the two ends of Frostmourne with sculpted ice action-bar edges.

## Install or update

Extract the `EndCapper` folder into your Forever client's `Interface/AddOns` folder. The final path must be `Interface/AddOns/EndCapper/EndCapper.toc`.

When upgrading, replace the old addon folder with the release folder. Keep your `WTF` folder: it contains saved settings. Enable EndCapper in the AddOns list. Restart the client if newly installed artwork does not appear after `/reload`.

## Choose and position artwork

1. Outside combat, type `/ecap`, or enter Edit Mode and select an end cap.
2. Use the scrollable artwork dropdown in the Left or Right column. Selecting artwork also focuses that side's controls. Check **Link pairs** to select matching sisters together.
3. Adjust size, flip and artwork offsets. Click **Save** to keep both sides. Save is disabled when there are no changes.
4. Drag the cap's selection box to move the whole cap. Use Blizzard's **Edit Mode Save** to save that dragged position.

**Link pairs** disables the side selectors and applies sister designs together. Linked mode shows one scrollable dropdown of complete combinations, such as Moonbough / Lunar. Swap reverses the displayed and applied order. Unlinked mode retains the two individual artwork dropdowns. Moonbough pairs with Lunar; Verdant pairs with Moonwell. Standalone designs are cloned and mirrored. **Swap** exchanges the sisters; Flip, Size, X and Y apply to both. **Separation distance** sets the horizontal gap between the two visible drag-frame edges, from 0 to 2000 UI units. At 0 their edges touch without overlap. Each frame sits half its current width plus half the gap from the shared centre. Frame size and effective UI scale are included automatically. Shared X moves that centre; artwork stays centred horizontally inside its frame. Y offsets both artworks vertically. Dragging a linked cap moves the shared horizontal centre. Uncheck Link pairs to keep the visible frame positions and resume independent controls. **Reset pair** resets shared placement, flip and swap and snaps both caps to the bottom. Save keeps the mode and controls; Cancel discards the preview. Existing installations start unlinked. Switching native Edit Mode layouts restores that layout's placement and discards unapplied addon previews. Save keeps EndCapper placement for the active layout; Edit Mode Save saves native dragging.

**Snap to bottom** aligns the drag box with the screen bottom, then aligns the artwork's measured crop line to that edge. It targets the selected side when unlinked and both sides when linked. This is the default alignment; **Reset side / Reset pair** reapplies it. Y = 0 uses the crop line as its bottom reference, and positive Y lifts the art. Existing explicit Y values remain offsets until Snap or Reset sets them to zero. X offsets keep their existing meaning.

First-link separation starts near native cap spacing. Your adjusted separation is retained when unlinking and relinking, including a deliberate zero. Reset Pair restores native-based spacing for the reset artwork size.

Manual dragging releases the frame from bottom anchoring; save that dragged position through Blizzard's Edit Mode Save. Snap previews respect Save/Cancel, and artwork offsets do not move the drag box. Cancel, closing options, leaving Edit Mode or entering combat discards unapplied previews. Combat rollback is displayed when combat ends.

Animated effects stop at the artwork's bottom edge. This cutoff follows artwork size and positioning while leaving the art and drag box intact.

## Included artwork

| Design | Effects |
| --- | --- |
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

**Default** restores Blizzard's artwork; **Hidden** hides the cap. For untouched native artwork, choose Default with flip off, size 100% and offsets 0/0.

Sanctum and Eclipse retain their central crystal mounts without outer halo rings. Seraph and Umbra retain their separate rotating halos.

Effects play automatically. Undead and Lordaeron run Amber Flow and Rot Fog together. Paired native effects on other designs run together, alongside any custom emission or rotating halo listed above. Existing saved settings are preserved when upgrading.

Violetspire and Kirin Tor form a linked sister pair. The spire retains its custom floating crystal, fragments and pulsing emission, with its existing rotating seal and Arcane Glow. Kirin Tor uses its own native Dalaran Eye effect alongside Arcane Glow.

With **Flip horizontally** unchecked, Lordaeron, Shadowfang, Stormhorn and Felwing mirror on the right. Undead, Snowfang and the other custom designs mirror on the left. Checking Flip reverses that default, including attached effects. Switching artwork keeps your checkbox choice. Existing saved appearances are preserved; uncheck Flip to adopt a revised default on an already configured cap.

## Commands

- `/ecap` or `/endcapper`: open artwork options.
- `/ecap status`: report native effect loading state on each side.

## Compatibility and troubleshooting

- Designed for Forever's default mouse-and-keyboard action bar; interface 16001. Development client metadata: 1.60.1.70862.
- Replacement action-bar addons and gamepad layouts are not supported. Options are English only.
- Cap placement follows the active native Edit Mode layout: size, X/Y, snap state, linked mode, pair centre and separation are remembered per layout. Artwork choices and effect calibration remain account-wide. Native dragged positions still use Edit Mode Save.
- Editing is available outside combat. No third-party libraries are required.
- Native effects may need time to load and refresh automatically when loading completes. Use `/ecap status` if one remains absent; saving changed settings or showing the cap again can recover a late-loaded model.
- Disabling EndCapper and reloading restores the original caps; saved settings remain available.

For bug reports, include the addon version, `/dump GetBuildInfo()` output, artwork/side, steps to reproduce and any Lua error. See `CHANGELOG.md` and `LICENSE` for release and distribution details.
