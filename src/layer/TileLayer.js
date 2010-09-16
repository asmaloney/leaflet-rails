L.TileLayer = L.Class.extend({
	includes: L.Mixin.Events,
	
	options: {
		tileSize: 256,
		minZoom: 0,
		maxZoom: 18,
		subdomains: 'abc',
		copyright: '',
		unloadInvisibleTiles: false || L.Browser.mobileWebkit
	},
	
	initialize: function(url, options) {
		L.Util.extend(this.options, options);
		
		this._url = url;
		
		if (typeof this.options.subdomains == 'string') {
			this.options.subdomains = this.options.subdomains.split('');
		}
	},
	
	onAdd: function(map) {
		this._map = map;
		
		this._container = document.createElement('div');
		this._container.className = 'leaflet-layer';
		this._map.getPanes().tilePane.appendChild(this._container);
		
		this._tileImg = document.createElement('img');
		
		L.Util.extend(this._tileImg, {
			className: 'leaflet-tile',
			galleryimg: 'no'
		});
		
		var tileSize = this.options.tileSize;
		
		L.Util.extend(this._tileImg.style, {
			width: tileSize + 'px',
			height: tileSize + 'px',
			visibility: 'hidden'
		});
	},
	
	draw: function() {
		this._tiles = {};
		this._container.innerHTML = '';
	},
	
	load: function() {
		var bounds = this._map.getPixelBounds(),
			tileSize = this.options.tileSize;
		
		var nwTilePoint = new L.Point(
				Math.floor(bounds.min.x / tileSize),
				Math.floor(bounds.min.y / tileSize)),
			seTilePoint = new L.Point(
				Math.floor(bounds.max.x / tileSize),
				Math.floor(bounds.max.y / tileSize));
		
		this._loadTiles(nwTilePoint, seTilePoint);
		
		if (this.options.unloadInvisibleTiles) {
			this._unloadOtherTiles(nwTilePoint, seTilePoint);
		}
		//TODO fire layerload?
	},
	
	getTileUrl: function(tilePoint, zoom) {
		var url = this._url;
		
		var subdomains = this.options.subdomains,
			s = this.options.subdomains[(tilePoint.x + tilePoint.y) % subdomains.length];

		return this._url
				.replace('{s}', s)
				.replace('{z}', zoom)
				.replace('{x}', tilePoint.x)
				.replace('{y}', tilePoint.y);
	},
	
	_loadTiles: function(nwTilePoint, seTilePoint) {
		//TODO load from center
		for (var j = nwTilePoint.y; j <= seTilePoint.y; j++) {
			for (var i = nwTilePoint.x; i <= seTilePoint.x; i++) {				
				this._loadTile(new L.Point(i, j));
			}
		}
	},
	
	_unloadOtherTiles: function(nwTilePoint, seTilePoint) {
		var k, x, y, key;
		for (key in this._tiles) {
			kArr = key.split(':'),
			x = parseInt(kArr[0]),
			y = parseInt(kArr[1]);
			
			if (x < nwTilePoint.x || x > seTilePoint.x || y < nwTilePoint.y || y > seTilePoint.y) {
				this._container.removeChild(this._tiles[key]);
				delete this._tiles[key];
			}
		}		
	},
	
	_loadTile: function(tilePoint) {
		var origin = this._map.getPixelOrigin(),
			tileSize = this.options.tileSize,
			tilePos = tilePoint.multiplyBy(tileSize).subtract(origin),
			zoom = this._map.getZoom();
			
		var key = tilePoint.x + ':' + tilePoint.y;
		if (key in this._tiles) { return; }

		var tileLimit = (1 << zoom);
		tilePoint.x = ((tilePoint.x % tileLimit) + tileLimit) % tileLimit;
		if (tilePoint.y < 0 || tilePoint.y >= tileLimit) { return; }
		
		
		var tile = this._tileImg.cloneNode(false);
		this._tiles[key] = tile;
		
		L.DomUtil.setPosition(tile, tilePos);
		
		tile.onload = this._tileOnLoad;
		tile.onselectstart = tile.onmousemove = L.Util.falseFn;
		tile._leaflet_layer = this;
		
		tile.src = this.getTileUrl(tilePoint, zoom);
		
		this._container.appendChild(tile);
		//TODO tile queue
	},
	
	_tileOnLoad: function() {
		this.style.visibility = 'visible';
		this._leaflet_layer.fire('tileload', {tile: this});
	}
});