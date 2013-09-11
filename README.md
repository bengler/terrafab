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
* http://144.76.137.99:3000/#61.621410563980746%2C9.815261679895894%2C61.576831123842936%2C9.697756691408525
* http://tyskland:3000/#67.30938258399587%2C14.436416312623109%2C67.25298014547525%2C14.287584224494353
* http://144.76.137.99:3000/#59.99375068297132%2C10.83869180977561%2C59.82838509120348%2C10.464495935363114
* http://144.76.137.99:3000/#59.91365986419438%2C10.768929286124619%2C59.8976440110707%2C10.732627485077783
* http://127.0.0.1:5000/#61.877712019959674%2C9.489692327778107%2C61.82517698002414%2C9.357522670952667


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
