# UI SFX audio

The selected MP3 files under `assets/audio/ui_sfx/` are copied from the UI SFX
project. The upstream library contains 78 semantic cues across 12 sound packs;
this game currently ships the cues it uses in five packs (`soft`, `organic`,
`zen`, `arcade`, `scifi`) and can add another cue by copying one matching MP3.
Runtime code loads cues by meaning (`reward`, `select`, `complete`, etc.) and
chooses the pack independently.

The audio is CC0-1.0. The source revision and full license text are kept next
to this note in `source_url.txt` and `LICENSE-AUDIO.txt`.
