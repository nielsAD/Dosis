/**
 * Author: Niels A.D.
 * Project: DoSiS (https://github.com/nielsAD/Dosis)
 * License: GNU Lesser GPL (http://www.gnu.org/licenses/lgpl.html)
 *
 * Interactive treemap for files and directories
*/
'use strict';

var DEPTH = 2;
var LIMIT = 50;
var FONT_MENU = 12;      //px
var FONT_SCALE = 10;     //scaled by 1/em
var FONT_SCALE_ZOOM = 7; //scaled by 1/em

var EL_MENU    = document.getElementById('menu');
var EL_TOGGLE  = document.getElementById('menu-toggle');
var EL_HEADER  = document.getElementById('header');
var EL_CONTENT = document.getElementById('content');
var EL_SPINNER = document.getElementById('spinner');

var EL_SIZE    = document.getElementById('size');
var EL_PARENT  = document.getElementById('bc-parent');
var EL_NAME    = document.getElementById('bc-current');

if (!Array.prototype.forEach)
{
	Array.prototype.forEach = function(fun /*, thisArg */) {
		if (this === void 0 || this === null)
			throw new TypeError();

		var t = Object(this);
		var len = t.length >>> 0;
		
		if (typeof fun !== "function")
			throw new TypeError();

		var thisArg = arguments.length >= 2 ? arguments[1] : void 0;
		for (var i = 0; i < len; i++) {
			if (i in t)
				fun.call(thisArg, t[i], i, t);
		}
	};
}

if (!window.HTMLElement)
	var HTMLElement = function(){};

var generateColor = function() {

	var rgbToHex = function(i) {
		return (Math.round(i).toString(16) + '00').substr(0, 2);
	};

	var hslToHex = function() {
		// http://stackoverflow.com/questions/2353211/hsl-to-rgb-color-conversion
		var hue2rgb = function(p, q, t){
			if(t < 0) t += 1;
			if(t > 1) t -= 1;
			if(t < 1/6) return p + (q - p) * 6 * t;
			if(t < 1/2) return q;
			if(t < 2/3) return p + (q - p) * (2/3 - t) * 6;
			return p;
		};

		return function(h, s, l) {
			var r, g, b;

			if(s == 0){
				r = g = b = l;
			} else {
				var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
				var p = 2 * l - q;
				r = hue2rgb(p, q, h + 1/3);
				g = hue2rgb(p, q, h);
				b = hue2rgb(p, q, h - 1/3);
			}

			return '#' + rgbToHex(r * 255) + rgbToHex(g * 255) + rgbToHex(b * 255);
		}
	}();

	var step_size = 1.0 - Math.E / Math.PI;
	var h = 0.8 + Math.random() / 5;
	var s = 0.65;
	var l = 0.55;

	var smod = 0.005 * -1;
	var lmod = 0.005;

	var step = 0;
	var steps = 4;
	return function() {
		var inc = 3.0 / steps;

		if (inc < 0.01) {
			step = 1;
			steps = 16;
		}

		if (++step >= steps) {
			s += smod * Math.sqrt(steps);
			l += lmod * Math.sqrt(steps);

			if (s < 0.40) { s = 0.45; smod *= -1 };
			if (s > 0.65) { s = 0.60; smod *= -1 };

			if (l < 0.45) { l = 0.50; lmod *= -1 };
			if (l > 0.75) { l = 0.70; lmod *= -1 };

			step = 1;
			steps *= 2;
			inc /= 2.0;
		} else if (step % 2 === 0) {
			step++;
			inc += 3.0 / steps;
		}

		h += inc;
		while (h >= 1.0) h -= 1.0;

		return hslToHex(h, s, l);
	};
}();

var colorChildren = function(json, color) {
	if (json) {
		color = color || generateColor();
		json.data['$color'] = color;

		json.children = json.children || [];
		json.children.forEach(function(c) { colorChildren(c, color); });
	}
	return json;
};

