package interval;

import kha.FastFloat;
import interval.IntervalManager;
import interval.Types;


class Sequence implements Playable {
    public var inSequence:Bool;
    private var _loop:Bool;
    private var _interval:Array<Playable>;
    private var _cursor:Int = -1;
    public var callback:Void -> Void;
    public var beforeCallback:Void -> Void;
    private var _state:PlaybackState = NOT_STARTED;
    private var _keepAlive:Bool;

    public function new(?intervals:Array<Playable> = null) {
        inSequence = false;
        if (intervals != null) {
            _interval = intervals;
        }
        else {
            _interval = new Array<Playable>();
        }
        for (i in _interval) {
            i.inSequence = true;
            i._loop = false;
            i._keepAlive = true;
        }
    }

    public inline function append(ival:Playable) {
        ival.inSequence = true;
        _interval.push(ival);
    }

    public inline function play():Void {
        if (_interval.length == 0) {
            throw "Empty sequence";
        }
        else if (_state != NOT_STARTED && _state != FINISHED && _state != PAUSED) {
            throw "Invalid state to call play";
        }
        if (_state != PAUSED && beforeCallback != null) {
            beforeCallback();
        }
        IntervalManager._playQueue.push(this);
        _cursor = 0;
        _interval[0].play();
        _state = PLAYING;
    }

    public inline function pause():Void {
        _state = PAUSED;
    }

    public inline function resume():Void {
        if (_state != PAUSED) {
            throw "Can only resume paused Sequence";
        }
        _state = PLAYING;
    }

    public inline function stop():Void {
        if (_cursor != -1) {
            _interval[_cursor].stop();
        }
    }

    public inline function step(dt:FastFloat):FastFloat {
        var rdt = dt;
        while (rdt >= 0) {
            switch (_state) {
                case PAUSED | NOT_STARTED: return -1;
                case FINISHED:
                    remove(true);
                    return dt;
                case PLAYING:
                    rdt = _interval[_cursor].step(rdt);
                    if (rdt == -1) {
                        break;
                    }
                    else if (rdt == -2) {
                        remove(true);
                        break;
                    }
                    else {
                        ++_cursor;
                        if (_cursor == _interval.length) {
                            if (_loop) {
                                _cursor = 0;
                            }
                            else {
                                remove(true);
                                break;
                            }
                        }
                        _interval[_cursor].play();
                    }
                default:
            }
        }
        return rdt;
    }

    public inline function remove(?_auto:Bool = false):Void {
        if (callback != null) {
            callback();
        }
        if (!inSequence) {
            IntervalManager._removeQueue.push(this);
        }
        for (i in _interval) {
            i.remove();
        }
    }

    public inline function loop(?_set:Bool = true) {
        _loop = _set;
    }

    public inline function getEntry(?id:Int = -1):Playable {
        if (Math.abs(id) < _interval.length) {
            if (id < 0) {
                return _interval[_interval.length - id];
            }
            return _interval[id];
        }
        throw "Index out of range";
    }
}
