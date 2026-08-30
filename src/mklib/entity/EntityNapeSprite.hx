package mklib.entity;

import nape.callbacks.CbType;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import mklib.tools.Tags;
import mklib.state.State;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSprite;
import flixel.addons.nape.FlxNapeSpace;
import mklib.animation.AnimationManager;
import mklib.save.SaveManager;

/**
 * Erweiterte Entity-Klasse mit integriertem Nape-Physikkörper (`FlxNapeSprite`).
 *
 * Ermöglicht das automatische Auslesen von Tags/Kollisionstypen (`CbType`) direkt aus den
 * LDtk-Feldern (`Tag` oder `Tags`), den Zugriff auf den Grafikpfad (`graphicPath`),
 * das automatische Zuschneiden von Tile-Ausschnitten (`TileRect`) mit festem Nape-Körper (`BodyType.STATIC`)
 * sowie die exakte Zentrierung von Nape-Shapes auf Basis der Entity- bzw. Sprite-Maße.
 */
class EntityNapeSprite extends FlxNapeSprite {
	/**
	 * Die zugrundeliegende LDtk-Entity-Instanz mit Rohdaten und Feldern.
	 */
	public var _entity:ldtk.Entity;

	/**
	 * Die weltweit eindeutige Instanz-ID (IID) der Entity aus LDtk.
	 */
	public var iid:String;

	/**
	 * Referenz auf den aktuellen `mklib.state.State`, sofern aktiv.
	 */
	public var state:State;

	/**
	 * Der relative Pfad zur Grafikdatei (relativ zur LDtk-Projektdatei),
	 * falls der Entity in LDtk ein Tile zugewiesen ist, andernfalls `null`.
	 */
	public var graphicPath:Null<String>;

	/**
	 * Gibt an, ob die Entity über eine zugewiesene Grafikdatei in LDtk verfügt.
	 */
	public var hasGraphic:Bool = false;

	/**
	 * Erstellt eine neue Instanz von `EntityNapeSprite` anhand einer LDtk-Entity.
	 *
	 * Wenn in LDtk ein Single Value Tile mit dem Namen "TileRect" definiert und nicht `null` ist,
	 * wird der entsprechende Ausschnitt aus dem Tileset geladen, die Sprite-Größe angepasst,
	 * ein neuer statischer Nape-Körper (`BodyType.STATIC`) erzeugt und optional als Sensor konfiguriert.
	 *
	 * @param entity Die aus dem LDtk-Level geladene Entity-Definition.
	 */
	public function new(entity:ldtk.Entity) {
		iid = entity.iid;
		_entity = entity;
		super(entity.pixelX, entity.pixelY, null, false, false);

		if (FlxG.state != null && Std.isOfType(FlxG.state, State)) {
			state = cast FlxG.state;
		}

		var tileRectField:Dynamic = getField("TileRect");
		if (tileRectField == null) {
			tileRectField = getField("tileRect");
		}

		if (tileRectField != null) {
			var tilesetUid:Int = Reflect.hasField(tileRectField, "tilesetUid") ? Reflect.field(tileRectField, "tilesetUid") : 0;
			var tileX:Int = Reflect.hasField(tileRectField, "x") ? Reflect.field(tileRectField, "x") : 0;
			var tileY:Int = Reflect.hasField(tileRectField, "y") ? Reflect.field(tileRectField, "y") : 0;
			var tileW:Int = Reflect.hasField(tileRectField,
				"w") ? Reflect.field(tileRectField,
					"w") : (Reflect.hasField(tileRectField, "width") ? Reflect.field(tileRectField, "width") : Std.int(entity.width));
			var tileH:Int = Reflect.hasField(tileRectField,
				"h") ? Reflect.field(tileRectField,
					"h") : (Reflect.hasField(tileRectField, "height") ? Reflect.field(tileRectField, "height") : Std.int(entity.height));

			var resolvedPath:Null<String> = resolveTilesetPath(tilesetUid);
			if (resolvedPath != null) {
				graphicPath = resolvedPath;
				hasGraphic = true;
				loadTileRectGraphic(resolvedPath, tileX, tileY, tileW, tileH);
			} else {
				width = tileW;
				height = tileH;
			}

			createRectangularBody(tileW, tileH, BodyType.STATIC);
		} else {
			createRectangularBody(entity.width, entity.height, BodyType.DYNAMIC);

			graphicPath = getGraphicPath();

			if (hasGraphic && _entity.tileInfos != null) {
				loadGraphic(graphicPath, true, _entity.tileInfos.w, _entity.tileInfos.h);
			}
		}

		if (hasField("Animations")) {
			initAnimation(getField("Animations"));
		}

		if (hasField("sensor")) {
			sensorEnabled(getField("sensor"));
		} else if (hasField("sensorEnabled")) {
			sensorEnabled(getField("sensorEnabled"));
		}

		if (hasField("visible")) {
			visible = getField("visible");
		}

		if (hasField("alpha")) {
			alpha = getField("alpha");
		}

		if (hasField("Tag")) {
			addCbType(getField("Tag"));
		} else if (hasField("Tags")) {
			addCbType();
		}

		if (hasField("allowMovement") && body != null) {
			body.allowMovement = getField("allowMovement");
		}

		updateShapePosition();

		setUserData();
	}

