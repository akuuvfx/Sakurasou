# Sakurasou

App iOS (SwiftUI, Liquid Glass) : télécharge l'audio de vidéos en MP3 via yt-dlp, édite les tags ID3 (titre, artiste, album, année, pochette) et envoie le fichier dans un dossier permanent.

- 3 onglets : Télécharger / Tags / Réglages (crédits yt-dlp inclus)
- Bouton « Envoyer le MP3 » dans les onglets 1 et 2
- `server/server.py` : petit serveur yt-dlp à héberger (yt-dlp ne tourne pas nativement sur iOS)
- Compilation : GitHub Actions (onglet Actions → artefact `Sakurasou-ipa`, IPA non signé à signer avec AltStore/Sideloadly)

Crédits : [yt-dlp](https://github.com/yt-dlp/yt-dlp)
