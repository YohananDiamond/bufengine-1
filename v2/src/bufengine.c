#include "bufengine.h"

#include <stddef.h>

bool bfe_Engine_init(bfe_Engine *e) {
	e->is_active = true;
	e->context = bfe_impl_initContext();
	if (e->context == NULL) return false;
	return true;
}

bool bfe_pollEvent(bfe_Engine *e, bfe_EventTag *tag, bfe_Event *ev) {
	return bfe_impl_getEvent(e->context, tag, ev, 0);
}

bool bfe_waitForEvent(bfe_Engine *e, bfe_EventTag *tag, bfe_Event *ev) {
	return bfe_impl_getEvent(e->context, tag, ev, -1);
}
