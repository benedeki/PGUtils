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
    - [can_role_alter_table](#can_role_alter_table)
    - [global_id](#global_id)
    - [lock_mutex](#lock_mutex)
    - [log_to_console](#log_to_console)
    - [restore_all_constraints](#restore_all_constraints)
    - [restore_constraints](#restore_constraints)    
    - [suspend_constraints](#suspend_constraints)
- [Contributing to PG Utils](#contributing-to-pg-utils)
  - [Did you find a bug?](#did-you-find-a-bug)
  - [Do you want to request a new feature?](#do-you-want-to-request-a-new-feature)
  - [Do you want to implement a new feature, fix a bug or improved the documentation?](#do-you-want-to-implement-a-new-feature-fix-a-bug-or-improved-the-documentation) 
- [Tests](#tests)
- [Notes](#notes)
  - [Constraint types](#constraint-types)

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

| Parameter           | Type              | Description                                                                                                                                                  |
|---------------------|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `i_array`           | array of any type | The array of any type to check                                                                                                                               |
| `i_nulls_distinct`  | BOOLEAN           | if TRUE, NULL values are treated as distinct, otherwise they are considered duplicates if appearing more than once in the array. The default value is FALSE. |

| Returns      |                                                                                                            |
|--------------|------------------------------------------------------------------------------------------------------------|
| BOOLEAN      | `TRUE` if the array contains only unique values,<br/>`FALSE` if the array has at least one duplicate value |

### Schema `pgutils`

#### can_role_alter_table

Checks if the specified role has permissions to alter the given table. 

| Parameter      | Type   | Default      | Description                                                                                                                                                                                                                |
|----------------|--------|--------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| i_schema_name  | TEXT   | -            | Schema name of the table to check the permissions for.                                                                                                                                                                     | 
| i_table_name   | TEXT   | -            | Table name for which the permissions should be checked.                                                                                                                                                                    | 
| i_role_name    | TEXT   | session_user | Name of the role for which the permissions should be checked. If not provided the user connected to the session is considered (not the owner of the function that calls this function even if `SECURITY DEFINER` is used). | 

| Returns   |         |                                                                              |
|-----------|---------|------------------------------------------------------------------------------|
| can_alter | BOOLEAN | `TRUE` if the role has the permission to alter the table, `FALSE` otherwise. |

#### global_id

Generates a unique ID, with the proper setup unique over all your servers

| Returns |                           |
|---------|---------------------------|
| BIGINT  | The unique 64-bit integer |

#### lock_mutex

The goal of this function is to implement concurrent operation execution - operation is given in the input parameter.

Call this function at the beginning of an operation (usually a wider UPDATE/INSERT) that you want to prevent concurrent
execution of, and the release will happen automatically when the transaction finishes or rolls back.

| Parameter    | Type | Description                                                                                                                                                                                                                                              |
|--------------|------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| i_mutex_name | TEXT | The name of the lock, usually the name of the function that wants to acquire the lock. This is used to prevent concurrent execution of the same function. Operations with the same `i_mutex_name` are serialized, different ones don't block each other. |

#### log_to_console

Prints out a message to the console, optionally prefixed by current timestamp. Useful when a progress report is handy
during long operations.

| Parameter       | Type    | Default | Description                                                                       |
|-----------------|---------|---------|-----------------------------------------------------------------------------------|
| i_log_message   | TEXT    | -       | Message to write into the console.                                                | 
| i_add_timestamp | BOOLEAN | `TRUE` | If TRUE, message is prefixed by a timestamp, otherwise only the message is output. | 


#### restore_all_constraints

Restores all the constraints that were temporarily suspended, presumably by
[`pgutils.suspend_constraints`](#suspend_constraints) function, and returns the schema, table name and info of the
restored constraint.

| Parameter              | Type    | Default | Description                                                                                                                                                                                                                                                                                                                                                                        |
|------------------------|---------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| i_enforced_valid_state | BOOLEAN | `NULL`  | Setting that can enforce the constraints to be restored in certain validity state regardless  of previous state. If set to `TRUE`, all the constraints will be restored as VALID, if set to `FALSE`, all the constraints will be restored as NOT VALID, and if set to NULL (default), the constraints will be restored to their previous state regardless of their previous state. | 

| Returns (set)   |         |                                                                      |
|-----------------|---------|----------------------------------------------------------------------|
| schema_name     | TEXT    | Schema name of the table for which the constraint has been restored. |
| table_name      | TEXT    | Table name for which the constraint has been restored.               |
| constraint_name | TEXT    | Name of the restored constraint.                                     |
| constraint_type | TEXT    | Type of the restored constraint.                                     |
| validated       | BOOLEAN | Whether the constraint is valid after being restored.                |

Possible returned constraint types can be seen in [constraint types](#constraint-types), the `char` column.

#### restore_constraints

Restores all the constraints for a given table that were temporarily suspended, presumably by 
`pgutils.suspend_constraints` function, and returns the names of the restored constraints.

| Parameter              | Type    | Default  | Description                                                                                                                                                                                                                                                                                                                                                                        |
|------------------------|---------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| i_schema_name          | TEXT    | 'public' | Schema name of the table for which the constraints should be restored.                                                                                                                                                                                                                                                                                                             | 
| i_table_name           | TEXT    | -        | Table name for which the constraints should be restored.                                                                                                                                                                                                                                                                                                                            |
| i_enforced_valid_state | BOOLEAN | `NULL`   | Setting that can enforce the constraints to be restored in certain validity state regardless  of previous state. If set to `TRUE`, all the constraints will be restored as VALID, if set to `FALSE`, all the constraints will be restored as NOT VALID, and if set to NULL (default), the constraints will be restored to their previous state regardless of their previous state. | 

| Returns (set)   |         |                                                       |
|-----------------|---------|-------------------------------------------------------|
| constraint_name | TEXT    | Name of the restored constraint.                      |
| constraint_type | TEXT    | Type of the restored constraint.                      |
| validated       | BOOLEAN | Whether the constraint is valid after being restored. |

Possible returned constraint types can be seen in [constraint types](#constraint-types), the `char` column.

#### suspend_constraints

suspends all the constraints of the specified types for a given table and stores their definitions in a table.

| Parameter          | Type     | Default  | Description                                                                                                                                                                                                                                                                                                                                                                                   |
|--------------------|----------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| i_schema_name      | TEXT     | 'public' | Schema name of the table for which the constraints should be suspended.                                                                                                                                                                                                                                                                                                                       | 
| i_table_name       | TEXT     | -        | Table name for which the constraints should be suspended.                                                                                                                                                                                                                                                                                                                                     |
| i_constraint_types | TEXT[]   | `NULL`   | Array of constraint types to suspend. If `NULL` all constraints are suspended.                                                                                                                                                                                                                                                                                                                |
| i_persistently     | BOOLEAN  | `FALSE`  | Flag that indicates whether the suspended constraints should be stored persistently so it last over transactions.<br>**NB!** Use persistence CAREFULLY RESPONSIBLY, as the constraints will be suspended until they are explicitly restored and can lead to data integrity issues. Only a user with grant to alter the table can use this option, otherwise the function will raise an error. |

See accepted [constraint types](#constraint-types).

| Returns (set)   |      |                                   |
|-----------------|------|-----------------------------------|
| constraint_name | TEXT | Name of the suspended constraint. |
| constraint_type | CHAR | Type of the suspended constraint. |

Possible returned constraint types can be seen in [constraint types](#constraint-types), the `char` column. 

#### suspend_constraints_by_name

suspends all the constraints of the provided names for a given table and stores their definitions in a table.

| Parameter          | Type     | Default  | Description                                                                                                                                                                                                                                                                                                                                                                                   |
|--------------------|----------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| i_schema_name      | TEXT     | 'public' | Schema name of the table for which the constraints should be suspended.                                                                                                                                                                                                                                                                                                                       | 
| i_table_name       | TEXT     | -        | Table name for which the constraints should be suspended.                                                                                                                                                                                                                                                                                                                                     |
| i_constraint_names | TEXT[]   | -        | Array of constraint names to suspend.                                                                                                                                                                                                                                                                                                                                                         |
| i_persistently     | BOOLEAN  | `FALSE`  | Flag that indicates whether the suspended constraints should be stored persistently so it last over transactions.<br>**NB!** Use persistence CAREFULLY RESPONSIBLY, as the constraints will be suspended until they are explicitly restored and can lead to data integrity issues. Only a user with grant to alter the table can use this option, otherwise the function will raise an error. |

| Returns (set)   |      |                                  |
|-----------------|------|----------------------------------|
| constraint_name | TEXT | Name of the suspended constraint. |
| constraint_type | TEXT | Type of the suspended constraint. |

Possible returned constraint types can be seen in [constraint types](#constraint-types), the `char` column.

## Tests

Tests are written using the [Balta](https://github.com/AbsaOSS/balta) Scala library, and the whole test suites is and sbt project.

To run the tests, you need to have sbt installed and configured on your machine. Then you can use the following command 
in the root directory of the project to run all tests:

```bash
psql -h host -p port -U user -d dbname -f tests/src/test/resources/test_users.ddl
psql -h host -p port -U user -d dbname  -c "GRANT CONNECT ON DATABASE [dbname] TO pgutils_tester;"
sbt test
```

where you need to replace `host`, `port`, `user` and `dbname` with the appropriate values for your Postgres database
(the same values that were used for installation).

## Contributing to PG Utils

### Did you find a bug?

* **Ensure the bug has not already been reported** by searching the **[GitHub Issues](https://github.com/benedeki/PGUtils/issues)**.
* If you are unable to find an open issue describing the problem, use the **Bug report** template to open a new one.

### Do you want to request a new feature?

* **Ensure the feature has not already been requested** by searching the **[GitHub Issues](https://github.com/benedeki/PGUtils/issues)**.
* If you are unable to find the feature request, create a new one.

### Do you want to implement a new feature, fix a bug or improved the documentation?

* Check [_Issues_](https://github.com/benedeki/PGUtils/issues) logs for the feature/bug. Check if someone isn't already working on it.
* If the issue or bug doesn't exist, please write it up first (see above).
* Assign the issue to yourself, so others know that someone is working on it.
* Fork the repository. (unless you have access to the main repository, in that case you can create a branch directly in the main repository)
* Follow the naming conventions for branches  - best is to use the automation workflow that creates the branch name based on the issue number and title. Type `/create-branch` in the comment section of the issue and the branch will be created for you.
  * The branch will be cut from the main and will have the issue number and title in the name, prefixed by the type of the work (_feature_, _bugfix_, _docs_ or _infra_).
* Code away. Ask away. 
  * Commit messages should start with a reference to the GitHub Issue and provide a brief description in the imperative mood:
    * **"#42 Answer the ultimate question"**
  * Don't forget to write tests for your work.
* After finishing everything, push to your forked repo/branch and open a Pull Request to the project main branch:
  * Pull Request titles should start with the Github Issue number:
    * **"42 Life, the universe and everything"**
  * Ensure the Pull Request description clearly describes the solution.
  * Add a section **Release notes** to the PR description:
    * The release notes will be utilized by the automation to generate the release notes for the release, using [generate-release-notes action](https://github.com/AbsaOSS/generate-release-notes). 
    * Add a line for each change that should be included in the release notes, prefixed by a bullet point. The line should be concise and clear, describing the change in a way that is suitable for release notes.
    * If the change doesn't need to be included in the release notes (like a documentation change), add a label `no RN` to the PR
  * Connect the PR to the _Issue_

**Thanks!**

## Notes

Originally it was intended to name the package and main schema _pg_utils_, and the owning role _pg_utils_owner_. 
But the prefix `pg_` is reserved for Postgres internal objects, so we had to rename the objets. Just omitting the
underscore seems to be the best option.

### Constraint types
The following constraint types are supported by the `suspend_constraints` and `list_constraints` functions 
(case-insensitive):

| Constraint type (word) | Constraint type (char) | Description            |
|------------------------|------------------------|------------------------|
| `CHECK`                | `c`                    | CHECK constraint       |
| `FOREIGN KEY`          | `f`                    | FOREIGN KEY constraint |
| `PRIMARY KEY`          | `p`                    | PRIMARY KEY constraint |
| `UNIQUE`               | `u`                    | UNIQUE constraint      |
| `NOT NULL`             | `n`                    | NOT NULL constraint    |
| `EXCLUSION`            | `x`                    | EXCLUSION constraint   |
