# Changelog

## 1.4.0

- Added Kirin Tor, Snowfang, Frosthilt, Frostblade, Hexbound, Soulbound, Cryptgate and Plaguewell. Rebuilt Worgen as Shadowfang and repainted Violetspire, bringing the collection to 26 custom designs.
- Added independently configurable End Cap and Corner Cap tabs. Enable either or both, then drag custom caps directly from the EndCapper panel. Click a cap to select it, fine-tune sliders with one-unit arrows, and use Snap to center for linked End Caps or Snap to corners for linked Corner Caps.
- Added a movable EndCapper logo button with a visibility toggle. Improved Save and Cancel so discarded previews restore saved positions.
- Added Frostmourne's ice formations, frost mist and glow, plus Frosthilt's Cold Flame eye trail. Hexbound and Soulbound feature pulsing fel details, with a hovering soul crystal on Soulbound.
- Added animated falling poison, Rot Fog and Blue Mist to Cryptgate and Plaguewell. Cryptgate has a candle flame and two amber eye trails, and Plaguewell has a glowing amber lantern. Their calibrated effects apply by default in both modes.
- Corrected the texture format for moving crystals, seals and halos to address black blocks and striped rendering artifacts.

## 1.3.0 — 2026-11-10

Changes since the 1.2.0 full release.

### New and updated artwork

- Added **Lordaeron**, a headless sister to Undead featuring ruined Lordaeron/Undercity architecture, bones, rot, worn blue banners and green-lit stonework. EndCapper now includes 18 custom designs, plus Default and Hidden.
- Completely rebuilt **Undead** around a decaying face with remaining flesh, hair, an open mouth and amber eyes. Both sisters have aligned, flat basal rails for a closer fit against action bars and the screen bottom.
- Refined Undead and Lordaeron with smooth, high-definition painterly shading and clean silhouettes while retaining the ruined, eerie theme.
- Repainted **Verdant** and **Moonwell** with smoother, matching wood and foliage. Rebuilt Moonwell's registered glyph, moon, water and reflected-light emission layers to match the new artwork; existing pulse timing and native effects remain.
- Revised default facing: Undead mirrors on the left and Lordaeron mirrors on the right when Flip is unchecked. Existing saved appearances remain intact.

### Artwork selection and linked controls

- Added **Link pairs** to select and position matching sisters together. Sister combinations are Undead / Lordaeron, Moonbough / Lunar, Verdant / Moonwell, Cinderforged / Cindermaw, Rimeforged / Rimeguard, Seraph / Sanctum, and Umbra / Eclipse.
- Worgen, Stormhorn, Felwing and Violetspire use mirrored copies of the same design in linked mode. Default and Hidden remain available as utility choices.
- Replaced the artwork button grid with scrollable native dropdown menus. Linked mode has one menu listing complete combinations; independent mode retains separate Left artwork and Right artwork menus.
- Added **Swap** to exchange the sisters' left/right assignments. The linked menu label follows the selected order.
- Linked mode disables the individual side selectors and shares Flip, Size, X and Y. Unlinking retains the visible frame positions and restores independent controls.
- Added **Separation distance**, ranging from 0 to 2000 UI units. It moves the cap frames, measuring the gap between their visible drag-frame edges; zero makes those edges touch without overlap. Frame width, artwork size and effective UI scale are included in placement.
- First-link separation defaults derive from native cap centre spacing. Adjusted separation, including a deliberate zero, survives unlinking, relinking and saving. Reset Pair restores native-based spacing instead of collapsing the caps together.
- Shared X moves the pair centre while artwork stays horizontally centred in each frame. Dragging a linked cap moves that shared centre while preserving separation.
- Added **Snap to bottom** in both modes. It places the drag frame at the screen bottom and aligns the artwork's measured crop line to that edge. This is the default alignment; Reset Side and Reset Pair reapply it.
- Y = 0 now references the artwork's bottom crop line; positive Y raises the artwork. Artwork offsets remain independent of the drag box. Native dragging releases bottom anchoring and continues to use Blizzard's Edit Mode Save.
- Grouped Left cap / Right cap selectors, Flip, Swap, sliders and Snap inside a subtle inner control box, with artwork selection above and Save/Cancel below.
- Renamed **Apply** to **Save**. Save is disabled until settings actually change, disables again after saving, and becomes disabled when edits are returned to their saved values. Cancel and closing the panel discard previews.

