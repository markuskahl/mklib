package mklib.physic;

import flixel.FlxSprite;
import nape.callbacks.CbType;
import nape.geom.AABB;
import nape.geom.GeomPoly;
import nape.geom.GeomPolyList;
import nape.geom.MarchingSquares;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;
import nape.shape.Shape;
import openfl.display.BitmapData;

/**
 * Automatisierte Generierung von Nape-Polygon-Shapes direkt aus Pixelgrafiken (BitmapData / FlxSprite)
 * mittels `nape.geom.MarchingSquares` und konvexer Polygonzerlegung (`convexDecomposition`).
 */
class ShapeBuilder {
	/**
	 * Erzeugt Nape-Polygon-Shapes direkt aus den sichtbaren Pixeln einer `BitmapData`.
	 *
	 * @param bmd Die Quell-BitmapData.
	 * @param body Optionaler Nape-Körper, dem die erzeugten Shapes direkt zugewiesen werden.
	 * @param alphaThreshold Schwellenwert für die Sichtbarkeit (0-255). Standard: 128.
	 * @param simplify Grad der Glättung/Vereinfachung der Kontur in Pixeln. Standard: 1.0.
	 * @param offset Optionaler Versatz der Shapes (z. B. (-origin.x, -origin.y)).
	 * @param sensor Sollen die erzeugten Shapes als Sensoren deklariert werden? Standard: false.
	 * @param cbType Optionaler CbType, der allen erzeugten Shapes zugewiesen wird.
	 * @return Array der erzeugten `Polygon`-Shapes.
	 */
	public static function createShapesFromBitmap(bmd:BitmapData, ?body:Body, alphaThreshold:Int = 128, simplify:Float = 1.0, ?offset:Vec2,
			sensor:Bool = false, ?cbType:CbType, cellSizeVal:Float = 1.0):Array<Polygon> {
		if (bmd == null) {
			return [];
		}

		var iso = function(x:Float, y:Float):Float {
			var ix = Math.floor(x);
			var iy = Math.floor(y);
			if (ix < 0 || ix >= bmd.width || iy < 0 || iy >= bmd.height) {
				return 1.0;
			}
			var pixelAlpha = (bmd.getPixel32(ix, iy) >>> 24);
			return (pixelAlpha >= alphaThreshold) ? -1.0 : 1.0;
		};

		var bounds = new AABB(0, 0, bmd.width, bmd.height);
		var cellSize = Vec2.get(cellSizeVal, cellSizeVal);

		var polyList:GeomPolyList = MarchingSquares.run(iso, bounds, cellSize);
		cellSize.dispose();

		var createdPolygons:Array<Polygon> = [];

		if (polyList != null) {
			for (i in 0...polyList.length) {
				var poly:GeomPoly = polyList.at(i);
				if (poly == null || poly.empty() || poly.size() < 3) {
					continue;
				}

				// Kontur glätten / vereinfachen (mit Fallback und Validierung)
				var currentPoly:GeomPoly = poly;
				if (simplify > 0) {
					try {
						var simplified = poly.simplify(simplify);
						if (simplified != null && !simplified.empty() && simplified.size() >= 3 && !simplified.isDegenerate() && Math.abs(simplified.area()) > 0.1) {
							currentPoly = simplified;
						}
					} catch (e:Dynamic) {
						// Falls simplify fehlschlägt, poly als Fallback beibehalten
					}
				}

				if (currentPoly == null || currentPoly.empty() || currentPoly.size() < 3 || currentPoly.isDegenerate() || Math.abs(currentPoly.area()) <= 0.1) {
					// Falls das vereinfachte Polygon degeneriert ist, versuche das unveränderte poly
					if (poly != null && !poly.empty() && poly.size() >= 3 && !poly.isDegenerate() && Math.abs(poly.area()) > 0.1) {
						currentPoly = poly;
					} else {
						continue;
					}
				}

				// In konvexe Polygone zerlegen
				var convexParts:GeomPolyList = null;
				try {
					convexParts = currentPoly.convexDecomposition();
				} catch (e:Dynamic) {
					// Fallback: versuche Original-Poly falls simplified fehlschlug
					if (currentPoly != poly && !poly.empty() && poly.size() >= 3 && !poly.isDegenerate() && Math.abs(poly.area()) > 0.1) {
						try {
							convexParts = poly.convexDecomposition();
						} catch (e2:Dynamic) {
							continue;
						}
					} else {
						continue;
					}
				}

				if (convexParts == null) {
					continue;
				}

				for (j in 0...convexParts.length) {
					var convexPoly:GeomPoly = convexParts.at(j);
					if (convexPoly == null || convexPoly.empty() || convexPoly.size() < 3 || convexPoly.isDegenerate() || Math.abs(convexPoly.area()) <= 0.1) {
						continue;
					}

					try {
						var shape = new Polygon(convexPoly, new Material(0, 0, 0, 1, 0));
						shape.sensorEnabled = sensor;

						if (offset != null && (offset.x != 0 || offset.y != 0)) {
							shape.translate(offset);
						}

						if (cbType != null) {
							shape.cbTypes.add(cbType);
						}

						if (body != null) {
							shape.body = body;
						}

						createdPolygons.push(shape);
					} catch (e:Dynamic) {
						continue;
					}
				}
			}
		}

		return createdPolygons;
	}

