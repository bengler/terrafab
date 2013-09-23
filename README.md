TerraFab
========

## Prerequisites

- Node.js 0.10.x or newer

## Getting up and running

You need the graphics library Cairo installed. Cairo needs to be linked with freetype to work with node_canvas for some reason. A simple way to achieve this if you are using homebrew on OS X is to install Cairo without X11-bindings, like so:

    $ brew install cairo --without-x


Then:

```bash
    $ npm install
    $ node server.js
```

The web app should now be accessible at [http://localhost:3000](http://localhost:3000)

## API endpoints

### /dtm

Renders a UTM 33 terrain model for a given bound (box).

#### Params
```box``` : A bounding box for the map given in UTM 33 coordinates given as 'NWx,NWy,SEx,SEy'.

```outsize``` : The image dimensions in pixels given as 'X,Y'.


```format``` (optional): Either 'png' or 'bin' (16bit binary in ENVI-format).


#### Example
```
/dtm?box=253723.176600653,6660500.4670516,267723.176600653,6646500.4670516&outsize=1000,1000
```

### /map

Renders a UTM 33 map tile for a given bound (box).

#### Params
```box``` : A bounding box for the map given in UTM 33 coordinates given as 'NWx,NWy,SEx,SEy'.

```outsize``` : The image dimensions in pixels given as 'X,Y'.

#### Example
```
/map?box=253723.176600653,6660500.4670516,267723.176600653,6646500.4670516&outsize=1000,1000
```
