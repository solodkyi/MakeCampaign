# Campaign Template Set Replacement Requirements

## Document purpose

This document defines the mandatory requirements for replacing the complete MakeCampaign poster-template catalog. It is intended as a handoff to the implementation agent.

This is not a creative brief. It does not prescribe colors, typography, illustration style, decorative elements, or visual themes. Those decisions require separate creative direction.

## Required outcome

The implementation must replace the visual implementation of all 15 current campaign templates while preserving the existing template catalog contract and all campaign-editor behavior.

The completed set must:

- contain exactly 15 templates;
- preserve every current template identifier, catalog position, user-facing name, gradient case, and image-placement case;
- remain compatible with campaigns persisted using the current `Template` model;
- support the complete campaign creation, editing, preview, thumbnail, photo-framing, QR, and export feature set;
- render exported posters pixel-identically to their resting previews at equivalent dimensions and scale;
- preserve or improve the current template-selector scrolling and rendering performance.

## Scope

### In scope

- Replacing the SwiftUI visual composition inside each of the 15 existing template views.
- Adjusting template-local layout constants needed for the replacement compositions.
- Adding template-local, bundled assets when required by the approved creative input.
- Updating or adding automated tests needed to prove the requirements in this document.
- Updating SwiftUI previews used to inspect the replacement templates.

### Out of scope

- Adding, removing, reordering, or renaming templates.
- Changing template identifiers or the `Template.Gradient` and `Template.ImagePlacement` cases.
- Migrating persisted campaign data.
- Changing campaign creation, editing, navigation, photo selection, photo reframing, text entry, QR, save, or export behavior.
- Redesigning `CampaignRenderer`, `CampaignPosterArtwork`, `CampaignTemplateArtwork`, the thumbnail cache, or the preview-asset pipeline.
- Replacing the established shared preview/export rendering path with separate implementations.
- Defining visual art direction.
- Committing, pushing, publishing, deleting, or modifying unrelated user-owned work without explicit authorization.

## Frozen catalog contract

The implementation must preserve the following catalog entries exactly and in this order:

| Position | Name | Gradient case | Image-placement case | Identifier | Existing view |
| ---: | --- | --- | --- | --- | --- |
| 1 | `1` | `blueLinear` | `center` | `blueLinear_center` | `BlueGradientTemplateView` |
| 2 | `2` | `cyanMagentaRadial` | `squareTrailing` | `cyanMagentaRadial_squareTrailing` | `CyanMagentaGradientTemplateView` |
| 3 | `3` | `linearPurple` | `topCenter` | `linearPurple_topCenter` | `PurpleGradientTemplateView` |
| 4 | `4` | `goldBlackLinear` | `hexagonTrailing` | `goldBlackLinear_hexagonTrailing` | `GoldBlackGradientTemplateView` |
| 5 | `5` | `pinkAngular` | `topCenter` | `pinkAngular_topCenter` | `PinkGradientTemplateView` |
| 6 | `6` | `tealPurpleRadial` | `roundedTrailing` | `tealPurpleRadial_roundedTrailing` | `TealPurpleGradientTemplateView` |
| 7 | `7` | `linearGreen` | `topToBottomTrailing` | `linearGreen_topToBottomTrailing` | `GreenGradientTemplateView` |
| 8 | `8` | `angularYellowBlue` | `trailing` | `angularYellowBlue_trailing` | `YellowBlueGradientTemplateView` |
| 9 | `9` | `linearSilverBlue` | `trailingToEdge` | `linearSilverBlue_trailingToEdge` | `SilverBlueTemplateView` |
| 10 | `10` | `radialRedBlack` | `topToEdge` | `radialRedBlack_topToEdge` | `RedBlackGradientTemplateView` |
| 11 | `11` | `linearIndigoOrange` | `trailing` | `linearIndigoOrange_trailing` | `IndigoOrangeGradientTemplateView` |
| 12 | `12` | `linearEmeraldBlack` | `hexagonTrailing` | `linearEmeraldBlack_hexagonTrailing` | `EmeraldBlackGradientTemplateView` |
| 13 | `13` | `radialAquaPurple` | `squareTrailing` | `radialAquaPurple_squareTrailing` | `AquaPurpleGradientTemplateView` |
| 14 | `14` | `radialMintIndigo` | `roundedTrailing` | `radialMintIndigo_roundedTrailing` | `MintIndigoGradientTemplateView` |
| 15 | `15` | `linearCoralTeal` | `trailing` | `linearCoralTeal_trailing` | `CoralTealGradientTemplateView` |

