#ifndef __MK_lock_primitives_H___
#define __MK_lock_primitives_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* Modification history:

   daj/july 25, 1990 - Created file and changed extern to static.
   daj/july 22, 1991 - Added arg to rec_mutex_unlock. Flushed C_ARG_DECLS crap.

 */

/*
 * rec_mutex.h
 *
 * Mutex locks which allow recursive locks and unlocks by the same thread.
 *
 * Michael B. Jones
 *
 * 24-Jun-1987
 */

/*
 * HISTORY:
 * $Log$
 * Revision 1.1  1999/06/28 23:51:32  leigh
 * Initial revision
 *
 * Revision 2.1.1.1  89/07/28  14:49:15  mbj
 *     Check parallel libc and file mapping changes into source tree branch.
 * 
 * 13-Dec-88  Mary Thompson (mrt) @ Carnegie Mellon
 *    Changed string_t to char * as string_t is no longer
 *    defined by cthreads.h
 *
 * 24-Jun-87  Michael Jones (mbj) at Carnegie-Mellon University
 *    Started from scratch.
 */

#ifndef _REC_MUTEX_
#define _REC_MUTEX_ 1

#import <mach/cthreads.h>

/*
 * Recursive mutex definition.
 */
typedef struct rec_mutex {
    struct mutex    cthread_mutex;    /* Mutex for the first time */
    cthread_t        thread;        /* Thread holding mutex */
    unsigned long    count;        /* Number of outstanding locks */
} *rec_mutex_t;

/*
 * Recursive mutex operations.
 */

static rec_mutex_t
rec_mutex_alloc(void);

static void
rec_mutex_init(rec_mutex_t m);

#if 0
static void
rec_mutex_set_name (rec_mutex_t m, char * name);

static char *
rec_mutex_name (rec_mutex_t m);

static void
rec_mutex_clear (rec_mutex_t m);

static void
rec_mutex_free (rec_mutex_t m);
#endif

static int
rec_mutex_try_lock (rec_mutex_t m);

static void
rec_mutex_lock (rec_mutex_t m);

static void
rec_mutex_unlock_no_count(rec_mutex_t m);

static void
rec_mutex_unlock (rec_mutex_t m);

#endif _REC_MUTEX_



#endif
