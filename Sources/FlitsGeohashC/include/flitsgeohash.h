
typedef enum {
    GEOHASH_NORTH = 0,
    GEOHASH_EAST,
    GEOHASH_WEST,
    GEOHASH_SOUTH
} GEOHASH_direction;

typedef struct {
    double max;
    double min;
} GEOHASH_range;

typedef struct {
    char* north;
    char* east;
    char* west;
    char* south;
    char* north_east;
    char* south_east;
    char* north_west;
    char* south_west;
} GEOHASH_neighbors;

typedef struct {
    char** hashes;
    int count;
    int capacity;
} GeohashArray;

char* GEOHASH_encode(double latitude, double longitude, unsigned int hash_length);
GEOHASH_neighbors* GEOHASH_get_neighbors(const char *hash);
void GEOHASH_free_neighbors(GEOHASH_neighbors *neighbors);

char* GEOHASH_get_adjacent(const char* hash, GEOHASH_direction dir);

GeohashArray GEOHASH_hashes_for_region(double centerLatitude, double centerLongitude, double latitudeDelta, double longitudeDelta, unsigned int len);
void GEOHASH_free_array(GeohashArray* array);