`Template.list` must still contain exactly these entries. A previously saved campaign must resolve its stored template to the same catalog entry after the replacement.

## Functional requirements

### Shared template interface

Each template view must continue to accept:

- a non-optional `purpose: String`;
- an optional `goal: String?`;
- injected photo content through the existing `viewProvider` contract.

Templates must render only the values supplied through this interface. Production artwork must not contain hard-coded sample campaign purpose or target values.

SwiftUI preview-only sample content may remain hard-coded inside `#Preview` declarations, but it must never enter runtime catalog rendering.

### Campaign purpose

- Every template must render the supplied purpose exactly once.
- Every rendered purpose region must be marked with `.campaignPosterElement(.campaignTitle)` exactly once.
- The region must remain selectable and editable through the existing poster interaction system.
- An empty campaign purpose must display the shared `campaign.posterPurpose` result, currently `Назва збору`.
- Purpose text must remain readable and contained for short text and for Ukrainian text from 1 through 120 extended grapheme clusters.
- Purpose layout must not rely on truncation that hides the complete value under normal supported input.

### Campaign target

- When `goal` is non-`nil`, every template must display the supplied formatted goal exactly once.
- The goal value region must be marked with `.campaignPosterElement(.target)` exactly once.
- The region must remain selectable and editable through the existing poster interaction system.
- When `goal` is `nil`, the complete target group must be absent. This includes the numeric value, currency, target label, and space reserved solely for that group.
- Templates must not parse, reformat, round, localize, or append another currency suffix to the supplied goal.

### Photo content

- Every template must contain exactly one designated photo frame populated by the injected photo content.
- Template views must not read, decode, cache, or load campaign photo data themselves.
- The frame must support both `.fill` and `.fit` photo content modes through the existing shared image rendering path.
- Existing photo scale, offset, and reference-size transforms must remain visually consistent between the resting preview and export.
- Manual drag and magnification reframing must continue to operate when the Photo, Template, and Text tabs are active.
- During an active manual-framing gesture, the complete photo must remain visible outside the designated frame with the existing translucent-overflow treatment, while the part inside the frame remains opaque.
- At the end of the gesture, content outside the designated frame must no longer be visible.
- Template-local masks, clipping, overlays, and decoration must not intercept photo gestures or prevent the shared photo interaction system from receiving them.
- The photo frame must not collapse to zero size or produce negative or non-finite frame dimensions in any supported poster format.

### QR content

- Templates must remain compatible with the shared `CampaignPosterArtwork` QR overlay.
- QR-disabled campaigns must display no QR content.
- QR-enabled campaigns with a valid link must display the shared QR image and call-to-action treatment without modification by individual templates.
- Template content that communicates the campaign purpose or target must not be obscured by the shared QR overlay in any supported poster format.
- Individual templates must not generate, decode, reposition, restyle, or duplicate the QR overlay.

### Poster formats

Every template must support all existing poster formats:

| Format | Aspect ratio | Export pixels |
| --- | ---: | ---: |
| Square | `1:1` | `1080 × 1080` |
| Portrait | `4:5` | `1080 × 1350` |
| Story | `9:16` | `1080 × 1920` |

For every format:

- all essential template content must remain inside poster bounds;
- purpose, target, and designated photo regions must remain usable and visually distinct;
- layout must be derived from the size supplied by the parent container rather than `UIScreen`, device model, orientation, or a fixed preview size;
- the same SwiftUI artwork must scale from template thumbnails through editor previews to full export resolution;
- the template must not introduce format-specific content that makes preview and export diverge.

