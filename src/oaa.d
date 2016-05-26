/**
 * OAA
 *
 * A fork of Ordered Associative Array, slightly modified by Rėdas Peškaitis.
 * Additions:
 * 1) tuple based OAA constructor 
 * 2) method to export array of [key : value] tuples
 * 3) methods to get, insert and delete values by integer index in the order of keys.
 *
 * Repository: https://github.com/re-pe/d-oaa
 *  
 * Original Ordered Associative Array by Cédric Picard
 * Email: cedric.picard@efrei.net
 * Repository: https://github.com/cym13/miscD
 *
 * Ordered Associative Array modeled from Python's OrderedDict.
 *
 * Subtypes built-in associative arrays.
 *
 * It works by using an array to keep the key order in addition to a regular
 * associative array.
 */
import std.traits;
import std.exception : enforce;
 
struct OAA(T) if (isAssociativeArray!T) {
    import std.algorithm;
    import std.typecons;

    alias KeyType!T   keyT;
    alias ValueType!T valueT;
    alias KeyValT = Tuple!(keyT, valueT);
    
    private keyT[] _order;
    private T      _map;

    alias _map this;

    /**
     * Associative Array based Constructor
     */
    this(T base) {
        _order.reserve(base.length);

        foreach (key, value ; base) {
            _order   ~= key;
            _map[key] = value;
        }
    }

    ///
    unittest {
        auto as_arr  = ["one": 1, "two": 2];
        auto oaa = OAA(as_arr);
        assert(oaa == as_arr);
    }

    /**
     * Ordered Associative Array based Constructor
     */
    this(OAA!T base) {
        _order.reserve(base.length);

        foreach (key, value ; base.byKeyValue) {
            _order   ~= key;
            _map[key] = value;
        }
    }

    ///
    unittest {
        auto oaa_1 = OAA(["one": 1, "two": 2, "three": 3]);
        auto oaa_2 = OAA(oaa_1);
        assert(oaa_1 == oaa_2);
    }

    /**
     * Array of Tuples based Constructor
     */
    this(Tuple!(keyT, valueT)[] base) {
        _order.reserve(base.length);

        foreach (value ; base) {
            _order   ~= value[0];
            _map[value[0]] = value[1];
        }
    }

    ///
    unittest {
        auto oaa1 = OAA([tuple("one", 1), tuple("two", 2), tuple("three", 3)]);
        auto oaa2 = OAA(["one": 1, "two": 2, "three": 3]);
        assert(oaa1 == oaa2);
    }

    /**
     * Remove all contents from the container.
     */
    void clear() {
        _map   = null;
        _order = null;
    }

    ///
    unittest {
        auto oaa = OAA(["one": 1, "two": 2]);
        oaa.clear;
        assert(oaa[].length == 0);
    }

    /**
     * Returns a range of keys in order
     */
    auto byKey() {
        return _order.dup;
    }

    /**
     * Returns a range of values in order
     */
    auto byValue() {
        return _order.map!(x => _map[x]);
    }

    /**
     * Returns a range of tuples (key, value) in order
     */
    auto byKeyValue() {
        return _order.map!(x => tuple(x, _map[x]));
    }

    /**
     * Returns an array of tuples (key, value) in order
     */
    auto tupleArray() {
        import std.array;
        return array(this.byKeyValue);
    }

    unittest {
        auto tup_arr1 = [tuple("one", 1), tuple("two", 2), tuple("three", 3)];
        auto oaa1 = OAA(tup_arr1);
        auto tup_arr2 = oaa1.tupleArray;
        assert(tup_arr1 == tup_arr2);
    }
    
    auto ref opIndex() {
        return _order[];
    }

    auto ref opIndex(const keyT key) {
        return _map[key];
    }

    /**
     * Returns a Tuple!(keyT, valueT) with n-th place in order
     */
    auto ref opIndex(int index) {
        KeyValT result;
        if (index < 0) {
            index = _order.length + index; 
        }
        if (index > -1 && index < _order.length) {
            result = Tuple!(keyT, valueT)(_order[index], _map[_order[index]]);
        }
        return result;
    }

    void opIndexAssign(const valueT value, const keyT key) {
        if (key !in _map)
            _order ~= key;
        _map[key] = value;
    }

    /**
     * Insert a Tuple!(keyT, valueT) to n-th place in order
     */
    void opIndexAssign(const Tuple!(keyT, valueT) tuple, int index) {
        
        auto key = tuple[0];
        auto value = tuple[1];

        if (key in _map) {
            auto curIndex = _order.countUntil(key);
            enforce!Exception(curIndex > -1, "Key is in asociative array, but has no order!");
            _order = std.algorithm.remove(_order, curIndex);
        }

        if (index < 0) {
            index = _order.length + index; 
        }

        if (index < 1){
            _order = [key] ~ _order;
        } else if (index > _order.length - 1){
            _order ~= [key];
        } else {
            _order = _order[0..index] ~ [key] ~ _order[index..$];
        }
        
        _map[key] = value;
    }

    /**
     * Remove an element in place given its key
     * Returns false if the element wasn't in the array, true otherwise
     */
    bool remove(const keyT key) {
        auto index = _order.countUntil(key);

        if (index == -1)
            return false;

        _order = std.algorithm.remove(_order, index);
        _map.remove(key);
        return true;
    }

    /**
     * Remove an element in place given its place in order
     * Returns false if the element wasn't in the array, true otherwise
     */
    bool remove(int index) {
 
        if (index < 0) {
            index = _order.length + index; 
        }

        if (index >= _order.length || index < 0){
            return false;
        }

        auto key = _order[index];

        _order = std.algorithm.remove(_order, index);
        _map.remove(key);
        return true;
    }

    ///
    unittest {
        import std.array:     array;
        import std.algorithm: sort;
    
        auto oaa = OAA(["one": 1, "two": 2, "three": 3]);

        sort(oaa[]);
        assert(oaa[].array == ["one", "three", "two"]);

        assert(!oaa.remove("four"));
        assert(oaa[].array == ["one", "three", "two"]);

        assert(oaa.remove("three"));
        assert(oaa[].array == ["one", "two"]);

        assert(oaa.remove(0));
        assert(oaa[].array == ["two"]);
        assert(oaa == ["two": 2]);
    }
}

///
unittest {
    import std.array;
    import std.algorithm: sort, reverse;
    import std.typecons;

    OAA!(int[string]) oaa;

    oaa["one"]   = 1;
    oaa["two"]   = 2;
    oaa["three"] = 3;

    // Usage is similar to an ordinary Associative Array
    assert(oaa["three"] == 3);

    // Usage is similar to an ordinary array index, adding and getting tuple
    import std.stdio;
    oaa[1] = tuple("four", 15);

    assert(oaa[1] == tuple("four", 15));
    assert(oaa[].array == ["one", "four", "two", "three"]);

    oaa.remove(-3);
    assert(oaa[].array == ["one", "two", "three"]);
    
    oaa[-2] = tuple("four", 15);
    assert(oaa[].array == ["one", "four", "two", "three"]);
    assert(oaa[-3] == tuple("four", 15));

    // It can be compared to ordinary AAs too
    assert(oaa == ["one":1, "two":2, "three":3, "four":15]);
    assert(oaa == ["four":15, "two":2, "three":3, "one":1]);

    // Slicing gives control over the ordered keys
    assert(oaa[].array == ["one", "four", "two", "three"]);

    reverse(oaa[]);
    assert(oaa[].array == ["three", "two", "four", "one"]);

    sort(oaa[]);
    assert(oaa[].array == ["four", "one", "three", "two"]);
    
}
