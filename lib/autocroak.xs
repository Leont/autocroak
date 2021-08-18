#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#undef UNLINK
#include "XSUB.h"
#include "ppport.h"

#include <sys/wait.h>

static Perl_ppaddr_t opcodes[OP_max];
#define pragma_base "autocroak/"
#define pragma_name pragma_base "enabled"
#define pragma_name_length (sizeof(pragma_name) - 1)
static U32 pragma_hash;

#ifndef cop_hints_exists_pvn
#define cop_hints_exists_pvn(cop, key, len, hash, flags) cop_hints_fetch_pvn(cop, key, len, hash, flags | 0x02)
#endif

#ifdef sv_string_from_errnum
#define sv_caterror(message, errno) sv_catsv(message, sv_string_from_errnum(errno, NULL))
#else
#define sv_caterror(message, errno) sv_catpv(message, strerror(errno))
#endif

#define autocroak_enabled() cop_hints_exists_pvn(PL_curcop, pragma_name, pragma_name_length, pragma_hash, 0)

bool S_errno_in_bitset(pTHX_ SV* arg, bool default_result) {
	if (SvPOK(arg)) {
		size_t byte = errno / 8;
		size_t position = 1 << (errno % 8);
		return byte < SvCUR(arg) && SvPVX(arg)[byte] & position;
	}
	return default_result;
}

#define allowed_for(TYPE, default_result) S_errno_in_bitset(aTHX_ cop_hints_fetch_pvs(PL_curcop, pragma_base #TYPE, 0), default_result)

#define dAXMARKI\
	int ax = TOPMARK + 1;\
	SV **mark = PL_stack_base + ax - 1;

#define throw_sv(message) croak_sv(sv_2mortal(message))

#define sv_catfile_maybe(message, filename) \
	if (SvPOK(filename)) {\
		sv_catpvs(message, " '");\
		sv_catsv(message, filename);\
		sv_catpvs(message, "'");\
	}\

