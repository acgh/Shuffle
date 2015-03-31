// @alctw / acgh

import Foundation

// MARK: Spreading

protocol Spreadable {
    // Not conforming to "Comparable" for brevity here...
    var spreadFactor: Float {
        get
        set
    }
    init(_ s:Self)
}

func randomFactor() -> Float {
    return Float(arc4random()) / Float(UINT32_MAX)
}

func randomFactorBetween(f1: Float, and f2: Float) -> Float {
    return f1 + randomFactor() * (f2 - f1)
}

func randomFactorAround(a: Float, range r: Float) -> Float {
    let p = a * r
    return randomFactorBetween(a - p, and: a + p)
}

func spread<T:Spreadable>(ts: [T]) -> [T] {
    let sp = 1.0 / (Float(count(ts)))
    let range:Float = 0.2 // 20%
    var offset:Float = randomFactorBetween(0, and: sp * (1 - range))
    return ts.map {
        offset += randomFactorAround(sp, range: range)
        var t = T($0)
        t.spreadFactor = offset
        return t
    }
}

// MARK: Building

protocol StringSubscriptable {
    subscript (key: String) -> String? {
        get
    }
}

protocol Shufflable: Spreadable, StringSubscriptable {
    
}

enum ShuffleTree<T:Shufflable> {
    case Node([ShuffleTree<T>])
    case Leaf([T])
    
    init(_ ns:[ShuffleTree<T>]) {
        self = Node(ns)
    }
    
    init(_ values:[T]) {
        self = Leaf(spread(values))
    }
    
    func shuffledElements(merger: ([[T]]) -> [T]) -> [T] {
        switch self {
        case let .Node(children):
            var toMerge = [[T]]()
            for c in children {
                toMerge += [c.shuffledElements(merger)]
            }
            // Merge then Spread again
            return spread(merger(toMerge))
        case let .Leaf(elements): return elements
        default: return []
        }
    }
}

func group<T:StringSubscriptable>(# elements: [T], by key:String) -> [[T]] {
    var groups = [String:[T]]()
    for elt in elements {
        if let value = elt[key] {
            if groups[value] == nil {
                groups[value] = [T]()
            }
            groups[value]!.append(elt)
        }
    }
    return Array(groups.values)
}

func shuffleTree<T:Shufflable>(shufflables elts: [T],
    by keys:[String]) -> ShuffleTree<T> {
        if let key = keys.first {
            let grp = group(elements: elts, by: key)
            let remainingKeys = Array(keys[1..<keys.endIndex])
            var nodes = [ShuffleTree<T>]()
            for elts in grp {
                let node = shuffleTree(shufflables: elts, by: remainingKeys)
                nodes.append(node)
            }
            return ShuffleTree(nodes)
        }
        else {
            return ShuffleTree(elts)
        }
}

func sillyMerge<T:Shufflable>(# sortedArrays: [[T]], comparison: (T, T) -> Bool) -> [T] {
    // A unefficient merge of N sorted arrays :)
    // Merge:
    var merged = [T]()
    for a in sortedArrays {
        merged += a
    }
    // Sort again...
    merged.sort(comparison)
    return merged
}


// MARK: Custom types

struct Artist {
    var id:String
    var name:String
}

struct Album {
    var id:String
    var title:String
}

struct Track {
    var id:String
    var title:String
    var artist:Artist
    var album:Album
    
    init(_ d:[String:AnyObject]) {
        // You wouldn't do such a ugly parsing in the struct in production
        // But it's not the intent of this playground
        id = d["id"] as! String
        title = d["title"] as! String
        
        let ard:AnyObject = d["artist"]!
        let ald:AnyObject = d["album"]!
        artist = Artist(id: ard["id"] as! String, name: ard["name"] as! String)
        album = Album(id: ald["id"] as! String, title: ald["title"] as! String)
    }
}

struct ShufflableTrack : Shufflable {
    private var track: Track
    var spreadFactor: Float = 0.0
    
    init(_ t: Track) {
        track = t
    }
    
    init(_ s: ShufflableTrack) {
        track = s.track
    }
    
    static let artist   = "artist"
    static let album    = "album"
    static let title    = "title"
    
    subscript (key: String) -> String? {
        // KVC of the poor :)
        switch key {
        case ShufflableTrack.artist:    return track.artist.id
        case ShufflableTrack.album:     return track.album.id
        case ShufflableTrack.title:     return track.title
        default: return nil
        }
    }
}

func shufflables(ts: [Track]) -> [ShufflableTrack] {
    return ts.map { ShufflableTrack($0) }
}

func tracks(sts: [ShufflableTrack]) -> [Track] {
    return sts.map { $0.track }
}

// MARK: Sample

func lotsOfTracks(# artists: Int,
    albumsPerArtist albums: Int,
    tracksPerAlbum tracks: Int) -> [Track] {
        var ts = [Track]()
        for artIdx in 0..<artists {
            let art = ["id": "art:\(artIdx)", "name": "artist:\(artIdx)"]
            for albIdx in 0..<albums {
                let aid = "\(artIdx).\(albIdx)"
                let alb = ["id": "alb:\(aid)", "title": "album:\(aid)"]
                for trIdx in 0..<tracks {
                    let id = "\(aid).\(trIdx)"
                    let t = Track(["id": "track :  \(id)", "title": "title:\(id)",
                        "artist": art, "album": alb])
                    ts.append(t)
                }
            }
        }
        return ts
}

let shs = shufflables(lotsOfTracks(artists: 10, albumsPerArtist: 3, tracksPerAlbum: 5))
let st = shuffleTree(shufflables: shs,
                              by: [ShufflableTrack.artist,
                                    ShufflableTrack.album,
                                    ShufflableTrack.title])
let elements = st.shuffledElements {
    // This is a naive O(n + nlogn) merge for each keys
    // You may want to implement a smarter merge with a binary heap for exemple
    sillyMerge(sortedArrays: $0) { $0.spreadFactor < $1.spreadFactor }
}
let shuffledTracks = tracks(elements)
for t in shuffledTracks {
    println("\(t.id)")
}
