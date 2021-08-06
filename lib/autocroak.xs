#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static Perl_ppaddr_t opcodes[OP_max];
#define pragma_name "autocroak"
#define pragma_name_length (sizeof(pragma_name) - 1)
static U32 pragma_hash;

#ifndef cop_hints_exists_pvn
#define cop_hints_exists_pvn(cop, key, len, hash, flags) cop_hints_fetch_pvn(cop, key, len, hash, flags | 0x02)
#endif

#define autocroak_enabled() cop_hints_exists_pvn(PL_curcop, pragma_name, pragma_name_length, pragma_hash, 0)

bool S_errno_in_bitset(pTHX_ SV* arg) {
	if (SvPOK(arg)) {
		size_t byte = errno / 8;
		size_t position = 1 << (errno % 8);
		if (byte < SvCUR(arg) && SvPVX(arg)[byte] & position)
			return TRUE;
	}
	return FALSE;
}

#define allowed_for(TYPE) S_errno_in_bitset(aTHX_ cop_hints_fetch_pvs(PL_curcop, pragma_name "_" #TYPE, 0))

#define INC_WRAPPER(TYPE)\
static OP* croak_##TYPE(pTHX) {\
	OP* next = opcodes[OP_##TYPE](aTHX);\
	if (autocroak_enabled()) {\
		dSP;\
		if (!SvOK(TOPs) && !allowed_for(TYPE))\
			Perl_croak(aTHX_ "Could not call %s: %s", PL_op_name[OP_##TYPE], strerror(errno));\
	}\
	return next;\
}
#include "autocroak.inc"
#undef INC_WRAPPER

static OP* croak_OPEN(pTHX) {
	if (autocroak_enabled()) {
		dSP;
		SV **mark = PL_stack_base + TOPMARK;
		if (SP - MARK == 3 && SvPOK(MARK[3])) {
			SV* mode = sv_2mortal(SvREFCNT_inc(MARK[2]));
			SV* filename = sv_2mortal(SvREFCNT_inc(MARK[3]));
			OP* next = opcodes[OP_OPEN](aTHX);
			SPAGAIN;
			if (!SvOK(TOPs) && !allowed_for(OPEN)) {
				SV* message = newSVpvs("Could not open file '");
				sv_catsv(message, filename); // this will handle unicode
				sv_catpvf(message, "' with mode %s: %s", SvPV_nolen(mode), strerror(errno));
				croak_sv(message);
			}
			return next;
		}
		else {
			OP* next = opcodes[OP_OPEN](aTHX);
			SPAGAIN;
			if (!SvOK(TOPs) && !allowed_for(OPEN))
				Perl_croak(aTHX_ "Could not open: %s", strerror(errno));
			return next;
		}
	}
	else
		return opcodes[OP_OPEN](aTHX);
}

static OP* croak_SYSTEM(pTHX) {
	OP* next = opcodes[OP_SYSTEM](aTHX);
	if (autocroak_enabled()) {
		dSP;
		if (SvTRUE(TOPs) && !allowed_for(SYSTEM))
			Perl_croak(aTHX_ "Can't call system: it returned %d", SvUV(TOPs));
	}
	return next;
}

static OP* croak_PRINT(pTHX) {
	OP* next = opcodes[OP_PRINT](aTHX);
	if (autocroak_enabled()) {
		dSP;
		if (!SvTRUE(TOPs) && !allowed_for(PRINT))
			Perl_croak(aTHX_ "Could not print: %s", strerror(errno));
	}
	return next;
}

static OP* croak_FLOCK(pTHX) {
	if (autocroak_enabled() && !allowed_for(FLOCK)) {
		dSP;
		int non_blocking = TOPu & LOCK_NB;
		OP* next = opcodes[OP_FLOCK](aTHX);
		SPAGAIN;
		if (!SvOK(TOPs) && !(non_blocking && errno == EAGAIN || allowed_for(FLOCK)))
			Perl_croak(aTHX_ "Could not flock: %s", strerror(errno));
		return next;
	}
	else
		return opcodes[OP_FLOCK](aTHX);
}

static unsigned initialized;

MODULE = autocroak				PACKAGE = autocroak

PROTOTYPES: DISABLED

BOOT:
	OP_CHECK_MUTEX_LOCK;
	if (!initialized) {
		initialized = 1;
		PERL_HASH(pragma_hash, pragma_name, pragma_name_length);
#define INC_WRAPPER(TYPE) \
		opcodes[OP_##TYPE] = PL_ppaddr[OP_##TYPE];\
		PL_ppaddr[OP_##TYPE] = croak_##TYPE;
#include "autocroak.inc"
		INC_WRAPPER(OPEN)
		INC_WRAPPER(SYSTEM)
		INC_WRAPPER(PRINT)
		INC_WRAPPER(FLOCK)
#undef INC_WRAPPER
	}
	OP_CHECK_MUTEX_UNLOCK;