	public function setUserData():Void {
		if (body != null) {
			body.userData.obj = this;
			body.userData.instance = this;
			if (body.shapes != null) {
				for (shape in body.shapes) {
					shape.userData.obj = this;
					shape.userData.instance = this;
				}
			}
		}
	}

	/**
	 * Erzeugt vollautomatisch Nape-Polygon-Shapes aus der sichtbaren Pixelgrafik dieses Sprites
	 * und weist sie dem Nape-Körper zu.
	 *
	 * @param alphaThreshold Schwellenwert für die Sichtbarkeit (0-255). Standard: 128.
	 * @param simplify Grad der Glättung/Vereinfachung in Pixeln. Standard: 1.0.
	 * @param sensor Sollen die Shapes als Sensoren deklariert werden? Standard: false.
	 * @param cbType Optionaler CbType für die erzeugten Shapes.
	 * @param clearExisting Vorhandene Shapes vorher löschen? Standard: true.
	 * @param cellSizeVal Zellengröße für MarchingSquares in Pixeln. Standard: 1.0 (exakte Pixelauflösung).
	 * @return Array der erzeugten `Polygon`-Shapes.
	 */
	public function createShapesFromGraphic(alphaThreshold:Int = 128, simplify:Float = 1.0, sensor:Bool = false, ?cbType:CbType,
			clearExisting:Bool = true, cellSizeVal:Float = 1.0):Array<Polygon> {
		if (body == null) {
			return [];
		}

		var wasSpace = body.space;
		if (wasSpace != null) {
			body.space = null;
		}

		if (clearExisting) {
			body.shapes.clear();
		}

		var shapes = mklib.physic.ShapeBuilder.createShapesFromSprite(this, body, alphaThreshold, simplify, sensor, cbType, cellSizeVal);

		// Fallback: Falls keine Shapes aus Pixeln erzeugt werden konnten (z. B. 0 sichtbare Pixel oder extrem dünn),
		// erzeuge eine rechteckige Bounding-Box, damit das Objekt nicht kollisionslos wird.
		if (body.shapes.length == 0 && width > 0 && height > 0) {
			var fallbackShape = new Polygon(Polygon.box(width, height), new nape.phys.Material(0, 0, 0, 1, 0));
			fallbackShape.sensorEnabled = sensor;
			if (cbType != null) {
				fallbackShape.cbTypes.add(cbType);
			}
			fallbackShape.body = body;
			shapes.push(fallbackShape);
		}

		setUserData();

		if (wasSpace != null) {
			body.space = wasSpace;
		}

		return shapes;
	}

