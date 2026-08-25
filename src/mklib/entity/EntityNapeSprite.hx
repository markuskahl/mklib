package mklib.entity;

import nape.geom.Vec2;
import mklib.tools.Tags;
import mklib.state.State;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSprite;

/**
 * Erweiterte Entity-Klasse mit integriertem Nape-Physikkörper (`FlxNapeSprite`).
 *
 * Ermöglicht das automatische Auslesen von Tags/Kollisionstypen (`CbType`) direkt aus den
 * LDtk-Feldern (`Tag` oder `Tags`) sowie die exakte Zentrierung von Nape-Shapes auf Basis der LDtk-Entity-Maße.
 */
class EntityNapeSprite extends FlxNapeSprite
{
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
     * Erstellt eine neue Instanz von `EntityNapeSprite` anhand einer LDtk-Entity.
     *
     * @param entity Die aus dem LDtk-Level geladene Entity-Definition.
     */
    public function new(entity:ldtk.Entity)
    {
        iid = entity.iid;
        _entity = entity;
        super(entity.pixelX, entity.pixelY);

        if (FlxG.state != null && Std.isOfType(FlxG.state, State))
        {
            state = cast FlxG.state;
        }
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
    public function addCbType(name:String = null):Void
    {
        if (body == null)
        {
            trace("Warning: Cannot add CbType because body is not yet initialized!");
            return;
        }

        if (name == null)
        {
            if (_entity != null && _entity.json != null && _entity.json.fieldInstances != null)
            {
                for (inst in _entity.json.fieldInstances)
                {
                    if (inst.__identifier == "Tag" || inst.__identifier == "Tags")
                    {
                        if (Std.isOfType(inst.__value, Array))
                        {
                            var arr:Array<Dynamic> = cast inst.__value;
                            for (val in arr)
                            {
                                var tagStr:String = Std.string(val);
                                if (Tags.exist(tagStr))
                                {
                                    body.cbTypes.add(Tags.get(tagStr));
                                }
                            }
                        }
                        else
                        {
                            var tagStr:String = Std.string(inst.__value);
                            if (Tags.exist(tagStr))
                            {
                                body.cbTypes.add(Tags.get(tagStr));
                            }
                        }
                    }
                }
            }
        }
        else
        {
            if (Tags.exist(name))
            {
                body.cbTypes.add(Tags.get(name));
            }
        }

        body.userData.instance = this;
    }

    /**
     * Positioniert den Nape-Körper im Mittelpunkt der LDtk-Entity-Dimensionen.
     * Hilfreich nach dem Erstellen von Nape-Shapes, da Nape-Körper standardmäßig
     * ihren Ursprung im Schwerpunkt/Mittelpunkt haben.
     */
    public function updateShapePosition():Void
    {
        if (body != null && _entity != null)
        {
            body.position.setxy(_entity.pixelX + (_entity.width / 2), _entity.pixelY + (_entity.height / 2));
        }
    }
}
