package mklib.entity;

import mklib.entity.EntityNapeSprite;
import nape.phys.BodyType;

/**
 * Automatisches Hindernis (`Obstacle`), das von `EntityNapeSprite` erbt
 * und seine festen Nape-Kollisions-Shapes vollautomatisch aus der sichtbaren Pixelgrafik erzeugt.
 */
@:keep
class Obstacle extends EntityNapeSprite {
	public function new(entity:ldtk.Entity) {
		super(entity);

		if (body != null) {
			body.type = BodyType.STATIC;
			// Erzeugt vollautomatisch die exakten Nape-Polygon-Shapes aus der Pixelgrafik
			createShapesFromGraphic();
		}
	}
}