### Native Edit Mode profiles and persistence

- Added placement records for native Edit Mode layouts, storing side size, offsets, horizontal frame anchors, bottom snapping, linked state, pair centre and separation independently per layout. Artwork choices, facing and effect calibration remain shared.
- Layout switching saves committed outgoing placement, discards unsaved previews, restores incoming placement and clears rollback anchors belonging to the previous layout. Reconciliation follows native layout application and defers during combat.
- Existing placement is associated with the first active layout. Previously unused layouts retain their native anchors; newly copied layouts inherit committed placement before becoming independent.
- Layout identity includes name, type and interface style, plus character identity for character-specific layouts. In-session renames and index changes after deletion preserve the associated records.
- Fixed a profile lookup error that could freeze every editor control: Blizzard's active layout index includes preset layouts, while its saved-layout list does not. EndCapper now resolves the same combined preset/saved ordering as the native UI.
- Temporary metadata failures no longer block rendering or discard drafts. Placement writes wait until the active layout can be identified, and initial profile binding occurs before editor draft creation.
- Updated saved-settings schema from 21 to 28 with normalized, bounded placement records and initialized-separation tracking. Existing explicit artwork, facing, positioning and supported effect overrides are preserved; only retired effect settings are removed.

### Effects and rendering architecture

- Replaced Undead's blue spectral trail with simultaneous native **Amber Flow** and green **Rot Fog** on both Undead and Lordaeron. Removed Undead's old custom eye pulse; Worgen's eye glow and native spectral trail remain.
- Baked revised effect placement, size, angle, opacity and layer defaults for Undead, Lordaeron, Worgen, Moonbough, Lunar, Violetspire, Cindermaw, Rimeforged, Rimeguard, Moonwell, Seraph, Sanctum, Umbra and Eclipse, without replacing explicit saved overrides or personal artwork placement.
- Removed Faerie Fire from Moonbough and Lunar, retaining Moonlight and migrating their retired selections. Verdant retains its supported alternative.
- Added a bottom-only effect cutoff registered to the visible basal edge of every custom design. It follows artwork size, offsets and native dragging, leaving the artwork and drag box intact and retaining space for effects above and beside the artwork.
- Added a shared clipping module. Custom emission, glow and halo textures use pooled clipping hosts; the separate arcane crystal retains its existing motion while its emission and seal use the appropriate stationary clipping plane.
- Native effect scenes remain direct cap children with independent front/back ordering and overlap enabled. Their physical viewport bottom is shortened at the artwork baseline, with field-of-view and view-translation compensation preserving calibrated size and position. This replaces generic child clipping, which caused rear effects to disappear.
- Fully cropped native effects hide safely and recover when moved above the cutoff. Missing clipping capabilities use a guarded rendering fallback instead of the failing native wrapper path. No new per-frame Lua update loop was added.
- Added native model-load completion callbacks for both effect layers. Late-loaded effects now reconcile automatically through the current render path instead of waiting for a manual save.
- Load completion uses model/generation/readiness checks, coalesced scheduling, bounded polling recovery and hidden/combat/disabled guards to prevent stale callbacks from restoring old effects.
- Made previews, native completion callbacks and frame/texture hooks refresh only their owning side. Editing one cap no longer restarts the opposite cap's effects; requests for both sides merge safely when needed.
- Preserved active native scenes during ordinary previews and saves instead of repeatedly stopping and restarting them. Both layers retain independent loading, failure and visibility handling. This fixes intermittent missing second effects and alternating rear glows during sister changes and repeated saves.
- Expanded `/ecap status` diagnostics to report native scene overlap state as well as loading state.

### Project and release maintenance

- Established a consistent smooth painterly artwork fidelity rule, with preserved source images and reproducible artwork/emission preparation for the revised designs.
- Added regression coverage for asynchronous paired effects, per-side refresh isolation, clipping and projection, artwork/emission registration, linked controls, native frame spacing, profile migration/switching and change-aware Save behavior.
- Expanded the clean player package from 57 to 60 files for Lordaeron and the new clipping/layout modules. Development history, source images, research, tools, tests and backups remain outside the release ZIP. Native game models are referenced rather than redistributed.

## 1.2.0 — 2026-11-10

- Moonwell
- Seraph
- Sanctum
- Umbra
- Eclipse
