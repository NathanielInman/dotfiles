# Fonts
If you don't already have a shared fonts folder, do so:
```
sudo mkdir -p /usr/local/share/fonts/ttf
```
Download `Pragmata Pro` from `https://fsd.it/shop/fonts/pragmatapro/`
```
unzip PragmataPro0.829.zip #or w/e the version is
sudo mv PragmataPro0.829 /usr/local/share/fonts/ttf
fc-cache # clear the font cache
fc-list | grep Pragmata  # validate it's there
xfd -fa "PragmataPro Liga-18" # this will allow you to select special glyphs
```
In order to paste a glyph into vim merely go into insert mode then `ctrl+v` followed by `u` then the character such that character `0x00f11c` would be `ctrl+v, u, f, 1, 1, c`.
