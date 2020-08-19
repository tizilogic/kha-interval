package interval;

import kha.FastFloat;
import interval.Types;


@:allow(interval.Playable)
class IntervalManager {
    private static var _activeNodes = new Map<Int,Int>();
    private static var _playQueue = new Array<Playable>();
    private static var _removeQueue = new Array<Playable>();

    public static function step(dt:FastFloat) {
        _activeNodes.clear();
        for (i in 0..._playQueue.length) {
            _playQueue[_playQueue.length - 1 - i].step(dt);
        }
        while (_removeQueue.length > 0) {
            _playQueue.remove(_removeQueue.pop());
        }
    }
}
