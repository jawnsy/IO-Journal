/* Journal.xs: Perl interface for journalled file operations
 *
 * This is a Perl XS interface to libjio, which was written by Alberto
 * Bertogli and released into the public domain circa 2009.
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
#include <sys/types.h>
#include <unistd.h>
#include <libjio.h>
#include "model.h"

MODULE = IO::Journal    PACKAGE = IO::Journal

PROTOTYPES: DISABLE

IO::Journal
sysopen(class, filename, flags, perms = 0666)
  char *class
  char *filename
  int flags
  int perms
  PREINIT:
    journal *self;
    int ret;
    struct jfsck_result result;
  INIT:
    Newx(self, 1, journal);
  CODE:
    /* Clean up past transactions */
    jfsck(filename, NULL, &result);
    jfsck_cleanup(filename, NULL);

    ret = jopen(&(self->jfs), filename, flags, perms, 0);
    if (ret < 0)
      croak("Error opening file: %s", filename);

    /* Save the fd for future use */
    self->fd = ret;

    if (flags & O_APPEND)
      jlseek(&(self->jfs), 0, SEEK_END); /* point to end of file */
    else
      jlseek(&(self->jfs), 0, SEEK_SET); /* point to beginning */

    RETVAL = self;
  OUTPUT:
    RETVAL

SV *
sysread(self, ...)
  IO::Journal self
  PREINIT:
    char *buf;
    size_t count = 1024;
    size_t ret;
  INIT:
    /* count */
    if (SvIOK(ST(1)))
      count = (size_t) SvIV(ST(1));

    Newx(buf, count, char);
  CODE:
    /* offset */
    if (SvIOK(ST(2)))
      ret = jpread(&(sel->jfs), buf, count, (off_t) SvIV(ST(2)));
    else
      ret = jread(&(self->jfs), buf, count);

    RETVAL = newSVpvn(buf, ret);
  OUTPUT:
    RETVAL
  CLEANUP:
    Safefree(buf);

void
DESTROY(self)
  IO::Journal self
  CODE:
    jclose(&(self->jfs));
    Safefree(self);
