# Sakurasou

App iOS qui télécharge l'audio de vidéos en **MP3**, **directement sur l'iPhone** (aucun serveur) :

- `yt-dlp` exécuté dans un Python embarqué (PythonKit + python-apple-support)
- `ffmpeg` embarqué (SwiftFFmpeg-iOS) pour la conversion MP3

3 onglets (Liquid Glass) : Télécharger · Tags · Réglages. Bouton « Envoyer le MP3 » vers un dossier permanent.

## Compilation
GitHub Actions → *Build iOS* → artefact `Sakurasou-ipa` (IPA non signée, à signer avec AltStore/Sideloadly).

## Crédits
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- [FFmpeg](https://ffmpeg.org) / LAME
- [Palladium](https://github.com/tfourj/Palladium) (tfourj, GPL-3.0) : approche d'intégration, SwiftFFmpeg-iOS
- [PythonKit](https://github.com/pvieito/PythonKit)
- [python-apple-support](https://github.com/beeware/Python-Apple-support)

**Icône** : ajoute `icon.png` (1024×1024) dans `Sakurasou/Assets.xcassets/AppIcon.appiconset/`.
