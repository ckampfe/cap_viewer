# CapViewer

A simple viewer for [cap](https://github.com/ckampfe/cap)

![example](https://i.imgur.com/uMFs9ysl.png)

To use this:

```sh
$ git clone
$ cd cap_viewer
# modify config/config.exs here:
# https://github.com/ckampfe/cap_viewer/blob/master/config/config.exs#L20-L21
# so it points to the path of your cap database
$ mix deps.get
$ cd assets && npm install
$ mix phx.server
# got to localhost:4000/entries
```
