# Fonts
If you don't already have a shared fonts folder, do so:
```
sudo mkdir -p /usr/local/share/fonts/ttf
```
Download `Pragmata Pro` from `https://fsd.it/shop/fonts/pragmatapro/`
```
unzip PragmataPro*.zip
sudo mv PragmataPro*/ /usr/local/share/fonts/ttf/
fc-cache -f # rebuild the font cache
fc-list | grep Pragmata  # validate it's there
```
To browse the special glyphs, use a character map such as `gucharmap`. In order to paste a glyph into vim merely go into insert mode then `ctrl+v` followed by `u` then the character such that character `0x00f11c` would be `ctrl+v, u, f, 1, 1, c`.
