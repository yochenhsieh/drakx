/*
 * Guillaume Cottenceau (gc@mandrakesoft.com)
 *
 * Copyright 2000 MandrakeSoft
 *
 * This software may be freely redistributed under the terms of the GNU
 * public license.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

#ifndef _CONFIG_STAGE1_H_
#define _CONFIG_STAGE1_H_

#define _GNU_SOURCE 1


/* If we have more than that amount of memory, we assume we can load the second stage as a ramdisk */
#define MEM_LIMIT_RAMDISK 52 * 1024

#define DISTRIB_NAME "Linux-Mandrake"

/* user-definable (in Makefile): DISABLE_NETWORK, DISABLE_DISK, DISABLE_CDROM, DISABLE_PCMCIA */


/* some factorizing for disabling more features */

#ifdef DISABLE_DISK
#ifdef DISABLE_CDROM
#define DISABLE_MEDIAS
#endif
#endif


#endif