	/**
	 * Ermittelt die `EntityNapeSprite`-Instanz aus einem Nape-`Interactor` (Shape oder Body).
	 *
	 * @param interactor Der Nape-Interactor (z. B. `cb.int1` oder `cb.int2` aus einem `InteractionCallback`).
	 * @return Die zugehörige `EntityNapeSprite`-Instanz oder `null`.
	 */
	public static function getFromInteractor(interactor:nape.phys.Interactor):Null<EntityNapeSprite> {
		if (interactor == null) {
			return null;
		}
		if (interactor.userData != null && interactor.userData.obj != null) {
			return interactor.userData.obj;
		}
		if (interactor.userData != null && interactor.userData.instance != null) {
			return interactor.userData.instance;
		}
		if (interactor.isShape() && interactor.castShape.body != null && interactor.castShape.body.userData != null) {
			if (interactor.castShape.body.userData.obj != null) {
				return interactor.castShape.body.userData.obj;
			}
			return interactor.castShape.body.userData.instance;
		}
		if (interactor.isBody() && interactor.castBody.userData != null) {
			if (interactor.castBody.userData.obj != null) {
				return interactor.castBody.userData.obj;
			}
			return interactor.castBody.userData.instance;
		}
		return null;
	}

	/**
	 * Die Nape-Körperposition zu Beginn des aktuellen Frames (vor dem Physik-Schritt).
	 */
	public var prevBodyX:Float = 0;

	public var prevBodyY:Float = 0;

	/**
	 * Zuletzt berührtes Hindernis für vorausschauende, jitterfreie Kollisionsprüfung.
	 */
	public var lastCollidedObstacle:Null<flixel.FlxSprite> = null;

	/**
	 * Aktualisiert das Sprite und speichert die Vorher-Position des Nape-Körpers
	 * für präzise und jitterfreie Kollisionsauflösung.
	 */
	override public function update(elapsed:Float):Void {
		if (body != null) {
			prevBodyX = body.position.x;
			prevBodyY = body.position.y;
		}
		super.update(elapsed);
	}

	/**
	 * Wird aufgerufen, wenn die Position des Sprites (z. B. durch `resolvePixelCollision`)
	 * manuell korrigiert wurde. Kann in Unterklassen (wie `Hero`) überschrieben werden.
	 */
	public function onPositionCorrected():Void {}

	/**
	 * Prüft vorausschauend, ob eine Bewegung in die angegebene Richtung (`dirX`, `dirY`)
	 * zu einer Pixel-Überlappung mit dem Hindernis führen würde.
	 *
	 * @param dirX Horizontale Bewegungsrichtung (-1, 0, 1 oder Geschwindigkeit).
	 * @param dirY Vertikale Bewegungsrichtung (-1, 0, 1 oder Geschwindigkeit).
	 * @return `true`, falls die Richtung durch Pixel-Grafik blockiert ist, sonst `false`.
	 */
	public function isPixelBlocked(dirX:Float, dirY:Float):Bool {
		if (lastCollidedObstacle == null || body == null) {
			return false;
		}

		var stepX:Float = (dirX > 0) ? 1.0 : ((dirX < 0) ? -1.0 : 0.0);
		var stepY:Float = (dirY > 0) ? 1.0 : ((dirY < 0) ? -1.0 : 0.0);

		if (stepX == 0 && stepY == 0) {
			return false;
		}

		var origX:Float = body.position.x;
		var origY:Float = body.position.y;

		body.position.setxy(origX + stepX, origY + stepY);
		x = body.position.x - origin.x;
		y = body.position.y - origin.y;

		var blocked:Bool = FlxG.pixelPerfectOverlap(this, lastCollidedObstacle);

		body.position.setxy(origX, origY);
		x = body.position.x - origin.x;
		y = body.position.y - origin.y;

		return blocked;
	}

