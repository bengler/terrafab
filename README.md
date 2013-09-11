TerraFab
========

## Prerequisites

- Node.js 0.10.x or newer

## Getting up and running

```bash
    $ npm install
    $ node server.js
```

The web app should now be accessible at [http://localhost:3000](http://localhost:3000)


## Places to go:

* http://144.76.137.99:3000/#61.50934147309199%2C7.660449715288643%2C61.464762032954184%2C7.542944726801276
* http://144.76.137.99:3000/#61.61053056809217%2C9.844268291114034%2C61.565951127954364%2C9.726763302626665



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
