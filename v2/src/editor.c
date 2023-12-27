#include <stdio.h>

#include "bufengine.h"
#include "log.h"

int main(void) {
	bfe_Engine e;
	if (!bfe_Engine_init(&e)) return 1;

	logD("mmyeah! we're here");

	while (e.is_active) {
		int evc;
		bfe_EventTag tag;
		bfe_Event ev;

		for (evc = 0;; evc++) {
			/* fetch event (first one is obligatory and blocking) */
			if (evc == 0) bfe_waitForEvent(&e, &tag, &ev);
			else if (!bfe_pollEvent(&e, &tag, &ev)) break;

			switch (tag) {
			case BFE_EV_KEYDOWN:
				logD("KeyDown! (key %d)", ev.key);
				break;
			default:
				logD("Unknown event (tag %d)", tag);
				break;
			}

			/* TODO: propagate input events to current buffer. On that note,
			   There'll be windowing abilities, right? Or I can just skip that
			   and only think about it when I start working on the WM
			   implementation. */
		}

		/* TODO: render screen */
	}

	return 0;
}
