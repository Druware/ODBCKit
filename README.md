# ODBCKit

The ODBCKit is an open source framework for Mac developers to leverage the underlying Open Database Connectivity resources in the business network. Built with the intent of providing an easy and approachable toolkit for Mac Developers, it evolved into a little bit more, also providing a simple graphical query tool as well as a couple of Automator Actions to the provide user level access to the ODBC databases.

What this means in the real world is that using this toolkit, it should be easier to write and maintain applications that have ready access to enterprise level data sources like Oracle, Microsoft SQL Server and others. Why is this a big deal? well, one of the biggest concerns with the Mac platform is business applications. If there is an easy way to create and maintain applications that use the same enterprise database engines as their Windows counterparts, expanding the Mac in to the world of big business and corporate development becomes just a little bit easier.

By making this open source, specifically under the BSD license model, the toolkit is readily usable in both commercial and open source projects without concern for the viral nature of some of the open source alternatives while allowing users to guide the forward evolution of the project through both suggestions and code contributions.
## ODBCKit, Objective-C, the legacy

As a project, there is a long history here, in fact it is the second longest running project that Druware has worked on, with origins going back to 2004. Originally written in Objective-C, using design cues from tools like Microsoft's own database objects, as well as concepts from platforms like Delphi's database access objects, it was a ground up wrapper around the generic ODBC platform. It was not really built with the idea of sharing it with the world, it was built to fill a personal need and desire. Life, time, and opportunities  change how plans evolve. 

In 2005, a friend expressed a need for something similar to this project, and when explaining it to him, he asked if he could use it. I sent him a copy, and over a few conversations we decided that I should make it open source and public. So it was that it landed on SourceForge where it has lived for the last 20 years, and the last 10 of those with very little direct attention. It worked, the tools I built around it worked and there was little need to enhance it. 

## ODBCKit, Swift Version

Enter 2026, and a couple of new projects that could leverage the ODBCKit into those workflows. Pulling the code down, and integrating it into some newer projects, the legacy of Objective-C was showing its age. So we decided it was time for a rewrite into Swift. Swift has some very nice features ( and also some very tedious things when it comes to C interop ). So, we started the rework. In less than a week, a foundation was built, and yes, there is now a functioning Swift implementation, and it has moved on to GitHub.

New? yes.  Improved? still in progress. 

## Like What You See? Contribute!

Though we do all of the development on this project under the auspices of Druware, we have no commercial products built upon it that pay for it. If you find it useful, make a contribution. All of those donations go directly to the people writing the code and doing the maintenance.
