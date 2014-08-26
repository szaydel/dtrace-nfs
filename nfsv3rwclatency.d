#!/usr/sbin/dtrace -s
#pragma D option quiet
#pragma D option dynvarsize=10M

/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License, Version 1.0 only
 * (the "License").  You may not use this file except in compliance
 * with the License.
 *
 * You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
 * or http://www.opensolaris.org/os/licensing.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at usr/src/OPENSOLARIS.LICENSE.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */

/*
 * Copyright (c) 2014, RackTop Systems.
 * Sam Zaydel szaydel@racktopsystems.com
 */


nfsv3:::op-read-start {
  self->x[args[0]->ci_remote,
      args[1]->noi_curpath] = args[1]->noi_xid;

  ts[args[1]->noi_xid] = timestamp;
  }

nfsv3:::op-read-done /ts[args[1]->noi_xid] != 0
  && self->x[args[0]->ci_remote, args[1]->noi_curpath] == args[1]->noi_xid/ {
        this->delta = (timestamp - ts[args[1]->noi_xid]) / 1000;

  @reads[args[0]->ci_remote] = quantize(this->delta);
  /* Uncomment to get per-file latency (verbose)
  @rd_lat[args[0]->ci_remote, args[1]->noi_curpath] = avg(this->delta);
  */
  @rd_lat_av = avg(this->delta);
  ts[args[1]->noi_xid] = 0;
  self->x[args[0]->ci_remote, args[1]->noi_curpath] = 0;
}

nfsv3:::op-write-start {
  self->x[args[0]->ci_remote, args[1]->noi_curpath] = args[1]->noi_xid;
  ts[args[1]->noi_xid] = timestamp;
}

nfsv3:::op-write-done /ts[args[1]->noi_xid] != 0
    && self->x[args[0]->ci_remote, args[1]->noi_curpath] == args[1]->noi_xid/ {
          this->delta = (timestamp - ts[args[1]->noi_xid]) / 1000;

  @writes[args[0]->ci_remote] = quantize(this->delta);
  /* Uncomment to get per-file latency (verbose)
  @wr_lat[args[0]->ci_remote, args[1]->noi_curpath] = avg(this->delta);
  */
  @wr_lat_av = avg(this->delta);
  ts[args[1]->noi_xid] = 0;
  self->x[args[0]->ci_remote, args[1]->noi_curpath] = 0;
}

nfsv3:::op-commit-start {
  self->x[args[0]->ci_remote, args[1]->noi_curpath] = args[1]->noi_xid;
  ts[args[1]->noi_xid] = timestamp;
}

nfsv3:::op-commit-done /ts[args[1]->noi_xid] != 0
    && self->x[args[0]->ci_remote, args[1]->noi_curpath] == args[1]->noi_xid/ {
          this->delta = (timestamp - ts[args[1]->noi_xid]) / 1000;

  @commits[args[0]->ci_remote] = quantize(this->delta);
  /* Uncomment to get per-file latency (verbose)
  @cmt_lat[args[0]->ci_remote, args[1]->noi_curpath] = avg(this->delta);
  */
  @cmt_lat_av = avg(this->delta);
  ts[args[1]->noi_xid] = 0;
  self->x[args[0]->ci_remote, args[1]->noi_curpath] = 0;
}

END {
  /* normalize(@reads, 1000) */
  printa("\tREAD (us):\t\t\tClient: => %-16s %@d\n", @reads);
  printa("\tWRITE (us):\t\t\tClient: => %-16s %@d\n", @writes);
  printa("\tCOMMIT (us):\t\t\tClient: => %-16s %@d\n", @commits);
  /* Uncomment to get per-file latency (verbose)
  printa("[READ latency]: Client: %s Filepath: %s Latency(us): %@d\n", @rd_lat);
  printa("[WRITE latency]: Client: %s Filepath: %s Latency(us): %@d\n", @wr_lat);
  printa("[COMMIT latency]: Client: %s Filepath: %s Latency(us): %@d\n", @cmt_lat);
  */
  printa("Average Read Latency(us):\t%-8@d\n", @rd_lat_av);
  printa("Average Write Latency(us):\t%-8@d\n", @wr_lat_av);
  printa("Average Commit Latency(us):\t%-8@d\n", @cmt_lat_av);
}
