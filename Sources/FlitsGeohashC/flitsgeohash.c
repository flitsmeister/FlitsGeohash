
#include "flitsgeohash.h"
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

#define MAX_HASH_LENGTH 22
#define MAX_ITERATIONS 100000

#define SET_BIT(bits, mid, range, val, bit) \
    mid = (range->min + range->max) / 2.0; \
    if (val > mid) { \
        bits |= (1 << bit); \
        range->min = mid; \
    } else { \
        range->max = mid; \
    }

static const char BASE32_ENCODE_TABLE[32] = "0123456789bcdefghjkmnpqrstuvwxyz";

static const char NEIGHBORS_TABLE[8][32] = {
    "p0r21436x8zb9dcf5h7kjnmqesgutwvy", /* NORTH EVEN */
    "bc01fg45238967deuvhjyznpkmstqrwx", /* NORTH ODD  */
    "bc01fg45238967deuvhjyznpkmstqrwx", /* EAST EVEN  */
    "p0r21436x8zb9dcf5h7kjnmqesgutwvy", /* EAST ODD   */
    "238967debc01fg45kmstqrwxuvhjyznp", /* WEST EVEN  */
    "14365h7k9dcfesgujnmqp0r2twvyx8zb", /* WEST ODD   */
    "14365h7k9dcfesgujnmqp0r2twvyx8zb", /* SOUTH EVEN */
    "238967debc01fg45kmstqrwxuvhjyznp"  /* SOUTH ODD  */
};

static const char BORDERS_TABLE[8][9] = {
    "prxz",     /* NORTH EVEN */
    "bcfguvyz", /* NORTH ODD */
    "bcfguvyz", /* EAST  EVEN */
    "prxz",     /* EAST  ODD */
    "0145hjnp", /* WEST  EVEN */
    "028b",     /* WEST  ODD */
    "028b",     /* SOUTH EVEN */
    "0145hjnp"  /* SOUTH ODD */
};

char* 
GEOHASH_encode(double lat, double lon, unsigned int len)
{
    char *hash;
    unsigned char bits = 0;
    double mid;
    GEOHASH_range lat_range = { 90, -90 };
    GEOHASH_range lon_range = { 180, -180 };

    double val1, val2, val_tmp;
    GEOHASH_range *range1, *range2, *range_tmp;

    hash = (char *)malloc(sizeof(char) * (len + 1));
    if (hash == NULL)
        return NULL;

    val1 = lon; range1 = &lon_range;
    val2 = lat; range2 = &lat_range;

    for (int i = 0; i < len; i++) {
        bits = 0;

        SET_BIT(bits, mid, range1, val1, 4);
        SET_BIT(bits, mid, range2, val2, 3);
        SET_BIT(bits, mid, range1, val1, 2);
        SET_BIT(bits, mid, range2, val2, 1);
        SET_BIT(bits, mid, range1, val1, 0);

        hash[i] = BASE32_ENCODE_TABLE[bits];
        
        val_tmp   = val1;
        val1      = val2;
        val2      = val_tmp;
        range_tmp = range1;
        range1    = range2;
        range2    = range_tmp;
    }

    hash[len] = '\0';

    return hash;
}

GEOHASH_neighbors*
GEOHASH_get_neighbors(const char* hash)
{
    GEOHASH_neighbors *neighbors;

    neighbors = (GEOHASH_neighbors*)malloc(sizeof(GEOHASH_neighbors));
    if (neighbors == NULL)
        return NULL;

    neighbors->north = GEOHASH_get_adjacent(hash, GEOHASH_NORTH);
    neighbors->east  = GEOHASH_get_adjacent(hash, GEOHASH_EAST);
    neighbors->west  = GEOHASH_get_adjacent(hash, GEOHASH_WEST);
    neighbors->south = GEOHASH_get_adjacent(hash, GEOHASH_SOUTH);

    neighbors->north_east = GEOHASH_get_adjacent(neighbors->north, GEOHASH_EAST);
    neighbors->north_west = GEOHASH_get_adjacent(neighbors->north, GEOHASH_WEST);
    neighbors->south_east = GEOHASH_get_adjacent(neighbors->south, GEOHASH_EAST);
    neighbors->south_west = GEOHASH_get_adjacent(neighbors->south, GEOHASH_WEST);

    return neighbors;
}

void
GEOHASH_free_neighbors(GEOHASH_neighbors *neighbors)
{
    free(neighbors->north);
    free(neighbors->east);
    free(neighbors->west);
    free(neighbors->south);
    free(neighbors->north_east);
    free(neighbors->south_east);
    free(neighbors->north_west);
    free(neighbors->south_west);
    free(neighbors);
}

