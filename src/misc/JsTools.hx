package misc;

class JsTools {
	public static function init() {
	}

	public static function makeSortable(selector:String, onSort:(from:Int, to:Int)->Void) {
		js.Lib.eval('sortable("$selector", { items:":not(.fixed)" })');
		new J(selector)
			.off("sortupdate")
			.on("sortupdate", function(ev) {
				var from : Int = ev.detail.origin.index;
				var to : Int = ev.detail.destination.index;
				onSort(from,to);
			}
		);
	}

	public static function prepareProjectFile(p:led.Project) : { bytes:haxe.io.Bytes, json:Dynamic } {
		var json = p.toJson();
		var jsonStr = dn.JsonPretty.stringify(json);

		return {
			bytes: haxe.io.Bytes.ofString( jsonStr ),
			json: json,
		}
	}

	public static function createLayerTypeIcon(type:led.LedTypes.LayerType, withName=true, ?ctx:js.jquery.JQuery) : js.jquery.JQuery {
		var wrapper = new J('<span class="layerType"/>');

		var icon = new J('<span class="icon"/>');
		icon.appendTo(wrapper);
		icon.addClass( switch type {
			case IntGrid: "intGrid";
			case Entities: "entity";
			case Tiles: "tile";
		});

		if( withName ) {
			var name = new J('<span class="name"/>');
			name.text( L.getLayerType(type) );
			name.appendTo(wrapper);
		}

		if( ctx!=null )
			wrapper.appendTo(ctx);
		return wrapper;
	}

	public static function createFieldTypeIcon(type:led.LedTypes.FieldType, withName=true, ?ctx:js.jquery.JQuery) : js.jquery.JQuery {
		var icon = new J("<span/>");
		icon.addClass("icon fieldType");
		icon.addClass(type.getName());
		if( withName )
			icon.append('<span class="typeName">'+L.getFieldType(type)+'</span>');
		icon.append('<span class="typeIcon">'+L.getFieldTypeShortName(type)+'</span>');

		if( ctx!=null )
			icon.appendTo(ctx);

		return icon;
	}


	public static function createEntityPreview(project:led.Project, ed:led.def.EntityDef, sizePx=24) {
		var jWrapper = new J('<div class="entityPreview icon"></div>');
		jWrapper.css("width", sizePx+"px");
		jWrapper.css("height", sizePx+"px");

		var scale = sizePx / M.fmax(ed.width, ed.height);
		var jEnt = new J('<div class="entity"/>');
		jEnt.appendTo(jWrapper);

		switch ed.renderMode {
			case Rectangle:
				jEnt.css("background-color", C.intToHex(ed.color));
				jEnt.css("width", ed.width*scale);
				jEnt.css("height", ed.height*scale);

			case Ellipse:

			case Tile:
				var jCanvas = new J('<canvas></canvas>');
				jCanvas.appendTo(jEnt);
				if( ed.isTileValid() ) {
					var td = project.defs.getTilesetDef(ed.tilesetId);
					td.drawTileToCanvas(jCanvas, ed.tileId);
					jCanvas.attr("width", td.tileGridSize);
					jCanvas.attr("height", td.tileGridSize);
					jCanvas.css("width",sizePx+"px");
					jCanvas.css("height",sizePx+"px");
				}
		}

		// var scale = sizePx/40;
		// var ent = new J('<div/>');
		// ent.addClass("entity");
		// ent.css("width", ed.width*scale);
		// ent.css("height", ed.height*scale);
		// ent.css("background-color", C.intToHex(ed.color));

		// var wrapper = ent.wrap("<div/>").parent();
		// wrapper.addClass("icon entityPreview");
		// wrapper.width(sizePx);
		// wrapper.height(sizePx);

		return jWrapper;
	}


