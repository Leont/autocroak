#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static OP* (*old_chk_open)(pTHX_ OP*);

static OP* croak_open(pTHX) {
	OP* next = PL_ppaddr[OP_OPEN](aTHX);
	dSP;
	if (!SvOK(TOPs))
		Perl_croak(aTHX_ "Could not call open: %s", strerror(errno));
	return next;
}

static OP* ch_open(pTHX_ OP* op) {
	SV** svp = hv_fetchs(GvHVn(PL_hintgv), "autocroak", 0);
	if(svp && SvIV(*svp))
		op->op_ppaddr = croak_open;
	return old_chk_open(aTHX_ op);
}

MODULE = autocroak				PACKAGE = autocroak

PROTOTYPES: DISABLED

BOOT:
	old_chk_open = PL_check[OP_OPEN];
	PL_check[OP_OPEN] = ch_open;
