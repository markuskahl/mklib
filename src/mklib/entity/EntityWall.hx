package mklib.entity;

import mklib.entity.EntityNapeSprite;
import flixel.util.FlxColor;

/**
 * Beispiel für eine feste Wand (`Wall`), die von `EntityNapeSprite` erbt.
 * Initialisiert einen statischen Nape-Körper, zentriert die Form und übernimmt automatisch LDtk-Tags.
 */
@:keep
class Wall extends EntityNapeSprite {
	/**
	 * Erstellt eine neue Instanz von `Wall` mit statischem Nape-Körper.
	 *
	 * @param entity Die aus LDtk geladene Entity-Definition.
	 */
	public function new(entity:ldtk.Entity) {
		super(entity);

		if (body != null) {
			body.type = nape.phys.BodyType.STATIC;
		}

		makeGraphic(entity.width, entity.height, FlxColor.RED);
	}
}
