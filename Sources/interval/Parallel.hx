package interval;

import kha.FastFloat;
import interval.Interval;
import interval.IntervalManager;
import interval.Sequence;
import interval.Types;


class Parallel implements Playable {
    public var inSequence:Bool;
    private var _loop:Bool;
    private var _interval:Array<Playable>;
    private var _sequences:Array<Sequence>;
    private var _syncStart:Bool;
    public var callback:Void -> Void;
    public var beforeCallback:Void -> Void;
    private var _state:PlaybackState = NOT_STARTED;
    private var _keepAlive:Bool;
    private var _invalid = false;

    public function new(?intervals:Array<Playable> = null, ?syncStart:Bool = true) {
        inSequence = false;
        _syncStart = syncStart;
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
        ival._loop = false;
        ival._keepAlive = true;
        _interval.push(ival);
    }

    public inline function play():Void {
        if (_interval.length == 0) {
            throw "Empty parallel";
        }
        else if (_state != NOT_STARTED && _state != FINISHED && _state != PAUSED) {
            throw "Invalid state to call play";
        }
        if (_state != PAUSED && beforeCallback != null) {
            beforeCallback();
        }
        IntervalManager._playQueue.push(this);
        if (_state != PAUSED) {
            _reset();
        }
        _state = PLAYING;
    }

    private inline function _reset():Void {
        if (_sequences == null) {
            _sequences = new Array<Sequence>();
        } else {
            _sequences.resize(0);
        }

        var maxLen:FastFloat = 0.0;
        for (i in _interval) {
            if (i.length() > maxLen) {
                maxLen = i.length();
            }
        }

        for (i in _interval) {
            var iLen = i.length();
            if (iLen < maxLen) {
                var s = new Sequence();
                if (_syncStart) {
                    s.append(i);
                    s.append(Interval.nop(maxLen - iLen));
                } else {
                    s.append(Interval.nop(maxLen - iLen));
                    s.append(i);
                }
            }
            else {
                _sequences.push(new Sequence([i]));
            }
        }
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
        if (_state == PLAYING || _state == PAUSED) {
            for (i in _sequences) {
                i.stop();
            }
        }
        _state = NOT_STARTED;
    }

    public inline function step(dt:FastFloat):FastFloat {
        var rdt = dt;
        switch (_state) {
            case PAUSED | NOT_STARTED: return -1;
            case FINISHED:
                remove(true);
                return dt;
            case PLAYING:
                for (s in _sequences) {
                    rdt = s.step(dt);
                }
            default:
        }
        return rdt;
    }

    public inline function remove(?_auto:Bool = false):Void {
        if (_invalid) {
            return;
        }
        if (callback != null) {
            callback();
        }
        if (!inSequence) {
            IntervalManager._removeQueue.push(this);
        }
        if (_sequences != null && _sequences.length > 0) {
            for (s in _sequences) {
                s.remove();
            }
            _sequences.resize(0);
        }
        _invalid = true;
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

    public inline function length():FastFloat {
        var len:FastFloat = 0.0;
        for (i in _interval) {
            if (i.length() > len) {
                len = i.length();
            }
        }
        return len;
    }
}
