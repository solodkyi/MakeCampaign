# RobyZbir SwiftUI Design System

## Goal

Create a reusable, feature-independent SwiftUI design-system layer that faithfully translates the non-artwork parts of `docs/components/design-system/robyzbir-component-library.html` into the MakeCampaign app.

## Scope

The layer will expose SwiftUI foundation tokens and controls only. Existing campaign-list, form, template-selection, and navigation views will not be restyled in this change. The nine `CoverArtwork` families and all associated cover imagery are explicitly excluded.

## Architecture

`MakeCampaign/DesignSystem` will be split between foundations and composed components. Foundations expose semantic roles instead of feature-specific colors or layout values; components consume those roles and take their content, actions, and bindings as inputs. Neither layer imports Composable Architecture or accesses app state, so any feature can adopt it without a dependency on another feature.

The palette is resolved from `ColorScheme`: light uses the app, surface, field, ink, muted, and border values from the HTML contract; dark uses its dark app, card, tray, foreground, muted, border, and field counterparts. Explicit theme overrides are supported for previews and feature-local rendering, while the default follows the system scheme.

The app supports iOS 17. Components use standard SwiftUI visuals there. A small reusable glass action surface will use native Liquid Glass only on iOS 26 and later, with a material fallback on iOS 17–25.

## Foundations

- `RBColor`: exact semantic colors: canvas, app, surface, elevated surface, field, paper, ink, muted ink, border, accent, accent hover, destructive, steel, iOS blue, iOS green, grouped background, and Telegram.
- `RBTheme`: `system`, `light`, and `dark` selection plus environment values that resolve semantic roles.
- `RBSpacing`, `RBRadius`, and `RBShadow`: values from the HTML contract: 4-point spacing scale; 13/14/16/18/20/24/26/pill radii; card, artwork, editor, and floating shadows.
- `RBTypography`: screen title, card title, monetary/data, and micro-label roles. UI text uses a weight/size mapping from the HTML’s Manrope roles; data uses a monospaced system design. The reference’s externally hosted Google fonts are not downloaded or bundled.

## Reusable Components

- Primary button style with the 56-point orange accent treatment, disabled state, and accessibility-preserving SwiftUI `Button` behavior.
- Filter chip with selected and idle states.
- Labelled field helpers and text-field styling for text/numeric inputs, including validation/error presentation supplied by the caller.
- Generic segmented control and generic format-option grid with `Binding` selection.
- Progress bar accepting a clamped `Double` progress value.
- Switch row based on SwiftUI `Toggle`.
- Tool tile and selection tile for reusable editor actions.
- `RBBottomSheet` with handle, title, arbitrary content, and safe-area-aware primary action slot.
- `RBEditorTray` with a generic tab collection, selected tab binding, and body slot.
- `RBCampaignCard` with generic caller-supplied thumbnail and campaign metadata slots; no artwork rendering or campaign-model dependency.
- A glass icon action surface whose iOS 26 implementation uses `glassEffect`, and whose earlier-platform fallback matches the reference’s translucent material pill.

## API and State Rules

Components expose semantic inputs such as `isSelected`, `progress`, `selection`, or a supplied `Binding`; they do not own feature reducers or persistence. Controls provide VoiceOver labels/traits through their native SwiftUI control types. Destructive styling is only applied when the caller explicitly requests it.

## Testing and Verification

New unit tests will first assert stable, non-visual behavior: theme role resolution, progress clamping, and selection/state helpers. Each test will be run while failing before the matching implementation exists, then re-run green after the minimal implementation. Preview coverage will exercise light/dark and active/inactive states.

Before completion, the tracked `workflow.config.json` will define a lowercase-kebab-case design-system scope with the project’s relevant build and unit-test commands. The configuration will be committed/clean relative to `HEAD` before a fresh `python3 Scripts/workflow.py run <scope>` execution. Its exit status must be zero.
