# Character selection reference update

The character picker follows the supplied reference with a glossy purple title
ribbon, large blue Boy and pink Girl portraits with integrated name plaques,
a cream panel with a gold rim, a lavender name input, and cream Cancel / purple
Let's go buttons. The courtyard is blurred behind the dialog. Selected artwork
gets a purple glow around its silhouette and an accessible selected state.

The banner and framed characters are separate transparent assets. Their aspect
ratios remain intact as the panel adapts to phones and tablets. The editable
name input and its 24-character counter remain native Flutter controls. The
content scrolls when space is limited or the keyboard opens; the save action
stays outside that scroll area. First-time setup retains its required selection,
name validation, recorded instructions, and playback-completion save gate.
Cancel is available when editing an existing learner profile. Saving preserves
the learner's lesson progress and rewards.

## Artwork and prompts

The built-in `image_gen` tool extracted/recreated these sprites from the user's
character-selection reference, with a transparent background:

- [banner.png](../assets/images/character_selection/banner.png)
- [boy.png](../assets/images/character_selection/boy.png)
- [girl.png](../assets/images/character_selection/girl.png)

The exact final prompts and saved asset paths are in
[character_selection_art_prompts.json](../tools/character_selection_art_prompts.json).
`CharacterSelectionArt.assets` lists the runtime assets and loading preloads them.

## Verification

The rendered dialog previews are in `build/ui_previews/update_character_picker_320.png`,
`update_character_picker_390.png`, `update_character_picker_430.png`, and
`update_character_picker_768.png`. First-time setup is also captured in
`build/ui_previews/update_profile_setup.png`.

Scoped checks cover equal-size separate tap targets, portrait proportions,
banner placement, selected semantics, readable text over the dark app theme,
name-counter bounds, large text with the keyboard open, cancellation, saving
and restoring a profile, voice-gated onboarding, and the asset bundle audit.
All 44 scoped checks passed in `build/character-selection-reference-verified-tests.log`.
Static analysis found no issues (`build/character-selection-reference-analysis.log`). Physical-device visual
and keyboard behavior have not been checked.