## Rendering parity requirements

- `CampaignTemplateArtwork` must remain the single template routing point used by preview, thumbnail, and export rendering.
- Each preserved gradient/image-placement pair must route to exactly one corresponding template view; no pair may fall through to `EmptyView`.
- The resting interactive preview and exported poster must use the same visual composition and produce identical RGBA pixels when rendered with equivalent inputs, dimensions, display environment, and scale.
- Template selector thumbnails using `.poster` composition must match the corresponding live preview pixels.
- Template-only thumbnails must continue using the lightweight injected placeholder-photo composition and must not instantiate interactive poster controls.
- Rendering must be deterministic. Template output must not depend on current date, time, random values, network state, asynchronous completion order, device-specific screen metrics, or mutable global state.
- Light/dark appearance and locale inputs must flow through the existing rendering environment without creating preview/export differences.
- No template may maintain separate visual state that changes the resting artwork after interaction ends.

## Performance requirements

- Replacing templates must not change the existing thumbnail cache keys, cache limits, in-flight request coalescing, cancellation behavior, or prewarming behavior.
- Template views must remain pure, synchronous SwiftUI compositions over their supplied values and geometry.
- A template body must not perform image decoding, file access, network access, data persistence, `ImageRenderer` creation, QR generation, or other blocking work.
- A template must not start tasks, timers, animations that run continuously, or per-frame state mutations when shown as a thumbnail.
- Template decoration must not add gesture-time offscreen rasterization to the shared photo layer.
- Template thumbnails must remain rendered once per unique cache key and reused during scrolling.
- Changing only photo scale, offset, or reference size must not reload the visible template-thumbnail batch.
- The full 15-template strip must remain responsive during rapid horizontal scrolling on the configured iPhone 17 Pro simulator running iOS 26.3.1.
- The existing opt-in thumbnail, renderer, and scroll benchmarks must be run before and after replacement. The agent must record both result sets and treat a regression greater than 10% in median cold-all-template rendering, median initial-four rendering, median warm rendering, median warm export rendering, scroll duration, scroll CPU use, or scroll memory use as a failure unless the user explicitly accepts it.
- Memory must remain bounded by the current thumbnail cache limits: 48 images and 24 MiB decoded-byte cost.

## Accessibility requirements

- The shared poster must continue exposing exactly one interactive accessibility element for the photo, campaign title, and target when the target exists.
- Template thumbnails must not expose nested interactive poster elements.
- Decorative shapes, gradients, and images must not appear as separate accessibility elements.
- Existing accessibility identifiers and named poster editing actions must remain unchanged.
- Text contrast at rendered output must be at least 4.5:1 for normal text and 3:1 for large text under the WCAG 2.1 AA definition, including text placed over photos or gradients.
- Accessibility behavior must remain valid in both light and dark system appearances even when the template artwork itself is appearance-independent.

## Asset requirements

- Any new runtime asset must be bundled with the app and available without network access.
- The implementation must include only assets whose license permits inclusion and distribution in the application.
- New asset filenames must be stable, unique, and suitable for source control.
- Raster assets must include sufficient source resolution for the largest supported export without visible upscaling artifacts.
- Template code must not repeatedly decode bundled raster assets during body evaluation or thumbnail scrolling.
- Missing optional decorative assets must not prevent purpose, target, photo, or QR content from rendering.

## Test requirements

Implementation must be test-first. New or updated tests must fail against the pre-replacement behavior for the intended requirement before production code is changed, then pass with the replacement implementation.

Automated coverage must prove at minimum:

