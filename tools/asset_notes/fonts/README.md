# Bundled existing typefaces

Nunito and Fredoka are the same families previously selected through `google_fonts`. These local font files remove first-launch network fetching; they are not new game illustrations or voice assets.

The seven TTF files were downloaded from `https://fonts.gstatic.com/s/a/<sha256>.ttf` using the exact file hashes declared by the locked `google_fonts` **6.3.3** package. Each downloaded SHA-256 was checked against that package metadata.

| File | SHA-256 |
|---|---|
| Nunito-Regular.ttf | 6f96017e762896b4cf3c2db345d41d7a72a3720a95698c3cd47020bf433db435 |
| Nunito-Medium.ttf | 1f6452d3509db129d3468088c1c952f1a844b6dc865703a09595fc53700a6251 |
| Nunito-SemiBold.ttf | f165190d31319dc6384c83fdd014ed983630541b21d005b5caadf1d74fbd513d |
| Nunito-Bold.ttf | 8148a236e4127dad38346ce596c544389aa2fdaaa9f311e589741de30d25ddb8 |
| Nunito-ExtraBold.ttf | 43364ac2d05d1033b5e255ce77e4d84d2f6467bfadb5e5985ca4e688949e73bf |
| Nunito-Black.ttf | a5ddd59da28c281984ae3bd12aa3b9af3b204e61156e50f1108d5fcf71aa5665 |
| Fredoka-Regular.ttf | 125cc34039587d0926961da82659002e686518af02c0771f7224c40a63f2c144 |

Licenses are included as `nunito-OFL.txt` and `fredoka-OFL.txt` and registered with Flutter's license registry. Sources: [Nunito license](https://github.com/google/fonts/blob/main/ofl/nunito/OFL.txt), [Fredoka license](https://github.com/google/fonts/blob/main/ofl/fredoka/OFL.txt). The [google_fonts asset-bundling documentation](https://pub.dev/packages/google_fonts#bundling-fonts-when-releasing) describes matching local font names. Runtime fetching is disabled in `main.dart`; the stabilization test loads all used variants with HTTP disabled.
