# Shuffle

This Swift playground demonstrates a possible implementation of the Shuffle described by Lukáš Poláček from Spotify here:

https://labs.spotify.com/2014/02/28/how-to-shuffle-songs/

This is by no means an efficient implementation for large lists of tracks.
It generates a small data set with a structure similar to the "Track" resource from the Spotify REST API. Querying and parsing Spotify resources is not the focus of this playground, so it's a little bit ugly there.

The important part is the group/spread/merge logic.
The main idea is to recursively group tracks based on a set of keys, then spread them, and merge them back. The spread/merge acts as some kind of random interleaving.

The current merge is very naive. A merge using a binary heap/priority queue would be more efficient.

The next step would be to add some visualization to give a better feeling of the effect of this algorithm compared to the Fisher-Yates shuffle.
