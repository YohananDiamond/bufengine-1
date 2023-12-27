#ifndef _IMPL_TERMINAL
#define _IMPL_TERMINAL

#include "bufengine.h"
#include "log.h"
#include <ncurses.h>
#include <stdlib.h>

typedef struct Context {
	WINDOW *win;
} Context;

unsigned ncurses2keycode(unsigned x) {
	return x; /* TODO: un-no-op */
}

void *bfe_impl_initContext(void) {
	Context *ctx;
	ctx = malloc(sizeof(Context));
	if (!ctx) return NULL;

	ctx->win = initscr();
	if (ctx->win == NULL) return NULL;

	if (raw() == ERR) return NULL;
	if (noecho() == ERR) return NULL;
	if (nodelay(ctx->win, true) == ERR) return NULL;
    if (attroff(A_BLINK) == ERR) return NULL;

	return ctx;
}

bool bfe_impl_getEvent(void *_c, bfe_EventTag *tag, bfe_Event *ev, int timeout_ms) {
	unsigned ch;

	/* FIXME: timeout not working? */
	timeout(timeout_ms);
	ch = getch();

	if (ch == ERR) return false;
	
	*tag = BFE_EV_KEYDOWN;
	ev->key = ncurses2keycode(ch);
	return true;
}

void bfe_impl_deinitContext(void *_c) {
	/* Context *ctx = (Context*)_c; */
	free(_c);
	endwin();
}

#endif /* _IMPL_TERMINAL */
