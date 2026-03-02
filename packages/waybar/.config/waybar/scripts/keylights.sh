#\!/bin/bash

if [ "$(keylightctl describe --all 2> /dev/null | grep "| 0 |" | cut -c 34-36)" = "off" ]; then
  echo '{"text": "", "class": "off"}'
else
  echo '{"text": "", "class": "on"}'
fi
