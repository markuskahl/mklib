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
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.geom.Matrix;

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

	/**
	 * Schneidet ein einzelnes Frame aus einer Spritesheet-BitmapData aus und spiegelt es optional.
	 *
	 * @param sourceBmd Die Quell-Spritesheet-BitmapData.
	 * @param frameRect Der Ausschnitt des Frames (x, y, w, h).
	 * @param flipX Soll das Frame horizontal gespiegelt werden? Standard: false.
	 * @param flipY Soll das Frame vertikal gespiegelt werden? Standard: false.
	 * @return Eine neue BitmapData mit den Pixeln des Frames oder `null`.
	 */
	public static function extractFrameBitmap(sourceBmd:BitmapData, frameRect:Rectangle, flipX:Bool = false, flipY:Bool = false):Null<BitmapData> {
		if (sourceBmd == null || frameRect == null || frameRect.width <= 0 || frameRect.height <= 0) {
			return null;
		}
		var w:Int = Std.int(frameRect.width);
		var h:Int = Std.int(frameRect.height);
		var frameBmd = new BitmapData(w, h, true, 0x00000000);
		frameBmd.copyPixels(sourceBmd, frameRect, new Point(0, 0));

		if (!flipX && !flipY) {
			return frameBmd;
		}

		var flippedBmd = new BitmapData(w, h, true, 0x00000000);
		var matrix = new Matrix();
		matrix.scale(flipX ? -1 : 1, flipY ? -1 : 1);
		matrix.translate(flipX ? w : 0, flipY ? h : 0);
		flippedBmd.draw(frameBmd, matrix);
		frameBmd.dispose();
		return flippedBmd;
	}

	/**
	 * Erzeugt Nape-Polygon-Shapes für alle Frames einer Animation eines `FlxSprite` (sowohl normal als auch gespiegelt für `flipX`).
	 *
	 * @param sprite Das Quell-Sprite mit geladenen Frames/Grafik und Animationen.
	 * @param animName Name der Animation (z. B. "attack" oder "attack_up").
	 * @param alphaThreshold Schwellenwert für die Sichtbarkeit (0-255). Standard: 128.
	 * @param simplify Grad der Glättung/Vereinfachung in Pixeln. Standard: 1.0.
	 * @param sensor Sollen die Shapes als Sensoren deklariert werden? Standard: true.
	 * @param cbType Optionaler CbType für die erzeugten Shapes (z. B. Tags.get("ObstacleSensor")).
	 * @param cellSizeVal Zellengröße für MarchingSquares. Standard: 1.0.
	 * @return Map der Shapes mit Schlüsseln wie "attack:0:0" (normal) und "attack:0:1" (gespiegelt) sowie "frame:6:0".
	 */
	public static function createShapesForAnimation(sprite:FlxSprite, animName:String, alphaThreshold:Int = 128, simplify:Float = 1.0,
			sensor:Bool = true, ?cbType:CbType, cellSizeVal:Float = 1.0):Map<String, Array<Polygon>> {
		var result:Map<String, Array<Polygon>> = new Map();
		if (sprite == null || sprite.graphic == null || sprite.graphic.bitmap == null || sprite.animation == null) {
			return result;
		}

		var anim = sprite.animation.getByName(animName);
		if (anim == null || anim.frames == null || anim.frames.length == 0) {
			return result;
		}

		var sourceBmd:BitmapData = sprite.graphic.bitmap;
		var frameW:Int = Std.int(sprite.width > 0 ? sprite.width : 32);
		var frameH:Int = Std.int(sprite.height > 0 ? sprite.height : 32);
		var originX:Float = sprite.origin.x;
		var originY:Float = sprite.origin.y;

		for (frameNum in 0...anim.frames.length) {
			var frameIndex:Int = anim.frames[frameNum];

			var rect:Rectangle = null;
			if (sprite.frames != null && frameIndex < sprite.frames.frames.length) {
				var flxFrame = sprite.frames.frames[frameIndex];
				if (flxFrame != null && flxFrame.frame != null) {
					rect = new Rectangle(flxFrame.frame.x, flxFrame.frame.y, flxFrame.frame.width, flxFrame.frame.height);
					frameW = Std.int(flxFrame.frame.width);
					frameH = Std.int(flxFrame.frame.height);
				}
			}

			if (rect == null) {
				var cols:Int = Math.floor(sourceBmd.width / frameW);
				if (cols <= 0) cols = 1;
				var fx:Int = (frameIndex % cols) * frameW;
				var fy:Int = Math.floor(frameIndex / cols) * frameH;
				rect = new Rectangle(fx, fy, frameW, frameH);
			}

			// 1. Normal (flipX = false)
			var bmdNormal = extractFrameBitmap(sourceBmd, rect, false, false);
			if (bmdNormal != null) {
				var offsetVec = Vec2.get(-originX, -originY);
				var shapesNormal = createShapesFromBitmap(bmdNormal, null, alphaThreshold, simplify, offsetVec, sensor, cbType, cellSizeVal);
				offsetVec.dispose();
				bmdNormal.dispose();

				for (s in shapesNormal) {
					s.userData.animName = animName;
					s.userData.frameNumber = frameNum;
					s.userData.frameIndex = frameIndex;
				}
				result.set(animName + ":" + frameNum + ":0", shapesNormal);
				result.set("frame:" + frameIndex + ":0", shapesNormal);
			}

			// 2. Flipped (flipX = true)
			var bmdFlipped = extractFrameBitmap(sourceBmd, rect, true, false);
			if (bmdFlipped != null) {
				var offsetVec = Vec2.get(-originX, -originY);
				var shapesFlipped = createShapesFromBitmap(bmdFlipped, null, alphaThreshold, simplify, offsetVec, sensor, cbType, cellSizeVal);
				offsetVec.dispose();
				bmdFlipped.dispose();

				for (s in shapesFlipped) {
					s.userData.animName = animName;
					s.userData.frameNumber = frameNum;
					s.userData.frameIndex = frameIndex;
				}
				result.set(animName + ":" + frameNum + ":1", shapesFlipped);
				result.set("frame:" + frameIndex + ":1", shapesFlipped);
			}
		}

		return result;
	}
}
