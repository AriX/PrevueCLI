#include <stdint.h>

#if !defined(PPCF_INLINE)
    #if defined(__GNUC__) && (__GNUC__ == 4) && !defined(DEBUG)
        #define PPCF_INLINE static __inline__ __attribute__((always_inline))
    #elif defined(__GNUC__)
        #define PPCF_INLINE static __inline__
    #elif defined(__cplusplus)
	#define PPCF_INLINE static inline
    #elif defined(_MSC_VER)
        #define PPCF_INLINE static __inline
    #elif TARGET_OS_WIN32
	#define PPCF_INLINE static __inline__
    #endif
#endif

#if (defined(__CYGWIN32__) || defined(_WIN32)) && !defined(__WIN32__)
#define __WIN32__ 1
#endif

#if defined(_WIN64) && !defined(__WIN64__)
#define __WIN64__ 1
#endif

#if defined(__WIN64__) && !defined(__LLP64__)
#define __LLP64__ 1
#endif

#if defined(_MSC_VER) && defined(_M_IX86)
#define __i386__ 1
#endif

#if (defined(__i386__) || defined(__x86_64__)) && !defined(__LITTLE_ENDIAN__)
#define __LITTLE_ENDIAN__ 1
#endif

#if !defined(__BIG_ENDIAN__) && !defined(__LITTLE_ENDIAN__)
#error Do not know the endianess of this architecture
#endif

#if !__BIG_ENDIAN__ && !__LITTLE_ENDIAN__
#error Both __BIG_ENDIAN__ and __LITTLE_ENDIAN__ cannot be false
#endif

#if __BIG_ENDIAN__ && __LITTLE_ENDIAN__
#error Both __BIG_ENDIAN__ and __LITTLE_ENDIAN__ cannot be true
#endif

#if (TARGET_OS_OSX || TARGET_OS_IPHONE) && !defined(PPCF_USE_OSBYTEORDER_H)
#include <libkern/OSByteOrder.h>
#define PPCF_USE_OSBYTEORDER_H 1
#endif

PPCF_INLINE uint32_t PPCFSwapInt32(uint32_t arg) {
#if PPCF_USE_OSBYTEORDER_H
    return OSSwapInt32(arg);
#else
    uint32_t result;
    result = ((arg & 0xFF) << 24) | ((arg & 0xFF00) << 8) | ((arg >> 8) & 0xFF00) | ((arg >> 24) & 0xFF);
    return result;
#endif
}

PPCF_INLINE uint64_t PPCFSwapInt64(uint64_t arg) {
#if PPCF_USE_OSBYTEORDER_H
    return OSSwapInt64(arg);
#else
    union PPCFSwap {
        uint64_t sv;
        uint32_t ul[2];
    } tmp, result;
    tmp.sv = arg;
    result.ul[0] = PPCFSwapInt32(tmp.ul[1]); 
    result.ul[1] = PPCFSwapInt32(tmp.ul[0]);
    return result.sv;
#endif
}

typedef struct {uint32_t v;} PPCFSwappedFloat32;
typedef struct {uint64_t v;} PPCFSwappedFloat64;

PPCF_INLINE PPCFSwappedFloat32 PPCFConvertFloatHostToSwapped(float arg) {
    union PPCFSwap {
	float v;
	PPCFSwappedFloat32 sv;
    } result;
    result.v = arg;
#if __LITTLE_ENDIAN__
    result.sv.v = PPCFSwapInt32(result.sv.v);
#endif
    return result.sv;
}

PPCF_INLINE PPCFSwappedFloat64 PPCFConvertDoubleHostToSwapped(double arg) {
    union PPCFSwap {
	double v;
	PPCFSwappedFloat64 sv;
    } result;
    result.v = arg;
#if __LITTLE_ENDIAN__
    result.sv.v = PPCFSwapInt64(result.sv.v);
#endif
    return result.sv;
}

PPCF_INLINE float PPCFConvertFloatSwappedToHost(PPCFSwappedFloat32 arg) {
    union PPCFSwap {
    float v;
    PPCFSwappedFloat32 sv;
    } result;
    result.sv = arg;
#if __LITTLE_ENDIAN__
    result.sv.v = PPCFSwapInt32(result.sv.v);
#endif
    return result.v;
}

PPCF_INLINE double PPCFConvertDoubleSwappedToHost(PPCFSwappedFloat64 arg) {
    union PPCFSwap {
    double v;
    PPCFSwappedFloat64 sv;
    } result;
    result.sv = arg;
#if __LITTLE_ENDIAN__
    result.sv.v = PPCFSwapInt64(result.sv.v);
#endif
    return result.v;
}