	/**
	 * Löst eine pixelgenaue Überlappung (`FlxG.pixelPerfectOverlap`) mit einem anderen Sprite
	 * verzögerungsfrei, präzise und mit flüssigem Wall-Sliding auf.
	 *
	 * @param obstacle Das kollidierende Hindernis oder Ziel-Sprite.
	 * @return `true`, wenn eine Pixel-Kollision vorlag und aufgelöst wurde, sonst `false`.
	 */
	public function resolvePixelCollision(obstacle:flixel.FlxSprite):Bool {
		if (obstacle == null || body == null) {
			return false;
		}

		lastCollidedObstacle = obstacle;

		if (!FlxG.pixelPerfectOverlap(this, obstacle)) {
			return false;
		}

		var targetX:Float = body.position.x;
		var targetY:Float = body.position.y;
		var startX:Float = (prevBodyX != 0) ? prevBodyX : targetX;
		var startY:Float = (prevBodyY != 0) ? prevBodyY : targetY;

		// 1. Versuche Y-Bewegung beizubehalten (Sliding entlang X-Wand):
		// Schiebe X von startX so nah wie möglich an targetX heran (ohne Lücke)
		body.position.setxy(startX, targetY);
		x = body.position.x - origin.x;
		y = body.position.y - origin.y;

		if (!FlxG.pixelPerfectOverlap(this, obstacle)) {
			var stepX:Float = (targetX >= startX) ? 1.0 : -1.0;
			var curX:Float = startX;
			while ((stepX > 0 ? curX + stepX <= targetX : curX + stepX >= targetX)) {
				body.position.setxy(curX + stepX, targetY);
				x = body.position.x - origin.x;
				y = body.position.y - origin.y;
				if (FlxG.pixelPerfectOverlap(this, obstacle)) {
					break;
				}
				curX += stepX;
			}
			body.position.setxy(curX, targetY);
			x = body.position.x - origin.x;
			y = body.position.y - origin.y;
			body.velocity.x = 0;
			onPositionCorrected();
			return true;
		}

		// 2. Versuche X-Bewegung beizubehalten (Sliding entlang Y-Wand):
		// Schiebe Y von startY so nah wie möglich an targetY heran (ohne Lücke)
		body.position.setxy(targetX, startY);
		x = body.position.x - origin.x;
		y = body.position.y - origin.y;

		if (!FlxG.pixelPerfectOverlap(this, obstacle)) {
			var stepY:Float = (targetY >= startY) ? 1.0 : -1.0;
			var curY:Float = startY;
			while ((stepY > 0 ? curY + stepY <= targetY : curY + stepY >= targetY)) {
				body.position.setxy(targetX, curY + stepY);
				x = body.position.x - origin.x;
				y = body.position.y - origin.y;
				if (FlxG.pixelPerfectOverlap(this, obstacle)) {
					break;
				}
				curY += stepY;
			}
			body.position.setxy(targetX, curY);
			x = body.position.x - origin.x;
			y = body.position.y - origin.y;
			body.velocity.y = 0;
			onPositionCorrected();
			return true;
		}

		// 3. Wenn beides kollidiert (Ecke): Bis zum Kontakt heranrücken
		body.position.setxy(startX, startY);
		x = body.position.x - origin.x;
		y = body.position.y - origin.y;

		if (!FlxG.pixelPerfectOverlap(this, obstacle)) {
			var stepX:Float = (targetX >= startX) ? 1.0 : -1.0;
			var stepY:Float = (targetY >= startY) ? 1.0 : -1.0;
			var curX:Float = startX;
			var curY:Float = startY;

			while ((stepX > 0 ? curX + stepX <= targetX : curX + stepX >= targetX)) {
				body.position.setxy(curX + stepX, curY);
				x = body.position.x - origin.x;
				y = body.position.y - origin.y;
				if (FlxG.pixelPerfectOverlap(this, obstacle))
					break;
				curX += stepX;
			}
			while ((stepY > 0 ? curY + stepY <= targetY : curY + stepY >= targetY)) {
				body.position.setxy(curX, curY + stepY);
				x = body.position.x - origin.x;
				y = body.position.y - origin.y;
				if (FlxG.pixelPerfectOverlap(this, obstacle))
					break;
				curY += stepY;
			}

			body.position.setxy(curX, curY);
			x = body.position.x - origin.x;
			y = body.position.y - origin.y;
			body.velocity.setxy(0, 0);
			onPositionCorrected();
			return true;
		}

		// 4. Fallback: Bei verbleibender Überlappung minimal herausdrücken
		body.velocity.setxy(0, 0);
		var diffX:Float = (x + width * 0.5) - (obstacle.x + obstacle.width * 0.5);
		var diffY:Float = (y + height * 0.5) - (obstacle.y + obstacle.height * 0.5);
		var pushX:Float = (diffX >= 0) ? 1.0 : -1.0;
		var pushY:Float = (diffY >= 0) ? 1.0 : -1.0;

		var iterations:Int = 0;
		while (iterations < 16 && FlxG.pixelPerfectOverlap(this, obstacle)) {
			body.position.x += pushX;
			body.position.y += pushY;
			x = body.position.x - origin.x;
			y = body.position.y - origin.y;
			iterations++;
		}

		onPositionCorrected();
		return true;
	}

