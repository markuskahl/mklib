package mklib.entity;

import flixel.FlxG;
import mklib.state.State;
import flixel.FlxSprite;

/**
 * Basisklasse für visuelle Entities, die aus einem LDtk-Level geladen werden.
 *
 * Erbt von `FlxSprite` und synchronisiert automatisch Position, Abmessungen,
 * die eindeutige Instanz-ID (`iid`) sowie die Referenz auf den aktuellen `State`.
 */
class EntitySprite extends FlxSprite
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
     * Erstellt eine neue Instanz von `EntitySprite` anhand einer LDtk-Entity.
     *
     * @param entity Die aus dem LDtk-Level geladene Entity-Definition.
     */
    public function new(entity:ldtk.Entity)
    {
        _entity = entity;
        super(entity.pixelX, entity.pixelY);
        iid = entity.iid;
        width = entity.width;
        height = entity.height;
        if (FlxG.state != null && Std.isOfType(FlxG.state, State))
        {
            state = cast FlxG.state;
        }
    }
}