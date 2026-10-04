# New UI runtime artwork

These assets were derived with the built-in imagegen tool from the user's
design references. The original references are in `design_reference/new_ui/`.

- `flappy_bird.png`: transparent blue bird sprite, derived from `flappy letter UI.png`.
- `parent_garden.png`: clean garden background, derived from `parent ui design.png`.
- `frame_pink.png`: transparent pink variant of the existing glossy blue answer frame.

The other four answer frame colors remain in `../answer_choices/`. Foliage,
panels, progress values, labels and button interactions are Flutter widgets.

## Generation prompts

**Blue bird:** Extract/recreate only the little blue bird flying right in the
Flappy Letters reference. Preserve bright cyan feathers, white face/belly,
large eyes, orange beak/feet, spread wings, cheerful expression and polished
3D cartoon style. One complete centered bird with small clear margins.
Transparent background. No pipes, leaves, text, blocks, UI, clouds or frame.

**Parent garden:** Reconstruct only the lush sunny green forest/garden backdrop
from the Parent Panel reference in the same soft 3D children's illustration
style and green/lime palette. Remove all UI, text, icons, mascots, cards and
signs. Continuous softly focused garden clearing, distant trees, blue sky and
sunlight at the top. Leafy borders and small flowers, unobstructed center.
Portrait 9:16, no text or UI elements.

**Pink frame:** Change only the blue/cyan rim of the supplied glossy rounded
square frame to vivid hot pink/magenta. Preserve shape, cream blank center,
beveled rim, white highlights, shadows, proportions, transparent margins and
square canvas. No text, symbols, leaves or extra objects. Opaque cream center.