	/**
	 * Erstellt einen rechteckigen Nape-Physikkörper für dieses Sprite.
	 * Fügt die Shapes vor der Registrierung im Physikraum hinzu, um Broadphase-Fehler (z. B. bei STATIC Bodies) zu verhindern.
	 *
	 * @param Width Breite des Körpers (Standard: Sprite-Breite).
	 * @param Height Höhe des Körpers (Standard: Sprite-Höhe).
	 * @param _Type Nape-Körpertyp (Standard: DYNAMIC).
	 */
	override public function createRectangularBody(Width:Float = 0, Height:Float = 0, ?_Type:BodyType):Void {
		if (body != null) {
			destroyPhysObjects();
		}

		if (Width <= 0) {
			Width = (width > 0) ? width : frameWidth;
		}
		if (Height <= 0) {
			Height = (height > 0) ? height : frameHeight;
		}

		centerOffsets(false);
		var targetType:BodyType = (_Type != null) ? _Type : BodyType.DYNAMIC;
		var initialX:Float = (_entity != null) ? _entity.pixelX + (Width / 2) : x + (Width / 2);
		var initialY:Float = (_entity != null) ? _entity.pixelY + (Height / 2) : y + (Height / 2);

		var newBody = new Body(targetType, Vec2.weak(initialX, initialY));
		newBody.shapes.add(new Polygon(Polygon.box(Width, Height)));
		newBody.allowRotation = false;
		newBody.userData.instance = this;

		this.body = newBody;
		this.physicsEnabled = true;
		if (FlxNapeSpace.space != null) {
			this.body.space = FlxNapeSpace.space;
		}
		setBodyMaterial();
	}

	/**
	 * Liest den Wert eines benutzerdefinierten LDtk-Feldes (`fieldInstances`) aus.
	 *
	 * @param identifier Der Bezeichner des Feldes in LDtk (z. B. "sensorEnabled", "TileRect" oder "image").
	 * @return Der Wert des Feldes oder `null`, falls nicht vorhanden.
	 */
	public function getField(identifier:String):Dynamic {
		if (_entity != null && _entity.json != null && _entity.json.fieldInstances != null) {
			for (inst in _entity.json.fieldInstances) {
				if (inst.__identifier == identifier) {
					return inst.__value;
				}
			}
		}
		return null;
	}

	/**
	 * Prüft, ob ein benutzerdefiniertes LDtk-Feld für diese Entity existiert.
	 *
	 * @param identifier Der Bezeichner des Feldes in LDtk.
	 * @return `true`, wenn das Feld vorhanden ist, andernfalls `false`.
	 */
	public function hasField(identifier:String):Bool {
		if (_entity != null && _entity.json != null && _entity.json.fieldInstances != null) {
			for (inst in _entity.json.fieldInstances) {
				if (inst.__identifier == identifier) {
					return true;
				}
			}
		}
		return false;
	}

	/**
	 * Aktiviert oder deaktiviert die Sensor-Eigenschaft für alle Shapes des Körpers.
	 * Wird kein Parameter übergeben (`null`), wird das LDtk-Feld `"sensor"` oder `"sensorEnabled"` ausgelesen.
	 * 
	 * @param enable Optional: `true`, um alle Shapes als Sensoren zu markieren, `false` andernfalls.
	 */
	public function sensorEnabled(?enable:Null<Bool>):Void {
		if (enable == null) {
			var fieldVal = getField("sensor");
			if (fieldVal == null) {
				fieldVal = getField("sensorEnabled");
			}
			enable = (fieldVal == true);
		}

		if (body != null && body.shapes != null) {
			body.shapes.foreach(function(shape:nape.shape.Shape) {
				shape.sensorEnabled = enable;
			});
		}
	}

