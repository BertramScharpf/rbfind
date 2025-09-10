# RbFind

A substitute for the Unix find tool using Ruby expressions


## Description

RbFind does the same as the standard Unix find tool but has a
different calling syntax. Specify your search reqest as a
Ruby expression.


## Features

  * ls long format style output
  * Built-in grep
  * Colored ls and grep output
  * Automatically exclude version control system or Vim swap files
  * No dependecies


## Example

Find files that were modified in the last five minutes.

```sh
rbfind -p 'file and age < 5.m'
```

Grep whole directory but skip `.git/` or `.svn/`, and
`.filename.swp`.

```sh
rbfind -CWg require
```

Save time and do not grep large files.

```sh
rbfind 'filesize < 100.kB and grep /require/'
```

Output ls long format.

```sh
rbfind -P
```

Print MD5 digest and size for each file.

```sh
rbfind 'spacesep digest_md5, size.w8, path'
```


## Copyright

  * (C) 2008-2025, Bertram Scharpf <software@bertram-scharpf.de>
  * License: [BSD-2-Clause+](./LICENSE)
  * Repository: [ruby-nvim](https://github.com/BertramScharpf/rbfind.git)