char*
GEOHASH_get_adjacent(const char* hash, GEOHASH_direction dir)
{
    int len, idx;
    const char *border_table, *neighbor_table;
    char *base, *refined_base, *ptr, last;

    len  = strlen(hash);
    last = tolower(hash[len - 1]);
    idx  = dir * 2 + (len % 2);

    border_table = BORDERS_TABLE[idx];

    base = (char *)malloc(sizeof(char) * (len + 1));
    if (base == NULL)
        return NULL;
    memset(base, '\0', sizeof(char) * (len + 1));

    strncpy(base, hash, len - 1);

    if (strchr(border_table, last) != NULL) {
        refined_base = GEOHASH_get_adjacent(base, dir);
        if (refined_base == NULL) {
            free(base);
            return NULL;
        }
        strncpy(base, refined_base, strlen(refined_base));
        free(refined_base);
    }

    neighbor_table = NEIGHBORS_TABLE[idx];

    ptr = strchr(neighbor_table, last);
    if (ptr == NULL) {
        free(base);
        return NULL;
    }
    idx = (int)(ptr - neighbor_table);
    len = strlen(base);
    base[len] = BASE32_ENCODE_TABLE[idx];
    return base;
}

void add_hash(GeohashArray* array, char* hash) {
    if (array->count >= array->capacity) {
        int new_capacity = array->capacity * 2;
        char** new_hashes = realloc(array->hashes, new_capacity * sizeof(char*));
        if (!new_hashes) {
            // Allocation failed
            GEOHASH_free_array(array);
            free(hash);
            exit(EXIT_FAILURE);
        }
        array->hashes = new_hashes;
        array->capacity = new_capacity;
    }
    array->hashes[array->count++] = hash;
}

int geohash_equals(const char* a, const char* b) {
    return strcmp(a, b) == 0;
}

char* GEOHASH_clone(const char* hash) {
    if (!hash) {
        exit(EXIT_FAILURE);
        return NULL;
    }
    
    char* clone = strdup(hash);
    if (!clone) {
        exit(EXIT_FAILURE);
        return NULL;
    }
    return clone;
}

GeohashArray
GEOHASH_hashes_for_region(double centerLat, double centerLon, double latDelta, double lonDelta, unsigned int len) {
    
    double north = centerLat + latDelta / 2.0;
    double south = centerLat - latDelta / 2.0;
    double west  = centerLon - lonDelta / 2.0;
    double east  = centerLon + lonDelta / 2.0;
    
    char* nw = GEOHASH_encode(north, west, len);
    char* ne = GEOHASH_encode(north, east, len);
    char* se = GEOHASH_encode(south, east, len);
    
    char* current = GEOHASH_clone(nw);
    char* eastLimit = GEOHASH_clone(ne);
    char* westStart = GEOHASH_clone(nw);
    
    GeohashArray result = {
        .hashes = malloc(128 * sizeof(char*)),
        .count = 0,
        .capacity = 128
    };
    if (!result.hashes) {
        // Allocation failed
        exit(EXIT_FAILURE);
    }
    
    add_hash(&result, GEOHASH_clone(current));
    
    int maxIterations = MAX_ITERATIONS; // Prevent infinite loops
    while (!geohash_equals(current, se) && maxIterations-- > 0) {
        if (geohash_equals(nw, ne)) {
            // Single column case
            char* nextSouth = GEOHASH_get_adjacent(westStart, GEOHASH_SOUTH);
            free(westStart);
            westStart = nextSouth;
            free(current);
            current = GEOHASH_clone(westStart);
            add_hash(&result, GEOHASH_clone(current));
            continue;
        }
        
        // Move east
        char* next = GEOHASH_get_adjacent(current, GEOHASH_EAST);
        free(current);
        current = next;
        add_hash(&result, GEOHASH_clone(current));

        if (geohash_equals(current, eastLimit) && !geohash_equals(current, se)) {
            char* tmp;
            
            tmp = GEOHASH_get_adjacent(eastLimit, GEOHASH_SOUTH);
            free(eastLimit);
            eastLimit = tmp;
            
            tmp = GEOHASH_get_adjacent(westStart, GEOHASH_SOUTH);
            free(westStart);
            westStart = tmp;
            
            free(current);
            current = GEOHASH_clone(westStart);
            add_hash(&result, GEOHASH_clone(current));
        }
    }
    
    // Cleanup
    free(nw);
    free(ne);
    free(se);
    free(current);
    free(eastLimit);
    free(westStart);
    
    return result;
}

void GEOHASH_free_array(GeohashArray* array) {
    for (int i = 0; i < array->count; i++) {
        free(array->hashes[i]);
    }
    free(array->hashes);
    array->hashes = NULL;
    array->count = 0;
    array->capacity = 0;
}