	/**
	 * Ermittelt und normalisiert den Pfad zur Tileset-Grafikdatei anhand der Tileset-UID aus dem LDtk-Projekt.
	 *
	 * @param tilesetUid Die UID des Tilesets im LDtk-Projekt.
	 * @return Der aufgelöste relative Asset-Pfad (z. B. "assets/tilesets/dungeon.png") oder `null`.
	 */
	public function resolveTilesetPath(tilesetUid:Int):Null<String> {
		if (_entity == null) {
			return null;
		}

		var proj:ldtk.Project = (state != null && state.project != null) ? state.project : @:privateAccess _entity.untypedProject;
		if (proj == null) {
			return null;
		}

		var tilesetDef = proj.getTilesetDefJson(tilesetUid);
		if (tilesetDef == null || tilesetDef.relPath == null) {
			return null;
		}

		var rawPath:String = (proj.projectDir != null && proj.projectDir.length > 0) ? (proj.projectDir + "/" + tilesetDef.relPath) : tilesetDef.relPath;
		var normalized:String = haxe.io.Path.normalize(rawPath);
		if (!StringTools.startsWith(normalized, "assets/")) {
			if (StringTools.startsWith(normalized, "/")) {
				normalized = "assets" + normalized;
			} else {
				normalized = "assets/" + normalized;
			}
		}
		return normalized;
	}

	/**
	 * Schneidet einen spezifischen rechteckigen Ausschnitt aus einer Tilemap/Tileset-Grafik
	 * aus und weist ihn diesem Sprite zu.
	 *
	 * @param path Relativer Asset-Pfad zur Tileset-Grafikdatei.
	 * @param tileX X-Koordinate des Ausschnitts im Tileset (in Pixeln).
	 * @param tileY Y-Koordinate des Ausschnitts im Tileset (in Pixeln).
	 * @param tileW Breite des Ausschnitts (in Pixeln).
	 * @param tileH Höhe des Ausschnitts (in Pixeln).
	 */
	public function loadTileRectGraphic(path:String, tileX:Int, tileY:Int, tileW:Int, tileH:Int):Void {
		var cacheKey:String = path + "_tileRect_" + tileX + "_" + tileY + "_" + tileW + "_" + tileH;
		if (FlxG.bitmap != null && FlxG.bitmap.checkCache(cacheKey)) {
			loadGraphic(FlxG.bitmap.get(cacheKey));
		} else {
			var sourceBmd:openfl.display.BitmapData = null;
			if (FlxG.bitmap != null) {
				var sourceGraphic = FlxG.bitmap.add(path);
				if (sourceGraphic != null && sourceGraphic.bitmap != null) {
					sourceBmd = sourceGraphic.bitmap;
				}
			}
			if (sourceBmd == null && openfl.utils.Assets.exists(path)) {
				sourceBmd = openfl.utils.Assets.getBitmapData(path);
			}

			if (sourceBmd != null) {
				var cropBmd = new openfl.display.BitmapData(tileW, tileH, true, 0x00000000);
				cropBmd.copyPixels(sourceBmd, new openfl.geom.Rectangle(tileX, tileY, tileW, tileH), new openfl.geom.Point(0, 0));
				if (FlxG.bitmap != null) {
					var croppedGraphic = FlxG.bitmap.add(cropBmd, false, cacheKey);
					loadGraphic(croppedGraphic);
				} else {
					loadGraphic(cropBmd);
				}
			}
		}
		width = tileW;
		height = tileH;
	}

	/**
	 * Ermittelt und normalisiert den Pfad zur Grafikdatei (beginnend mit `assets/`),
	 * falls der Entity in LDtk ein Tile oder TileRect zugewiesen ist. Setzt zudem das Flag `hasGraphic`.
	 *
	 * @return Der aufgelöste Asset-Pfad zur Bilddatei oder `null`.
	 */
	public function getGraphicPath():Null<String> {
		hasGraphic = false;

		if (_entity == null) {
			return null;
		}

		var tileRect:Dynamic = getField("TileRect");
		if (tileRect == null) {
			tileRect = getField("tileRect");
		}
		if (tileRect != null) {
			var tilesetUid:Int = Reflect.hasField(tileRect, "tilesetUid") ? Reflect.field(tileRect, "tilesetUid") : 0;
			var path = resolveTilesetPath(tilesetUid);
			if (path != null) {
				hasGraphic = true;
				return path;
			}
		}

		if (_entity.tileInfos != null) {
			var path = resolveTilesetPath(_entity.tileInfos.tilesetUid);
			if (path != null) {
				hasGraphic = true;
				return path;
			}
		}

		return null;
	}

