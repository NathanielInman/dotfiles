# Linux Scripts

## Finding a window
There are times where you want to find the `CLASS` or other such attributes of running programs to apply configurations within `dunst`, `i3` or other applications.

```
# this allows you to click on most windows showing those attributes within the cli
xprop

# this lets you test your attributes you're using within your apps to validate they're accurate
xdotool search --onlyvisible --classname Zoom
```
