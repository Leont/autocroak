#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static Perl_ppaddr_t opcodes[OP_max];

#ifndef cop_hints_exists_pvs
#define cop_hints_exists_pvs(cop, key, flags) cop_hints_fetch_pvs(cop, key, flags | 0x00000002)
#endif

#define INC_WRAPPER(TYPE)\
static OP* croak_##TYPE(pTHX) {\
	OP* next = opcodes[OP_##TYPE](aTHX);\
	if (cop_hints_exists_pvs(PL_curcop, "autocroak", 0)) {\
		dSP;\
		if (!SvOK(TOPs))\
			Perl_croak(aTHX_ "Could not call %s: %s", PL_op_name[OP_##TYPE], strerror(errno));\
	}\
	return next;\
}
#include "autocroak.inc"
#undef INC_WRAPPER

static unsigned initialized;

MODULE = autocroak				PACKAGE = autocroak

PROTOTYPES: DISABLED

BOOT:
	OP_CHECK_MUTEX_LOCK;
	if (!initialized) {
		initialized = 1;
#define INC_WRAPPER(TYPE) \
		opcodes[OP_##TYPE] = PL_ppaddr[OP_##TYPE];\
		PL_ppaddr[OP_##TYPE] = croak_##TYPE;
#include "autocroak.inc"
#undef INC_WRAPPER
	}
	OP_CHECK_MUTEX_UNLOCK;