1. `Template.list` still contains exactly 15 entries in the frozen order with the frozen names, cases, and identifiers.
2. Every catalog entry routes to non-empty artwork.
3. Preview and shared artwork pixels match for every template.
4. Poster thumbnail and live preview pixels match for every template.
5. Resting interactive preview and exported artwork pixels match for square, portrait, and story output.
6. Preview/export parity is preserved for `.fill`, `.fit`, transformed photo, QR-enabled, QR-disabled, light appearance, dark appearance, and Ukrainian locale variants.
7. Every template renders a purpose region and conditionally renders a target region.
8. An empty purpose uses `Назва збору`; a missing target renders no target group.
9. Manual photo framing preserves translucent overflow during interaction and clips overflow when interaction ends.
10. Template thumbnails expose no nested interactive poster elements.
11. Template selection, photo reframing, purpose editing, target editing, QR display, and export remain functional in simulator UI tests.
12. Thumbnail caching, batch retention during photo reframing, request coalescing, cancellation, exact output size, and memory limits remain unchanged.

Pixel-parity assertions must compare rendered pixel buffers. Screenshot presence alone is not sufficient evidence of parity.

Performance tests must use the existing opt-in flags:

- `CAMPAIGN_THUMBNAIL_BENCHMARK=1`
- `CAMPAIGN_RENDERER_BENCHMARK=1`
- `CAMPAIGN_SCROLL_BENCHMARK=1`

## Manual verification requirements

The agent must verify all 15 templates on an iPhone 17 Pro simulator running iOS 26.3.1.

For each template, verification must cover:

- square, portrait, and story formats;
- short and long Ukrainian purpose text;
- target present and target absent;
- photo `.fill` and `.fit` modes;
- photo drag and magnification reframing;
- active translucent overflow and resting clipped state;
- QR enabled and disabled;
- template thumbnail, editor preview, and exported image comparison;
- light and dark system appearances.

The agent must provide retained screenshots for each template in all three formats using one consistent populated campaign fixture. Additional screenshots must cover empty purpose, missing target, `.fit`, active reframing, and QR-disabled states. Screenshots are review artifacts and do not replace automated pixel tests.

## Repository and delivery requirements

- Preserve all pre-existing dirty-tree changes and unrelated files.
- Do not reset, restore, delete, stage, commit, or reinterpret user-owned changes without explicit authorization.
- Do not change `workflow.config.json` as part of the template replacement unless a required test cannot be represented by the existing scope and the user explicitly approves the configuration change.
- Build and test against the configured iPhone 17 Pro simulator running iOS 26.3.1.
- Before declaring the replacement complete, run:

  ```sh
  python3 Scripts/workflow.py run features/campaign-creation
  ```

- The workflow must exit with status `0`. Failed, timed-out, interrupted, malformed, or modified workflow artifacts do not satisfy acceptance; after repair, a new workflow run is required.
- The final handoff must list every modified file, every added asset, all tests added or changed, benchmark before/after results, the successful workflow run ID, and the completed manual verification matrix.
- The agent must not commit, push, publish, or open a pull request unless separately authorized.

## Acceptance criteria

The replacement set is accepted only when all of the following are true:

- Exactly 15 replacement visual implementations are present.
- The frozen catalog contract is unchanged.
- Previously persisted template identifiers still resolve correctly.
- Every template supports all required campaign content and interactions.
- Every template renders correctly in square, portrait, and story formats.
- Empty purpose and missing-target behavior match this specification.
- Preview, thumbnails, and export pass the required pixel-parity tests.
- Photo framing and QR behavior remain functional.
- Accessibility requirements pass automated and manual checks.
- Recorded performance does not regress beyond the allowed threshold.
- All required automated tests pass.
- The mandatory `features/campaign-creation` workflow exits `0` in a fresh run.
- The requested manual-verification evidence and final change inventory are delivered.

## Explicitly unspecified creative decisions

This document intentionally does not specify:

- palette;
- font family or typographic style;
- illustration or photography style;
- gradient appearance;
- shape language;
- decorative motifs;
- visual tone;
- content hierarchy beyond the functional visibility and interaction requirements above;
- how visually similar or different the 15 templates should be.

The implementation agent must obtain an approved creative brief or approved visual references before making those decisions.
