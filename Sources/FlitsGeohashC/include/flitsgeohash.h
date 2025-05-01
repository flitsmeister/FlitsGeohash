
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

char* GEOHASH_encode(double latitude, double longitude, unsigned int hash_length);
GEOHASH_neighbors* GEOHASH_get_neighbors(const char *hash);
void GEOHASH_free_neighbors(GEOHASH_neighbors *neighbors);

char* GEOHASH_get_adjacent(const char* hash, GEOHASH_direction dir);
