Proposal for implementing column-wise tables in PyTables
========================================================

:Author: Francesc Alted
:Date: 2012-04-13

Abstract
~~~~~~~~

Both NumPy and PyTables implement tables that are arranged row-wise.
This approach works well for performing lookups on top of very large
tables with a relatively small record size (typically <= 64 bytes).

However, there are a lot of user cases where a column-wise arrangement
would be more beneficial, like for example being able to add or remove
columns efficiently, having tables with a much larger record size, or
columns that could have a variable length elements (varchar, ragged
arrays or BLOBs).

Rational
~~~~~~~~

What's a Table in PyTables?
---------------------------

PyTables is a package that provides efficient containers for data
on-disk.  It revolves around its central object called Table.  A Table
is a fixed-record size object that allows the user to deal with
tabular data in an easy and effective way.  PyTables implements
several different ways to query the data that is included on it, like
the regular, in-kernel and indexed searches.  Also, while the Table
objects are two-dimensional (i.e. rows and columns), it supports that
any of the columns could be a multidimensional array.

However, one of the limitations of the current Table implementation in
PyTables is that data is arranged in a row-wise way, so the different
fields on every record are contiguous, while data in individual
columns are obviously strided.  This has proved to be a great
limitation in several use case scenarios.

Examples of Table limitations
-----------------------------

One first example of these limitations is the adding and removal of
columns, that implies a complete rewriting of the underlying data in
the table.  Obviously, when you are dealing with extremely large
tables, this is not desirable (and sometimes, not even possible).

Another example where row-wise tables suck is when coping with tables
with a large number of columns, and the user is only interested in
scanning for a few of them.  Due to the nature of a row-wise table,
the data from all the columns will have to be loaded, even if the user
is only interested in just some of them.

CWTable: a column-wise table for PyTables
-----------------------------------------

Implementing a column-wise variety of Table (let's call it CWTable)
would solve all the above problems, and in addition, would allow
compressors work better --the reason being that compressing an
homogeneous array is typically much more efficient than using an
heterogenous one.

An in-memory column-wise table too?
-----------------------------------

carray is a chunked container for numerical data.  Chunking allows for
efficient enlarging/shrinking of data container.  In addition, it can
also be compressed for reducing memory needs.  The compression process
is carried out internally by Blosc, a high-performance compressor that
is optimized for binary data.

Also, the carray package comes with a handy object, called ctable,
that arranges data by column (and not by row, as in NumPy’s structured
arrays).  This allows for much better performance for walking tabular
data by column and also for adding and deleting columns.

As such, PyTables would benefit if it could make use of a
carray.ctable container for hosting column-wise data in-memory, which
would become the obvious object to use when fetching data from the
CWTable.

Implementation
~~~~~~~~~~~~~~

Leveraging existing infraestructure
-----------------------------------

The CWTable (Column Wise Table) should make use of the existing
EArray, VLArray and Group infraestructure in current PyTables.  The
Group would hold all the metainformation about the table, either by
using attributes or small datasets (both with reserved names).

The data for fixed-length columns will be stored on EArrays that will
grow or shrink just as more rows are added or removed.  The
undimensional EArray-based columns will be eligible to be indexed, and
queries would be able to involve as many indexes as desired.  Even
indexes that correspond to other Table or CWTable objects could be
used too (as long as their length is compatible).

Plus: Variable length columns supported too
-------------------------------------------

Also, variable-length data columns will be stored in existing VLArray
objects, allowing to enrich the data types supported with (large)
variable length ascii or unicode strings, ragged arrays, or just
binary BLOBs.

Other features
--------------

CWTable should implement support for easily adding and removing
columns.  This should be as easy as adding or removing a new EArray or
VLArray to the parent Group of the CWTable.

Finally, CWTable should inherit from Node (and possibly from Table too, or any
other intemediate class), so all the operations that work with Node
objects (copy, move, remove...) will work for them too.

carray.ctable in-memory column-wise container
---------------------------------------------

There already exists machinery in PyTables to allow the user to select
the in-memory containers that will be handed out during reads, so this
should be pretty easy to implement.

The feature supporting this is the `flavor` attribute in the Leaf
class.  By assigning this attribute to something like "carray", would
be enough for handing out a carray object.

In addition, it would be nice if one additional global parameter could
be added to the "tables/parameters.py" so that the default flavor
could be chosen more easily.