	/**
	 * Erzeugt Nape-Polygon-Shapes passgenau für ein `FlxSprite` (oder Unterklasse).
	 * Richtet die Shapes automatisch am Ursprung (`origin.x`, `origin.y`) des Sprites aus.
	 *
	 * @param sprite Das Quell-Sprite.
	 * @param body Optionaler Nape-Körper (falls null, wird sprite.body verwendet, falls vorhanden).
	 * @param alphaThreshold Schwellenwert für die Sichtbarkeit (0-255). Standard: 128.
	 * @param simplify Grad der Glättung/Vereinfachung in Pixeln. Standard: 1.0.
	 * @param sensor Sollen die Shapes als Sensoren deklariert werden? Standard: false.
	 * @param cbType Optionaler CbType für die erzeugten Shapes.
	 * @param cellSizeVal Zellengröße für MarchingSquares in Pixeln. Standard: 1.0 (exakte Pixelauflösung).
	 * @return Array der erzeugten `Polygon`-Shapes.
	 */
	public static function createShapesFromSprite(sprite:FlxSprite, ?body:Body, alphaThreshold:Int = 128, simplify:Float = 1.0, sensor:Bool = false,
			?cbType:CbType, cellSizeVal:Float = 1.0):Array<Polygon> {
		if (sprite == null) {
			return [];
		}

		var targetBody:Body = (body != null) ? body : (Reflect.hasField(sprite, "body") ? Reflect.field(sprite, "body") : null);

		sprite.drawFrame();
		var bmd:BitmapData = (sprite.framePixels != null) ? sprite.framePixels : sprite.pixels;

		var offsetX:Float = -sprite.origin.x;
		var offsetY:Float = -sprite.origin.y;
		var offsetVec = Vec2.get(offsetX, offsetY);

		var shapes = createShapesFromBitmap(bmd, targetBody, alphaThreshold, simplify, offsetVec, sensor, cbType, cellSizeVal);
		offsetVec.dispose();

		return shapes;
	}

	/**
	 * Erzeugt einen neuen Nape-`Body` und bestückt ihn automatisch mit Polygon-Shapes aus dem Sprite.
	 *
	 * @param sprite Das Quell-Sprite.
	 * @param type Der Nape-BodyType (STATIC, DYNAMIC, KINEMATIC). Standard: STATIC.
	 * @param alphaThreshold Schwellenwert für die Sichtbarkeit (0-255). Standard: 128.
	 * @param simplify Grad der Glättung/Vereinfachung in Pixeln. Standard: 1.0.
	 * @param sensor Sollen die Shapes als Sensoren deklariert werden? Standard: false.
	 * @param cbType Optionaler CbType.
	 * @param cellSizeVal Zellengröße für MarchingSquares in Pixeln. Standard: 1.0.
	 * @return Der fertige Nape-`Body` mit allen konvexen Polygon-Shapes.
	 */
	public static function createBodyFromSprite(sprite:FlxSprite, ?type:BodyType, alphaThreshold:Int = 128, simplify:Float = 1.0, sensor:Bool = false,
			?cbType:CbType, cellSizeVal:Float = 1.0):Body {
		var bodyType:BodyType = (type != null) ? type : BodyType.STATIC;
		var newBody = new Body(bodyType);

		if (sprite != null) {
			createShapesFromSprite(sprite, newBody, alphaThreshold, simplify, sensor, cbType, cellSizeVal);
		}

		return newBody;
	}
}
