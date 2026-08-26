package mklib.macro;

#if macro
import haxe.Json;
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Compile-Time-Makro zur automatischen Generierung einer typsicheren Animationsdatenbank.
 *
 * Liest alle `.json`-Animationsdateien aus einem angegebenen Ordner ein,
 * bereinigt Bildpfade auf relative Projekt-Asset-Pfade und erzeugt zur Compile-Zeit
 * ein `Map<String, SpriteSheetData>`-Literal.
 */
class AnimationBuilder {
	/**
	 * Scannt das angegebene Verzeichnis zur Compile-Zeit nach `.json`-Animationsdefinitionen
	 * und gibt ein typisiertes `Map<String, SpriteSheetData>`-Objekt als Makro-Expression zurück.
	 *
	 * @param folderPath Pfad zum Animationsordner (z. B. `"assets/data/animations"`).
	 * @return AST-Expression eines `Map<String, SpriteSheetData>`-Literals.
	 */
	public static macro function buildDatabase(folderPath:String):Expr {
		#if macro
		// Stellt sicher, dass vom Projekt-Root aus gesucht wird
		var projectRoot = Sys.getCwd();
		var targetDir = Path.isAbsolute(folderPath) ? folderPath : Path.join([projectRoot, folderPath]);

		if (!FileSystem.exists(targetDir)) {
			Context.error('Ordner nicht gefunden im Spielprojekt: $targetDir', Context.currentPos());
			return macro new Map();
		}

		function sanitizePath(rawPath:String):String {
			// Wandelt "C:/.../assets/images/player.png" -> "assets/images/player.png" um
			var normalized = rawPath.split("\\").join("/");
			var assetIdx = normalized.indexOf("assets/");
			return (assetIdx != -1) ? normalized.substr(assetIdx) : normalized;
		}

		var elements:Array<Expr> = [];

		for (file in FileSystem.readDirectory(targetDir)) {
			var fullPath = Path.join([targetDir, file]);

			if (!FileSystem.isDirectory(fullPath) && Path.extension(fullPath).toLowerCase() == "json") {
				try {
					var parsed:Dynamic = Json.parse(File.getContent(fullPath));

					// Pfad zur Compile-Zeit anpassen
					if (parsed.imagePath != null) {
						parsed.imagePath = sanitizePath(parsed.imagePath);
					}

					var keyName = Path.withoutExtension(file);
					var keyExpr = Context.makeExpr(keyName, Context.currentPos());
					var valExpr = Context.makeExpr(parsed, Context.currentPos());

					elements.push(macro $keyExpr => $valExpr);
				} catch (e:Dynamic) {
					Context.error('Fehler in $file: $e', Context.currentPos());
				}
			}
		}

		if (elements.length == 0) {
			return macro new Map<String, mklib.animation.AnimationTypes.SpriteSheetData>();
		}

		return macro [ $a{elements} ];
		#else
		return macro null;
		#end
	}
}