var generateJSONEntry = function() {
	var counter = 0;
	return function(folderChance, depth, maxChildren) {
		var json = {
			'children': [],
			'data': {
				'$area': Math.round(Math.random()*1024*1024*512)
			},
			'id': 'FileID' + counter,
			'name': 'File' + counter++
		};

		if (Math.random() > folderChance) {
			json.data['$area'] = Math.round(Math.random()*1024*1024*512);
			json.data.isFile = true;
		} else {
			json.id = 'DirectoryID' + (counter - 1);
			json.name = 'Directory' + (counter - 1);

			if (depth !== 0) {
				if (isNaN(maxChildren) || maxChildren <= 0)
					maxChildren = Number.MAX_VALUE;
				for(var i = Math.min(Math.round(Math.random()*50), maxChildren); i > 0; i--) {
					json.children.push(generateJSONEntry(folderChance / 3, depth - 1, maxChildren));
				}
			}
		}

		return json;
	};
}();

var toggleSpinner = function() {
	var timer = null;
	var toggleShow = function() { EL_SPINNER.style.display = 'block'; };
	var toggleHide = function() { EL_SPINNER.style.display = 'none';  };
	
	return function(show) {
		if (timer !== null)
			clearTimeout(timer);
		if (!show)
			toggleHide();
		else
			timer = setTimeout(toggleShow, 500);
	};
}();

var scaleFontSize = function(node, scale) {
	var size = (node.data['$width'] / (scale*node.name.length));
	return (size < 0.6) ? 0 : size;
};

var scaleByteSize = function(bytes) {
	var units = ['B', 'kB','MB','GB','TB','PB'];
	var idx = 0;

	bytes = bytes || 0;
	while(bytes > 1000 && idx < units.length) {
		idx++;
		bytes /= 1000;
	}
	return bytes.toFixed(1) + ' ' + units[idx];
};

var interop = {
	external: (window.external && window.external.DoSiS)
		? window.external
		: {
			DoSiS: false,
			maxChildren: -1,
			log: function(s) {
				console && console.log(s);
			},
			getDirectoryTree: function(id, depth) {
				return generateJSONEntry(1, depth, this.maxChildren);
			}
		},
	
	setMaxChildren: function(maxChildren) {
		this.external.maxChildren = maxChildren || -1;
	},
	
	log: function(s) {
		this.external.log(s);
	},

	getDirectoryTree: function(id, depth) {
		toggleSpinner(true);
		try {
			var res = this.external.getDirectoryTree(id, depth);
			if (typeof res === 'string')
				res = JSON.parse(res);
			return colorChildren(res);
		} finally {
			toggleSpinner(false);
		}
	}
};

interop.setMaxChildren(LIMIT);

var tm = new $jit.TM.Squarified({
	injectInto: EL_CONTENT,
	type: '2D',

	orientation: 'v',
	titleHeight: 1.25,
	offset: 1.5,

	constrained: true,
	levelsToShow: DEPTH,
	labelsToShow: [1, 1],

	animate: true,
	duration: 500,
	fps: 25,
	hideLabels: true,

	Label: {
		type: 'HTML',
		size: 9,
		family: 'Lucida Grande,Verdana'
	},

	Node: {
		overridable: true,
		color: '#113377'
	},

	request: function(nodeId, level, onComplete) {
		if (nodeId[0] !== 'D') {
			onComplete.onComplete(nodeId, {});
		} else
			onComplete.onComplete(nodeId, interop.getDirectoryTree(nodeId, DEPTH - 1));
	},

	onPlaceLabel: function(domElement, node) {
		if (node.data.isFile) {
			$jit.util.addClass(domElement, 'node-static');
		} else {
			var scale = scaleFontSize(node, FONT_SCALE);
			domElement.style.fontSize = scale + 'em';
			domElement.innerHTML = (scale) ? node.name : '';

			$jit.util.removeClass(domElement, 'node-static');
		}
	},

	onCreateLabel: function(domElement, node) {
		if (node._depth === 0)
			tm.breadcrumbs.setRoot(node, domElement);

		domElement.onmousedown = function(event) {
			var right = ((event && event.which) || (window.event && window.event.button)) & 2;
			if (right) {
				tm.breadcrumbs.leaveNode();
			} else {
				var parent = tm.leaf(node) && node.getParents()[0];
				tm.breadcrumbs.enterNode(parent || node);
			}
		};

		domElement.onmouseover = function() {
			var scale = scaleFontSize(node, FONT_SCALE_ZOOM);
			domElement.style.fontSize = scale + 'em';
			domElement.innerHTML = (scale) ? node.name : '';

			tm.breadcrumbs.hoverNode(node);
		};

		domElement.onmouseout = function() {
			domElement.style.fontSize = scaleFontSize(node, FONT_SCALE) + 'em';
			tm.breadcrumbs.hoverNode();
		};
	}
});