#define UNDEFINED_WRAPPER(TYPE)\
static OP* croak_##TYPE(pTHX) {\
	OP* next = opcodes[OP_##TYPE](aTHX);\
	if (autocroak_enabled()) {\
		dSP;\
		if (!SvOK(TOPs) && !allowed_for(TYPE, FALSE)) {\
			SV* message = newSVpvs("Could not ");\
			sv_catpv(message, PL_op_desc[OP_##TYPE]);\
			sv_catpvs(message, ": ");\
			sv_caterror(message, errno);\
			throw_sv(message);\
		}\
	}\
	return next;\
}

#define UNDEFINED_FILE_WRAPPER(TYPE, FILENAME)\
static OP* croak_##TYPE(pTHX) {\
	dSP;\
	dAXMARKI;\
	SV* filename = FILENAME;\
	OP* next = opcodes[OP_##TYPE](aTHX);\
	if (autocroak_enabled()) {\
		SPAGAIN;\
		if (!SvOK(TOPs) && !allowed_for(TYPE, FALSE)) {\
			SV* message = newSVpvs("Could not ");\
			sv_catpv(message, PL_op_desc[OP_##TYPE]);\
			sv_catfile_maybe(message, filename);\
			sv_catpvs(message, ": ");\
			sv_caterror(message, errno);\
			throw_sv(message);\
		}\
	}\
	return next;\
}

#define NUMERIC_WRAPPER(TYPE, OFFSET)\
static OP* croak_##TYPE(pTHX) {\
	dSP;\
	dAXMARKI;\
	dITEMS;\
	size_t expected = items - OFFSET;\
	SV* filename = expected == 1 ? ST(OFFSET) : NULL;\
	OP* next = opcodes[OP_##TYPE](aTHX);\
	if (autocroak_enabled()) {\
		SPAGAIN;\
		UV got = SvUV(TOPs);\
		if (got < expected && !allowed_for(TYPE, FALSE))\
			if (expected == 1) {\
				SV* message = newSVpvs("Could not ");\
				sv_catpv(message, PL_op_desc[OP_##TYPE]);\
				sv_catfile_maybe(message, filename);\
				sv_catpvs(message, ": ");\
				sv_caterror(message, errno);\
				throw_sv(message);\
			}\
			else {\
				SV* message = newSVpvf("Could not %s (%lu/%lu times): ", PL_op_desc[OP_##TYPE], (expected-got) ,expected);\
				sv_caterror(message, errno);\
				throw_sv(message);\
			}\
	}\
	return next;\
}

#define FILETEST_WRAPPER(TYPE) \
static OP* croak_##TYPE(pTHX) {\
	dSP;\
	SV* filename = TOPs;\
	OP* next = opcodes[OP_##TYPE](aTHX);\
	if (autocroak_enabled()) {\
		SPAGAIN;\
		if (!SvOK(TOPs) && !allowed_for(TYPE, TRUE)) {\
				SV* message = newSVpvs("Could not ");\
				sv_catpv(message, PL_op_desc[OP_##TYPE]);\
				sv_catfile_maybe(message, filename);\
				sv_catpvs(message, ": ");\
				sv_caterror(message, errno);\
				throw_sv(message);\
		}\
	}\
	return next;\
}

#include "autocroak.inc"
#undef FILETEST_WRAPPER
#undef NUMERIC_WRAPPER
#undef UNDEFINED_FILE_WRAPPER
#undef UNDEFINED_WRAPPER

static OP* croak_OPEN(pTHX) {
	if (autocroak_enabled()) {
		dSP;
		dAXMARKI;
		dITEMS;\
		if (items == 3) {
			SV* mode = ST(1);
			SV* filename = ST(2);
			OP* next = opcodes[OP_OPEN](aTHX);
			SPAGAIN;
			if (!SvOK(TOPs) && !allowed_for(OPEN, FALSE)) {
				SV* message = newSVpvs("Could not open file");
				sv_catfile_maybe(message, filename);
				sv_catpvs(message, " with mode '");
				sv_catsv(message, mode);
				sv_catpvs(message, "': ");
				sv_caterror(message, errno);
				throw_sv(message);
			}
			return next;
		}
		else {
			OP* next = opcodes[OP_OPEN](aTHX);
			SPAGAIN;
			if (!SvOK(TOPs) && !allowed_for(OPEN, FALSE)) {
				SV* message = newSVpvs("Could not open: ");
				sv_caterror(message, errno);
				throw_sv(message);
			}
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
		if (SvTRUE(TOPs) && !allowed_for(SYSTEM, FALSE)) {
			int status = SvIV(TOPs);
			SV* message;
			if (status > 0) {
				message = newSVpvs("Call to system failed: ");
				if (WIFEXITED(status)) {
					sv_catpvf(message, "exited %d", WEXITSTATUS(status));
				}
				else if (WIFSIGNALED(status)) {
					int signum = WTERMSIG(status);
					sv_catpvf(message, "got signal (%s)", strsignal(signum));
				}
				else {
					assert(0);
				}
			}
			else {
				message = newSVpvs("Can't call system: ");
				sv_caterror(message, errno);
			}

			throw_sv(message);
		}
	}
	return next;
}

static OP* croak_PRINT(pTHX) {
	OP* next = opcodes[OP_PRINT](aTHX);
	if (autocroak_enabled()) {
		dSP;
		if (!SvTRUE(TOPs) && !allowed_for(PRINT, FALSE)) {
			SV* message = newSVpvs("Could not print: ");
			sv_caterror(message, errno);
			throw_sv(message);
		}
	}
	return next;
}

static OP* croak_FLOCK(pTHX) {
	if (autocroak_enabled()) {
		dSP;
		int non_blocking = TOPu & LOCK_NB;
		OP* next = opcodes[OP_FLOCK](aTHX);
		SPAGAIN;
		if (!SvOK(TOPs) && !allowed_for(FLOCK, non_blocking && errno == EAGAIN)) {
			SV* message = newSVpvs("Could not flock: ");
			sv_caterror(message, errno);
			throw_sv(message);
		}
		return next;
	}
	else
		return opcodes[OP_FLOCK](aTHX);
}

static OP* croak_SSELECT(pTHX) {
	dSP;
	dAXMARKI;
	OP* next = opcodes[OP_SSELECT](aTHX);
	if (autocroak_enabled()) {
		SPAGAIN;
		if (SvIV(ST(0)) < 0 && !allowed_for(SSELECT, FALSE)) {
			SV* message = newSVpvs("Could not select: ");
			sv_caterror(message, errno);
			throw_sv(message);
		}
	}
	return next;
}

static unsigned initialized;

MODULE = autocroak				PACKAGE = autocroak

PROTOTYPES: DISABLED

BOOT:
	OP_CHECK_MUTEX_LOCK;
	if (!initialized) {
		initialized = 1;
		PERL_HASH(pragma_hash, pragma_name, pragma_name_length);
#define OPCODE_REPLACE(TYPE) \
		opcodes[OP_##TYPE] = PL_ppaddr[OP_##TYPE];\
		PL_ppaddr[OP_##TYPE] = croak_##TYPE;
#define UNDEFINED_WRAPPER(TYPE) OPCODE_REPLACE(TYPE)
#define UNDEFINED_FILE_WRAPPER(TYPE, OFFSET) OPCODE_REPLACE(TYPE)
#define NUMERIC_WRAPPER(TYPE, OFFSET) OPCODE_REPLACE(TYPE)
#define FILETEST_WRAPPER(TYPE) OPCODE_REPLACE(TYPE)
#include "autocroak.inc"
		OPCODE_REPLACE(OPEN)
		OPCODE_REPLACE(SYSTEM)
		OPCODE_REPLACE(PRINT)
		OPCODE_REPLACE(FLOCK)
		OPCODE_REPLACE(SSELECT)
#undef FILETEST_WRAPPER
#undef NUMERIC_WRAPPER
#undef UNDEFINED_FILE_WRAPPER
#undef UNDEFINED_WRAPPER
	}
	OP_CHECK_MUTEX_UNLOCK;
