package mklib.save;

/**
 * Schnittstelle für Entities und Spielobjekte, deren Zustand gespeichert
 * und wiederhergestellt werden kann.
 */
interface ISaveable {
	/**
	 * Gibt die zu serialisierenden Zustandsdaten des Objekts als anonyme Struktur / Dynamic zurück.
	 *
	 * @return Ein Objekt mit den zu speichernden Feldern (z. B. `{ health: 80, isOpened: true }`).
	 */
	public function saveState():Dynamic;

	/**
	 * Stellt den Zustand des Objekts aus den übergebenen Daten wieder her.
	 *
	 * @param data Das zuvor mit `saveState()` gespeicherte Datenobjekt.
	 */
	public function loadState(data:Dynamic):Void;
}