	public static function createPivotEditor( curPivotX:Float, curPivotY:Float, ?inputName:String, ?bgColor:UInt, onPivotChange:(pivotX:Float, pivotY:Float)->Void ) {
		var pivots = new J("xml#pivotEditor").children().first().clone();

		pivots.find("input[type=radio]").attr("name", inputName==null ? "pivot" : inputName);

		if( bgColor!=null )
			pivots.find(".bg").css( "background-color", C.intToHex(bgColor) );
		else
			pivots.find(".bg").hide();

		pivots.find("input[type=radio][value='"+curPivotX+" "+curPivotY+"']").prop("checked",true);

		pivots.find("input[type=radio]").each( function(idx:Int, elem) {
			var r = new J(elem);
			r.change( function(ev) {
				var rawPivots = r.val().split(" ");
				onPivotChange( Std.parseFloat( rawPivots[0] ), Std.parseFloat( rawPivots[1] ) );
			});
		});

		return pivots;
	}

	public static function createIcon(id:String) {
		var jIcon = new J('<span class="icon"/>');
		jIcon.addClass(id);
		return jIcon;
	}




	static var _fileCache : Map<String,String> = new Map();
	public static function clearFileCache() {
		_fileCache = new Map();
	}

	public static function getHtmlTemplate(name:String) : Null<String> {
		if( !_fileCache.exists(name) ) {
			var path = dn.FilePath.fromFile(App.APP_DIR + "tpl/" + name);
			path.extension = "html";

			if( !fileExists(path.full) )
				throw "File not found "+path.full;

			_fileCache.set( name, readFileString(path.full) );
		}

		return _fileCache.get(name);
	}


	static function getTmpFileInput() {
		var input = new J("input#tmpFileInput");
		if( input.length==0 ) {
			input = new J("<input/>");
			input.attr("type","file");
			input.attr("id","tmpFileInput");
			input.appendTo( new J("body") );
			input.hide();
		}
		input.off();
		input.removeAttr("accept");
		input.removeAttr("nwsaveas");

		input.click( function(ev) {
			input.val("");
		});

		return input;
	}

	public static function loadDialog(?fileTypes:Array<String>, rootDir:String, onLoad:(filePath:String)->Void) {
		var input = getTmpFileInput();

		if( fileTypes==null || fileTypes.length==0 )
			fileTypes = [".*"];
		input.attr("accept", fileTypes.join(","));
		input.attr("nwWorkingDir",rootDir);

		input.change( function(ev) {
			var path : String = input.val();
			if( path==null || path.length==0 )
				return;

			input.remove();
			onLoad(path);
		});
		input.click();
	}

	public static function saveAsDialog(?fileTypes:Array<String>, rootDir:String, onFileSelect:(filePath:String)->Void) {
		var input = getTmpFileInput();

		if( fileTypes==null || fileTypes.length==0 )
			fileTypes = [".*"];
		input.attr("accept", fileTypes.join(","));
		input.attr("nwsaveas","nwsaveas");
		input.attr("nwWorkingDir",rootDir);

		input.change( function(ev) {
			var path = input.val();
			input.remove();
			onFileSelect(path);
		});
		input.click();
	}


	public static inline function createKeyInLabel(label:String) {
		var r = ~/(.*)\[(.*)\](.*)/gi;
		if( !r.match(label) )
			return new J('<span>$label</span>');
		else {
			var j = new J("<span/>");
			j.append(r.matched(1));
			j.append( new J('<span class="key">'+r.matched(2)+'</span>') );
			j.append(r.matched(3));
			return j;
		}
	}

	public static inline function createKey(?kid:Int, ?keyLabel:String) {
		if( kid!=null )
			keyLabel = K.getKeyName(kid);

		if( keyLabel.toLowerCase()=="shift" )
			keyLabel = "⇧";

		return new J('<span class="key">$keyLabel</span>');
	}


