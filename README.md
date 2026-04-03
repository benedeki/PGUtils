# PG Utils

PG Utils is a collection of utility functions (and supporting structures) that simplify some tasks and offer abilities 
that are often needed when working with Postgres databases. 

*Table of contents*
- [Installation](#installation)
- [Usage](#usage)
- [Documentation](#documentation)
  - [Schema `pgarray`](#schema-pgarray)
    - [is_unique](#is_unique)
  - [Schema `pgutils`](#schema-pgutils)
    - [global_id](#global_id)
    - [lock_mutex](#lock_mutex)
    - [log_to_console](#log_to_console)
- [Tests](#tests)

## Installation

For now use command

```bash
psql "postgres://user:passowrd@host:port/dbname" -f install.psql
```

or if you use .pgpass file for authentication, you can omit the password and use:

```bash
psql -h host -p port -U user -d dbname -f install.psql
```

or integrate with your deployment/migration tool of choice,

or deploy it manually executing each file found in the database folder.

## Usage

All functions are available in the `pgutils` and `pgarray` schemas. And they are assigned to the `public` role, so 
they are available to all users by default. 

Objects not having `public` role assigned  are intended to be user only by 
the library itself and are not intended to be used directly by users of the library. They are not documented in the 
documentation section below.

## Documentation

### Schema `pgarray`

#### is_unique

Checks if the array contains only unique values

| Parameter           | Type              | Description                                                                            |
|---------------------|-------------------|----------------------------------------------------------------------------------------|
| `i_array`           | array of any type | The array of any type to check                                                         |
| `i_nulls_distinct`  | BOOLEAN           | if TRUE, NULL values are treated as distinct, otherwise they are considered duplicates |

| Returns      |                                                                                                            |
|--------------|------------------------------------------------------------------------------------------------------------|
| BOOLEAN      | `TRUE` if the array contains only unique values,<br/>`FALSE` if the array has at least one duplicate value |

### Schema `pgutils`

#### global_id

Generates a unique ID, with the proper setup unique over all your servers

| Returns |                           |
|---------|---------------------------|
| BIGINT  | The unique 64-bit integer |

### lock_mutex

The goal of this function is to implement concurrent operation execution - operation is given in the input parameter.

Call this function at the beginning of an operation (usually a wider UPDATE/INSERT) that you want to prevent concurrent
execution of, and the release will happen automatically when the transaction finishes or rolls back.

| Parameter    | Type | Description                                                                                                                |
|--------------|------|----------------------------------------------------------------------------------------------------------------------------|
| i_mutex_name | TEXT | Name of the operation that will perform the lock. The name is the key for locking, different names won't block each other. |

### log_to_console

Prints out a message to the console, optionally prefixed by current timestamp. Useful when a progress report is handy
during long operations.

| Parameter       | Type    | Default | Description                                                                       |
|-----------------|---------|---------|-----------------------------------------------------------------------------------|
| i_log_message   | TEXT    | -       | Message to write into the console.                                                | 
| i_add_timestamp | BOOLEAN | `TRUE` | If TRUE, message is prefixed by a timestamp, otherwise only the message is output. | 

## Tests

Test will be added in the future using the [Balta](https://github.com/AbsaOSS/balta) library.

## Notes

Originally it was intended to name the package and main schema _pg_utils_, and the owning role _pg_utils_owner_. 
But the prefix `pg_` is reserved for Postgres internal objects, so we had to rename the objets. Just omitting the
underscore seems to be the best option.
