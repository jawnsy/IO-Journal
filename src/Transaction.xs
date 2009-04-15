/* Transaction.xs: Perl interface for manipulation of transactions
 *
 * This is a Perl XS interface to libjio's transaction mechanism.
 *
 * This package and its contents are released by the author into the Public
 * Domain, to the full extent permissible by law. For additional information,
 * please see the included `LICENSE' file.
 *
 * $Id$
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <libjio.h>
#include <sys/types.h>
#include <unistd.h>
#include "model.h"

MODULE = IO::Journal::Transaction    PACKAGE = IO::Journal::Transaction

PROTOTYPES: DISABLE

IO::Journal::Transaction
new(class, journal)
  char *class
  IO::Journal journal
  PREINIT:
    transaction *self;
  INIT:
    Newx(self, 1, transaction); /* allocate 1 transaction instance */
  CODE:
    self->journal = journal;
    jtrans_init(&(journal->jfs), &(self->jtrans));
    RETVAL = self;
  OUTPUT:
    RETVAL

void
syswrite(self, text, ...)
  IO::Journal::Transaction self
  char *text
  PREINIT:
    size_t count;
    off_t offset;
    int ret;
  CODE:
    if (!SvIOK(ST(2))) /* count */
      count = strlen(text);

    if (!SvIOK(ST(3))) /* offset */
      offset = jlseek(&(self->journal->jfs), 0, SEEK_CUR);

    ret = jtrans_add(&(self->jtrans), text, count, offset);
    if (ret > 0) /* If success, advance file pointer */
      jlseek(&(self->journal->jfs), count, SEEK_CUR);

void
commit(self)
  IO::Journal::Transaction self
  PREINIT:
    int r;
  CODE:
    r = jtrans_commit(&(self->jtrans));
    if (r < 0)
      croak("Error during commit. Data may be lost.");

void
rollback(self)
  IO::Journal::Transaction self
  PREINIT:
    int r;
  CODE:
    r = jtrans_rollback(&(self->jtrans));
    if (r < 0)
      croak("Error encountered while rolling back");

void
DESTROY(self)
  IO::Journal::Transaction self
  CODE:
    jtrans_free(&(self->jtrans));
    Safefree(self);
