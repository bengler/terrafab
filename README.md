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

## Configuration

All configuration can be done under ``./config/app.json``. Have a look at the ``./config/app.example.json``.

In order to configure the accessToken and accessTokenSecret for Shapeways, you may obtain them by
calling the route ``/accesstoken`` in the app after you have configrued the consumerKey and
consumerKeySecret for your Shapeways application.

## Model endpoints

### /preview

### /download


## API endpoints

### /dtm (GET)

Renders a UTM 33 terrain model for a given bound (box).

#### Params
```box``` : A bounding box for the map given in UTM 33 coordinates given as 'NWx,NWy,SEx,SEy'.

```outsize``` : The image dimensions in pixels given as 'X,Y'.


```format``` (optional): Either 'png' or 'bin' (16bit binary in ENVI-format).


#### Example
```
/dtm?box=253723.176600653,6660500.4670516,267723.176600653,6646500.4670516&outsize=1000,1000
```

### /map (GET)

Renders a UTM 33 map tile for a given bound (box).

#### Params
```box``` : A bounding box for the map given in UTM 33 coordinates given as 'NWx,NWy,SEx,SEy'.

```outsize``` : The image dimensions in pixels given as 'X,Y'.

#### Example
```
/map?box=253723.176600653,6660500.4670516,267723.176600653,6646500.4670516&outsize=1000,1000
```

## Shapeways endpoints

### /accesstoken (GET)

Let you login to Shapeways to get an access token for the your Shapeways application.
Note: the end user will not be logging into this. It's a tool for obtaining an access token
for the application (in order to post models to the Shapeways API).

There is also: ``/login`` and  ``/callback`` which is taken care of by the oAuth bonanza.

#### Params
None

#### Example
```
/accesstoken
