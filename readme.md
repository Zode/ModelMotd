# ModelMotd
requires [AFB](https://github.com/zode/afbase) to run.
Adds a model motd (along with a song) that is only displayed upon first spawn, and then made invisible after doing anything.

### CVARS:
```
modelmotd_enable - 0/1 disable/enable modelmotd
```

## registers:
```
#include "AFBaseExpansions/ModelMotd"
ModelMotd_Call();
```

## modifying for your server:
clone the .mdl file, and make any texture adjustments necessary.
to change the model and/or song swap out the lines 59 & 60 in ModelMotd.as