	public static function parseComponents(jCtx:js.jquery.JQuery) {
		// (i) Info bubbles
		jCtx.find(".info").each( function(idx, e) {
			var jThis = new J(e);

			if( jThis.data("str")==null ) {
				if( jThis.hasClass("identifier") )
					jThis.data( "str", L.t._("An identifier should be UNIQUE and only contain LETTERS, NUMBERS or UNDERSCORES (ie. \"_\").") );
				else
					jThis.data("str", jThis.text());
				jThis.empty();
			}
			ui.Tip.attach(jThis, jThis.data("str"), "infoTip");
		});

		// Auto tool-tips
		jCtx.find("[title]").each( function(idx,e) {
			var jThis = new J(e);
			var tip = jThis.attr("title");
			jThis.removeAttr("title");

			// Parse key shortcut
			var keys = [];
			if( jThis.attr("keys")!=null ) {
				var rawKeys = jThis.attr("keys").split("+").map( function(k) return StringTools.trim(k).toLowerCase() );
				jThis.removeAttr("keys");
				for(k in rawKeys) {
					switch k {
						case "ctrl" : keys.push(K.CTRL);
						case "shift" : keys.push(K.SHIFT);
						case "alt" : keys.push(K.ALT);
						case _ :
							if( k.length==1 ) {
								var cid = k.charCodeAt(0);
								if( cid>="a".code && cid<="z".code )
									keys.push( cid - "a".code + K.A );
							}
					}
				}
			}

			ui.Tip.attach( jThis, tip, keys );
		});
	}


	public static function makePath(path:String) {
		path = StringTools.replace(path,"\\","/");
		var parts = path.split("/").map( function(p) return '<span>$p</span>' );
		var e = new J( parts.join('<span class="slash">/</span>') );
		return e.wrapAll('<div class="path"/>').parent();
	}

	// *** File API (NWJS) **************************************

	#if hxnodejs

	public static function fileExists(path:String) {
		if( path==null )
			return false;
		else {
			js.node.Require.require("fs");
			return js.node.Fs.existsSync(path);
		}
	}

	public static function readFileString(path:String) : Null<String> {
		if( !fileExists(path) )
			return null;
		else
			return js.node.Fs.readFileSync(path).toString();
	}

	public static function readFileBytes(path:String) : Null<haxe.io.Bytes> {
		if( !fileExists(path) )
			return null;
		else
			return js.node.Fs.readFileSync(path).hxToBytes();
	}

	public static function writeFileBytes(path:String, bytes:haxe.io.Bytes) {
		js.node.Require.require("fs");
		js.node.Fs.writeFileSync( path, js.node.Buffer.hxFromBytes(bytes) );
	}

	public static function getCwd() {
		return js.Node.process.cwd();
	}

	public static function exploreToFile(filePath:String) {
		var fp = dn.FilePath.fromFile(filePath);
		if( isWindows() )
			fp.useBackslashes();
		nw.Shell.showItemInFolder(fp.full);
	}

	public static function isWindows() {
		return js.Node.process.platform.toLowerCase().indexOf("win")==0;
	}

	public static function removeClassReg(jElem:js.jquery.JQuery, reg:EReg) {
		jElem.removeClass( function(idx, classes) {
			var all = [];
			while( reg.match(classes) ) {
				all.push( reg.matched(0) );
				classes = reg.matchedRight();
			}
			return all.join(" ");
		});
	}

	public static function clearCanvas(jCanvas:js.jquery.JQuery) {
		if( !jCanvas.is("canvas") )
			throw "Not a canvas";

		var cnv = Std.downcast( jCanvas.get(0), js.html.CanvasElement );
		cnv.getContext2d().clearRect(0,0, cnv.width, cnv.height);
	}


	public static function createSingleTilePicker(tilesetId:Null<Int>, tileId:Null<Int>, onPick:(tileId:Int)->Void) {
		var jTile = new J('<canvas class="tile"></canvas>');

		if( tilesetId!=null ) {
			jTile.addClass("active");
			var td = Editor.ME.project.defs.getTilesetDef(tilesetId);

			// Render tile
			if( tileId!=null ) {
				jTile.removeClass("empty");
				jTile.attr("width", td.tileGridSize);
				jTile.attr("height", td.tileGridSize);
				td.drawTileToCanvas(jTile, tileId);
			}
			else
				jTile.addClass("empty");

			// Open picker
			jTile.click( function(ev) {
				var m = new ui.Modal();
				m.addClass("singleTilePicker");

				var tp = new ui.TilesetPicker(m.jContent, td);
				tp.singleSelectedTileId = tileId;
				tp.onSingleTileSelect = function(tileId) {
					m.close();
					onPick(tileId);
				}
			});
		}
		else
			jTile.addClass("empty");

		return jTile;
	}

	#end

}