	/**
	 * Weist dem Nape-Physikkörper (`body`) die entsprechenden `CbType`-Tags zu.
	 *
	 * - Wird `name` übergeben, wird gezielt dieser Tag hinzugefügt.
	 * - Bleibt `name` leer (`null`), werden die Entity-Felder `Tag` bzw. `Tags` aus den LDtk-JSON-Daten
	 *   ausgewertet und alle übereinstimmenden CbTypes registriert.
	 *
	 * Zudem wird `body.userData.instance` auf diese Instanz gesetzt.
	 *
	 * @param name Optionaler Name des spezifischen Tags (Standard: `null`, automatisches Auslesen).
	 */
	public function addCbType(name:String = null):Void {
		if (body == null) {
			trace("Warning: Cannot add CbType because body is not yet initialized!");
			return;
		}

		if (name == null) {
			if (_entity != null && _entity.json != null && _entity.json.fieldInstances != null) {
				for (inst in _entity.json.fieldInstances) {
					if (inst.__identifier == "Tag" || inst.__identifier == "Tags") {
						if (Std.isOfType(inst.__value, Array)) {
							var arr:Array<Dynamic> = cast inst.__value;
							for (val in arr) {
								var tagStr:String = Std.string(val);
								if (Tags.exist(tagStr)) {
									body.cbTypes.add(Tags.get(tagStr));
								}
							}
						} else {
							var tagStr:String = Std.string(inst.__value);
							if (Tags.exist(tagStr)) {
								body.cbTypes.add(Tags.get(tagStr));
							}
						}
					}
				}
			}
		} else {
			if (Tags.exist(name)) {
				body.cbTypes.add(Tags.get(name));
			}
		}

		body.userData.instance = this;
	}

	/**
	 * Positioniert den Nape-Körper im Mittelpunkt der LDtk-Entity-Dimensionen bzw. Sprite-Maße.
	 * Hilfreich nach dem Erstellen von Nape-Shapes, da Nape-Körper standardmäßig
	 * ihren Ursprung im Schwerpunkt/Mittelpunkt haben.
	 */
	public function updateShapePosition():Void {
		if (body != null && _entity != null) {
			var targetW:Float = (width > 0) ? width : _entity.width;
			var targetH:Float = (height > 0) ? height : _entity.height;
			body.position.setxy(_entity.pixelX + (targetW / 2), _entity.pixelY + (targetH / 2));
		}
	}

	/**
	 * Initialisiert und startet Animationen aus der `AnimationRegistry` für diese Entity.
	 *
	 * @param animKey Name/Schlüssel der Animationsdefinition in `AnimationRegistry.db` (z. B. "Fire").
	 *                Falls nicht angegeben, wird das LDtk-Feld `"Animations"` verwendet.
	 */
	public function initAnimation(?animKey:String):Void {
		if (animKey == null) {
			animKey = getField("Animations");
		}
		if (animKey != null) {
			AnimationManager.apply(this, animKey);
		}
	}

	/**
	 * Markiert diese Nape-Entity im `SaveManager` als zerstört/aufgesammelt,
	 * sodass sie beim erneuten Betreten des Levels nicht mehr gespawnt wird.
	 *
	 * @param killSprite Falls `true` (Standard), wird sofort `kill()` aufgerufen.
	 */
	public function markDestroyed(killSprite:Bool = true):Void {
		if (iid != null) {
			var lvlName:Null<String> = (state != null) ? state.levelName : null;
			SaveManager.markEntityDestroyed(iid, lvlName);
		}
		if (killSprite) {
			kill();
		}
	}

	/**
	 * Prüft, ob diese Entity im aktuellen Save-Zustand als zerstört markiert ist.
	 */
	public function isSaveDestroyed():Bool {
		if (iid == null) {
			return false;
		}
		var lvlName:Null<String> = (state != null) ? state.levelName : null;
		return SaveManager.isEntityDestroyed(iid, lvlName);
	}
}
