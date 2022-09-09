Central konfig
==============


This example can show how can be managed cluster of flussonic servers.


Please, mention that it is not a production, do not use this as is =)


You can find new component defined in 01-konfig.yaml and konfig folder.

How does it works?

When new publish stream comes to any pod in publish service via load balancer, flussonic asks for a new stream configuration
from this centralized konfig server.

New stream is recorded into mongodb and methods fetchTranscoders is called to find out what transcoders are available right now.

Fixed transcoder is assigned to this stream. This stream is targeted to transcoder via push option that is calculated dynamically.

Transcoder calculates configuration of this stream and performs some actions (or doesn't do anything as in this example).

Then restreamer gets this stream also via konfig app instead of using source directive.



Also take a look at logger in ../../lib/log2mongo that can be used as a prototype of json log uploader.

