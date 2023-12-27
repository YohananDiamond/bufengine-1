#ifndef _BUFENGINE_H
#define _BUFENGINE_H

#include <stdbool.h>

/**
 * Constants
 */
#define BFE_FLAG_ALLOW_RELEASE (1 << 0)
#define BFE_EV_KEYDOWN 1

typedef struct bfe_Engine {
	bool is_active;
	void *context; /* the state */
} bfe_Engine;

typedef unsigned bfe_EventTag;
typedef union bfe_Event {
	unsigned key;
} bfe_Event;

/**
 * Main API
 */
bool bfe_Engine_init(bfe_Engine *e);
bool bfe_pollEvent(bfe_Engine *e, bfe_EventTag *tag, bfe_Event *ev);
bool bfe_waitForEvent(bfe_Engine *e, bfe_EventTag *tag, bfe_Event *ev);

/**
 * Foreign interface (implementation)
 */
void *bfe_impl_initContext(void);
bool bfe_impl_getEvent(void *context, bfe_EventTag *tag, bfe_Event *ev, int timeout_ms);
void bfe_impl_deinitContext(void *_c);

#endif /* _BUFENGINE_H */
