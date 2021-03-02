#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static Perl_ppaddr_t opcodes[OP_max];

static OP* croak_op(pTHX) {
	OP* current = PL_op;
	OP* next = opcodes[current->op_type](aTHX);
	SV* should_croak = cop_hints_fetch_pvs(PL_curcop, "autocroak", 0);
	if (should_croak != &PL_sv_placeholder && SvTRUE(should_croak)) {
		dSP;
		if (!SvOK(TOPs))
			Perl_croak(aTHX_ "Could not call %s: %s", PL_op_name[current->op_type], strerror(errno));
	}
	return next;
}


MODULE = autocroak				PACKAGE = autocroak

PROTOTYPES: DISABLED

BOOT:
	OP_CHECK_MUTEX_LOCK;
	if (!initialized) {
		initialized = 1;
#define INC_WRAPPER(TYPE) \
		opcodes[OP_##TYPE] = PL_ppaddr[OP_##TYPE];\
		PL_ppaddr[OP_##TYPE] = croak_op;
#include "autocroak.inc"
#undef INC_WRAPPER
	}
	OP_CHECK_MUTEX_UNLOCK;