tm.breadcrumbs = {
	depth: 0,
	parents: [],

	toggleParent: function() {
		var visible = this.parents.length > 1;
		if (EL_PARENT.parentNode == visible)
			return;

		if (visible) {
			EL_PARENT.title = this.getPath();
			EL_PARENT.onclick = function() {
				tm.breadcrumbs.leaveNode();
			};

			EL_NAME.parentNode.insertBefore(EL_PARENT, EL_NAME);
            this.hoverNode();
		} else {
			EL_PARENT.parentNode.removeChild(EL_PARENT);
		}
	},

	pushParent: function(node) {	
		var res = this.parents.push(node);
		this.toggleParent();
		return res;
	},

	popParent: function() {
		var res = this.parents.pop();
		this.toggleParent();
		return res;
	},

	getParent: function() {
		var len = this.parents.length;
		return (len > 0) ? this.parents[len - 1] : null;
	},
    
	getPath: function() {
		return $jit.util.map(this.parents, function(n, i){ return i && n.name || ""; }).join('/');
	},

	toggleStatic: function(node, enable) {
		var el = (!node || !node.id || node instanceof HTMLElement)
			? node
			: document.getElementById(node.id);

		if (el)
			el.className = (enable) ? 'node-root' : 'node';
	},

	setRoot: function(node, domElement) {
		this.depth = node._depth;
		while (this.parents.length) this.popParent();
		this.pushParent(node);
		this.toggleStatic(domElement || node, true);
		this.hoverNode();
	},
	
	hoverNode: function(node) {
		node = node || (this.parents.length && this.getParent());
		EL_SIZE.innerHTML = scaleByteSize(node && node.data['$area']);
		EL_NAME.innerHTML = node && '<span>&#' + (node.data.isFile ? 128196 : 128193) + ';</span> ' + node.name || '';
		EL_NAME.style.fontSize = Math.max(5, Math.ceil(FONT_MENU - (node && node.name.length / 10 || 0))) + 'px';
    },

	enterNode: function(node, domElement) {
		if (!tm.busy && node && node.id && this.getParent() !== node) {
			this.depth = node._depth;
			this.pushParent(node);
			this.toggleStatic(domElement || node, true);

			tm.enter(node);
		}
	},

	leaveNode: function() {
		if (!tm.busy && this.parents.length > 1) {
			var node = this.popParent();
			this.toggleStatic(node, false);
			
			var old_depth = this.depth;
			var new_depth = this.depth = this.getParent()._depth;

			for (var i = old_depth; node && i > new_depth + 1; i--)
				node = node.getParents()[0];
				
			tm.clickedNode = node;
			tm.out();
		}
	}
};

var resize = function() {
	if (tm.canvas) {
		tm.canvas.resize(EL_CONTENT.offsetWidth, EL_CONTENT.offsetHeight);
	}
};

var toggleMenu = function() {
	var showing = EL_MENU.className === 'menu-open';
	if (showing) {
		EL_HEADER.className = EL_MENU.className = EL_CONTENT.className = '';
		EL_TOGGLE.lastChild.innerHTML = '&#187;'
	} else {
		EL_HEADER.className = EL_MENU.className = EL_CONTENT.className = 'menu-open';
		EL_TOGGLE.lastChild.innerHTML = '&#171;'
	}
	setTimeout(resize, 250);
};

window.onresize = resize;
EL_TOGGLE.onclick = toggleMenu;

setTimeout(function(){
	var json = interop.getDirectoryTree('D', DEPTH);
	json.children.forEach(function(c) {
		if (c.data.isFile)
			return;

		var color = generateColor();
		c.children.forEach(function(e) { colorChildren(e, color); });
	});

	tm.loadJSON(json);
	tm.refresh();
}, 25);
