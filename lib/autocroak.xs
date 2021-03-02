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

#define BOOT_WRAPPER(TYPE)\
	opcodes[OP_##TYPE] = PL_ppaddr[OP_##TYPE];\
	PL_ppaddr[OP_##TYPE] = croak_op;

MODULE = autocroak				PACKAGE = autocroak

PROTOTYPES: DISABLED

BOOT:
	BOOT_WRAPPER(OPEN);
	BOOT_WRAPPER(SYSOPEN);
	BOOT_WRAPPER(CLOSE);
	BOOT_WRAPPER(TRUNCATE);
	BOOT_WRAPPER(EXEC);
	BOOT_WRAPPER(SYSTEM);
	BOOT_WRAPPER(FORK);

	BOOT_WRAPPER(BIND);
	BOOT_WRAPPER(CONNECT);
	BOOT_WRAPPER(LISTEN);
	BOOT_WRAPPER(SSOCKOPT);

	BOOT_WRAPPER(LSTAT);
	BOOT_WRAPPER(STAT);
	BOOT_WRAPPER(CHDIR);
	BOOT_WRAPPER(CHOWN);
	BOOT_WRAPPER(CHROOT);
	BOOT_WRAPPER(UNLINK);
	BOOT_WRAPPER(CHMOD);
	BOOT_WRAPPER(UTIME);
	BOOT_WRAPPER(RENAME);
	BOOT_WRAPPER(LINK);
	BOOT_WRAPPER(SYMLINK);
	BOOT_WRAPPER(READLINK);
	BOOT_WRAPPER(MKDIR);
	BOOT_WRAPPER(RMDIR);
	BOOT_WRAPPER(OPEN_DIR);
	BOOT_WRAPPER(READDIR);
	BOOT_WRAPPER(CLOSEDIR);

	BOOT_WRAPPER(REQUIRE);
	BOOT_WRAPPER(DOFILE);

	BOOT_WRAPPER(GHBYADDR);
	BOOT_WRAPPER(GNBYADDR);
